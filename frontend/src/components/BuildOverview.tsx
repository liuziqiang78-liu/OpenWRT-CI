import { useState } from 'react'
import { motion } from 'framer-motion'
import {
  ClipboardList, GitBranch, Cpu, Puzzle, Shield, Settings,
  Rocket, ExternalLink, Clock, CheckCircle2, AlertCircle, RotateCcw,
  Wifi, Globe,
} from 'lucide-react'
import { useBuildStore } from '../stores/buildStore'
import { triggerBuild } from '../services/api'
import Button from './ui/Button'
import Card from './ui/Card'
import Badge from './ui/Badge'

// Step 7: 编译概览
export default function BuildOverview() {
  const store = useBuildStore()
  const {
    token, user, branch, platform, subtarget, devices,
    selectedPlugins, externalPlugins,
    firewall, rootfs, enableCcache, uploadToReleases, template,
    rootPassword, wifiSsid, wifiPassword, lanIp,
    buildUrl, buildStatus,
    setBuildUrl, setBuildStatus, prevStep,
  } = store

  const [building, setBuilding] = useState(false)
  const [error, setError] = useState('')

  const handleBuild = async () => {
    setBuilding(true)
    setError('')
    try {
      const result = await triggerBuild({
        token,
        branch,
        platform,
        subtarget,
        devices,
        plugins: selectedPlugins,
        external_plugins: externalPlugins,
        firewall,
        rootfs,
        enable_ccache: enableCcache,
        upload_to_releases: uploadToReleases,
        template,
        root_password: rootPassword,
        wifi_ssid: wifiSsid,
        wifi_password: wifiPassword,
        lan_ip: lanIp,
      })
      setBuildUrl(result.html_url)
      setBuildStatus('running')
    } catch (err: any) {
      setError(err.message || '编译触发失败')
    } finally {
      setBuilding(false)
    }
  }

  const container = {
    hidden: { opacity: 0 },
    show: { opacity: 1, transition: { staggerChildren: 0.06 } },
  }
  const item = {
    hidden: { opacity: 0, y: 15 },
    show: { opacity: 1, y: 0 },
  }

  // 配置摘要列表
  const summaries = [
    {
      icon: <GitBranch size={16} className="text-emerald-400" />,
      label: '分支',
      value: branch,
    },
    {
      icon: <Cpu size={16} className="text-cyan-400" />,
      label: '平台',
      value: `${platform} / ${subtarget}`,
    },
    {
      icon: <Cpu size={16} className="text-blue-400" />,
      label: '设备',
      value: `${devices.length} 个设备`,
      detail: devices.join(', '),
    },
    {
      icon: <Puzzle size={16} className="text-purple-400" />,
      label: '插件',
      value: `${selectedPlugins.length} 个插件`,
      detail: selectedPlugins.length > 0 ? selectedPlugins.join(', ') : undefined,
    },
    {
      icon: <Shield size={16} className="text-orange-400" />,
      label: '防火墙',
      value: firewall,
    },
    {
      icon: <Settings size={16} className="text-gray-400" />,
      label: '编译选项',
      value: `rootfs: ${rootfs} | 模板: ${template} | ccache: ${enableCcache ? '开' : '关'} | 上传: ${uploadToReleases ? '开' : '关'}`,
    },
    {
      icon: <Wifi size={16} className="text-pink-400" />,
      label: 'WiFi',
      value: wifiSsid || '未设置',
    },
    {
      icon: <Globe size={16} className="text-violet-400" />,
      label: 'LAN IP',
      value: lanIp,
    },
  ]

  return (
    <motion.div
      initial={{ opacity: 0, y: 20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="space-y-6"
    >
      <div className="text-center mb-8">
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: 'spring', delay: 0.1 }}
          className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-rose-500/20 to-amber-500/20 flex items-center justify-center"
        >
          <ClipboardList className="w-8 h-8 text-rose-400" />
        </motion.div>
        <h2 className="text-2xl font-bold text-gray-100">编译概览</h2>
        <p className="text-gray-500 mt-2">确认配置无误后开始编译</p>
      </div>

      {/* 用户信息 */}
      {user && (
        <div className="max-w-2xl mx-auto flex items-center gap-3 p-4 glass-card">
          <img src={user.avatar_url} alt={user.login} className="w-10 h-10 rounded-full ring-2 ring-primary-500/30" />
          <div>
            <div className="font-medium text-gray-200">{user.login}</div>
            <div className="text-xs text-gray-500">GitHub 账户</div>
          </div>
        </div>
      )}

      {/* 配置摘要 */}
      <motion.div
        variants={container}
        initial="hidden"
        animate="show"
        className="max-w-2xl mx-auto space-y-2"
      >
        {summaries.map((s, i) => (
          <motion.div key={i} variants={item}>
            <Card className="!p-4">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-white/[0.04] flex items-center justify-center shrink-0">
                  {s.icon}
                </div>
                <div className="flex-1 min-w-0">
                  <div className="text-xs text-gray-500">{s.label}</div>
                  <div className="text-sm font-medium text-gray-200 truncate">{s.value}</div>
                  {s.detail && (
                    <div className="text-xs text-gray-500 mt-0.5 truncate">{s.detail}</div>
                  )}
                </div>
              </div>
            </Card>
          </motion.div>
        ))}

        {/* 外部插件 */}
        {externalPlugins.length > 0 && (
          <motion.div variants={item}>
            <Card className="!p-4">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-white/[0.04] flex items-center justify-center shrink-0">
                  <Puzzle size={16} className="text-amber-400" />
                </div>
                <div>
                  <div className="text-xs text-gray-500">外部插件</div>
                  <div className="text-sm font-medium text-gray-200">
                    {externalPlugins.map((ep) => ep.name).join(', ')}
                  </div>
                </div>
              </div>
            </Card>
          </motion.div>
        )}
      </motion.div>

      {/* 编译预估时间 */}
      <div className="max-w-2xl mx-auto flex items-center gap-2 p-3 rounded-xl bg-amber-500/[0.04] border border-amber-500/10">
        <Clock size={14} className="text-amber-400 shrink-0" />
        <span className="text-xs text-amber-400/80">
          预估编译时间：约 30-60 分钟（取决于设备数量和插件数量）
        </span>
      </div>

      {/* 编译状态 */}
      {buildUrl && (
        <motion.div
          initial={{ opacity: 0, scale: 0.95 }}
          animate={{ opacity: 1, scale: 1 }}
          className="max-w-2xl mx-auto"
        >
          <Card glow className="!p-6">
            <div className="flex items-center gap-4">
              <div className="w-12 h-12 rounded-xl bg-emerald-500/10 flex items-center justify-center">
                <CheckCircle2 className="w-6 h-6 text-emerald-400" />
              </div>
              <div className="flex-1">
                <div className="font-semibold text-gray-100">编译已触发！</div>
                <div className="text-sm text-gray-400 mt-1">
                  GitHub Actions 正在处理你的编译请求
                </div>
              </div>
              <a
                href={buildUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-2 px-4 py-2 rounded-xl bg-primary-500/10 text-primary-400 hover:bg-primary-500/20 transition-colors text-sm font-medium"
              >
                查看进度 <ExternalLink size={14} />
              </a>
            </div>
          </Card>
        </motion.div>
      )}

      {/* 错误信息 */}
      {error && (
        <div className="max-w-2xl mx-auto flex items-center gap-3 p-4 rounded-xl bg-red-500/[0.06] border border-red-500/20">
          <AlertCircle size={18} className="text-red-400 shrink-0" />
          <span className="text-sm text-red-400">{error}</span>
        </div>
      )}

      {/* 操作按钮 */}
      <div className="flex justify-between items-center pt-4">
        <Button onClick={prevStep} variant="ghost" icon={<RotateCcw size={16} />}>
          返回修改
        </Button>
        {!buildUrl && (
          <motion.div
            animate={building ? {} : { scale: [1, 1.02, 1] }}
            transition={{ repeat: Infinity, duration: 2 }}
          >
            <Button
              onClick={handleBuild}
              loading={building}
              variant="primary"
              size="lg"
              icon={<Rocket size={20} />}
              className="!px-10 !py-4 !text-base shadow-xl shadow-primary-500/30"
            >
              🚀 开始编译
            </Button>
          </motion.div>
        )}
      </div>
    </motion.div>
  )
}


