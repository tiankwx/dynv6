# 说明 Note
 dynv6更新脚本
 Dynv6 update script

## 使用方法 Use
```
/bin/bash /dynv6.sh 更新域名 token [获取IPv6地址的网卡名] [ipv6/ipv4/ip]
/bin/bash /dynv6.sh domain token [device] [ipv6/ipv4/ip]
```

## 计划任务 Crontab 
```
# 每三分钟检查一次
# Check every three minutes；
*/3 * * * * /bin/bash /dynv6.sh domain.dynv6.net xxxxxxxxx eth0

```