#!/usr/bin/env bash
# Push devops-showcase to GitHub using a one-time PAT.
# Usage: GH_TOKEN="ghp_xxx" bash scripts/push.sh
set -euo pipefail

REPO_NAME="devops-showcase"
GH_USER="ZChos1n"

if [ -z "${GH_TOKEN:-}" ]; then
  echo "ERROR: 请先设置 GH_TOKEN 环境变量"
  echo '  GH_TOKEN="ghp_xxx" bash scripts/push.sh'
  exit 1
fi

cd "$(dirname "$0")/.."

echo "==> 1/4 配置 remote（带临时 token，不会写入配置）"
git remote remove origin 2>/dev/null || true
git remote add origin "https://${GH_TOKEN}@github.com/${GH_USER}/${REPO_NAME}.git"

echo "==> 2/4 提交尚未纳入版本的文件（PUSH_GUIDE / push.sh）"
git add -A
if ! git diff --cached --quiet; then
  git -c user.name="showcase" -c user.email="showcase@example.com" \
    commit -q -m "docs: add GitHub push guide and script"
fi

echo "==> 3/4 分支切为 main 并推送"
git branch -M main
git push -u origin main

echo "==> 4/4 从 remote 中移除 token（安全清理）"
git remote set-url origin "https://github.com/${GH_USER}/${REPO_NAME}.git"

echo ""
echo "完成：https://github.com/${GH_USER}/${REPO_NAME}"
