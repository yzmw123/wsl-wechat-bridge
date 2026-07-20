#!/bin/bash
set -e
echo "=== 检查 fcitx 框架装好没 ==="
dpkg -l | grep -iE "^ii.*fcitx" | awk '{print $2, $3}' || echo "无 fcitx 包"

echo "=== 安装搜狗 deb ==="
sudo DEBIAN_FRONTEND=noninteractive dpkg -i ~/sogoupinyin_4.2.1.145_amd64.deb || echo "dpkg 返回非零，继续修复..."

echo "=== 修复依赖 ==="
sudo DEBIAN_FRONTEND=noninteractive apt-get -f install -y 2>&1 | tail -20

echo "=== 检查搜狗 ==="
dpkg -l | grep -iE "sogou" | awk '{print $2, $3}'
echo "=== fcitx 二进制 ==="
which fcitx fcitx-configtool 2>/dev/null
