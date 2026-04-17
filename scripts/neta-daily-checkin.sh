#!/bin/bash
# 🦋 芭德卡特 - 每日自动签到脚本
# 功能：自动签到领取捏 Ta 电量

set -e

echo "🦋 芭德卡特 - 每日自动签到"
echo "=========================="

# API 配置
API_URL="https://api.talesofai.cn/v1/checkin/manual"
NETA_TOKEN="${NETA_TOKEN:-}"

# 检查 Token
if [ -z "$NETA_TOKEN" ]; then
    echo "❌ 错误：NETA_TOKEN 环境变量未设置"
    exit 1
fi

echo "📝 开始签到..."

# 发送签到请求
RESPONSE=$(curl -s -X POST \
  -H "x-platform: nieta-app-web" \
  -H "x-token: $NETA_TOKEN" \
  -H "device-id: 7548453225138204160" \
  -H "x-nieta-app-version: 6.9.9" \
  -H "User-Agent: Mozilla/5.0 (Linux; Android 13; V2220A Build/TP1A.220624.014) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.7680.119 Mobile Safari/537.36" \
  -H "Content-Type: application/json" \
  -d '{}' \
  "$API_URL")

echo "📊 响应：$RESPONSE"

# 解析响应
# 情况 1: 返回 checkin_result (新 API 格式)
if echo "$RESPONSE" | jq -e '.checkin_result' > /dev/null 2>&1; then
    CHECKIN_RESULT=$(echo "$RESPONSE" | jq -r '.checkin_result')
    REWARD_NAME=$(echo "$RESPONSE" | jq -r '.reward_detail.reward_name // "未知"')
    REWARD_VALUE=$(echo "$RESPONSE" | jq -r '.reward_detail.reward_value // 0')
    CYCLE_DAY=$(echo "$RESPONSE" | jq -r '.reward_detail.cycle_day // "?"')
    
    if [ "$CHECKIN_RESULT" = "true" ]; then
        echo "🎉 签到成功！获得 ${REWARD_VALUE}${REWARD_NAME} (第${CYCLE_DAY}天)"
        exit 0
    else
        echo "❌ 签到失败：checkin_result=false"
        exit 1
    fi

# 情况 2: 返回 message (旧 API 格式)
elif echo "$RESPONSE" | jq -e '.message' > /dev/null 2>&1; then
    MESSAGE=$(echo "$RESPONSE" | jq -r '.message')
    echo "✅ 签到结果：$MESSAGE"
    
    # 判断是否成功
    if [[ "$MESSAGE" == *"签到成功"* ]]; then
        echo "🎉 签到成功！电量已到账"
        exit 0
    elif [[ "$MESSAGE" == *"已经签到"* ]]; then
        echo "ℹ️  今天已经签到过了"
        exit 0
    else
        echo "⚠️  未知响应：$MESSAGE"
        exit 1
    fi

# 情况 3: 其他格式
else
    echo "❌ 签到失败：$RESPONSE"
    exit 1
fi
