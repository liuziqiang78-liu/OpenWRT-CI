import { forwardRef, useState } from 'react'
import { Eye, EyeOff } from 'lucide-react'
import type { InputHTMLAttributes } from 'react'

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  label?: string
  error?: string
  helper?: string
  icon?: React.ReactNode
  isPassword?: boolean
}

// 通用输入框组件
const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ label, error, helper, icon, isPassword, className = '', ...props }, ref) => {
    const [showPassword, setShowPassword] = useState(false)

    return (
      <div className="w-full">
        {label && (
          <label className="block text-sm font-medium text-gray-300 mb-2">
            {label}
          </label>
        )}
        <div className="relative">
          {icon && (
            <div className="absolute left-3.5 top-1/2 -translate-y-1/2 text-gray-500">
              {icon}
            </div>
          )}
          <input
            ref={ref}
            type={isPassword ? (showPassword ? 'text' : 'password') : props.type}
            className={`
              w-full rounded-xl bg-white/[0.04] border border-white/[0.08]
              px-4 py-3 text-gray-100 placeholder-gray-600
              focus:outline-none focus:ring-2 focus:ring-primary-500/40 focus:border-primary-500/40
              transition-all duration-200
              ${icon ? 'pl-11' : ''}
              ${isPassword ? 'pr-11' : ''}
              ${error ? 'border-red-500/50 focus:ring-red-500/30' : ''}
              ${className}
            `}
            {...props}
          />
          {isPassword && (
            <button
              type="button"
              onClick={() => setShowPassword(!showPassword)}
              className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300 transition-colors"
            >
              {showPassword ? <EyeOff size={18} /> : <Eye size={18} />}
            </button>
          )}
        </div>
        {error && <p className="mt-1.5 text-sm text-red-400">{error}</p>}
        {helper && !error && <p className="mt-1.5 text-sm text-gray-500">{helper}</p>}
      </div>
    )
  }
)

Input.displayName = 'Input'
export default Input
