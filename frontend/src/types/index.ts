// TypeScript 类型定义

// GitHub 用户信息
export interface GitHubUser {
  login: string
  avatar_url: string
  html_url: string
}

// 分支信息
export interface Branch {
  name: string
  description: string
  default?: boolean
}

// 平台信息（三级联动）
export interface Platform {
  vendor: string
  targets: PlatformTarget[]
}

export interface PlatformTarget {
  name: string
  subtargets?: string[]
  devices: string[]
}

// 插件信息
export interface Plugin {
  name: string
  description: string
  category: string
}

export interface PluginCategory {
  id: string
  name: string
  icon: string
  plugins: Plugin[]
}

// 外部插件
export interface ExternalPlugin {
  name: string
  repo: string
  branch: string
}

// 编译配置
export interface BuildConfig {
  token: string
  branch: string
  platform: string
  subtarget: string
  devices: string[]
  plugins: string[]
  externalPlugins: ExternalPlugin[]
  firewall: string
  enableCcache: boolean
  uploadToReleases: boolean
  template: string
  rootPassword: string
  wifiSsid: string
  wifiPassword: string
  lanIp: string
}

// 编译状态
export interface BuildStatus {
  status: 'pending' | 'running' | 'success' | 'failed'
  progress: number
  message: string
  html_url?: string
}

// API 响应
export interface ApiResponse<T> {
  success: boolean
  data: T
  message?: string
}

// 步骤定义
export interface Step {
  id: number
  title: string
  subtitle: string
  icon: string
}

// 防火墙类型
export type FirewallType = 'iptables' | 'nftables'

// 固件模板
export type FirmwareTemplate = 'base' | 'full'
