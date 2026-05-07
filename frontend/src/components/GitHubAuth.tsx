import { useState } from 'react'
import { motion } from 'framer-motion'
import { Key, Shield, Github, CheckCircle2, AlertCircle } from 'lucide-react'
import { useBuildStore } from '../stores/buildStore'
import { verifyToken } from '../services/api'
import Button from './ui/Button'
import Input from './ui/Input'
import Card from './ui/Card'

// Step 1: GitHub 认证
export default function GitHubAuth() {
  const { token, user, tokenVerified, setToken, setUser, setTokenVerified, nextStep } = useBuildStore()
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleVerify = async () => {
    if (!token.trim()) {
      setError('请输入 GitHub Token')
      return
    }
    setLoading(true)
    setError('')
    try {
      const data = await verifyToken(token)
      setUser({ login: data.login, avatar_url: data.avatar_url, html_url: data.html_url })
      setTokenVerified(true)
    } catch (err: any) {
      setError(err.message || '验证失败')
      setTokenVerified(false)
      setUser(null)
    } finally {
      setLoading(false)
    }
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
          className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-primary-500/20 to-accent-cyan/20 flex items-center justify-center"
        >
          <Key className="w-8 h-8 text-primary-400" />
        </motion.div>
        <h2 className="text-2xl font-bold text-gray-100">GitHub 认证</h2>
        <p className="text-gray-500 mt-2">连接你的 GitHub 账户以触发云编译</p>
      </div>

      <Card className="max-w-lg mx-auto">
        <div className="space-y-5">
          <Input
            label="Personal Access Token"
            placeholder="ghp_xxxxxxxxxxxxxxxxxxxx"
            value={token}
            onChange={(e) => {
              setToken(e.target.value)
              if (tokenVerified) {
                setTokenVerified(false)
                setUser(null)
              }
            }}
            isPassword
            icon={<Key size={18} />}
            error={error}
          />

          <Button
            onClick={handleVerify}
            loading={loading}
            variant="primary"
            className="w-full"
            icon={<Github size={18} />}
          >
            验证 Token
          </Button>

          {/* 验证成功 */}
          {tokenVerified && user && (
            <motion.div
              initial={{ opacity: 0, scale: 0.95 }}
              animate={{ opacity: 1, scale: 1 }}
              className="flex items-center gap-4 p-4 rounded-xl bg-emerald-500/[0.06] border border-emerald-500/20"
            >
              <img
                src={user.avatar_url}
                alt={user.login}
                className="w-12 h-12 rounded-full ring-2 ring-emerald-500/30"
              />
              <div className="flex-1">
                <div className="flex items-center gap-2">
                  <span className="font-semibold text-gray-100">{user.login}</span>
                  <CheckCircle2 size={16} className="text-emerald-400" />
                </div>
                <div className="text-sm text-emerald-400/70">认证成功</div>
              </div>
            </motion.div>
          )}

          {/* 安全提示 */}
          <div className="flex items-start gap-3 p-3 rounded-lg bg-amber-500/[0.04] border border-amber-500/10">
            <AlertCircle size={16} className="text-amber-400 mt-0.5 shrink-0" />
            <div className="text-xs text-amber-400/80 leading-relaxed">
              <strong>安全提示：</strong>Token 仅在浏览器端使用，不会存储到服务器。
              建议创建权限最小化的 Fine-grained Token，仅授予 Actions 和 Repo 读取权限。
            </div>
          </div>
        </div>
      </Card>

      {/* 下一步按钮 */}
      <div className="flex justify-end pt-4">
        <Button
          onClick={nextStep}
          disabled={!tokenVerified}
          variant="primary"
          size="lg"
        >
          下一步：选择分支
        </Button>
      </div>
    </motion.div>
  )
}
