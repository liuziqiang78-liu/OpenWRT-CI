import { useEffect, useState, useMemo } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Puzzle, Search, ChevronDown, ChevronRight, Plus, Check, X } from 'lucide-react'
import { useBuildStore } from '../stores/buildStore'
import { fetchPlugins } from '../services/api'
import type { PluginCategory, Plugin } from '../types'
import Button from './ui/Button'
import Badge from './ui/Badge'
import ExternalPluginDialog from './ExternalPluginDialog'

// Step 4: 插件选择
export default function PluginSelect() {
  const { selectedPlugins, externalPlugins, togglePlugin, nextStep, prevStep } = useBuildStore()
  const [categories, setCategories] = useState<PluginCategory[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')
  const [search, setSearch] = useState('')
  const [expandedCategories, setExpandedCategories] = useState<Set<string>>(new Set())
  const [showExternalDialog, setShowExternalDialog] = useState(false)

  useEffect(() => {
    fetchPlugins()
      .then((data) => {
        setCategories(data)
        // 默认展开第一个分类
        if (data.length > 0) {
          setExpandedCategories(new Set([data[0].id]))
        }
      })
      .catch((e) => setError(e.message))
      .finally(() => setLoading(false))
  }, [])

  const toggleCategory = (id: string) => {
    setExpandedCategories((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  // 搜索过滤
  const filteredCategories = useMemo(() => {
    if (!search.trim()) return categories
    const q = search.toLowerCase()
    return categories
      .map((cat) => ({
        ...cat,
        plugins: cat.plugins.filter(
          (p) => p.name.toLowerCase().includes(q) || p.description.toLowerCase().includes(q)
        ),
      }))
      .filter((cat) => cat.plugins.length > 0)
  }, [categories, search])

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
      <div className="text-center mb-6">
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ type: 'spring', delay: 0.1 }}
          className="w-16 h-16 mx-auto mb-4 rounded-2xl bg-gradient-to-br from-purple-500/20 to-pink-500/20 flex items-center justify-center"
        >
          <Puzzle className="w-8 h-8 text-purple-400" />
        </motion.div>
        <h2 className="text-2xl font-bold text-gray-100">选择插件</h2>
        <p className="text-gray-500 mt-2">
          已选择 <span className="text-primary-400 font-semibold">{selectedPlugins.length}</span> 个插件
          {externalPlugins.length > 0 && (
            <span className="text-gray-500"> + {externalPlugins.length} 个外部插件</span>
          )}
        </p>
      </div>

      {/* 搜索框 */}
      <div className="max-w-2xl mx-auto">
        <div className="relative">
          <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500" />
          <input
            type="text"
            placeholder="搜索插件名称或描述..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-11 pr-10 py-3 rounded-xl bg-white/[0.04] border border-white/[0.08] text-gray-100 placeholder-gray-600 focus:outline-none focus:ring-2 focus:ring-primary-500/40 transition-all"
          />
          {search && (
            <button
              onClick={() => setSearch('')}
              className="absolute right-3.5 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-300"
            >
              <X size={16} />
            </button>
          )}
        </div>
      </div>

      {/* 分类列表 */}
      <div className="max-w-3xl mx-auto space-y-3">
        {filteredCategories.map((category) => {
          const isExpanded = expandedCategories.has(category.id)
          const selectedCount = category.plugins.filter((p) =>
            selectedPlugins.includes(p.name)
          ).length

          return (
            <motion.div
              key={category.id}
              layout
              className="glass-card overflow-hidden"
            >
              {/* 分类标题 */}
              <button
                onClick={() => toggleCategory(category.id)}
                className="w-full flex items-center gap-3 p-4 hover:bg-white/[0.02] transition-colors"
              >
                <span className="text-xl">{category.icon}</span>
                <span className="font-medium text-gray-200 flex-1 text-left">{category.name}</span>
                {selectedCount > 0 && (
                  <Badge variant="primary">{selectedCount} 已选</Badge>
                )}
                <span className="text-xs text-gray-500">{category.plugins.length} 个</span>
                <motion.div
                  animate={{ rotate: isExpanded ? 90 : 0 }}
                  transition={{ duration: 0.2 }}
                >
                  <ChevronRight size={16} className="text-gray-500" />
                </motion.div>
              </button>

              {/* 插件列表 */}
              <AnimatePresence>
                {isExpanded && (
                  <motion.div
                    initial={{ height: 0, opacity: 0 }}
                    animate={{ height: 'auto', opacity: 1 }}
                    exit={{ height: 0, opacity: 0 }}
                    transition={{ duration: 0.3 }}
                    className="overflow-hidden"
                  >
                    <div className="px-4 pb-4 grid grid-cols-1 sm:grid-cols-2 gap-2">
                      {category.plugins.map((plugin) => {
                        const isSelected = selectedPlugins.includes(plugin.name)
                        return (
                          <motion.button
                            key={plugin.name}
                            whileHover={{ scale: 1.01 }}
                            whileTap={{ scale: 0.99 }}
                            onClick={() => togglePlugin(plugin.name)}
                            className={`
                              flex items-start gap-3 p-3 rounded-xl text-left transition-all duration-200
                              ${isSelected
                                ? 'bg-primary-500/[0.08] border border-primary-500/30'
                                : 'bg-white/[0.02] border border-white/[0.04] hover:border-white/[0.1] hover:bg-white/[0.04]'
                              }
                            `}
                          >
                            <div className={`mt-0.5 shrink-0 w-5 h-5 rounded-md flex items-center justify-center border transition-all ${
                              isSelected
                                ? 'bg-primary-500 border-primary-500'
                                : 'border-gray-600 bg-transparent'
                            }`}>
                              {isSelected && <Check size={12} className="text-white" />}
                            </div>
                            <div className="flex-1 min-w-0">
                              <div className={`text-sm font-medium ${isSelected ? 'text-primary-300' : 'text-gray-300'}`}>
                                {plugin.name}
                              </div>
                              <div className="text-xs text-gray-500 mt-0.5 line-clamp-2">
                                {plugin.description}
                              </div>
                            </div>
                          </motion.button>
                        )
                      })}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          )
        })}
      </div>

      {/* 外部插件 */}
      <div className="max-w-3xl mx-auto">
        <div className="flex items-center justify-between mb-3">
          <span className="text-sm font-medium text-gray-400">外部插件</span>
          <Button
            variant="secondary"
            size="sm"
            icon={<Plus size={14} />}
            onClick={() => setShowExternalDialog(true)}
          >
            添加外部插件
          </Button>
        </div>
        {externalPlugins.length > 0 && (
          <div className="space-y-2">
            {externalPlugins.map((ep, i) => (
              <div
                key={i}
                className="flex items-center gap-3 p-3 rounded-xl bg-white/[0.02] border border-white/[0.06]"
              >
                <div className="flex-1 min-w-0">
                  <div className="text-sm font-medium text-gray-200">{ep.name}</div>
                  <div className="text-xs text-gray-500 truncate">
                    {ep.repo} @ {ep.branch}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <ExternalPluginDialog
        open={showExternalDialog}
        onClose={() => setShowExternalDialog(false)}
      />

      <div className="flex justify-between pt-4">
        <Button onClick={prevStep} variant="ghost">上一步</Button>
        <Button onClick={nextStep} variant="primary" size="lg">
          下一步：编译选项
        </Button>
      </div>
    </motion.div>
  )
}
