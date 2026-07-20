#!/bin/bash
set -e
echo "===== 1. 杀掉所有 fcitx / fcitx5 进程 ====="
kill -9 9197 5995 31063 2>/dev/null || true
pkill -9 -x fcitx 2>/dev/null || true
pkill -9 -x fcitx5 2>/dev/null || true
sleep 1
echo "--- 残留 fcitx 进程 ---"
ps -eo pid,args | grep -iE "[f]citx" || echo "(干净)"

echo ""
echo "===== 2. 修改 fcitx profile：启用搜狗，放第一位 ====="
PROFILE=~/.config/fcitx/profile
python3 - "$PROFILE" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
s = re.sub(r'sogoupinyin:False', 'sogoupinyin:True', s)
m = re.search(r'EnabledIMList=[^\n]*', s)
if m:
    prefix = 'EnabledIMList='
    items = m.group(0)[len(prefix):].split(',')
    items = [i for i in items if i and not i.startswith('sogoupinyin:')]
    items.insert(0, 'sogoupinyin:True')
    s = s[:m.start()] + prefix + ','.join(items) + s[m.end():]
open(p,'w').write(s)
print("modified")
PY
grep EnabledIMList "$PROFILE" | cut -c1-100

echo ""
echo "===== 3. 确认搜狗 fcitx addon 存在 ====="
ls -la /usr/lib/x86_64-linux-gnu/fcitx/fcitx-sogoupinyin.so 2>/dev/null || \
ls -la /usr/lib/fcitx/fcitx-sogoupinyin.so 2>/dev/null || \
echo "(找不到 fcitx-sogoupinyin.so，检查 sogoupinyin 安装)"
dpkg -L sogoupinyin 2>/dev/null | grep -E "fcitx-sogoupinyin" | head

echo ""
echo "===== 4. 在 DISPLAY=:20 启动 fcitx（带 dbus）====="
display=":20"
DISPLAY="$display" dbus-launch fcitx -d --replace 2>&1 | head -3
sleep 2
echo "--- fcitx 进程 ---"
ps -eo pid,args | grep -iE "[f]citx" | head

echo ""
echo "===== 5. 验证搜狗 addon 加载（看 fcitx 日志）====="
sleep 1
tail -n 30 ~/.cache/wechat-desktop/fcitx5.log 2>/dev/null | grep -iE "sogou|addon" | head -10
