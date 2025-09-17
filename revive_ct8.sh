#!/bin/bash

# --- 用户配置区 ---
# CT8 面板登录页面的 URL
LOGIN_URL="https://panel.ct8.pl/login/"
# 用户名输入框的 name 属性
USERNAME_FIELD="username"
# 密码输入框的 name 属性
PASSWORD_FIELD="password"
# 登录失败时页面会显示的错误信息 (根据你的截图已更新)
FAILURE_KEYWORD="Please enter a correct username and password"
# ------------------------------------

# 函数：将字符串转换为 Base64
toBase64() {
  echo -n "$1" | base64
}

# 从环境变量加载配置，提供默认值
AUTOUPDATE=${AUTOUPDATE:-Y}
SENDTYPE=${SENDTYPE:-null}
TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-null}
TELEGRAM_USERID=${TELEGRAM_USERID:-null}
WXSENDKEY=${WXSENDKEY:-null}
BUTTON_URL=${BUTTON_URL:-null}
LOGININFO=${LOGININFO:-N}
TOKEN=${TOKEN:-""} 

# Base64 编码一些通知服务需要的变量
TOKEN=$(toBase64 $TOKEN)
base64_TELEGRAM_TOKEN=$(toBase64 $TELEGRAM_TOKEN)
Base64BUTTON_URL=$(toBase64 $BUTTON_URL)

export TELEGRAM_TOKEN TELEGRAM_USERID BUTTON_URL

# 使用 jq 解析 JSON 数组
# 运行前请确保已设置 HOSTS_JSON 环境变量
# 例如: export HOSTS_JSON='{"info":[{"username":"你的用户名","password":"你的密码"}]}'
hosts_info=($(echo "${HOSTS_JSON}" | jq -c ".info[]"))
summary=""

# 循环处理每个账户
for info in "${hosts_info[@]}"; do
  user=$(echo $info | jq -r ".username")
  pass=$(echo $info | jq -r ".password")
  host="panel.ct8.pl"

  echo "--- 正在处理 CT8 账户: $user ---"

  # 使用 curl 模拟登录 POST 请求
  output=$(curl -s -L \
    --cookie-jar /tmp/ct8_cookie.txt \
    -A "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/108.0.0.0 Safari/537.36" \
    -d "${USERNAME_FIELD}=${user}&${PASSWORD_FIELD}=${pass}" \
    "${LOGIN_URL}")

  # 检查返回的 HTML 内容是否包含失败关键字
  if echo "$output" | grep -q "$FAILURE_KEYWORD"; then
    echo "登录失败，用户名或密码错误"
    msg="🔴CT8 主机 ${host}, 用户 ${user}， 登录失败，请检查用户名或密码!\n"
  else
    echo "登录成功，账号正常"
    msg="🟢CT8 主机 ${host}, 用户 ${user}， 登录成功，账号正常!\n"
  fi

  summary=$summary$(echo -n $msg)
done

# 如果 LOGININFO 设置为 Y，则发送汇总通知
if [[ "$LOGININFO" == "Y" ]]; then
  if [ -f "./tgsend.sh" ]; then
    chmod +x ./tgsend.sh
    ./tgsend.sh "$summary"
    echo "--- 汇总信息已发送 ---"
  else
    echo "未找到 tgsend.sh，无法发送通知。"
  fi
fi

# 清理 cookie 文件
rm -f /tmp/ct8_cookie.txt

echo "--- 所有任务完成 ---"
