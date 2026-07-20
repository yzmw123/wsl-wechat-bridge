#!/bin/bash
set -e
echo "=== 1. im-config 选 fcitx（非交互，直接写 ~/.xinputrc）==="
if command -v im-config >/dev/null 2>&1; then
  im-config -n fcitx || true
  echo "--- ~/.xinputrc ---"
  cat ~/.xinputrc 2>/dev/null || echo "无 .xinputrc"
fi

echo "=== 2. 把改好的 wechat-desktop 推到 /usr/local/bin ==="
sudo cp /mnt/d/project/wsl-wechat-bridge/app/linux/bin/wechat-desktop /usr/local/bin/wechat-desktop
ls -la /usr/local/bin/wechat-desktop

echo "=== 3. 启动 fcitx（带 DISPLAY=:20，跟脚本一致）==="
display=":20"
if ! pgrep -x fcitx >/dev/null 2>&1; then
  DISPLAY="$display" dbus-launch fcitx -d --replace 2>&1 | head -5
  sleep 2
fi
pgrep -a fcitx || echo "fcitx 没跑"

echo "=== 4. 看 fcitx 加载的输入法 ==="
sleep 1
cat ~/.config/fcitx/profile 2>/dev/null | head -30 || echo "无 profile"

echo "=== 5. 看 fcitx 日志 ==="
tail -n 20 ~/.cache/wechat-desktop/fcitx5.log 2>/dev/null || echo "无日志"
