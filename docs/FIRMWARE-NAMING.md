# 固件命名规范

## 格式

```
[平台]-[设备]-[版本]-[日期]-[时间].bin
```

## 示例

```
MEDIATEK-Xiaomi_AX3000T-v2026.04.11-20260411-1200.bin
ROCKCHIP-NanoPi_R4S-v2026.04.11-20260411-1200.bin
X86-Generic-v2026.04.11-20260411-1200.img.gz
QUALCOMMAX-JDCloud_RE-CS-02-v2026.04.11-20260411-1200.bin
```

## 字段说明

| 字段 | 说明 | 示例 |
|------|------|------|
| 平台 | MEDIATEK / ROCKCHIP / X86 / QUALCOMMAX | MEDIATEK |
| 设备 | 设备型号 (下划线分隔) | Xiaomi_AX3000T |
| 版本 | 语义化版本号 | v2026.04.11 |
| 日期 | 编译日期 (YYYYMMDD) | 20260411 |
| 时间 | 编译时间 (HHMM) | 1200 |

## 文件类型

| 类型 | 扩展名 | 说明 |
|------|--------|------|
| 固件 | .bin | 标准固件 |
| X86 镜像 | .img.gz | 压缩镜像 |
| 虚拟机 | .vmdk | VMware 镜像 |
| 配置 | .txt | 配置文件 |

## 实现

在 WRT-CORE.yml 中：

```yaml
NEW_FILE="${WRT_SOURCE}-${WRT_DEVICE}-${WRT_VERSION}-${WRT_DATE}.bin"
```

## 好处

1. ✅ 一目了然识别固件信息
2. ✅ 便于版本管理
3. ✅ 避免刷错固件
4. ✅ 方便自动化处理
