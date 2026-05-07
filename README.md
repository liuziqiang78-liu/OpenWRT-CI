# 🚀 OpenWRT Cloud Builder

现代化的 OpenWRT 路由器固件云编译 WebUI，基于 GitHub Actions 实现云端编译。

## 项目架构

```
openwrt-cloud-builder/
├── backend/           # Python FastAPI 后端 API 服务
├── frontend/          # React + Vite + TailwindCSS 前端
└── docker-compose.yml # 一键启动
```

## 核心功能

- 🔑 **GitHub Token 认证** - 安全验证 GitHub 身份
- 🌿 **分支选择** - main-nss / 25.12-nss
- 💻 **硬件平台选择** - 按厂商/平台/设备三级联动
- 🧩 **插件选择** - 14 大分类，100+ 插件，支持外部插件扩展
- 🛡️ **防火墙选择** - iptables / nftables
- ⚡ **ccache 加速** - 编译缓存提速
- 📤 **自动上传** - 编译完成自动发布到 Releases
- ⚙️ **自定义配置** - Root 密码、WiFi 名称/密码
- 📋 **编译概览** - 一键查看所有配置汇总

## 数据来源

- **源码仓库**: [LiBwrt/openwrt-6.x](https://github.com/LiBwrt/openwrt-6.x)
- **CI 配置**: [liuziqiang78-liu/OpenWRT-CI](https://github.com/liuziqiang78-liu/OpenWRT-CI)

## 快速启动

### 方式一: Docker Compose (推荐)

```bash
docker-compose up -d
```

访问 http://localhost:3000

### 方式二: 手动启动

**后端:**
```bash
cd backend
pip install -r requirements.txt
python run.py
```

**前端:**
```bash
cd frontend
npm install
npm run dev
```

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `CONFIG_DIR` | OpenWRT-CI 配置目录路径 | `../OpenWRT-CI/config` |
| `BACKEND_URL` | 后端 API 地址 | `http://localhost:8000` |
| `PORT` | 后端端口 | `8000` |

## API 文档

启动后端后访问: http://localhost:8000/docs

## 许可证

MIT
