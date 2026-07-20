#!/bin/bash
echo "===== 修复 dbus：给用户创建私有的 runtime-dir ====="

# 创建用户自己的 runtime-dir，绕过 WSLg 那个 040777 的目录
mkdir -p ~/.runtime-dir
chmod 700 ~/.runtime-dir
export XDG_RUNTIME_DIR=~/.runtime-dir
echo "XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR"
ls -ld ~/.runtime-dir

echo ""
echo "===== 杀掉 fcitx，用修复后的环境重启 ====="
pkill -9 -x fcitx 2>/dev/null || true
sleep 1

echo "用 dbus-run-session 启动 fcitx（强制走 session dbus）"
DISPLAY=:20 XDG_RUNTIME_DIR=~/.runtime-dir \
  dbus-run-session -- fcitx -d --replace 2>&1 | head -5 &
sleep 3

echo "--- fcitx 进程 ---"
ps -eo pid,args | grep -E "[f]citx -d" || echo "(没跑)"

echo ""
echo "===== 验证 DBUS_SESSION_BUS_ADDRESS 是否被 fcitx 拿到 ====="
FPID=$(pgrep -x fcitx | head -1)
echo "fcitx pid=$FPID"
cat /proc/$FPID/environ 2>/dev/null | tr '\0' '\n' | grep -E "DBUS_SESSION_BUS_ADDRESS|XDG_RUNTIME_DIR" || echo "(读不到环境变量)"

echo ""
echo "===== 用 zenity 测试（在同一个 dbus session 里）====="
DISPLAY=:20 XDG_RUNTIME_DIR=~/.runtime-dir \
  zenity --entry --title="输入法测试" --text="按 Ctrl+Space 然后打拼音" 2>/dev/null &
echo "zenity 已启动，请切到 zenity 窗口测试"
