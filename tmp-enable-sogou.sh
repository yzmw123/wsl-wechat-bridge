#!/bin/bash
echo "=== 修改 fcitx profile：启用搜狗，放第一位 ==="
PROFILE=~/.config/fcitx/profile
if [ -f "$PROFILE" ]; then
  python3 - "$PROFILE" <<'PY'
import sys, re
p = sys.argv[1]
s = open(p).read()
s = re.sub(r'sogoupinyin:False', 'sogoupinyin:True', s)
m = re.search(r'EnabledIMList=[^\n]*', s)
if m:
    line = m.group(0)
    prefix = 'EnabledIMList='
    items = line[len(prefix):].split(',')
    items = [i for i in items if i and not i.startswith('sogoupinyin:')]
    items.insert(0, 'sogoupinyin:True')
    s = s[:m.start()] + prefix + ','.join(items) + s[m.end():]
open(p,'w').write(s)
print("modified")
PY
  echo "--- head of EnabledIMList ---"
  grep EnabledIMList "$PROFILE" | cut -c1-120
fi
echo "=== sogoupinyin 文件 ==="
dpkg -L sogoupinyin 2>/dev/null | grep -E "bin/|sogoupinyin|fcitx" | head
