#!/bin/bash 
# 检查是否已安装 shadowsocks-rust 
SS_VER=$(ssserver -V | grep "shadowsocks-rust" | cut -d " " -f 2)
if [ -z "$SS_VER" ]; then
    echo "Shadowsocks-Rust 未安装，开始安装..."
else
    echo "当前安装的 Shadowsocks-Rust 版本为 $SS_VER"
    echo "检查最新版本..."
    LATEST_VER=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep "tag_name" | cut -d '"' -f 4)
    if [ "$LATEST_VER" == "$SS_VER" ]; then
        echo "已安装最新版本"
    else
        echo "升级到最新版本 $LATEST_VER"
   
    fi
fi

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
echo "请输入 server_port（默认值9711）：" 
read SERVER_PORT 
SERVER_PORT=${SERVER_PORT:-9711}
echo "请输入 password（默认值diaodiaoni）：" 
read PASSWORD 
PASSWORD=${PASSWORD:-diaodiaoni}


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
