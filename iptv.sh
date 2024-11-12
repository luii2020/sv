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
import time
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options

# 设置 Chrome 为无头模式
chrome_options = Options()
chrome_options.add_argument('--headless')  # 无头模式
chrome_options.add_argument('--disable-gpu')  # 禁用GPU加速
chrome_options.add_argument('--no-sandbox')  # 禁用沙盒模式

# 创建浏览器对象
driver = webdriver.Chrome(options=chrome_options)

# 目标 URL
url = "http://tonkiang.us/"

try:
    # 打开页面
    driver.get(url)
    time.sleep(3)  # 等待页面加载

    # 提取第一页内容
    print("抓取第一页内容...")

    # 遍历分页（假设有多页）
    page_num = 1
    while True:
        print("正在抓取第 {} 页...".format(page_num))  # 使用 .format()

        # 获取页面中的所有链接
        links = driver.find_elements(By.TAG_NAME, 'a')
        found_links = []

        for link in links:
            href = link.get_attribute('href')
            text = link.text
            # 如果链接文本包含 "翡翠台"
            if href and "翡翠台" in text:
                found_links.append(href)

        if found_links:
            print("找到以下与 '翡翠台' 相关的链接：")
            for link in found_links:
                print(link)
        else:
            print("在第 {} 页没有找到 '翡翠台' 相关链接。".format(page_num))  # 使用 .format()

        # 判断是否有下一页
        try:
            next_page_link = driver.find_element(By.LINK_TEXT, str(page_num + 1))
            next_page_link.click()  # 点击下一页
            page_num += 1
            time.sleep(3)  # 等待新页面加载
        except Exception as e:
            print("没有更多页面了，抓取完成。")
            break
except Exception as e:
    print("发生错误: {}".format(e))  # 使用 .format()
finally:
    # 关闭浏览器
    driver.quit()

print("任务完成！")

EOF

# 执行抓取脚本
echo "正在执行抓取脚本..."
python3.5 fetch_favorite_channel.py

# 删除脚本文件
echo "删除临时脚本文件..."
rm fetch_favorite_channel.py

echo "任务完成！"
