#!/usr/bin/env python3
"""
MiMo v2.5 Pro WebUI Server
云端 API 模式 - 端口 9081
所有 API 请求通过此代理转发到云端，解决 CORS 和 Token 问题
"""

import http.server, socketserver, json, os, sys, urllib.request, urllib.error

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 9081
if not (1024 <= PORT <= 65535):
    print(f"[WebUI] 错误: 端口 {PORT} 无效")
    sys.exit(1)

WEBUI_DIR = os.path.dirname(os.path.abspath(__file__))
CONFIG_FILE = '/data/adb/mimo/config/mimo_mode.json'

# ── 配置加载 ──────────────────────────────────────────
MIMO_API   = 'https://api.mi.com/v1'
MIMO_TOKEN = ''

def load_config():
    global MIMO_API, MIMO_TOKEN
    # 环境变量优先
    MIMO_API = os.environ.get('MIMO_API', MIMO_API)
    MIMO_TOKEN = os.environ.get('MIMO_TOKEN', MIMO_TOKEN)
    # 配置文件覆盖
    if os.path.exists(CONFIG_FILE):
        try:
            with open(CONFIG_FILE) as f:
                cfg = json.load(f)
            MIMO_API = cfg.get('api', {}).get('url', MIMO_API)
            MIMO_TOKEN = cfg.get('api', {}).get('token', MIMO_TOKEN)
        except: pass

def save_token(token):
    """保存 Token 到配置文件"""
    global MIMO_TOKEN
    MIMO_TOKEN = token
    try:
        if os.path.exists(CONFIG_FILE):
            with open(CONFIG_FILE) as f:
                cfg = json.load(f)
        else:
            cfg = {"mode": "cloud", "api": {}}
        cfg['api']['token'] = token
        with open(CONFIG_FILE, 'w') as f:
            json.dump(cfg, f, indent=4)
    except Exception as e:
        print(f"[WebUI] 保存 Token 失败: {e}")

load_config()
print(f"[WebUI] API: {MIMO_API} | Token: {'✓' if MIMO_TOKEN else '✗'}")

# ── 请求处理 ──────────────────────────────────────────
class H(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *a, **kw):
        super().__init__(*a, directory=WEBUI_DIR, **kw)

    def do_GET(self):
        if self.path == '/api/config':
            return self._handle_config_get()
        if self.path == '/api/health':
            return self._proxy('GET', '/health')
        if self.path == '/api/models':
            return self._proxy('GET', '/v1/models')
        if self.path == '/v1/models':
            return self._proxy('GET', '/v1/models')
        if self.path == '/':
            self.path = '/index.html'
        super().do_GET()

    def do_POST(self):
        if self.path == '/api/config':
            return self._handle_config_post()
        # 所有 /v1/* 和 /api/* 请求代理到云端
        if self.path.startswith('/v1/'):
            api_path = self.path  # /v1/chat/completions → /v1/chat/completions
            return self._proxy('POST', api_path)
        if self.path.startswith('/api/'):
            api_path = self.path.replace('/api/', '/v1/', 1)
            return self._proxy('POST', api_path)
        self.send_error(404)

    def do_OPTIONS(self):
        self.send_response(200)
        self._cors()
        self.end_headers()

    # ── 配置接口 ──────────────────────────────────────
    def _handle_config_get(self):
        cfg = {
            'mode': 'cloud',
            'apiUrl': MIMO_API,
            'token': MIMO_TOKEN,
            'hasToken': bool(MIMO_TOKEN),
            'model': 'mimo-v2.5-pro'
        }
        self._json_response(200, cfg)

    def _handle_config_post(self):
        try:
            body = self.rfile.read(int(self.headers.get('Content-Length', 0)))
            data = json.loads(body) if body else {}
            if 'token' in data:
                save_token(data['token'])
                self._json_response(200, {'ok': True, 'hasToken': bool(MIMO_TOKEN)})
            else:
                self._json_response(400, {'error': 'missing token'})
        except Exception as e:
            self._json_response(500, {'error': str(e)})

    # ── JSON 响应 ─────────────────────────────────────
    def _json_response(self, code, data):
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Content-Length', len(body))
        self._cors()
        self.end_headers()
        self.wfile.write(body)

    # ── 代理转发 ──────────────────────────────────────
    def _proxy(self, method, path):
        try:
            # 修复: MIMO_API 已含 /v1，path 也含 /v1，需去重
            # /v1/chat/completions → /chat/completions
            # /health → /health (不变)
            api_suffix = path
            if api_suffix.startswith('/v1/'):
                api_suffix = api_suffix[3:]  # 去掉 /v1 前缀，保留 /chat/completions
            url = MIMO_API + api_suffix

            # 读取请求体
            content_length = int(self.headers.get('Content-Length', 0))
            body = self.rfile.read(content_length) if content_length > 0 else None

            # 构建代理请求
            req = urllib.request.Request(url, data=body, method=method)

            # ★ Token: 优先用前端传来的，其次用服务端配置的
            auth = self.headers.get('Authorization', '')
            if auth:
                req.add_header('Authorization', auth)
            elif MIMO_TOKEN:
                req.add_header('Authorization', f'Bearer {MIMO_TOKEN}')

            # 透传 Content-Type
            ct = self.headers.get('Content-Type')
            if ct:
                req.add_header('Content-Type', ct)

            # 发送请求
            with urllib.request.urlopen(req, timeout=120) as r:
                resp_ct = r.headers.get('Content-Type', '')

                # ★ SSE 流式响应
                if 'text/event-stream' in resp_ct:
                    self.send_response(200)
                    self.send_header('Content-Type', 'text/event-stream')
                    self.send_header('Cache-Control', 'no-cache')
                    self.send_header('Connection', 'keep-alive')
                    self.send_header('X-Accel-Buffering', 'no')  # 禁止 nginx 缓冲
                    self._cors()
                    self.end_headers()
                    try:
                        while True:
                            ln = r.readline()
                            if not ln:
                                break
                            self.wfile.write(ln)
                            self.wfile.flush()
                    except (BrokenPipeError, ConnectionResetError):
                        pass
                    return

                # 普通响应
                rb = r.read()
                self.send_response(200)
                self.send_header('Content-Type', resp_ct)
                self.send_header('Content-Length', len(rb))
                self._cors()
                self.end_headers()
                self.wfile.write(rb)

        except urllib.error.HTTPError as e:
            # 尝试读取错误响应体
            try:
                err_body = e.read()
                self.send_response(e.code)
                self.send_header('Content-Type', 'application/json')
                self._cors()
                self.end_headers()
                self.wfile.write(err_body)
            except:
                self._json_response(e.code, {'error': {'message': str(e.reason), 'code': e.code}})

        except urllib.error.URLError as e:
            self._json_response(502, {'error': {'message': f'无法连接云端 API: {e.reason}', 'code': 502}})

        except Exception as e:
            self._json_response(500, {'error': {'message': str(e), 'code': 500}})

    def _cors(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type, Authorization')

    def log_message(self, fmt, *a):
        # 只记录请求行，不记录每行日志
        if 'GET' in str(a) or 'POST' in str(a):
            print(f"[WebUI] {a[0]}")

# ── 启动 ──────────────────────────────────────────────
print(f"""
╔═══════════════════════════════════════╗
║  MiMo v2.5 Pro  WebUI                ║
╠═══════════════════════════════════════╣
║  http://localhost:{PORT:<19}║
║  API → {MIMO_API:<29}║
║  Token: {'✓ configured' if MIMO_TOKEN else '✗ not set':<28}║
╚═══════════════════════════════════════╝
""")

with socketserver.TCPServer(("", PORT), H) as s:
    try:
        s.serve_forever()
    except KeyboardInterrupt:
        print("\n[WebUI] stopped")
        s.shutdown()
