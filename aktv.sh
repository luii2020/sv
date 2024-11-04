# 安装 7z
if ! command -v 7z &> /dev/null; then
    echo "7z 未安装，正在安装..."
    # 对于 Debian/Ubuntu 系统
    if [ -f /etc/debian_version ]; then
        sudo apt update
        sudo apt install -y p7zip-full
    # 对于 CentOS/RHEL 系统
    elif [ -f /etc/redhat-release ]; then
        sudo yum install -y epel-release
        sudo yum install -y p7zip
    else
        echo "不支持的操作系统，请手动安装 7z"
        exit 1
    fi
fi

# 下载和解压
wget https://aktv.top/AKTVNODE/apps/AKTV_SERVER_1.1.7z
7z x AKTV_SERVER_1.1.7z

# 获取 VPS 的 IP 地址
IP_ADDRESS=$(curl -s http://ipecho.net/plain) # 或使用 `curl -s ifconfig.me`

# 手动输入端口
read -p "请输入端口（默认 16888）: " PORT
PORT=${PORT:-16888}  # 如果没有输入，则使用默认端口 16888

# 创建配置文件
cat << EOF > /root/config.json
{
    "ip": "$IP_ADDRESS",
    "port": "$PORT"
}
EOF

# 设置最大权限
chmod 777 /root/AKTV_NODE-linux

# 创建 systemd 服务文件
cat << EOF > /etc/systemd/system/aktv.service
[Unit]
Description=AKTV Node Service
After=network.target

[Service]
Type=simple
User=root
Group=nogroup
WorkingDirectory=/root
ExecStart=/root/AKTV_NODE-linux -c /root/config.json
Restart=on-failure
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

# 重新加载 systemd 配置
systemctl daemon-reload

# 启动服务并设置开机自启动
systemctl start aktv.service
systemctl enable aktv.service

# 显示服务状态
systemctl status aktv.service
