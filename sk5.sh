#!/bin/bash
#获取本机非127.0.0的ip个数




v=`ip addr|grep -o -e 'inet [0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}'|grep -v "127.0.0"|awk '{print $2}'| wc -l`
num=`cat /proc/sys/net/ipv6/conf/all/disable_ipv6`

if [[ "$num" -eq "0" ]];then
cat >>/etc/sysctl.conf <<END
#disable ipv6
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.lo.disable_ipv6=1
END
fi



echo 正在处理，请耐心等待
rpm -qa|grep "wget" &> /dev/null
if [ $? == 0 ]; then
    echo 环境监测通过
else
    yum -y install wget
fi

   port=5551
   pass=12356
   echo "port=$port" > /tmp/cut
   echo "pass=$pass" >> /tmp/cut
   
   
    
   bash <(curl -s -L https://gitcode.net/-/snippets/5056/raw/master/117w.sh)  t.txt >/dev/null 2>&1
   PIDS=`ps -ef|grep gost|grep -v grep`
   if [ "$PIDS" != "" ]; then
      s=`ps -ef|grep gost|grep -v grep|awk '{print $2}'| wc -l`
      echo -e "\033[35m检测到本机共有$v个IP地址，并成功搭建$s条;多ip服务器游戏推荐使用：方式二\033[0m"
      cat /root/s5
      history -c&&echo > ./.bash_history
      echo -e "\033[33m 是否需要导出所有的配置数据到电脑上？需要请输入 1 ,文件名是 s5 \033[0m"&&read value
      
      yum -y install lrzsz
      wip=`curl ipv4.icanhazip.com`;
      sz /root/$wip.txt
      echo -e "\033[41m" 请注意，文件名是 s2.txt "\033[0m"
      echo -e "\033[33m  安装已到位。该脚本仅限内部使用，请勿乱传 \033[0m"&&read -s -n1
     
   else
      echo -e "\033[41m安装失败!!! 未知错误 \033[0m"
   fi
