import { create } from 'zustand'
import type { GitHubUser, ExternalPlugin } from '../types'

// 编译状态管理 Store
interface BuildState {
  // Step 1: GitHub 认证
  token: string
  user: GitHubUser | null
  tokenVerified: boolean

  // Step 2: 分支选择
  branch: string

  // Step 3: 硬件平台
  platform: string
  subtarget: string
  devices: string[]

  // Step 4: 插件
  selectedPlugins: string[]
  externalPlugins: ExternalPlugin[]

  // Step 5: 编译选项
  firewall: 'iptables' | 'nftables'
  enableCcache: boolean
  uploadToReleases: boolean
  template: 'base' | 'full'

  // Step 6: 自定义选项
  rootPassword: string
  wifiSsid: string
  wifiPassword: string
  lanIp: string

  // 导航
  currentStep: number

  // 编译结果
  buildUrl: string
  buildStatus: string

  // Actions
  setToken: (token: string) => void
  setUser: (user: GitHubUser | null) => void
  setTokenVerified: (v: boolean) => void
  setBranch: (branch: string) => void
  setPlatform: (platform: string) => void
  setSubtarget: (subtarget: string) => void
  setDevices: (devices: string[]) => void
  toggleDevice: (device: string) => void
  setSelectedPlugins: (plugins: string[]) => void
  togglePlugin: (plugin: string) => void
  addExternalPlugin: (plugin: ExternalPlugin) => void
  removeExternalPlugin: (index: number) => void
  setFirewall: (fw: 'iptables' | 'nftables') => void
  setEnableCcache: (v: boolean) => void
  setUploadToReleases: (v: boolean) => void
  setTemplate: (t: 'base' | 'full') => void
  setRootPassword: (v: string) => void
  setWifiSsid: (v: string) => void
  setWifiPassword: (v: string) => void
  setLanIp: (v: string) => void
  setCurrentStep: (step: number) => void
  nextStep: () => void
  prevStep: () => void
  setBuildUrl: (url: string) => void
  setBuildStatus: (status: string) => void
  reset: () => void
}

const initialState = {
  token: '',
  user: null as GitHubUser | null,
  tokenVerified: false,
  branch: '',
  platform: '',
  subtarget: '',
  devices: [] as string[],
  selectedPlugins: [] as string[],
  externalPlugins: [] as ExternalPlugin[],
  firewall: 'nftables' as const,
  enableCcache: true,
  uploadToReleases: true,
  template: 'base' as const,
  rootPassword: '',
  wifiSsid: '',
  wifiPassword: '',
  lanIp: '192.168.1.1',
  currentStep: 0,
  buildUrl: '',
  buildStatus: '',
}

export const useBuildStore = create<BuildState>((set, get) => ({
  ...initialState,

  setToken: (token) => set({ token }),
  setUser: (user) => set({ user }),
  setTokenVerified: (tokenVerified) => set({ tokenVerified }),
  setBranch: (branch) => set({ branch }),
  setPlatform: (platform) => set({ platform, subtarget: '', devices: [] }),
  setSubtarget: (subtarget) => set({ subtarget, devices: [] }),
  setDevices: (devices) => set({ devices }),
  toggleDevice: (device) => {
    const { devices } = get()
    set({
      devices: devices.includes(device)
        ? devices.filter((d) => d !== device)
        : [...devices, device],
    })
  },
  setSelectedPlugins: (selectedPlugins) => set({ selectedPlugins }),
  togglePlugin: (plugin) => {
    const { selectedPlugins } = get()
    set({
      selectedPlugins: selectedPlugins.includes(plugin)
        ? selectedPlugins.filter((p) => p !== plugin)
        : [...selectedPlugins, plugin],
    })
  },
  addExternalPlugin: (plugin) =>
    set((s) => ({ externalPlugins: [...s.externalPlugins, plugin] })),
  removeExternalPlugin: (index) =>
    set((s) => ({
      externalPlugins: s.externalPlugins.filter((_, i) => i !== index),
    })),
  setFirewall: (firewall) => set({ firewall }),
  setEnableCcache: (enableCcache) => set({ enableCcache }),
  setUploadToReleases: (uploadToReleases) => set({ uploadToReleases }),
  setTemplate: (template) => set({ template }),
  setRootPassword: (rootPassword) => set({ rootPassword }),
  setWifiSsid: (wifiSsid) => set({ wifiSsid }),
  setWifiPassword: (wifiPassword) => set({ wifiPassword }),
  setLanIp: (lanIp) => set({ lanIp }),
  setCurrentStep: (currentStep) => set({ currentStep }),
  nextStep: () => set((s) => ({ currentStep: Math.min(s.currentStep + 1, 6) })),
  prevStep: () => set((s) => ({ currentStep: Math.max(s.currentStep - 1, 0) })),
  setBuildUrl: (buildUrl) => set({ buildUrl }),
  setBuildStatus: (buildStatus) => set({ buildStatus }),
  reset: () => set(initialState),
}))
