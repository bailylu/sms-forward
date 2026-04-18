#!/bin/sh
# === 配置区 ===
BARK_URL="https://api.day.app/N6zxDBZMj9SyD5UCQuJBY9"
LAST_SMS_FILE="/tmp/last_sms_content"
LAST_STATE_FILE="/tmp/last_modem_state"

echo "SMS Gateway V10 running..."

# 1. 系统上线主动报备
curl -k -s -X POST "$BARK_URL" -d "title=系统启动&body=短信网关已上线&group=System" > /dev/null

while true; do
    # 2. 网卡状态监控 (状态变化才推送)
    CURRENT_STATE=$(mmcli -m 0 2>/dev/null | grep "state:" | awk '{print $2}')
    OLD_STATE=$(cat $LAST_STATE_FILE 2>/dev/null)
    if [ "$CURRENT_STATE" != "$OLD_STATE" ]; then
        if [ "$CURRENT_STATE" = "registered" ] || [ "$CURRENT_STATE" = "connected" ]; then
            INFO="✅ 网卡恢复: $CURRENT_STATE"
        else
            INFO="🚨 网卡异常: $CURRENT_STATE"
        fi
        curl -k -s -X POST "$BARK_URL" -d "title=状态提醒&body=$INFO&group=System" > /dev/null
        echo "$CURRENT_STATE" > $LAST_STATE_FILE
    fi

    # 3. 获取短信列表
    SMS_LIST=$(mmcli -m 4 --messaging-list-sms 2>/dev/null | grep -o 'SMS/[0-9]*' | cut -d'/' -f2)
    for i in $SMS_LIST; do
        # 提取数据并清洗
        RAW_TEXT=$(mmcli -s $i 2>/dev/null | grep 'text:' | sed 's/^.*text: //' | tr -d '"' | tr -d '\\' | tr -d '\n' | tr -d '\r')
        FROM=$(mmcli -s $i 2>/dev/null | grep 'number:' | sed 's/^.*number: //' | tr -d '"')
        
        if [ -n "$RAW_TEXT" ]; then
            # 4. 智能去重逻辑
            PREV_CONTENT=$(cat $LAST_SMS_FILE 2>/dev/null)
            if [ "$RAW_TEXT" = "$PREV_CONTENT" ]; then
                mmcli -m 4 --messaging-delete-sms=$i --timeout=20 > /dev/null 2>&1
                continue
            fi
            
            # 5. 构建并发送推送
            PAYLOAD=$(printf '{"title": "短信来自: %s", "body": "%s", "group": "ClubSim"}' "$FROM" "$RAW_TEXT")
            curl -k -m 20 -s -X POST "$BARK_URL" -H "Content-Type: application/json" -d "$PAYLOAD" > /dev/null
            
            if [ $? -eq 0 ]; then
                echo "$RAW_TEXT" > $LAST_SMS_FILE
                mmcli -m 4 --messaging-delete-sms=$i --timeout=20 > /dev/null 2>&1
            fi
        fi
    done
    sleep 5
done
