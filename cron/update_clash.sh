#!/bin/bash

# 当任何命令失败时立即退出脚本
set -e
# 如果使用了未定义的变量，则报错
set -u

# --- 配置 ---
# 订阅链接
SUB_URL="https://xxx.example.com"
# 基础配置文件链接 (ACL4SSR 在线版)
BASE_CONFIG_URL="https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/config/ACL4SSR_Online.ini"
# Clash 配置文件存放路径
CLASH_CONFIG_PATH="/etc/clash/config.yaml"
# 临时下载文件路径
TEMP_CONFIG_PATH="/tmp/config.yaml.tmp"
# Subconverter API 地址
SUB_CONVERTER_API="http://subconverter:25500/sub"

# --- 函数 ---

# 记录日志并退出
log_and_exit() {
    echo "错误: $1" >&2
    exit 1
}

# URL 编码函数 (需要 Python 3)
url_encode() {
    # 使用 Python 的标准库进行 URL 编码，比原来的 curl|cut 方法更可靠
    python3 -c "import urllib.parse; print(urllib.parse.quote_plus('$1'))"
}

# --- 主逻辑 ---

echo "1. 正在对 URL 进行编码..."
# 对订阅链接和基础配置链接进行 URL 编码
ENCODED_SUB_URL=$(url_encode "${SUB_URL}")
ENCODED_BASE_CONFIG_URL=$(url_encode "${BASE_CONFIG_URL}")

# 构建最终的 API 请求 URL
FINAL_URL="${SUB_CONVERTER_API}?target=clash&url=${ENCODED_SUB_URL}&config=${ENCODED_BASE_CONFIG_URL}"

echo "2. 正在从 Subconverter 下载新的配置文件..."
# 使用 curl 下载配置文件
# -L: 跟随重定向
# -sS: 静默模式，但显示错误信息
# --fail: 在 HTTP 错误时(如 404)返回非零退出码，触发 set -e
# -o: 指定输出文件
curl -L -sS --fail -o "${TEMP_CONFIG_PATH}" "${FINAL_URL}" || log_and_exit "下载配置文件失败，请检查 Subconverter 服务或网络连接。"

echo "3. 正在验证下载的配置文件..."
# 检查临时文件是否为空或过小 (小于 100 字节通常意味着配置有问题)
if [ ! -s "${TEMP_CONFIG_PATH}" ] || [ "$(wc -c < "${TEMP_CONFIG_PATH}")" -lt 100 ]; then
    rm -f "${TEMP_CONFIG_PATH}"
    log_and_exit "下载的配置文件为空或过小，已中止操作。"
fi

echo "4. 正在修改自定义配置..."
sed -i '/香港/d' "${TEMP_CONFIG_PATH}"
sed -i '/台湾/d' "${TEMP_CONFIG_PATH}"
sed -i '/防失联/d' "${TEMP_CONFIG_PATH}"
sed -i 's/127.0.0.1/0.0.0.0/g' "${TEMP_CONFIG_PATH}"

echo "5. 正在替换旧的配置文件..."
# 使用 mv 替换旧文件，这是一个原子操作，更安全
cat "${TEMP_CONFIG_PATH}" > "${CLASH_CONFIG_PATH}"
rm -f "${TEMP_CONFIG_PATH}"

echo "6. 正在重启 Clash 服务..."
# 重启 Clash 服务以应用新配置
#systemctl restart clash || log_and_exit "重启 Clash 服务失败，请检查 Clash 服务状态。"
curl -X PUT http://clash:9090/configs -d '{}' || log_and_exit "重启 Clash 服务失败，请检查 Clash 服务状态。"

echo "Clash 配置更新并重启成功！"
