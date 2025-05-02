#!/bin/bash

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    echo "请以root用户运行此脚本"
    exit 1
fi

# 更新系统
echo "正在更新系统..."
yum update -y

# 安装必要软件包（仅xl2tpd和ppp）
echo "安装必要软件包..."
yum install -y epel-release
yum install -y xl2tpd ppp

# 配置L2TP（xl2tpd）
echo "配置L2TP..."
cat > /etc/xl2tpd/xl2tpd.conf <<EOF
[global]
ipsec saref = no  # 明确禁用IPsec集成
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

# 配置PPP认证（用户名/密码）
echo "配置PPP认证..."
cat > /etc/ppp/options.xl2tpd <<EOF
ipcp-accept-local
ipcp-accept-remote
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

# 创建PPP用户密码文件
echo "创建PPP用户密码..."
echo "ss * ss123 *" > /etc/ppp/chap-secrets

# 配置IP转发和NAT
echo "配置IP转发和NAT..."
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
sysctl -p

iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
systemctl restart network

# 启动服务
echo "启动服务..."
systemctl enable xl2tpd
systemctl start xl2tpd

# 配置防火墙（仅开放UDP 1701）
echo "配置防火墙..."
firewall-cmd --permanent --remove-port=500/udp  # 移除IPsec相关端口
firewall-cmd --permanent --remove-port=4500/udp
firewall-cmd --permanent --add-port=1701/udp
firewall-cmd --permanent --add-masquerade
firewall-cmd --reload

# 完成提示
echo "==============================================="
echo "L2TP服务器已安装完成（⚠️ 未启用加密！）"
echo "用户名: ss"
echo "密码: ss123"
echo "客户端连接时请使用以下参数："
echo "服务器IP: $(hostname -I | awk '{print $1}')"
echo "协议: L2TP（仅UDP 1701端口）"
echo "-----------------------------------------------"
echo "警告：数据未加密，请仅在可信网络中使用！"
