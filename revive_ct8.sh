#!/bin/bash

# --- 用户配置区 ---
# CT8 的 SSH 主机地址
SSH_HOST="s1.ct8.pl"
# CT8 的 SSH 端口 (标准端口是 22)
SSH_PORT="22"
# SSH 连接超时时间 (秒)
SSH_TIMEOUT=15
# ---------------------------------------------------------

# 函数：将字符串转换为 Base64
toBase64() {
  echo -n "$1" | base64
}

# 从环境变量加载配置
AUTOUPDATE=${AUTOUPDATE:-Y}
SENDTYPE=${SENDTYPE:-null}
TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-null}
TELEGRAM_USERID=${TELEGRAM_USERID:-null}
WXSENDKEY=${WXSENDKEY:-null}
BUTTON_URL=${BUTTON_URL:-null}
LOGININFO=${LOGININFO:-N}
TOKEN=${TOKEN:-""}

# 为通知服务编码变量
TOKEN=$(toBase64 $TOKEN)
base64_TELEGRAM_TOKEN=$(toBase64 $TELEGRAM_TOKEN)
Base64BUTTON_URL=$(toBase64 $BUTTON_URL)
export TELEGRAM_TOKEN TELEGRAM_USERID BUTTON_URL

# 使用 jq 解析 JSON 格式的账户列表
hosts_info=($(echo "${HOSTS_JSON}" | jq -c ".info[]"))
summary=""

# 循环处理每个账户
for info in "${hosts_info[@]}"; do
  user=$(echo $info | jq -r ".username")
  pass=$(echo $info | jq -r ".password")

  # 对用户名进行星号处理，保护隐私
  user_len=${#user}
  if [ "$user_len" -gt 2 ]; then
    prefix=${user:0:2}
    suffix_len=$((user_len - 2))
    asterisks=$(printf "%${suffix_len}s" | tr ' ' '*')
    masked_user="${prefix}${asterisks}"
  else
    masked_user="$user"
  fi

  echo "--- 正在处理 SSH 账户: $masked_user ---"

  # --- 核心保活逻辑：执行 'date' 命令并验证输出 ---
  # 尝试执行 'date' 命令并捕获其输出。
  # 2>/dev/null 会将SSH连接过程中的错误信息（如密码错误）丢弃，确保我们只捕获 date 命令本身的输出。
  date_output=$(sshpass -p "$pass" ssh -p ${SSH_PORT} -o StrictHostKeyChecking=no -o ConnectTimeout=${SSH_TIMEOUT} ${user}@${SSH_HOST} 'date' 2>/dev/null)

  # 检查 'date_output' 变量是否非空。如果非空，说明命令成功执行。
  if [ -n "$date_output" ]; then
    echo "SSH 验证成功"
    # 打印从服务器获取的日期结果
    echo "服务器时间: $date_output"
    msg="✅ 主机 ${SSH_HOST}, 用户 ${masked_user}， 验证成功 (服务器时间: ${date_output})!\n"
  else
    echo "SSH 验证失败，无法执行远程命令"
    msg="🔴 主机 ${SSH_HOST}, 用户 ${masked_user}， 验证失败，无法执行远程命令!\n"
  fi
  # --- 核心逻辑结束 ---

  summary=$summary$(echo -n $msg)
done

# 如果配置了，则发送汇总通知
if [[ "$LOGININFO" == "Y" ]]; then
  if [ -f "./tgsend.sh" ]; then
    chmod +x ./tgsend.sh
    ./tgsend.sh "$summary"
    echo "--- 汇总信息已发送 ---"
  else
    echo "未找到 tgsend.sh，无法发送通知。"
  fi
fi

echo "--- 所有任务完成 ---"
