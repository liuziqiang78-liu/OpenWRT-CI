import { motion } from 'framer-motion'
import { Check } from 'lucide-react'

interface StepIndicatorProps {
  steps: { title: string; subtitle: string; icon: string }[]
  currentStep: number
  onStepClick: (step: number) => void
}

// 步骤指示器组件
export default function StepIndicator({ steps, currentStep, onStepClick }: StepIndicatorProps) {
  return (
    <div className="w-full overflow-x-auto pb-2">
      <div className="flex items-center justify-between min-w-[700px] px-2">
        {steps.map((step, index) => {
          const isActive = index === currentStep
          const isCompleted = index < currentStep
          const isClickable = index <= currentStep

          return (
            <div key={index} className="flex items-center flex-1 last:flex-none">
              {/* 步骤节点 */}
              <button
                onClick={() => isClickable && onStepClick(index)}
                disabled={!isClickable}
                className={`
                  flex flex-col items-center gap-1.5 group transition-all duration-300
                  ${isClickable ? 'cursor-pointer' : 'cursor-default'}
                `}
              >
                <motion.div
                  animate={{
                    scale: isActive ? 1.1 : 1,
                  }}
                  className={`
                    relative w-11 h-11 rounded-xl flex items-center justify-center text-lg
                    transition-all duration-300
                    ${isCompleted
                      ? 'bg-gradient-to-br from-primary-500 to-primary-600 text-white shadow-lg shadow-primary-500/30'
                      : isActive
                        ? 'bg-primary-500/20 border-2 border-primary-500 text-primary-400 shadow-lg shadow-primary-500/20'
                        : 'bg-white/[0.04] border border-white/[0.08] text-gray-600'
                    }
                  `}
                >
                  {isCompleted ? <Check size={18} /> : step.icon}
                  {isActive && (
                    <motion.div
                      layoutId="step-ring"
                      className="absolute inset-0 rounded-xl border-2 border-primary-400"
                      transition={{ type: 'spring', stiffness: 300, damping: 30 }}
                    />
                  )}
                </motion.div>
                <div className="text-center">
                  <div
                    className={`text-xs font-medium transition-colors ${
                      isActive ? 'text-primary-400' : isCompleted ? 'text-gray-300' : 'text-gray-600'
                    }`}
                  >
                    {step.title}
                  </div>
                  <div className="text-[10px] text-gray-600 hidden sm:block">
                    {step.subtitle}
                  </div>
                </div>
              </button>

              {/* 连接线 */}
              {index < steps.length - 1 && (
                <div className="flex-1 mx-2 h-px relative">
                  <div className="absolute inset-0 bg-white/[0.06]" />
                  <motion.div
                    className="absolute inset-y-0 left-0 bg-gradient-to-r from-primary-500 to-primary-400"
                    initial={{ width: '0%' }}
                    animate={{ width: isCompleted ? '100%' : '0%' }}
                    transition={{ duration: 0.5, ease: 'easeInOut' }}
                  />
                </div>
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}
