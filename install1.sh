#!/bin/bash 
# 安装依赖 
#apt update 
#apt install -y wget xz-utils ca-certificates curl
# 检查是否已安装 shadowsocks-rust 
SS_VER=$(ssserver -V | grep "shadowsocks-rust" | cut -d " " -f 2)
if [ -z "$SS_VER" ]; then
    echo "Shadowsocks-Rust 未安装，开始安装..."
else
    echo "当前安装的 Shadowsocks-Rust 版本为 $SS_VER"
    echo "检查最新版本..."
    SSLATEST_VER=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep "tag_name" | cut -d '"' -f 4)
    if [ "$SSLATEST_VER" == "$SS_VER" ]; then
        echo "已安装最新版本"
    else
        echo "升级到最新版本 $LATEST_VER"
        SS_VER=$SSLATEST_VER
    fi
fi
# 检查是否已安装 v2ray-plugin 
VP_VER=$(v2ray-plugin --version | grep "v2ray-plugin" | cut -d " " -f 2)
if [ -z "$VP_VER" ]; then
    echo "v2ray-plugin 未安装，开始安装..."
else
    echo "当前安装的 v2ray-plugin 版本为 $VP_VER"
    echo "检查最新版本..."
    LATEST_VER=$(curl -s https://api.github.com/repos/teddysun/v2ray-plugin/releases/latest | grep "tag_name" | cut -d '"' -f 4)
    if [ "$LATEST_VER" == "$VP_VER" ]; then
        echo "已安装最新版本"
    else
        echo "升级到最新版本 $LATEST_VER"
        VP_VER=$LATEST_VER
    fi
fi
# 下载并解压 shadowsocks-rust 
cd /usr/local/bin/ 
wget https://github.com/shadowsocks/shadowsocks-rust/releases/download/$SS_VER/shadowsocks-$SS_VER.x86_64-unknown-linux-gnu.tar.xz 
xz -d shadowsocks-$SS_VER.x86_64-unknown-linux-gnu.tar.xz 
tar -xf shadowsocks-$SS_VER.x86_64-unknown-linux-gnu.tar 
rm -f shadowsocks-$SS_VER.x86_64-unknown-linux-gnu.tar 
# 下载并解压 v2ray-plugin 
wget https://github.com/teddysun/v2ray-plugin/releases/download/$VP_VER/v2ray-plugin-linux-amd64-$VP_VER.tar.gz 
tar -zxf v2ray-plugin-linux-amd64-$VP_VER.tar.gz 
rm -f v2ray-plugin-linux-amd64-$VP_VER.tar.gz 
mv v2ray-plugin_linux_amd64 /usr/local/bin/v2ray-plugin 
# 设置权限并创建配置文件 
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
rm -f install1.sh
