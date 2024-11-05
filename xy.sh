#!/bin/bash

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "请以 root 用户身份运行此脚本"
    exit 1
fi

# 安装 Xray
echo "正在安装 Xray ..."
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --version 1.8.23

# 生成 UUID
UUID=$(xray uuid)

# 生成 X25519 私钥
PRIVATE_KEY=$(xray x25519)

# 生成公钥
PUBLIC_KEY=$(echo "$PRIVATE_KEY" | xray x25519 --pubkey)

# 获取 shortIds（可以自定义，最多16个字符）
SHORT_IDS=$(echo -n "a3f9df45ae15d6c2" | tr -d '\n')  # 这个可以根据需要修改，保持两位数的字符

# 读取目标网站（DEST）地址
read -p "请输入目标网站（例如: dl.google.com）： " DEST
DEST=${DEST:-"dl.google.com"}  # 默认值为 dl.google.com，不包含端口号

# 配置文件路径
CONFIG_FILE="/usr/local/etc/xray/config.json"

# 备份默认配置文件（以防万一）
cp $CONFIG_FILE $CONFIG_FILE.bak

# 生成配置文件
echo "正在生成 Xray 配置文件 ..."
cat <<EOF > $CONFIG_FILE
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "$DEST:443",  # 向目标网站转发流量，但在 serverNames 中不包括端口号
          "xver": 0,
          "serverNames": [
            "$DEST",  # 不包含端口号
            "$DEST"   # 不包含端口号
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_IDS"
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "blocked",
        "ip": [
          "geoip:cn",
          "geoip:private"
        ]
      }
    ]
  },
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    },
    {
      "tag": "blocked",
      "protocol": "blackhole",
      "settings": {}
    }
  ]
}
EOF

# 重启 Xray 服务
echo "重启 Xray 服务 ..."
systemctl restart xray

# 启动并设置开机自启
echo "设置 Xray 为开机自启 ..."
systemctl enable xray

# 输出安装信息
echo "Xray 安装和配置完成！"
echo "--------------------------------------------"
echo "生成的 UUID: $UUID"
echo "生成的公钥: $PUBLIC_KEY"
echo "配置的目标网站: $DEST"
echo "配置的 shortIds: $SHORT_IDS"
echo "配置文件路径：$CONFIG_FILE"
echo "--------------------------------------------"

# 查看 Xray 服务状态
systemctl status xray
