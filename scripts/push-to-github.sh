#!/usr/bin/env bash
# Fallback: push this repository to GitHub from your own machine.
# Use this only if the WorkBuddy connector push does not work.
set -euo pipefail

REPO_NAME="devops-showcase"
GH_USER="ZChos1n"

echo "==> 1/4 确认 GitHub 上已存在空仓库 $GH_USER/$REPO_NAME"
echo "    如果还没有，先去 https://github.com/new 创建（Public，不要勾选 README）"
read -r -p "    建好了吗? 按回车继续... "

echo "==> 2/4 配置 remote"
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/${GH_USER}/${REPO_NAME}.git"

echo "==> 3/4 确保分支名为 main（GitHub 默认）"
git branch -M main

echo "==> 4/4 推送"
echo "    会弹出 GitHub 登录窗口，用浏览器或 PAT 授权即可"
git push -u origin main

echo "完成：https://github.com/${GH_USER}/${REPO_NAME}"
