#!/usr/bin/env bash
# 仓库自检：相对链接是否有效 + 是否残留个人化表述
# 用法：bash scripts/verify-links.sh
set -uo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR" || exit 1

fail=0

echo "[1/2] 检查相对链接"
broken=0
while IFS= read -r md; do
  while IFS= read -r link; do
    [ -n "$link" ] || continue
    target="$(dirname "$md")/$link"
    if [ ! -e "$target" ]; then
      echo "  失效链接: $md -> $link"
      broken=$((broken + 1))
    fi
  done < <(grep -oE '\]\([^)#]+\)' "$md" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//' | grep -vE '^(https?:|mailto:|#)')
done < <(find . -name '*.md' -not -path './node_modules/*' -not -path './.git/*')
[ "$broken" -eq 0 ] || fail=1

echo "[2/2] 检查个人化表述残留"
patterns=('文章思想' '文章角色' '文章五环节' 'WorkBuddy' '快消' 'addy-agent-skills')
for p in "${patterns[@]}"; do
  hits=$(grep -rn --include='*.md' --include='*.yml' --include='*.sh' -F "$p" . \
         --exclude-dir=.git 2>/dev/null | grep -v 'scripts/verify-links.sh')
  if [ -n "$hits" ]; then
    echo "  命中禁用表述「$p」:"
    printf '%s\n' "$hits" | sed 's/^/    /'
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "自检通过"
fi
exit "$fail"
