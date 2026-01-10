#!/bin/bash

toBase64() {
  echo -n "$1" | base64
}

AUTOUPDATE=${AUTOUPDATE:-Y}
SENDTYPE=${SENDTYPE:-null}
TELEGRAM_TOKEN=${TELEGRAM_TOKEN:-null}
TELEGRAM_USERID=${TELEGRAM_USERID:-null}
WXSENDKEY=${WXSENDKEY:-null}
WXPUSH_URL=${WXPUSH_URL:-null}
WX_TOKEN=${WX_TOKEN:-null}
BUTTON_URL=${BUTTON_URL:-null}
LOGININFO=${LOGININFO:-N}
TOKEN=${TOKEN:-""}

TOKEN=$(toBase64 $TOKEN)
base64_TELEGRAM_TOKEN=$(toBase64 $TELEGRAM_TOKEN)
Base64BUTTON_URL=$(toBase64 $BUTTON_URL)
base64_WXPUSH_URL=$(toBase64 $WXPUSH_URL)
base64_WX_TOKEN=$(toBase64 $WX_TOKEN)

export TELEGRAM_TOKEN TELEGRAM_USERID BUTTON_URL

# 使用 jq 提取 JSON 数组，并将其加载为 Bash 数组
hosts_info=($(echo "${HOSTS_JSON}" | jq -c ".info[]"))
summary=""
for info in "${hosts_info[@]}"; do
  user=$(echo $info | jq -r ".username")
  host=$(echo $info | jq -r ".host")
  port=$(echo $info | jq -r ".port")
  pass=$(echo $info | jq -r ".password")

  echo "检查主机: $host, 用户: $user, 端口: $port"
  
  # 对密码进行base64编码
  bas64_pass=$(toBase64 $pass)
  
  # 构建CT8的保活请求URL
  # 注意：CT8可能需要不同的URL格式，这里假设与serv00类似但使用不同的域名
  output=$(curl -s -o /dev/null -w "%{http_code}" "https://$host/keep?token=$TOKEN&autoupdate=$AUTOUPDATE&sendtype=$SENDTYPE&telegramtoken=$base64_TELEGRAM_TOKEN&telegramuserid=$TELEGRAM_USERID&wxsendkey=$WXSENDKEY&buttonurl=$Base64BUTTON_URL&password=$bas64_pass&wxpushurl=$base64_WXPUSH_URL&wxtoken=$base64_WX_TOKEN&port=$port")

  if [ "$output" -eq 200 ]; then
    echo "连接成功，账号正常"
    msg="🟢主机 ${host}:${port}, 用户 ${user}，连接成功，账号正常！\n"
  elif [ "$output" -eq 403 ]; then
    echo "账号被封或登录失败"
    msg="🔴主机 ${host}:${port}, 用户 ${user}，账号被封或登录失败！\n"
    chmod +x ./tgsend.sh
    export PASS=$pass
    ./tgsend.sh "CT8告警 - Host:${host}:${port}, user:${user}, 账号被封或登录失败，请检查！"
  elif [ "$output" -eq 404 ]; then
    echo "保活服务不在线"
    msg="🔴主机 ${host}:${port}, 用户 ${user}，保活服务不在线！\n"
    chmod +x ./tgsend.sh
    export PASS=$pass
    ./tgsend.sh "CT8告警 - Host:${host}:${port}, user:${user}, 保活服务不在线，请检查！"
  elif [ "$output" -eq 401 ]; then
    echo "授权码错误"
    msg="🔴主机 ${host}:${port}, 用户 ${user}，授权码错误！\n"
    chmod +x ./tgsend.sh
    export PASS=$pass
    ./tgsend.sh "CT8告警 - Host:${host}:${port}, user:${user}, 授权码错误，请检查！"
  else
    echo "连接失败，HTTP状态码: $output"
    msg="🔴主机 ${host}:${port}, 用户 ${user}，连接失败，HTTP状态码: ${output}！\n"
    chmod +x ./tgsend.sh
    export PASS=$pass
    ./tgsend.sh "CT8告警 - Host:${host}:${port}, user:${user}, 连接失败，状态码: ${output}，请检查网络或服务状态"
  fi
  summary=$summary$(echo -n $msg)
done

if [[ "$LOGININFO" == "Y" ]]; then
  chmod +x ./tgsend.sh
  ./tgsend.sh "CT8保活报告：\n$summary"
fi
