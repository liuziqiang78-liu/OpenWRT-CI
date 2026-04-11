# OpenWRT 插件架构兼容性

**更新时间**: 2026-04-11

---

## 📊 架构支持表

| 插件 | MEDIATEK | ROCKCHIP | X86 | IPQ60XX | IPQ50XX | IPQ807X |
|------|----------|----------|-----|---------|---------|---------|
| **Docker** | ⚠️ | ⚠️ | ✅ | ❌ | ❌ | ❌ |
| **DiskMan** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Aria2** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Qbittorrent** | ⚠️ | ⚠️ | ✅ | ❌ | ❌ | ❌ |
| **Transmission** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Samba4** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **MosDNS** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **OpenClash** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **HomeProxy** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

**图例**:
- ✅ 完全支持
- ⚠️ 需要大内存 (512MB+)
- ❌ 不支持

---

## 🔧 Docker 插件详情

### 包名
```
luci-app-dockerman
docker
dockerd
```

### 架构要求
- **X86**: ✅ 完美支持
- **ROCKCHIP**: ⚠️ 需要 512MB+ 内存
- **MEDIATEK**: ⚠️ 需要 512MB+ 内存
- **IPQ 系列**: ❌ 不支持 (资源限制)

### 依赖
```
cgroupfs-mount
libcgroup
libdocker
dockerd
docker-compose (可选)
```

### 功能
- 容器管理
- 镜像管理
- 网络管理
- 卷管理
- Docker Compose 支持

---

## 🛡️ 防火墙选择

### Firewall 类型

| 类型 | 说明 | 推荐 |
|------|------|------|
| **Firewall4 (NFT)** | 新版防火墙，基于 nftables | ✅ 推荐 |
| **Iptables** | 传统防火墙，兼容性好 | ⚠️ 兼容模式 |

### Firewall4 特性
- 性能更好
- 语法更简洁
- 支持更多特性
- OpenWrt 23.05+ 默认

### Iptables 特性
- 兼容旧插件
- 文档更多
- 用户熟悉
- 资源占用略高

---

*更新时间：2026-04-11*
