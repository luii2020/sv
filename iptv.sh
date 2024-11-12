#!/bin/bash

# 更新并安装 Python 3.5 和 pip
echo "正在更新系统..."
apt update -y && apt upgrade -y

echo "安装 Python 3.5 和 pip3..."
apt install -y python3.5 python3.5-dev python3-pip

# 安装 requests 和 beautifulsoup4 库
echo "安装 Python 必要的库..."
python3.5 -m pip install requests beautifulsoup4

# 创建抓取脚本 fetch_favorite_channel.py
echo "创建抓取脚本 fetch_favorite_channel.py..."

cat << 'EOF' > fetch_favorite_channel.py
import requests
from bs4 import BeautifulSoup

# 网页URL
url = "http://tonkiang.us/"

# 发送HTTP GET请求获取网页内容
response = requests.get(url)

# 确保请求成功
if response.status_code == 200:
    # 解析网页
    soup = BeautifulSoup(response.text, 'html.parser')

    # 查找所有 <a> 标签（超链接）
    links = soup.find_all('a', string=lambda text: text and "翡翠台" in text)

    # 输出找到的链接
    if links:
        print("找到以下与 '翡翠台' 相关的链接：")
        for link in links:
            href = link.get('href')
            print(f"链接: {href}")
    else:
        print("没有找到与 '翡翠台' 相关的链接。")
else:
    print(f"请求失败，状态码：{response.status_code}")
EOF

# 执行抓取脚本
echo "正在执行抓取脚本..."
python3.5 fetch_favorite_channel.py

# 删除脚本文件
echo "删除临时脚本文件..."
rm fetch_favorite_channel.py

echo "任务完成！"
