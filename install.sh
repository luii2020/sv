#!/bin/bash

# 安装依赖
apt install vim wget xz-utils ca-certificates -y 
apt install curl

# Fetch the latest version of Shadowsocks-Rust
SS_VERSION=$(curl --silent "https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v(.*)".*/\1/')
SS_URL="https://github.com/shadowsocks/shadowsocks-rust/releases/download/v$SS_VERSION/shadowsocks-v$SS_VERSION.x86_64-unknown-linux-gnu.tar.xz"

# Fetch the latest version of v2ray-plugin
VP_VERSION=$(curl --silent "https://api.github.com/repos/teddysun/v2ray-plugin/releases/latest" | grep '"tag_name":' | sed -E 's/.*"v(.*)".*/\1/')
VP_URL="https://github.com/teddysun/v2ray-plugin/releases/download/v$VP_VERSION/v2ray-plugin-linux-amd64-v$VP_VERSION.tar.gz"



cd /usr/local/bin/
wget "$SS_URL"
wget "$VP_URL"
xz -d shadowsocks-v$SS_VERSION.x86_64-unknown-linux-gnu.tar.xz
tar -xf shadowsocks-v$SS_VERSION.x86_64-unknown-linux-gnu.tar
tar -zxf v2ray-plugin-linux-amd64-v$VP_VERSION.tar.gz
mv v2ray-plugin_linux_amd64 v2ray-plugin
chown root.root ./ss* ./v2ray-plugin
mkdir -p /usr/local/etc/shadowsocks-rust


# 创建配置文件
echo "请输入 server_port："
read SERVER_PORT
echo "请输入 password："
read PASSWORD

mkdir -p /usr/local/etc/shadowsocks-rust
cat > /usr/local/etc/shadowsocks-rust/config.json << EOF
{
    "server": "0.0.0.0",
    "server_port": $SERVER_PORT,
    "method": "aes-256-gcm",
    "timeout": 300,
    "password": "$PASSWORD",
    "fast_open": false,
    "nameserver": "8.8.8.8",
    "mode": "tcp_only",
    "plugin": "v2ray-plugin",
    "plugin_opts": "server"
}
EOF

# 配置系统服务并启动
cat > /etc/systemd/system/shadowsocks-rust.service << EOF
[Unit]
Description=Shadowsocks-Rust Service
After=network.target
[Service]
Type=simple
User=nobody
Group=nogroup
StandardOutput=null
ExecStart=/usr/local/bin/ssserver -c /usr/local/etc/shadowsocks-rust/config.json
[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start shadowsocks-rust
systemctl enable shadowsocks-rust
systemctl status shadowsocks-rust
