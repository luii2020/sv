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
    links = soup.find_all('a')

    # 输出所有链接和链接内容（调试输出）
    print("所有链接：")
    for link in links:
        href = link.get('href')
        link_text = link.get_text()
        print("链接文本: {}, 链接地址: {}".format(link_text, href))

    # 查找与 '翡翠台' 相关的链接
    related_links = [link.get('href') for link in links if link.get_text() and "翡翠台" in link.get_text()]

    # 输出找到的相关链接
    if related_links:
        print("\n找到以下与 '翡翠台' 相关的链接：")
        for link in related_links:
            print(link)
    else:
        print("\n没有找到与 '翡翠台' 相关的链接。")
else:
    print("请求失败，状态码：{}".format(response.status_code))

EOF

# 执行抓取脚本
echo "正在执行抓取脚本..."
python3.5 fetch_favorite_channel.py

# 删除脚本文件
echo "删除临时脚本文件..."
rm fetch_favorite_channel.py

echo "任务完成！"
