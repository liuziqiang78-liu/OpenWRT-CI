# MiMo v2.5 Pro APatch Module

> 将小米 MiMo v2.5 Pro AI 助手集成到 Android 系统中

## 功能特性

- 🤖 **AI 对话** - 通过云端 API 与 MiMo v2.5 Pro 实时对话
- 🌐 **WebUI** - 精美的暗色主题聊天界面 (端口 9081)
- 💻 **CLI 工具** - 终端命令行对话工具
- 🔧 **17 个技能** - 搜索、文件、代码、记忆、设备控制、多模态、文档、设计、写作、数据科学
- 📱 **移动优化** - 完全自适应手机屏幕

## 系统要求

- Android 11+ (API 30)
- APatch 已安装
- 网络连接 (云端 API 模式)
- Python 3 (WebUI 需要)

## 安装

1. 下载最新 Release 中的 ZIP 文件
2. 在 APatch Manager 中安装模块
3. 重启设备
4. 设置 API Token (见下方)
5. 打开浏览器访问 `http://localhost:9081`

## 配置 API Token

### 方式一：命令行

```bash
mimo_config
# 按提示输入 API 地址和 Token
```

### 方式二：WebUI

1. 打开 `http://localhost:9081`
2. 点击右上角 ⚙️ 设置
3. 输入 API Token
4. 保存

## 使用方式

### WebUI (推荐)

浏览器打开 `http://localhost:9081`

### CLI 命令

```bash
# 交互式对话
mimo_chat

# 单次提问
mimo_chat ask "什么是量子计算？"

# 技能工具箱
mimo search "最新新闻"
mimo weather "北京"
mimo exec "ls -la"
mimo python "print('hello')"
mimo help
```

## 技能列表

| 类别 | 技能 | 命令 |
|------|------|------|
| 🌐 网络 | 搜索、网页抓取、天气 | `mimo search/fetch/weather` |
| 📁 文件 | 读写、查找、编辑 | `mimo read/write/find/grep` |
| 💻 执行 | Shell、Python、Node | `mimo exec/python/node` |
| 🧠 记忆 | 保存、搜索、列出 | `mimo memory save/search/list` |
| ⏰ 定时 | 添加、列出、运行 | `mimo cron add/list/run` |
| 📱 设备 | 信息、截图、录屏 | `mimo device info/screenshot/record` |
| 🖼️ 多模态 | 图片分析、OCR、音频 | `mimo image/ocr/audio/video` |
| 📊 文档 | Excel、Word、PPT | `mimo excel/word/pptx create` |
| 🎨 设计 | 前端、SVG、图表 | `mimo design frontend/svg/chart` |
| ✍️ 写作 | 创作、总结、翻译 | `mimo write_content/summarize/translate` |
| 📊 数据 | 分析、建模、可视化 | `mimo data analyze/model/visualize` |
| 🔧 GitHub | Issues、PR、仓库 | `mimo gh issue/pr/repo` |

## 端口

| 服务 | 端口 |
|------|------|
| WebUI | 9081 |

## 目录结构

```
/data/adb/mimo/
├── config/          配置文件
├── tools/           工具脚本
├── skills/          技能定义
├── prompts/         系统提示词
├── webui/           WebUI 文件
├── memory/          记忆数据
├── workspace/       工作目录
└── cache/           缓存
```

## 卸载

1. 在 APatch Manager 中移除模块
2. 重启设备
3. 如需完全清理: `rm -rf /data/adb/mimo`

## 技术栈

- **后端**: Python HTTP Server (代理模式)
- **前端**: 原生 HTML/CSS/JS (无框架依赖)
- **API**: OpenAI 兼容格式 (`/v1/chat/completions`)
- **流式**: Server-Sent Events (SSE)

## License

MIT License
