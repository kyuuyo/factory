#!/bin/bash
set -e

# ============================================================
# 制造业数字化 & ERP 学习资料 — GitHub Pages 发布脚本
# ============================================================

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REPO_URL=$(git remote get-url origin 2>/dev/null || echo "")
REPO_NAME=$(basename "$REPO_URL" .git 2>/dev/null || echo "factory")
REPO_OWNER=$(echo "$REPO_URL" | sed -n 's|.*github\.com[:/]\([^/]*\)/.*|\1|p')
PAGES_URL="https://${REPO_OWNER}.github.io/${REPO_NAME}"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  制造业数字化 & ERP 学习资料 发布工具${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# 1. 检查未提交变更
echo -e "${YELLOW}[1/4] 检查工作区状态...${NC}"
if ! git diff-index --quiet HEAD --; then
    echo -e "${RED}存在未提交的变更，请先 git add + git commit${NC}"
    git status -s
    exit 1
fi
echo -e "${GREEN}  ✓ 工作区干净${NC}"

# 2. 推送代码到 GitHub
echo ""
echo -e "${YELLOW}[2/4] 推送代码到 GitHub...${NC}"
git push origin master
echo -e "${GREEN}  ✓ 推送成功${NC}"

# 3. 配置 GitHub Pages
echo ""
echo -e "${YELLOW}[3/4] 配置 GitHub Pages...${NC}"

if command -v gh &>/dev/null && gh auth status &>/dev/null 2>&1; then
    # 使用 gh CLI 配置 GitHub Pages
    if gh api "repos/${REPO_OWNER}/${REPO_NAME}/pages" --jq '.source.branch' &>/dev/null 2>&1; then
        # Pages 已配置，触发重建
        echo -e "  GitHub Pages 已配置，触发重新构建..."
        gh api -X POST "repos/${REPO_OWNER}/${REPO_NAME}/pages/builds" --silent
    else
        # 首次配置 Pages
        echo -e "  正在启用 GitHub Pages (分支: master, 路径: /)..."
        gh api -X POST "repos/${REPO_OWNER}/${REPO_NAME}/pages" \
            -F "source[branch]=master" \
            -F "source[path]=/" --silent 2>/dev/null || {
            echo -e "${YELLOW}  ⚠ 自动配置失败，请手动设置:${NC}"
            echo -e "    ${REPO_URL}/settings/pages"
            echo -e "    Source: Deploy from a branch → master → / (root)"
        }
    fi
    echo -e "${GREEN}  ✓ Pages 配置完成${NC}"
else
    echo -e "${YELLOW}  ⚠ 未安装 gh CLI 或未登录，跳过自动配置${NC}"
    echo -e "  请手动访问以下地址启用 GitHub Pages:"
    echo -e "    ${REPO_URL}/settings/pages"
    echo -e "  设置: Source → Deploy from a branch → master → / (root)"
fi

# 4. 输出访问地址
echo ""
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}  发布完成！${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "  GitHub Pages:  ${PAGES_URL}"
echo -e "  Repo:          ${REPO_URL}"
echo ""
echo -e "  ${YELLOW}提示:${NC} Pages 首次构建需要 1-2 分钟生效"
echo ""
