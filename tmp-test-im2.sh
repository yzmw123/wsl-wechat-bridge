#!/bin/bash
echo "===== 用 python3 tkinter 做一个简单的输入法测试窗口 ====="
python3 <<'PY'
import tkinter as tk
root = tk.Tk()
root.title("输入法测试 - 按 Ctrl+Space 然后打拼音")
root.geometry("400x150")
entry = tk.Entry(root, width=40, font=("Sans", 18))
entry.pack(pady=30)
entry.focus_set()
label = tk.Label(root, text="在上面输入框按 Ctrl+Space，然后打拼音", font=("Sans", 12))
label.pack()
root.mainloop()
PY
