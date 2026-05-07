import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Cpu, ChevronDown, CheckSquare, Square, Check } from 'lucide-react'
import { useBuildStore } from '../stores/buildStore'
import { fetchPlatforms } from '../services/api'
import type { Platform, PlatformTarget, Device } from '../types'
import Button from './ui/Button'
import Card from './ui/Card'

// Step 3: 硬件平台选择
export default function PlatformSelect() {
  const { platform, subtarget, devices, setPlatform, setSubtarget, setDevices, toggleDevice, setPlatformCapabilities, nextStep, prevStep } = useBuildStore()
  const [platforms, setPlatforms] = useState<Platform[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    fetchPlatforms()
      .then(setPlatforms)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  // 当前厂商
  const currentVendor = platforms.find((p) => p.vendor === platform)
  // 当前目标
  const currentTarget = currentVendor?.targets.find((t) => t.name === subtarget) || currentVendor?.targets[0]
  // 可用设备
  const availableDevices: Device[] = currentTarget?.devices || []

  const handleSelectAll = () => {
    setDevices(availableDevices.map(d => d.id))
  }

  const handleDeselectAll = () => {
    setDevices([])
  }

  const handleToggleAll = () => {
    if (devices.length === availableDevices.length) {
      handleDeselectAll()
    } else {
      handleSelectAll()
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center py-20">
        <div className="w-8 h-8 border-2 border-primary-500/30 border-t-primary-500 rounded-full animate-spin" />
      </div>
    )
  }

  if (error) {
    return <div className="text-center py-8 text-red-400">{error}</div>
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
          className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-blue-500/20 to-cyan-500/20 flex items-center justify-center"
        >
          <Cpu className="w-8 h-8 text-cyan-400" />
        </motion.div>
        <h2 className="text-2xl font-bold text-gray-100">选择硬件平台</h2>
        <p className="text-gray-500 mt-2">选择路由器厂商、平台和设备型号</p>
      </div>

      <div className="max-w-3xl mx-auto space-y-6">
        {/* 厂商选择 */}
        <div>
          <label className="block text-sm font-medium text-gray-300 mb-3">厂商</label>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            {platforms.map((p) => (
              <Card
                key={p.vendor}
                selected={platform === p.vendor}
                hoverable
                onClick={() => {
                  setPlatform(p.vendor)
                  if (p.targets.length > 0) {
                    setSubtarget(p.targets[0].name)
                    setPlatformCapabilities(p.targets[0])
                  }
                }}
              >
                <div className="text-center py-2">
                  <div className="font-semibold text-gray-100">{p.vendor}</div>
                  <div className="text-xs text-gray-500 mt-1">{p.targets.length} 个平台</div>
                </div>
              </Card>
            ))}
          </div>
        </div>

        {/* 平台/子目标选择 */}
        <AnimatePresence mode="wait">
          {currentVendor && (
            <motion.div
              key={platform}
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
            >
              <label className="block text-sm font-medium text-gray-300 mb-3">平台 / 子目标</label>
              <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
                {currentVendor.targets.map((t) => (
                  <Card
                    key={t.name}
                    selected={subtarget === t.name || (!subtarget && t === currentVendor.targets[0])}
                    hoverable
                    onClick={() => {
                      setSubtarget(t.name)
                      setPlatformCapabilities(t)
                    }}
                  >
                    <div className="text-center py-2">
                      <div className="font-mono text-sm font-semibold text-gray-100">{t.name}</div>
                      <div className="text-xs text-gray-500 mt-1">{t.devices.length} 个设备</div>
                    </div>
                  </Card>
                ))}
              </div>
            </motion.div>
          )}
        </AnimatePresence>

        {/* 设备选择 */}
        <AnimatePresence mode="wait">
          {availableDevices.length > 0 && (
            <motion.div
              key={`${platform}-${subtarget}`}
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
            >
              <div className="flex items-center justify-between mb-3">
                <label className="text-sm font-medium text-gray-300">
                  设备型号
                  <span className="ml-2 text-xs text-gray-500">
                    已选 {devices.length}/{availableDevices.length}
                  </span>
                </label>
                <div className="flex gap-2">
                  <button
                    onClick={handleSelectAll}
                    className="text-xs text-primary-400 hover:text-primary-300 transition-colors"
                  >
                    全选
                  </button>
                  <span className="text-gray-600">|</span>
                  <button
                    onClick={handleDeselectAll}
                    className="text-xs text-gray-500 hover:text-gray-300 transition-colors"
                  >
                    清空
                  </button>
                  <span className="text-gray-600">|</span>
                  <button
                    onClick={handleToggleAll}
                    className="text-xs text-gray-500 hover:text-gray-300 transition-colors"
                  >
                    反选
                  </button>
                </div>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                {availableDevices.map((device) => {
                  const isSelected = devices.includes(device.id)
                  return (
                    <motion.button
                      key={device.id}
                      whileHover={{ scale: 1.01 }}
                      whileTap={{ scale: 0.99 }}
                      onClick={() => toggleDevice(device.id)}
                      className={`
                        flex items-center gap-3 p-3 rounded-xl text-left transition-all duration-200
                        ${isSelected
                          ? 'bg-primary-500/[0.08] border border-primary-500/30 text-primary-300'
                          : 'bg-white/[0.02] border border-white/[0.06] text-gray-400 hover:border-white/[0.12] hover:bg-white/[0.04]'
                        }
                      `}
                    >
                      {isSelected ? (
                        <CheckSquare size={18} className="text-primary-400 shrink-0" />
                      ) : (
                        <Square size={18} className="text-gray-600 shrink-0" />
                      )}
                      <span className="text-sm font-medium">{device.name}</span>
                      {isSelected && (
                        <motion.div
                          initial={{ scale: 0 }}
                          animate={{ scale: 1 }}
                          className="ml-auto"
                        >
                          <Check size={14} className="text-primary-400" />
                        </motion.div>
                      )}
                    </motion.button>
                  )
                })}
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <div className="flex justify-between pt-4">
        <Button onClick={prevStep} variant="ghost">上一步</Button>
        <Button onClick={nextStep} disabled={devices.length === 0} variant="primary" size="lg">
          下一步：选择插件
        </Button>
      </div>
    </motion.div>
  )
}
