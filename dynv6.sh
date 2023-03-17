#!/bin/sh -e

# 域名
hostname=$1
# token
token=$2
# 从那个网卡取IP
device=$3
# 类型，是更新IPV6还是IPV4，还是两者都更新
# types=$3

logfile="/var/log/dynv6"
# -d 参数判断 $logfile 是否存在
[ -d $logfile ] || mkdir -p $logfile

# 原IP文件
# file4=$logfile/$1.ipv4.data
# [ -e $file4 ] && old=$(cat $file4)
file6=$logfile/$1.IPv6.data
[ -e $file6 ] && old=$(cat $file6)

if [ -z "$hostname" -o -z "$token" ]; then
    echo "Usage: ./$0 your-name.dynv6.net token [device]"
    echo "用法：./$0 域名 token [网卡名]"
    exit 1
fi

# -z 字符串	字符串的长度为零则为真
# if [ -z "$types" ]; then
#   # 默认更新类型 类型：ipv6[只更新IPV6] ipv4[只更新IPV4] ip[全部更新]
#   default=ipv6
# fi

# -n 字符串	字符串的长度不为零则为真
if [ -n "$device" ]; then
    device="dev $device"
fi

address6=$(ip -6 addr list scope global $device | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1)

if [ -e /usr/bin/curl ]; then
    bin="curl -fsS"
elif [ -e /usr/bin/wget ]; then
    bin="wget -O-"
else
    echo "neither curl nor wget found"
    echo "既没有找到 curl 也没有找到 wget"
    exit 1
fi

if [ -z "$address6" ]; then
    echo "no IPv6 address found"
    echo "没有找到IPv6地址"
    exit 1
fi

if [ "$old" = "$address6" ]; then
    echo -e $(date +"%Y-%m-%d %H:%M:%S") >>$logfile/$1.IPv6.log
    echo -e "IPv6 address unchanged" | tee -a $logfile/$1.IPv6.log
    echo -e "IPv6 没有改变\n" | tee -a $logfile/$1.IPv6.log
    exit
fi

url="https://ipv6.dynv6.com/api/update?zone=$hostname&ipv6=$address6&token=$token"
# send addresses to dynv6
echo -e $(date +"%Y-%m-%d %H:%M:%S") >>$logfile/$1.IPv6.log
echo -e "新IP:$address6" >>$logfile/$1.IPv6.log
echo -e $url >>$logfile/$1.IPv6.log
echo -e "更新状态：" >>$logfile/$1.IPv6.log
$bin $url | tee -a $logfile/$1.IPv6.log
echo -e "\n" | tee -a $logfile/$1.IPv6.log
# $bin "http://ipv4.dynv6.com/api/update?hostname=$hostname&ipv4=auto&token=$token"

# save address
echo $address6 >$file6
