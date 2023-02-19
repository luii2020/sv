#!/bin/bash

# Check if shadowsocks-rust is installed
if command -v ssserver &> /dev/null
then
    # 获取 shadowsocks-rust 的最新版本号
SS_VER=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep "tag_name" | cut -d '"' -f 4)

# 获取当前 ssserver 的版本号
cd /usr/local/bin/ 
CUR_VER=$(./ssserver -V | cut -d '"' -f 4)

# 比较版本号
if [ "$CUR_VER" = "$SS_VER" ]; then
  echo "ssserver 版本号为最新版本：$CUR_VER"
else
  echo "ssserver 版本号不是最新版本，当前版本号为 $CUR_VER，最新版本号为 $SS_VER"
fi
    echo "shadowsocks-rust is already installed"
else
    echo "Installing shadowsocks-rust"
    # Install dependencies
    apt update
    apt install -y wget xz-utils ca-certificates curl
    
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

    # Create config file with default values
    SERVER_PORT=9711
    PASSWORD="diaodiaoni"

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

    # Configure system service and start
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
    systemctl enable shadowsocks-rust
    systemctl start shadowsocks-rust

    echo "shadowsocks-rust has been installed and started"
fi
