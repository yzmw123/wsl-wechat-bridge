#!/bin/bash
echo "===== 1. 现在在 DISPLAY=:20 上跑 xterm，验证 fcitx 是否真的能激活 ====="
echo "（等 xterm 弹出后，在 xterm 里按 Ctrl+Space，看能不能打出中文）"
echo ""
echo "环境变量："
export DISPLAY=:20
export XMODIFIERS="@im=fcitx"
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XIM_PROGRAM=fcitx
echo "DISPLAY=$DISPLAY GTK_IM_MODULE=$GTK_IM_MODULE XIM_PROGRAM=$XIM_PROGRAM"
echo ""
echo "启动 xterm..."
xterm -fa "Monospace" -fs 14 -title "输入法测试：按 Ctrl+Space 试打中文" &
sleep 2
echo "xterm 已启动，请切到 xterm 窗口测试"
