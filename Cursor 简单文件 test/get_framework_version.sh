#!/bin/bash

# 用法： ./get_framework_version.sh /path/to/Your.framework

FRAMEWORK_PATH="$1"

if [ ! -d "$FRAMEWORK_PATH" ]; then
  echo "❌ 请输入正确的 .framework 路径"
  exit 1
fi

# 尝试获取二进制文件名（和 framework 同名）
BINARY_NAME=$(basename "$FRAMEWORK_PATH" .framework)
BINARY_PATH="$FRAMEWORK_PATH/$BINARY_NAME"

if [ ! -f "$BINARY_PATH" ]; then
  echo "⚠️ 找不到二进制文件，尝试递归查找..."
  BINARY_PATH=$(find "$FRAMEWORK_PATH" -type f -perm +111 | head -n 1)
fi

if [ ! -f "$BINARY_PATH" ]; then
  echo "❌ 未找到可执行文件"
  exit 1
fi

echo "🔍 扫描版本号: $BINARY_PATH"

strings "$BINARY_PATH" \
  | grep -E '([0-9]+\.[0-9]+(\.[0-9]+)?)' \
  | grep -v -E 'Apple clang|iPhoneOS[0-9]|Mac OS X|Darwin|Mozilla|arm64|_types|dispatch|objc' \
  | sort -u

