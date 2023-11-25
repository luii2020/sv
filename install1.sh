#!/bin/bash

# 获取当前安装的版本号
SSRUST_VERSION_INSTALLED=$(ssserver --version 2>/dev/null | grep -oE "v[0-9]+\.[0-9]+\.[0-9]+")
VP_VERSION_INSTALLED=$(v2ray-plugin --version 2>/dev/null | grep -oE "v[0-9]+\.[0-9]+\.[0-9]+")

# 获取最新版本号
SSRUST_VERSION=$(curl -s https://api.github.com/repos/shadowsocks/shadowsocks-rust/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
VP_VERSION=$(curl -s https://api.github.com/repos/teddysun/v2ray-plugin/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')

# 检查是否已安装最新版本
if [ "$SSRUST_VERSION_INSTALLED" != "$SSRUST_VERSION" ] || [ "$VP_VERSION_INSTALLED" != "$VP_VERSION" ]; then
    # 如果需要更新，则执行下载和安装的步骤
    # 安装必要的软件
    apt update
    apt install -y vim wget xz-utils ca-certificates

    # 下载并解压最新版本的 Shadowsocks-Rust 和 v2ray-plugin
    wget "https://github.com/shadowsocks/shadowsocks-rust/releases/download/$SSRUST_VERSION/shadowsocks-v$SSRUST_VERSION.x86_64-unknown-linux-gnu.tar.xz"
    wget "https://github.com/teddysun/v2ray-plugin/releases/download/$VP_VERSION/v2ray-plugin-linux-amd64-$VP_VERSION.tar.gz"

    tar -xf "shadowsocks-v$SSRUST_VERSION.x86_64-unknown-linux-gnu.tar.xz"
    tar -zxf "v2ray-plugin-linux-amd64-$VP_VERSION.tar.gz"
    mv "v2ray-plugin_linux_amd64" /usr/local/bin/v2ray-plugin

    # 获取用户输入的密码和端口号
    read -p "请输入密码（默认diaodiaoni）: " PASSWORD
    PASSWORD=${PASSWORD:-diaodiaoni}
    read -p "请输入端口号（默认7900）: " PORT
    PORT=${PORT:-7900}

    # 创建配置文件
    mkdir -p /usr/local/etc/shadowsocks-rust
    cat > /usr/local/etc/shadowsocks-rust/config.json << EOF
    {
        "server":"0.0.0.0",
        "server_port":$PORT,
        "method":"aes-256-gcm",
        "timeout":300,
        "password":"$PASSWORD",
        "fast_open":false,
        "nameserver":"8.8.8.8",
        "mode":"tcp_only",
        "plugin":"v2ray-plugin",
        "plugin_opts":"server"
    }
EOF

    # 创建 systemd 服务
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

    # 启动服务并设置开机自启
    systemctl daemon-reload
    systemctl start shadowsocks-rust
    systemctl enable shadowsocks-rust
    systemctl status shadowsocks-rust

    # 列出最新版本号
    echo "Shadowsocks-Rust 最新版本号：$SSRUST_VERSION"
    echo "v2ray-plugin 最新版本号：$VP_VERSION"
else
    echo "已安装最新版本，无需更新。"
    echo "Shadowsocks-Rust 当前版本号：$SSRUST_VERSION_INSTALLED"
    echo "v2ray-plugin 当前版本号：$VP_VERSION_INSTALLED"
fi
