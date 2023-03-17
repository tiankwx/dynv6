# dynv6
 dynv6更新脚本 Dynv6 update script


## 使用方法
```
/bin/bash /dynv6.sh 更新域名 token 获取IPv6地址的网卡名

```

## 计划任务
```
# 每一分钟检查一次DDNS
*/1 * * * * /bin/bash /dynv6.sh roules.dynv6.net xxxxxxxxx br-lan

```