#!/bin/sh -e

# 域名
hostname=$1
# token
token=$2
# 从那个网卡取IP
device=$3
# 类型，是更新IPV6还是IPV4，还是两者都更新
types=$4

if [ -z "$hostname" -o -z "$token" ]; then
    echo "Usage: ./$0 domain token [device] [ipv4/ipv6/ip]"
    echo "用法：./$0 域名 token [网卡名] [更新类型]"
    exit 1
fi

# -z 字符串	字符串的长度为零则为真
if [ -z "$types" ]; then
    # 默认更新类型 类型：ipv6[只更新IPV6] ipv4[只更新IPV4] ip[全部更新]
    types=ip
fi

# -n 字符串	字符串的长度不为零则为真
if [ -n "$device" ]; then
    device=""
fi

logfile="/var/log/dynv6"
# -d 参数判断 $logfile 是否存在
[ -d $logfile ] || mkdir -p $logfile

if [ -e /usr/bin/curl ]; then
    bin="curl -fsS"
elif [ -e /usr/bin/wget ]; then
    bin="wget -O-"
else
    echo "neither curl nor wget found"
    echo "既没有找到 curl 也没有找到 wget"
    exit 1
fi

file4=$logfile/$1.ipv4.data
file6=$logfile/$1.IPv6.data

get_ipv4() {
    address4=$(curl -m 15 -s http://ipv4.miuku.net/)
    if [ -z "$address4" ]; then
        echo "no IPv4 address found"
        echo "没有找到IPv4地址"
        return 1
    fi
    # echo $address4 >$file4
}

get_ipv6() {
    address6=$(ip -6 addr list scope global $device | grep -v " fd" | sed -n 's/.*inet6 \([0-9a-f:]\+\).*/\1/p' | head -n 1)
    if [ -z "$address6" ]; then
        echo "no IPv6 address found"
        echo "没有找到IPv6地址"
        return 1
    fi
    # echo $address6 >$file6
}

update_ipv6_address() {
    get_ipv6

    [ -e $file6 ] && old=$(cat $file6)
    if [ -n "$old" ]; then
        echo -e "本地ipv6缓存地址"
        echo -e $old
    fi

    # 取解析地址
    remote=$(/usr/bin/nslookup $hostname 119.29.29.29 | grep Address: | tail -n1 | cut -d ' ' -f2)
    echo -e "nslookup解析地址"
    echo -e $remote

    if [ "$old" = "$address6" ] && [ "$remote" = "$address6" ]; then
        logpath=$logfile/$hostname.ipv6.log
        echo -e $(date +"%Y-%m-%d %H:%M:%S") >>$logpath
        echo -e "IPv6 address unchanged" | tee -a $logpath
        echo -e "IPv6 没有改变\n" | tee -a $logpath
        return 1
    else
        # 域名 类型 地址 token 日志路径 保存路径
        update $hostname ipv6 $address6 $token $logfile $file6
    fi
}

update_ipv4_address() {
    get_ipv4

    [ -e $file4 ] && old4=$(cat $file4)
    if [ -n "$old4" ]; then
        echo -e "本地ipv4缓存地址"
        echo -e $old4
    fi

    if [ "$old4" = "$address4" ]; then
        logpath=$logfile/$hostname.ipv4.log
        echo -e $(date +"%Y-%m-%d %H:%M:%S") >>$logpath
        echo -e "IPv4 address unchanged" | tee -a $logpath
        echo -e "IPv4 没有改变\n" | tee -a $logpath
        return 1
    else
        # 域名 类型 地址 token 日志路径 保存路径
        update $hostname ipv4 $address4 $token $logfile $file4
    fi
}

update() {
    url="https://dynv6.com/api/update?zone=$1&$2=$3&token=$4"
    echo $url
    # send addresses to dynv6
    logpath=$5/$1.$2.log
    echo -e $(date +"%Y-%m-%d %H:%M:%S") >>$logpath
    echo -e "新IP:$3" >>$logpath
    echo -e $url >>$logpath
    echo -e "更新状态：" >>$logpath
    $bin $url | tee -a $logpath
    echo -e "\n" | tee -a $logpath
    # save address
    echo $3 >$6
}

if [ $types = "ipv4" ]; then
    update_ipv4_address
elif [ $types = "ipv6" ]; then
    update_ipv6_address
else
    update_ipv4_address
    update_ipv6_address
fi
