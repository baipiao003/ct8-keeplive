# ct8批量保号、消息推送

## 变量说明

| 变量名          | 示例   | 备注                                                                             |
| --------------- | ------ | -------------------------------------------------------------------------------- |
| HOSTS_JSON      | 见示例 | 可存放 n 个服务器信息 (必选)                                                     |
| TELEGRAM_TOKEN  | 略     | telegram 机器人的 token (发送 TG 消息必选)                                       |
| TELEGRAM_USERID | 略     | 待通知的 teltegram 用户 ID (发送 TG 消息必选)                                    |
| WXSENDKEY       | 略     | server 酱的 sendkey，用于接收微信消息 (发送微信消息必选)                         |
| SENDTYPE        | 1      | 选择推送方式，1.Telegram, 2.微信, 3.都有 (发送消息必选)                          |
| BUTTON_URL      | 略     | 设置 TG 推送消息中的按钮链接 (发送 TG 消息可选),支持#HOST，#USER，#PASS 等变量。 |
| AUTOUPDATE      | Y/N    | 设置是否自动更新服务器上的代码,设置在 variable 变量中，值为 Y/N(默认: Y)         |
| LOGININFO       | Y/N    | 在 variable 变量中设置(默认为 N)，Y:发送登录汇总消息 N:只在登录失败时发送        |
| TOKEN           | 123456 | 网页保活(keepalive)的密钥(必选)                                                  |

各主机保活时可不必输入消息通知参数，由 github 同一配置参数。

如果主机上配置了消息推送参数，则优先级大于 github 上的配置。

## action 保活内容

1.定时自动登录各个主机，起到保号作用(因 serv00 需要每 3 个月登录一次)  
2.执行兜底保活策略  
3.检查主机上保活用的 cronjob 是否被删，若被删重建保活 cronjob  
4.自动更新 serv00-play 代码  
5.同步更新 telegram、微信等参数  
6.默认情况下只有登录失败才有 TG 消息通知，提醒可能封号(平时正常不会给你发消息，发消息之时便是你封号之日)
也可以设定 LOGININFO=Y，每次保活都会做汇总通知(但相信我，你不会喜欢这个功能)  
7.keepalive 保活虽然不做 ssh 登录，但一样有延续服务器有效期的效果(不再需要 3 月一登)。

## 消息推送

支持向 Telegram 和微信用户发送通知

关于如何配置 Telegram 以实现消息推送，可以看 [这个视频](https://www.youtube.com/watch?v=l8fPnMfq86c&t=3s)

关于微信的配置，目前使用第三方平台提供的功能，可以到 [这里](https://sct.ftqq.com/r/13223) 注册并登录 server 酱，取得 sendKey

## HOSTS_JSON 的配置实例

```js
 {
   "info": [
    {
      "host": "s2.serv00.com",
      "username": "kkk",
      "port": 22,
      "password": "fdsafjijgn"
    },
    {
      "host": "s2.serv00.com",
      "username": "bbb",
      "port": 22,
      "password": "fafwwwwazcs"
    }
  ]
}
```

## 免责声明

本程序仅供学习了解, 非盈利目的，请于下载后 24 小时内删除, 不得用作任何商业用途, 代码、数据及图片均有所属版权, 如转载须注明来源。
使用本程序必循遵守部署免责声明。使用本程序必循遵守部署服务器所在地、所在国家和用户所在国家的法律法规, 程序作者不对使用者任何不当行为负责。
