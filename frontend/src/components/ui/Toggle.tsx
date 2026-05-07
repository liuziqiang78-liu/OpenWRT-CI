import { motion } from 'framer-motion'

interface ToggleProps {
  checked: boolean
  onChange: (checked: boolean) => void
  label?: string
  description?: string
}

// 开关组件
export default function Toggle({ checked, onChange, label, description }: ToggleProps) {
  return (
    <div
      className="flex items-center justify-between cursor-pointer group"
      onClick={() => onChange(!checked)}
    >
      <div className="flex-1 mr-4">
        {label && (
          <div className="text-sm font-medium text-gray-200 group-hover:text-white transition-colors">
            {label}
          </div>
        )}
        {description && <div className="text-xs text-gray-500 mt-0.5">{description}</div>}
      </div>
      <div
        className={`relative w-12 h-7 rounded-full transition-colors duration-300 ${
          checked ? 'bg-primary-500' : 'bg-white/[0.08]'
        }`}
      >
        <motion.div
          className="absolute top-1 w-5 h-5 rounded-full bg-white shadow-md"
          animate={{ left: checked ? 26 : 4 }}
          transition={{ type: 'spring', stiffness: 500, damping: 30 }}
        />
      </div>
    </div>
  )
}
