import { motion } from 'framer-motion'
import { useBuildStore } from './stores/buildStore'
import StepIndicator from './components/StepIndicator'
import GitHubAuth from './components/GitHubAuth'
import BranchSelect from './components/BranchSelect'
import PlatformSelect from './components/PlatformSelect'
import PluginSelect from './components/PluginSelect'
import BuildOptions from './components/BuildOptions'
import CustomOptions from './components/CustomOptions'
import BuildOverview from './components/BuildOverview'
import ErrorBoundary from './components/ErrorBoundary'
import { Router, Cpu, Github } from 'lucide-react'

// 步骤定义
const STEPS = [
  { title: '认证', subtitle: 'GitHub', icon: '🔑' },
  { title: '分支', subtitle: '源码', icon: '🌿' },
  { title: '平台', subtitle: '硬件', icon: '💻' },
  { title: '插件', subtitle: '功能', icon: '🧩' },
  { title: '选项', subtitle: '编译', icon: '🛡️' },
  { title: '自定义', subtitle: '配置', icon: '⚙️' },
  { title: '概览', subtitle: '确认', icon: '📋' },
]

// 步骤页面映射
const STEP_COMPONENTS = [
  GitHubAuth,
  BranchSelect,
  PlatformSelect,
  PluginSelect,
  BuildOptions,
  CustomOptions,
  BuildOverview,
]

export default function App() {
  const { currentStep, setCurrentStep } = useBuildStore()
  const CurrentStepComponent = STEP_COMPONENTS[currentStep]

  return (
    <div className="min-h-screen tech-grid relative overflow-hidden">
      {/* 背景装饰 */}
      <div className="fixed inset-0 pointer-events-none">
        <div className="absolute top-0 left-1/4 w-96 h-96 bg-primary-500/5 rounded-full blur-3xl" />
        <div className="absolute bottom-0 right-1/4 w-96 h-96 bg-accent-cyan/5 rounded-full blur-3xl" />
        <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[800px] h-[800px] bg-primary-500/[0.02] rounded-full blur-3xl" />
      </div>

      <div className="relative z-10 max-w-5xl mx-auto px-4 py-6 sm:py-10">
        {/* 头部 */}
        <motion.header
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-8"
        >
          <div className="flex items-center justify-center gap-3 mb-2">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-primary-500 to-accent-cyan flex items-center justify-center shadow-lg shadow-primary-500/30">
              <Router size={22} className="text-white" />
            </div>
            <h1 className="text-2xl sm:text-3xl font-bold gradient-text">
              OpenWRT 云编译平台
            </h1>
          </div>
          <p className="text-sm text-gray-500">
            自定义你的路由器固件 · GitHub Actions 云端编译
          </p>
        </motion.header>

        {/* 步骤指示器 */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="glass-card p-4 mb-8"
        >
          <StepIndicator
            steps={STEPS}
            currentStep={currentStep}
            onStepClick={setCurrentStep}
          />
        </motion.div>

        {/* 步骤内容 */}
        <ErrorBoundary>
          <CurrentStepComponent />
        </ErrorBoundary>

        {/* 底部 */}
        <footer className="text-center mt-12 pb-6">
          <div className="flex items-center justify-center gap-2 text-xs text-gray-600">
            <Github size={14} />
            <span>Powered by GitHub Actions</span>
            <span className="text-gray-700">·</span>
            <span>OpenWRT Cloud Builder</span>
          </div>
        </footer>
      </div>
    </div>
  )
}
