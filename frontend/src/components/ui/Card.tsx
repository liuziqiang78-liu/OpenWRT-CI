import { motion } from 'framer-motion'
import type { ReactNode, HTMLAttributes } from 'react'

interface CardProps extends HTMLAttributes<HTMLDivElement> {
  selected?: boolean
  hoverable?: boolean
  glow?: boolean
  children: ReactNode
}

// 通用卡片组件
export default function Card({
  selected = false,
  hoverable = false,
  glow = false,
  children,
  className = '',
  ...props
}: CardProps) {
  return (
    <motion.div
      whileHover={hoverable ? { scale: 1.02, y: -2 } : undefined}
      whileTap={hoverable ? { scale: 0.98 } : undefined}
      className={`
        relative rounded-2xl p-5 transition-all duration-300
        bg-white/[0.03] backdrop-blur-xl border
        ${selected
          ? 'border-primary-500/50 bg-primary-500/[0.08] shadow-lg shadow-primary-500/20'
          : 'border-white/[0.06] hover:border-white/[0.12]'
        }
        ${hoverable ? 'cursor-pointer' : ''}
        ${glow ? 'shadow-lg shadow-primary-500/20' : ''}
        ${className}
      `}
      {...(props as any)}
    >
      {selected && (
        <motion.div
          layoutId="card-glow"
          className="absolute inset-0 rounded-2xl bg-gradient-to-r from-primary-500/10 to-accent-cyan/10 pointer-events-none"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.3 }}
        />
      )}
      <div className="relative z-10">{children}</div>
    </motion.div>
  )
}
