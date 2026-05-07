import { motion } from 'framer-motion'
import { Shield, Flame, Zap, Upload, Package, HardDrive } from 'lucide-react'
import { useBuildStore } from '../stores/buildStore'
import Button from './ui/Button'
import Card from './ui/Card'
import Toggle from './ui/Toggle'

// Step 5: 防火墙 & 编译选项
export default function BuildOptions() {
  const {
    firewall, rootfs, enableCcache, uploadToReleases, template,
    platformFirewallOptions, platformRootfsOptions,
    setFirewall, setRootfs, setEnableCcache, setUploadToReleases, setTemplate,
    nextStep, prevStep,
  } = useBuildStore()

  const container = {
    hidden: { opacity: 0 },
    show: { opacity: 1, transition: { staggerChildren: 0.08 } },
  }
  const item = {
    hidden: { opacity: 0, y: 20 },
    show: { opacity: 1, y: 0 },
  }

  const fwOptions = platformFirewallOptions.length > 0 ? platformFirewallOptions : ['iptables', 'nftables']
  const rootfsOptions = platformRootfsOptions.length > 0 ? platformRootfsOptions : ['squashfs']

  const fwIcons: Record<string, string> = { iptables: '🔥', nftables: '🛡️' }
  const fwDescs: Record<string, string> = {
    iptables: '传统防火墙，兼容性好',
    nftables: '新一代防火墙，性能更优',
  }
  const rootfsIcons: Record<string, string> = { squashfs: '📦', ext4: '💾', f2fs: '⚡' }
  const rootfsDescs: Record<string, string> = {
    squashfs: '压缩文件系统，体积小，只读',
    ext4: '标准 Linux 文件系统，读写',
    f2fs: '闪存优化文件系统，性能好',
  }

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
          className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-orange-500/20 to-red-500/20 flex items-center justify-center"
        >
          <Shield className="w-8 h-8 text-orange-400" />
        </motion.div>
        <h2 className="text-2xl font-bold text-gray-100">防火墙 & 编译选项</h2>
        <p className="text-gray-500 mt-2">配置防火墙类型和编译参数</p>
      </div>

      <motion.div
        variants={container}
        initial="hidden"
        animate="show"
        className="max-w-2xl mx-auto space-y-8"
      >
        {/* 防火墙类型 */}
        <motion.div variants={item}>
          <label className="block text-sm font-medium text-gray-300 mb-3">
            <Flame size={14} className="inline mr-1.5 text-orange-400" />
            防火墙类型
          </label>
          <div className="grid grid-cols-2 gap-3">
            {fwOptions.map((fw) => (
              <Card
                key={fw}
                selected={firewall === fw}
                hoverable
                onClick={() => setFirewall(fw as 'iptables' | 'nftables')}
              >
                <div className="text-center py-3">
                  <div className="text-lg mb-1">{fwIcons[fw] || '🔥'}</div>
                  <div className="font-semibold text-gray-100 font-mono">{fw}</div>
                  <div className="text-xs text-gray-500 mt-1">{fwDescs[fw] || fw}</div>
                </div>
              </Card>
            ))}
          </div>
        </motion.div>

        {/* Rootfs 文件系统 */}
        {rootfsOptions.length > 1 && (
          <motion.div variants={item}>
            <label className="block text-sm font-medium text-gray-300 mb-3">
              <HardDrive size={14} className="inline mr-1.5 text-cyan-400" />
              文件系统类型
            </label>
            <div className="grid grid-cols-3 gap-3">
              {rootfsOptions.map((r) => (
                <Card
                  key={r}
                  selected={rootfs === r}
                  hoverable
                  onClick={() => setRootfs(r)}
                >
                  <div className="text-center py-3">
                    <div className="text-lg mb-1">{rootfsIcons[r] || '📦'}</div>
                    <div className="font-semibold text-gray-100 font-mono text-sm">{r}</div>
                    <div className="text-xs text-gray-500 mt-1">{rootfsDescs[r] || r}</div>
                  </div>
                </Card>
              ))}
            </div>
          </motion.div>
        )}

        {/* 固件模板 */}
        <motion.div variants={item}>
          <label className="block text-sm font-medium text-gray-300 mb-3">
            <Package size={14} className="inline mr-1.5 text-cyan-400" />
            固件模板
          </label>
          <div className="grid grid-cols-2 gap-3">
            {(['base', 'full'] as const).map((t) => (
              <Card
                key={t}
                selected={template === t}
                hoverable
                onClick={() => setTemplate(t)}
              >
                <div className="text-center py-3">
                  <div className="text-lg mb-1">{t === 'base' ? '📦' : '📚'}</div>
                  <div className="font-semibold text-gray-100 capitalize">{t}</div>
                  <div className="text-xs text-gray-500 mt-1">
                    {t === 'base' ? '基础模板，体积小' : '完整模板，功能全'}
                  </div>
                </div>
              </Card>
            ))}
          </div>
        </motion.div>

        {/* 开关选项 */}
        <motion.div variants={item} className="space-y-4">
          <Card>
            <Toggle
              checked={enableCcache}
              onChange={setEnableCcache}
              label="ccache 缓存加速"
              description="使用编译缓存，显著加速重复编译"
            />
          </Card>
          <Card>
            <Toggle
              checked={uploadToReleases}
              onChange={setUploadToReleases}
              label="上传到 Releases"
              description="编译完成后自动上传固件到 GitHub Releases"
            />
          </Card>
        </motion.div>
      </motion.div>

      <div className="flex justify-between pt-4">
        <Button onClick={prevStep} variant="ghost">上一步</Button>
        <Button onClick={nextStep} variant="primary" size="lg">
          下一步：自定义选项
        </Button>
      </div>
    </motion.div>
  )
}
