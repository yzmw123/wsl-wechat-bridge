#!/bin/bash
echo "===== A. /usr/local/bin/wechat-desktop (真实内容，只看关键行) ====="
grep -nE "XIM_PROGRAM=|fcitx5|fcitx -d|DISPLAY=.*nohup|nohup fcitx" /usr/local/bin/wechat-desktop || echo "（没命中）"

echo ""
echo "===== B. 当前全部 fcitx 进程 ====="
ps -eo pid,user,args | grep -iE "[f]citx"

echo ""
echo "===== C. 微信进程 #30940 的输入法环境变量 ====="
cat /proc/30940/environ 2>/dev/null | tr '\0' '\n' | grep -E "IM_MODULE|XMODIFIERS|INPUT_METHOD|XIM_PROGRAM|QT_QPA" || echo "(微信进程不在 /proc 里)"

echo ""
echo "===== D. 家目录 fcitx 的 profile (EnabledIMList 前 80 字符) ====="
grep EnabledIMList ~/.config/fcitx/profile | cut -c1-120

echo ""
echo "===== E. 当前用的是哪个 display ====="
echo "DISPLAY=$DISPLAY"
