# OpenWRT 云编译平台 - 前端

基于 React + Vite + TailwindCSS 构建的现代化 WebUI，用于 OpenWRT 路由器固件云编译。

## 技术栈

- React 18 + TypeScript
- Vite 5
- TailwindCSS 3 (暗色科技感主题)
- Framer Motion (流畅动画)
- Lucide React (图标库)
- Zustand (状态管理)

## 快速开始

```bash
# 安装依赖
npm install

# 启动开发服务器
npm run dev

# 构建生产版本
npm run build
```

开发服务器默认运行在 `http://localhost:5173`

## 功能

7 步向导式配置流程：

1. 🔑 GitHub 认证 - Token 验证
2. 🌿 分支选择 - 源码分支
3. 💻 硬件平台 - 三级联动选择
4. 🧩 插件选择 - 14 类插件 + 外部插件
5. 🛡️ 防火墙 & 编译选项
6. ⚙️ 自定义选项 - 密码/WiFi/IP
7. 📋 编译概览 - 确认并触发编译

## 后端 API

前端默认连接 `http://localhost:8000/api`，可在 `src/services/api.ts` 中修改。

## 项目结构

```
src/
├── components/     # 页面组件 + UI 组件
├── stores/         # Zustand 状态管理
├── services/       # API 调用封装
├── types/          # TypeScript 类型
├── App.tsx         # 主应用
└── main.tsx        # 入口
```
