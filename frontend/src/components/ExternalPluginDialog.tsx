import { useState } from 'react'
import { motion } from 'framer-motion'
import { useBuildStore } from '../stores/buildStore'
import Button from './ui/Button'
import Input from './ui/Input'
import Dialog from './ui/Dialog'
import Card from './ui/Card'
import { Plus } from 'lucide-react'

// 外部插件添加对话框
export default function ExternalPluginDialog({ open, onClose }: { open: boolean; onClose: () => void }) {
  const { addExternalPlugin } = useBuildStore()
  const [name, setName] = useState('')
  const [repo, setRepo] = useState('')
  const [branch, setBranch] = useState('main')

  const handleSubmit = () => {
    if (!name.trim() || !repo.trim()) return
    addExternalPlugin({ name: name.trim(), repo: repo.trim(), branch: branch.trim() || 'main' })
    setName('')
    setRepo('')
    setBranch('main')
    onClose()
  }

  return (
    <Dialog open={open} onClose={onClose} title="添加外部插件">
      <div className="space-y-4">
        <Input
          label="插件名称"
          placeholder="例如: luci-app-xxx"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <Input
          label="仓库地址"
          placeholder="例如: https://github.com/user/repo"
          value={repo}
          onChange={(e) => setRepo(e.target.value)}
        />
        <Input
          label="分支"
          placeholder="main"
          value={branch}
          onChange={(e) => setBranch(e.target.value)}
        />
        <div className="flex justify-end gap-3 pt-2">
          <Button variant="ghost" onClick={onClose}>取消</Button>
          <Button
            variant="primary"
            onClick={handleSubmit}
            disabled={!name.trim() || !repo.trim()}
            icon={<Plus size={16} />}
          >
            添加
          </Button>
        </div>
      </div>
    </Dialog>
  )
}
