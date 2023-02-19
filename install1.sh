#!/bin/bash 

# Install dependencies 
apt update 
apt install -y wget xz-utils ca-certificates curl 

# Determine current and latest versions of Shadowsocks-rust and v2ray-plugin 
CURRENT_SS_VER=$(ssserver -V | awk '{print $NF}')
LATEST_SS_VER=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep "tag_name" | cut -d '"' -f 4) 
CURRENT_VP_VER=$(v2ray-plugin --version | awk '{print $NF}')
LATEST_VP_VER=$(curl -s https://api.github.com/repos/teddysun/v2ray-plugin/releases/latest | grep "tag_name" | cut -d '"' -f 4)

# Upgrade Shadowsocks-rust and v2ray-plugin if necessary
if [ "$CURRENT_SS_VER" != "$LATEST_SS_VER" ]; then
    cd /usr/local/bin/
    wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/$LATEST_SS_VER/shadowsocks-$LATEST_SS_VER.x86_64-unknown-linux-gnu.tar.xz 
    xz -d shadowsocks-$LATEST_SS_VER.x86_64-unknown-linux-gnu.tar.xz 
    tar -xf shadowsocks-$LATEST_SS_VER.x86_64-unknown-linux-gnu.tar 
    rm -f shadowsocks-$LATEST_SS_VER.x86_64-unknown-linux-gnu.tar 
fi

if [ "$CURRENT_VP_VER" != "$LATEST_VP_VER" ]; then
    cd /usr/local/bin/
    wget https://github.com/teddysun/v2ray-plugin/releases/download/$LATEST_VP_VER/v2ray-plugin-linux-amd64-$LATEST_VP_VER.tar.gz 
    tar -zxf v2ray-plugin-linux-amd64-$LATEST_VP_VER.tar.gz 
    rm -f v2ray-plugin-linux-amd64-$LATEST_VP_VER.tar.gz 
    mv v2ray-plugin_linux_amd64 /usr/local/bin/v2ray-plugin 
fi

# Set permissions and create config file 
chown root:root /usr/local/bin/ss* /usr/local/bin/v2ray-plugin 

# Create config file 
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
systemctl start shadowsocks-rust
systemctl enable shadowsocks-rust
systemctl status shadowsocks-rust
