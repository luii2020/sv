#!/bin/bash

# 安装依赖
apt update
apt install -y wget xz-utils ca-certificates 
choice="y"
apt install curl

# Determine latest version of shadowsocks-rust and v2ray-plugin
SS_VER=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep "tag_name" | cut -d '"' -f 4)
VP_VER=$(curl -s https://api.github.com/repos/teddysun/v2ray-plugin/releases/latest | grep "tag_name" | cut -d '"' -f 4)

# Download and extract shadowsocks-rust
cd /usr/local/bin/
wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/$SS_VER/shadowsocks-$SS_VER.x86_64-unknown-linux-gnu.tar.xz
xz -d shadowsocks-$SS_VER.x86_64-unknown-linux-gnu.tar.xz
tar -xf shadowsocks-$SS_VER.x86_64-unknown-linux-gnu.tar
rm -f shadowsocks-$SS_VER.x86_64-unknown-linux-gnu.tar

# Download and extract v2ray-plugin
wget https://github.com/teddysun/v2ray-plugin/releases/download/$VP_VER/v2ray-plugin-linux-amd64-$VP_VER.tar.gz
tar -zxf v2ray-plugin-linux-amd64-$VP_VER.tar.gz
rm -f v2ray-plugin-linux-amd64-$VP_VER.tar.gz
mv v2ray-plugin_linux_amd64 /usr/local/bin/v2ray-plugin

# Set permissions and create config file
chown root:root /usr/local/bin/ss* /usr/local/bin/v2ray-plugin


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
