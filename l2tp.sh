#!/bin/bash

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    echo "请以root用户运行此脚本"
    exit 1
fi

# 更新系统
echo "正在更新系统..."
yum update -y

# 安装必要软件包
echo "安装必要软件包..."
yum install -y epel-release
yum install -y strongswan xl2tpd ppp

# 配置IPsec
echo "配置IPsec..."
cat > /etc/ipsec.conf <<EOF
config setup
    virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12
    protostack=netkey
    nat_traversal=yes
    oe=off

conn L2TP-PSK-NAT
    rightsubnet=vhost:%priv
    also=L2TP-PSK-noNAT

conn L2TP-PSK-noNAT
    authby=secret
    pfs=no
    auto=add
    keyingtries=3
    ikelifetime=8h
    keylife=1h
    type=transport
    left=%defaultroute
    leftprotoport=17/1701
    right=%any
    rightprotoport=17/%any
    dpddelay=30s
    dpdtimeout=120s
    dpdaction=restart
EOF

# 配置预共享密钥
echo "配置预共享密钥..."
read -p "请输入预共享密钥（PSK）：" psk
psk=${psk:-"your_psk_here"}
echo "$psk $psk" > /etc/ipsec.secrets

# 配置XL2TPD
echo "配置XL2TPD..."
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
ipsec saref = yes
listen-addr = 0.0.0.0

[lns default]
ip range = 192.168.1.100-192.168.1.200
local ip = 192.168.1.1
require chap = yes
refuse pap = yes
require authentication = yes
name = l2tp-vpn
ppp debug = yes
pppoptfile = /etc/ppp/options.xl2tpd
length bit = yes
EOF

# 配置PPP选项
cat > /etc/ppp/options.xl2tpd <<EOF
ipcp-accept-local
ipcp-accept-remote
ms-dns 8.8.8.8
ms-dns 8.8.4.4
noccp
auth
crtscts
idle 1800
mtu 1410
mru 1410
nodefaultroute
debug
lock
proxyarp
connect-delay 5000
EOF

# 配置PPP认证
echo "配置PPP认证..."
read -p "请输入VPN用户名：" username
read -s -p "请输入VPN密码：" password
echo "$username * $password *" > /etc/ppp/chap-secrets

# 配置IP转发和NAT
echo "配置IP转发和NAT..."
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
systemctl restart network

# 启动服务
echo "启动服务..."
systemctl enable strongswan xl2tpd
systemctl start strongswan xl2tpd

# 配置防火墙
echo "配置防火墙..."
firewall-cmd --permanent --add-port 500/udp
firewall-cmd --permanent --add-port 4500/udp
firewall-cmd --permanent --add-port 1701/udp
firewall-cmd --permanent --add-masquerade
firewall-cmd --reload

# 完成提示
echo "==============================================="
echo "VPN服务器已安装完成！"
echo "预共享密钥: $psk"
echo "用户名: $username"
echo "客户端连接时请使用以下参数："
echo "服务器IP: $(hostname -I | awk '{print $1}')"
echo "协议: L2TP/IPsec PSK"
echo "-----------------------------------------------"
echo "请在阿里云控制台开放UDP 500, 4500, 1701端口"
echo "测试连接命令："
echo "Windows: rasdial 连接名称 用户名 密码"
echo "Android/iOS: 使用支持L2TP/IPsec的客户端"
