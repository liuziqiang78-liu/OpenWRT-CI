import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { GitBranch, Check } from 'lucide-react'
import { useBuildStore } from '../stores/buildStore'
import { fetchBranches } from '../services/api'
import type { Branch } from '../types'
import Button from './ui/Button'
import Card from './ui/Card'

// Step 2: 分支选择
export default function BranchSelect() {
  const { branch, setBranch, nextStep, prevStep } = useBuildStore()
  const [branches, setBranches] = useState<Branch[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    fetchBranches()
      .then(setBranches)
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  const container = {
    hidden: { opacity: 0 },
    show: { opacity: 1, transition: { staggerChildren: 0.1 } },
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
          className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-green-500/20 to-emerald-500/20 flex items-center justify-center"
        >
          <GitBranch className="w-8 h-8 text-emerald-400" />
        </motion.div>
        <h2 className="text-2xl font-bold text-gray-100">选择分支</h2>
        <p className="text-gray-500 mt-2">选择要编译的 OpenWRT 源码分支</p>
      </div>

      {loading ? (
        <div className="flex justify-center py-12">
          <div className="w-8 h-8 border-2 border-primary-500/30 border-t-primary-500 rounded-full animate-spin" />
        </div>
      ) : error ? (
        <div className="text-center py-8 text-red-400">{error}</div>
      ) : (
        <motion.div
          variants={container}
          initial="hidden"
          animate="show"
          className="grid gap-4 max-w-2xl mx-auto"
        >
          {branches.map((b) => (
            <motion.div key={b.name} variants={item}>
              <Card
                selected={branch === b.name}
                hoverable
                onClick={() => setBranch(b.name)}
              >
                <div className="flex items-center gap-4">
                  <div
                    className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                      branch === b.name
                        ? 'bg-primary-500/20 text-primary-400'
                        : 'bg-white/[0.04] text-gray-500'
                    }`}
                  >
                    <GitBranch size={22} />
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <span className="font-semibold text-gray-100 font-mono">{b.name}</span>
                      {b.default && (
                        <span className="px-2 py-0.5 text-[10px] font-medium bg-emerald-500/10 text-emerald-400 rounded-full border border-emerald-500/20">
                          推荐
                        </span>
                      )}
                    </div>
                    <div className="text-sm text-gray-500 mt-1">{b.description}</div>
                  </div>
                  {branch === b.name && (
                    <motion.div
                      initial={{ scale: 0 }}
                      animate={{ scale: 1 }}
                      className="w-6 h-6 rounded-full bg-primary-500 flex items-center justify-center"
                    >
                      <Check size={14} className="text-white" />
                    </motion.div>
                  )}
                </div>
              </Card>
            </motion.div>
          ))}
        </motion.div>
      )}

      <div className="flex justify-between pt-4">
        <Button onClick={prevStep} variant="ghost">
          上一步
        </Button>
        <Button onClick={nextStep} disabled={!branch} variant="primary" size="lg">
          下一步：选择平台
        </Button>
      </div>
    </motion.div>
  )
}
