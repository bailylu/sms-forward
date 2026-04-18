# SMS Forward to Bark

短信转发工具，将随身WiFi设备的短信转发到Bark。

## 功能

- 监听 modem 短信
- 转发到 Bark
- 网络状态变化通知
- 自动去重

## 部署

```bash
# 复制脚本
scp sms_forwarder.sh root@your-device:/root/

# 复制服务
scp sms-forward.service root@your-device:/etc/systemd/system/

# 启动服务
systemctl enable sms-forward
systemctl start sms-forward
```

## 配置

编辑 `sms_forwarder.sh` 中的 `BARK_URL` 为你的 Bark 地址。
