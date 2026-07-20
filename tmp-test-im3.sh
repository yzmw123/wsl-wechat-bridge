#!/bin/bash
echo "===== 1. 验证 fcitx 框架本身是否工作（用 fcitx-keyboard-us 测试）====="
echo "   先把 profile 临时改成只留 keyboard-us，看能不能激活"
PROFILE=~/.config/fcitx/profile
cp "$PROFILE" /tmp/profile.bak
python3 - "$PROFILE" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
m = re.search(r'EnabledIMList=[^\n]*', s)
if m:
    prefix = 'EnabledIMList='
    s = s[:m.start()] + prefix + 'fcitx-keyboard-us:True' + s[m.end():]
open(p,'w').write(s)
print("临时改成只留 keyboard-us")
PY
echo "--- 当前 EnabledIMList ---"
grep EnabledIMList "$PROFILE"

echo ""
echo "===== 2. 重启 fcitx 让配置生效 ====="
pkill -9 -x fcitx 2>/dev/null || true
sleep 1
DISPLAY=:20 dbus-launch fcitx -d --replace 2>&1 | head -2
sleep 2
ps -eo pid,args | grep -E "[f]citx -d" || echo "fcitx 没跑"

echo ""
echo "===== 3. 用 zenity 做输入测试（如果可用）====="
if command -v zenity >/dev/null 2>&1; then
  DISPLAY=:20 XMODIFIERS="@im=fcitx" GTK_IM_MODULE=fcitx XIM_PROGRAM=fcitx \
    zenity --entry --title="输入法测试" --text="按 Ctrl+Space 然后打拼音" 2>/dev/null &
  echo "zenity 已启动"
else
  echo "zenity 不可用"
fi

echo ""
echo "===== 4. 检查 dbus 状态（搜狗依赖 dbus）====="
echo "DBUS_SESSION_BUS_ADDRESS=$DBUS_SESSION_BUS_ADDRESS"
dbus-send --session --print-reply --dest=fcitx /org/freedesktop/DBus org.freedesktop.DBus.ListNames 2>&1 | head -5 || echo "dbus 调用失败"
