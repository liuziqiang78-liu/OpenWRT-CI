/**
 * API 服务 - GitHub Pages 版本
 * 直接调用 GitHub API，配置数据从静态 JSON 加载
 */

const GITHUB_OWNER = 'LiBwrt';
const GITHUB_REPO = 'openwrt-6.x';
const GITHUB_API = 'https://api.github.com';
const WORKFLOW_FILE = 'build.yml';

// 静态配置数据缓存
let configCache: any = null;

/**
 * 加载静态配置数据
 */
async function loadConfig(): Promise<any> {
  if (configCache) return configCache;
  const resp = await fetch(`${import.meta.env.BASE_URL}config-data.json`);
  configCache = await resp.json();
  return configCache;
}

/**
 * 验证 GitHub Token
 */
export async function verifyToken(token: string) {
  const resp = await fetch(`${GITHUB_API}/user`, {
    headers: { Authorization: `token ${token}`, Accept: 'application/vnd.github.v3+json' },
  });
  if (!resp.ok) throw new Error('Token 无效');
  const user = await resp.json();
  return { valid: true, login: user.login, avatar_url: user.avatar_url, html_url: user.html_url };
}

/**
 * 获取分支列表
 */
export async function fetchBranches() {
  const config = await loadConfig();
  return config.branches;
}

/**
 * 获取平台列表 - 转换 JSON 数据结构为组件期望的格式
 * JSON: platforms[].platforms[].devices[{id,name,profile}]
 * 组件: platforms[].targets[].devices[{id,name}]
 */
export async function fetchPlatforms() {
  const config = await loadConfig();
  return (config.platforms || []).map((vendor: any) => ({
    vendor: vendor.vendor,
    targets: (vendor.platforms || []).map((plat: any) => ({
      name: plat.name,
      devices: (plat.devices || []).map((d: any) =>
        typeof d === 'string' ? { id: d, name: d } : { id: d.profile || d.id, name: d.name }
      ),
      firewall_options: plat.firewall_options || ['iptables', 'nftables'],
      rootfs_options: plat.rootfs_options || [],
      wifi: plat.wifi ?? false,
      emmc: plat.emmc ?? false,
    })),
  }));
}

/**
 * 获取插件列表 - 转换 JSON 数据结构
 * JSON: plugins[].category / plugins[].plugins[].desc
 * 组件: PluginCategory.id / Plugin.description
 */
export async function fetchPlugins(category?: string) {
  const config = await loadConfig();
  const cats = (config.plugins || []).map((c: any) => ({
    id: c.category,
    name: c.name,
    icon: c.icon,
    plugins: (c.plugins || []).map((p: any) => ({
      name: p.name,
      description: p.desc || p.description || '',
      category: p.category || c.category,
    })),
  }));
  if (category) {
    return cats.filter((c: any) => c.id === category);
  }
  return cats;
}

/**
 * 获取防火墙类型
 */
export async function fetchFirewalls() {
  const config = await loadConfig();
  return config.firewalls;
}

/**
 * 触发 GitHub Actions 编译
 */
export async function triggerBuild(params: {
  token: string;
  branch: string;
  platform: string;
  subtarget: string;
  devices: string[];
  plugins: string[];
  external_plugins?: any[];
  firewall: string;
  rootfs: string;
  enable_ccache: boolean;
  upload_to_releases: boolean;
  template: string;
  root_password: string;
  wifi_ssid: string;
  wifi_password: string;
  lan_ip: string;
}) {
  const { token, ...rest } = params;
  const inputs: Record<string, string> = {
    source_branch: rest.branch,
    target: rest.platform,
    subtarget: rest.subtarget,
    firewall: rest.firewall,
    rootfs: rest.rootfs || 'squashfs',
    profile: rest.devices.join(' '),
    plugins: rest.plugins.join(' '),
    root_password: rest.root_password,
    lan_ip: rest.lan_ip || '192.168.1.1',
    wifi_ssid: rest.wifi_ssid,
    wifi_password: rest.wifi_password,
    enable_ccache: String(rest.enable_ccache),
    template: rest.template,
    upload_artifacts: String(rest.upload_to_releases),
  };

  const resp = await fetch(
    `${GITHUB_API}/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/workflows/${WORKFLOW_FILE}/dispatches`,
    {
      method: 'POST',
      headers: {
        Authorization: `token ${token}`,
        Accept: 'application/vnd.github.v3+json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ ref: rest.branch, inputs }),
    }
  );

  if (!resp.ok) {
    const err = await resp.text();
    throw new Error(`触发编译失败: ${resp.status} ${err}`);
  }

  // 获取最新的 workflow run
  await new Promise(r => setTimeout(r, 2000));
  const runsResp = await fetch(
    `${GITHUB_API}/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runs?per_page=1`,
    { headers: { Authorization: `token ${token}`, Accept: 'application/vnd.github.v3+json' } }
  );
  const runs = await runsResp.json();
  const run = runs.workflow_runs?.[0];

  return {
    run_id: run?.id,
    html_url: run?.html_url || `https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}/actions`,
  };
}

/**
 * 查询编译状态
 */
export async function getBuildStatus(token: string, runId: number) {
  const resp = await fetch(
    `${GITHUB_API}/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runs/${runId}`,
    { headers: { Authorization: `token ${token}`, Accept: 'application/vnd.github.v3+json' } }
  );
  if (!resp.ok) throw new Error('查询状态失败');
  const data = await resp.json();
  return {
    status: data.status,
    conclusion: data.conclusion,
    url: data.html_url,
    created_at: data.created_at,
    updated_at: data.updated_at,
  };
}
