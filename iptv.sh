#!/bin/bash

# 更新并安装必要的软件包
echo "Updating and installing dependencies..."
apt update
apt install -y python3 python3-pip nginx ffmpeg

# 安装 Python 所需的库
echo "Installing Python libraries..."
pip3 install requests beautifulsoup4 ffmpeg-python

# 创建目录用于存放 IPTV 脚本
echo "Creating directories for the IPTV script..."
mkdir -p /var/www/html/iptv
cd /var/www/html/iptv

# 创建 Python 脚本文件
echo "Creating the IPTV Python script..."
cat > /var/www/html/iptv/iptv_script.py <<EOF
import requests
import subprocess
import time
from bs4 import BeautifulSoup
import concurrent.futures
import logging
from datetime import datetime, timedelta

# 配置日志
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

# 记录当前时间，方便做时间筛选
CURRENT_TIME = datetime.now()

# 计算48小时之前的时间
TIME_LIMIT = CURRENT_TIME - timedelta(hours=48)

# 保存有效的IPTV链接和其抓取时间
valid_links = []

# 步骤 1: 获取网页内容并提取链接
def fetch_ipvtv_links():
    url = "http://tonkiang.us/"
    try:
        response = requests.get(url, timeout=10)
        response.raise_for_status()  # 确保请求成功
        soup = BeautifulSoup(response.text, 'html.parser')

        # 假设链接包含在特定的标签中
        links = soup.find_all('a', href=True)

        # 从这些链接中筛选出符合“翡翠台”和“fast”注释的链接
        iptv_links = []
        for link in links:
            if '翡翠台' in link.text and 'fast' in link.text:
                iptv_links.append(link['href'])

        logging.info("Found {} links.".format(len(iptv_links)))
        return iptv_links
    
    except requests.RequestException as e:
        logging.error("Error fetching links: {}".format(str(e)))
        return []

# 步骤 2: 测试每个链接的速度，并返回下载时间
def test_link_speed(link):
    try:
        # 使用ffmpeg获取流的速度，通过测量加载时间来确定速度
        start_time = time.time()
        result = subprocess.run(
            ['ffmpeg', '-v', 'error', '-i', link, '-t', '5', '-f', 'null', '-'],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE
        )
        end_time = time.time()

        # 如果没有错误输出，说明流是有效的
        if result.returncode == 0:
            duration = end_time - start_time
            logging.info("Valid stream: {} | Time: {} seconds".format(link, duration))
            return (duration, link)
        else:
            logging.warning("Invalid stream: {}".format(link))
            return None
    except Exception as e:
        logging.error(f"Error validating link {link}: {str(e)}")
        return None

# 步骤 3: 生成M3U8文件并输出具体的订阅链接
def generate_m3u8_file(valid_links):
    m3u8_content = "#EXTM3U\n"
    for link in valid_links:
        # 在 M3U8 中添加详细描述信息
        m3u8_content += f"#EXTINF:-1, {link}\n{link}\n"

    # 输出M3U8文件到 /var/www/html 目录
    m3u8_path = '/var/www/html/hk.m3u8'
    with open(m3u8_path, 'w') as file:
        file.write(m3u8_content)
    
    logging.info(f"M3U8 file generated with {len(valid_links)} valid links at {m3u8_path}.")

# 步骤 4: 过滤链接，确保链接只保留48小时内的，最多5条
def filter_and_sort_links(links_with_times):
    # 过滤掉超过48小时的链接
    valid = []
    for duration, link in links_with_times:
        link_time = datetime.fromtimestamp(duration)  # 假设duration为时间戳
        if link_time > TIME_LIMIT:
            valid.append((duration, link))

    # 排序：速度最快的链接排在前面
    sorted_links = sorted(valid, key=lambda x: x[0])  # 按照加载时间升序排序

    # 只保留前5条链接
    sorted_links = sorted_links[:5]

    return [link for _, link in sorted_links]

# 步骤 5: 定时任务，每天刷新一次
def refresh_links():
    iptv_links = fetch_ipvtv_links()

    if not iptv_links:
        logging.error("No IPTV links found. Exiting.")
        return

    # 使用并行处理验证多个链接的速度
    with concurrent.futures.ThreadPoolExecutor(max_workers=10) as executor:
        links_with_times = list(filter(None, executor.map(test_link_speed, iptv_links)))

    if links_with_times:
        final_links = filter_and_sort_links(links_with_times)
        generate_m3u8_file(final_links)
    else:
        logging.warning("No valid IPTV links found.")

# 设置每天刷新一次
def schedule_task():
    while True:
        refresh_links()
        time.sleep(86400)  # 每24小时刷新一次

if __name__ == '__main__':
    schedule_task()
EOF

# 启动 Python 脚本
echo "Starting the IPTV script..."
python3 /var/www/html/iptv/iptv_script.py &

# 配置 Nginx 以提供 M3U8 文件访问
echo "Configuring Nginx..."

# 创建 Nginx 配置文件
cat > /etc/nginx/sites-available/default <<EOF
server {
    listen 8080;

    # 设置服务器的 root 路径
    root /var/www/html;

    # 配置允许访问 .m3u8 文件
    location / {
        try_files \$uri \$uri/ =404;
    }

    # 通过 http://服务器IP/hk.m3u8 访问 M3U8 文件
    location /hk.m3u8 {
        try_files /hk.m3u8 =404;
    }

    # Optional: 设置服务器的默认主页 (若需要)
    index index.html;
}
EOF

# 重启 Nginx 服务使配置生效
systemctl reload nginx

# 提供访问链接
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "Server setup completed. You can access your M3U8 file at http://$SERVER_IP:8080/hk.m3u8"
