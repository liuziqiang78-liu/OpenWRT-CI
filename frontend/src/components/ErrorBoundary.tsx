import { Component, type ReactNode } from 'react'

interface Props {
  children: ReactNode
}

interface State {
  hasError: boolean
  error: Error | null
}

export default class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: any) {
    console.error('ErrorBoundary caught:', error, errorInfo)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-[400px] flex items-center justify-center">
          <div className="text-center max-w-lg mx-auto p-8">
            <div className="text-6xl mb-4">⚠️</div>
            <h2 className="text-xl font-bold text-red-400 mb-2">页面渲染出错</h2>
            <p className="text-gray-500 text-sm mb-4">{this.state.error?.message}</p>
            <button
              onClick={() => this.setState({ hasError: false, error: null })}
              className="px-4 py-2 rounded-xl bg-primary-500/20 text-primary-400 hover:bg-primary-500/30 transition-colors text-sm"
            >
              重试
            </button>
          </div>
        </div>
      )
    }
    return this.props.children
  }
}
