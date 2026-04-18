# 随身WiFi 短信转发到 Bark

## 项目概述

本项目实现将高通410随身WiFi设备（已刷Debian系统）的短信转发到Bark。

### 功能特性

- 实时监听接收短信
- 自动转发到Bark
- 网络状态监控（信号/运营商）
- 自动去重

---

## 硬件准备

### 推荐设备

- **高通410 (Qualcomm MDM8209A)** 随身WiFi设备
- 可选型号：UFI001 / UFI003 / CCE-5G 等
- 设备需已刷入Debian系统

### 判断设备是否支持

设备管理器中应出现 **9008 QDLoader** 端口（刷机模式）

---

## 刷机教程

### 1. 下载刷机包

下载包含以下内容的刷机包：
- `Mico` 刷机工具
- `xxx.bin` 全量包

> 注意：刷机包请联系设备卖家获取，或从恩山无线论坛等社区下载。

### 2. 进入9008刷机模式

1. 设备连接电脑
2. 同时按住**电源键**和**音量+**
3. 直到电脑出现9008端口（约10秒）

### 3. 刷入Debian

1. 打开 `Mico` 刷机工具
2. 选择 `.bin` 全量包
3. 点击开始刷入
4. **等待设备自动重启**（约2-3分钟）

> ⚠️ 刷机过程中请勿断开设备！

---

## 连接设备

### 网络配置

设备通过USB共享网络，IP地址固定为 **10.42.0.1**

```bash
# SSH连接（电脑需与设备在同一网络）
ssh root@10.42.0.1
```

### 连接信息

| 项目 | 值 |
|------|-----|
| IP地址 | 10.42.0.1 |
| 用户名 | root |
| 密码 | 1313144 |
| 端口 | 22 |

---

## 部署短信转发

### 方式一：使用本项目脚本（推荐）

```bash
# 1. 连接设备
ssh root@10.42.0.1

# 2. 下载转发脚本
wget https://raw.githubusercontent.com/bailylu/sms-forward/main/sms_forwarder.sh
# 或手动复制脚本内容

# 3. 创建服务
mv sms_forwarder.sh /root/
chmod +x /root/sms_forwarder.sh

# 4. 配置Bark地址（编辑脚本第4行）
vi /root/sms_forwarder.sh
# 将 BARK_URL 改为你的 Bark 地址

# 5. 启动服务
# 创建 systemd 服务（见下方）

# 6. 开机自启
systemctl enable sms-forward
systemctl start sms-forward
```

### 方式二：使用DbusSmsForward（原始项目）

```bash
# 1. 下载程序
wget https://github.com/lkiuyu/DbusSmsForward/releases

# 2. 安装依赖
apt install libicu67

# 3. 配置权限
chmod -R 777 DbusSmsForward

# 4. 运行配置
./DbusSmsForward

# 5. 按提示选择转发渠道
# 支持：Bark (-fB)、 PushPlus (-fP)、钉钉 (-fD)、TG (-fT) 等
```

---

## systemd 服务配置

将以下内容保存为 `/etc/systemd/system/sms-forward.service`：

```ini
[Unit]
Description=SMS to Bark Forwarder
After=network.target

[Service]
Type=simple
ExecStart=/root/sms_forwarder.sh
Restart=always
RestartSec=10
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
```

启动服务：

```bash
systemctl daemon-reload
systemctl enable sms-forward
systemctl start sms-forward
systemctl status sms-forward
```

---

## Bark 配置

### 获取Bark Key

1. iPhone 下载 **Bark** App
2. 打开App，复制测试URL
3. URL格式：`https://api.day.app/你的DeviceKey/...`
4. 将 `你的DeviceKey` 填入脚本

### 公共Bark服务器

如使用公共服务器，地址为：`https://api.day.app`

---

## 查看运行状态

```bash
# 检查服务状态
systemctl status sms-forward

# 查看日志
journalctl -u sms-forward -f

# 检查Modem状态
mmcli -m 4

# 检查短信列表
mmcli -m 4 --messaging-list-sms
```

---

## 项目结构

```
sms-forward/
├── README.md              # 本教程
├── sms_forwarder.sh       # 转发脚本（Shell版本）
├── sms-forward.service    # systemd服务配置
└── [bin文件]              # Debian镜像（需自行获取）
```

---

## 硬件信息

设备信息（参考）：

| 项目 | 值 |
|------|-----|
| 型号 | UFI103_CT |
| 架构 | ARM64 (aarch64) |
| CPU | Qualcomm MDM8209A |
| 基带 | qcom-soc |
| 内存 | 按实际设备 |

---

## 常见问题

### Q: 设备无法连接SSH
- 检查USB网络共享是否开启
- 确认电脑IP设置为同一网段（如 10.42.0.100）
- 尝试重启设备

### Q: mmcli找不到modem
- 等待设备完全启动（约2分钟）
- 检查ModemManager服务状态：`systemctl status ModemManager`

### Q: 短信未转发
- 检查Bark Key是否正确
- 检查网络连接
- 查看日志排查：`journalctl -u sms-forward`

---

## 参考链接

- [DbusSmsForward 原始项目](https://github.com/lkiuyu/DbusSmsForward)
- [Bark Server](https://github.com/finb/bark)
- [恩山无线论坛](https://www.right.com.cn/forum/) - 随身WiFi刷机社区

---

## License

MIT
