import { motion } from 'framer-motion'
import { Settings, Lock, Wifi, Globe, HardDrive } from 'lucide-react'
import { useBuildStore } from '../stores/buildStore'
import Button from './ui/Button'
import Card from './ui/Card'
import Input from './ui/Input'

// Step 6: 自定义选项
export default function CustomOptions() {
  const {
    rootPassword, wifiSsid, wifiPassword, lanIp,
    platformWifi, platformEmmc,
    setRootPassword, setWifiSsid, setWifiPassword, setLanIp,
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
          className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-violet-500/20 to-fuchsia-500/20 flex items-center justify-center"
        >
          <Settings className="w-8 h-8 text-violet-400" />
        </motion.div>
        <h2 className="text-2xl font-bold text-gray-100">自定义选项</h2>
        <p className="text-gray-500 mt-2">配置路由器的初始设置</p>
      </div>

      <motion.div
        variants={container}
        initial="hidden"
        animate="show"
        className="max-w-lg mx-auto space-y-5"
      >
        {/* 平台能力提示 */}
        {(platformWifi || platformEmmc) && (
          <motion.div variants={item}>
            <Card className="!p-4">
              <div className="text-xs text-gray-500 mb-2">当前平台支持</div>
              <div className="flex gap-3">
                {platformWifi && (
                  <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-cyan-500/10 text-cyan-400 text-xs font-medium">
                    <Wifi size={12} /> WiFi
                  </span>
                )}
                {platformEmmc && (
                  <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-lg bg-amber-500/10 text-amber-400 text-xs font-medium">
                    <HardDrive size={12} /> eMMC
                  </span>
                )}
              </div>
            </Card>
          </motion.div>
        )}

        <motion.div variants={item}>
          <Input
            label="Root 密码"
            placeholder="设置路由器管理密码"
            value={rootPassword}
            onChange={(e) => setRootPassword(e.target.value)}
            isPassword
            icon={<Lock size={18} />}
            helper="留空将使用默认密码"
          />
        </motion.div>

        {/* WiFi 设置 - 仅在平台支持时显示 */}
        {platformWifi && (
          <>
            <motion.div variants={item}>
              <Input
                label="WiFi 名称 (SSID)"
                placeholder="MyNetwork"
                value={wifiSsid}
                onChange={(e) => setWifiSsid(e.target.value)}
                icon={<Wifi size={18} />}
              />
            </motion.div>

            <motion.div variants={item}>
              <Input
                label="WiFi 密码"
                placeholder="设置 WiFi 连接密码"
                value={wifiPassword}
                onChange={(e) => setWifiPassword(e.target.value)}
                isPassword
                icon={<Lock size={18} />}
                helper="建议使用 WPA3 加密，至少 8 位字符"
              />
            </motion.div>
          </>
        )}

        <motion.div variants={item}>
          <Input
            label="LAN IP 地址"
            placeholder="192.168.1.1"
            value={lanIp}
            onChange={(e) => setLanIp(e.target.value)}
            icon={<Globe size={18} />}
            helper="路由器管理页面的访问地址"
          />
        </motion.div>
      </motion.div>

      <div className="flex justify-between pt-4">
        <Button onClick={prevStep} variant="ghost">上一步</Button>
        <Button onClick={nextStep} variant="primary" size="lg">
          下一步：编译概览
        </Button>
      </div>
    </motion.div>
  )
}
