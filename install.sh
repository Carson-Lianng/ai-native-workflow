#!/usr/bin/env bash
# AI-Native Workflow 安装器
# 把 workflow-init 与 backlog-sdd-bridge 两个技能装到编码 agent 的技能目录。
# 只写技能目录，不触碰你的项目文件。

set -euo pipefail

VERSION="0.1.0"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS=(workflow-init backlog-sdd-bridge)

targets=()
mode="global"
dry_run=false
force=false
explicit_target=false

usage() {
  cat <<'EOF'
用法: ./install.sh [选项]

选项:
  --target <name>   指定环境: claude | cursor | codebuddy | all（可重复）
  --dest <dir>      装到自定义技能目录（适配未内置的 agent，可重复）
  --project         装到当前目录的项目级技能目录，而非用户全局
  --dry-run         只打印将要写入的路径，不落盘
  --force           覆盖已存在的同名技能
  --list            只列出探测到的安装目标
  -h, --help        显示本帮助

示例:
  ./install.sh                        # 自动探测全局环境
  ./install.sh --target claude        # 只装 Claude Code
  ./install.sh --project --dest .agent/skills
EOF
}

log()  { printf '%s\n' "$*"; }
warn() { printf '警告: %s\n' "$*" >&2; }
die()  { printf '错误: %s\n' "$*" >&2; exit 1; }

add_target() {
  local dir="$1"
  [ -n "$dir" ] || return 0
  for t in "${targets[@]:-}"; do
    [ "$t" = "$dir" ] && return 0
  done
  targets+=("$dir")
}

# 把 --target 名称解析成技能目录
resolve_target() {
  local name="$1"
  local base
  if [ "$mode" = "project" ]; then base="$PWD"; else base="$HOME"; fi

  case "$name" in
    claude)
      if [ "$mode" = "project" ]; then add_target "$base/.claude/skills"
      else add_target "$base/.claude/skills"; fi ;;
    cursor)
      # Cursor 的技能目录是项目级的
      if [ "$mode" = "project" ]; then add_target "$base/.cursor/skills"
      else add_target "$PWD/.cursor/skills"; fi ;;
    codebuddy)
      if [ "$mode" = "project" ]; then add_target "$base/.codebuddy/skills"
      else add_target "$base/.codebuddy/skills"; fi ;;
    all)
      resolve_target claude; resolve_target cursor; resolve_target codebuddy ;;
    *)
      die "未知环境: $name（可用: claude | cursor | codebuddy | all，或改用 --dest <dir>）" ;;
  esac
}

detect_targets() {
  if [ "$mode" = "project" ]; then
    # 项目级：只在已存在对应配置目录时装
    [ -d "$PWD/.claude" ]    && add_target "$PWD/.claude/skills"
    [ -d "$PWD/.cursor" ]    && add_target "$PWD/.cursor/skills"
    [ -d "$PWD/.codebuddy" ] && add_target "$PWD/.codebuddy/skills"
  else
    [ -d "$HOME/.claude" ]    && add_target "$HOME/.claude/skills"
    [ -d "$HOME/.codebuddy" ] && add_target "$HOME/.codebuddy/skills"
  fi
}

copy_dir() {
  local src="$1" dst="$2"
  if [ -d "$dst" ] && [ "$force" != true ]; then
    warn "已存在，跳过（用 --force 覆盖）: $dst"
    return 0
  fi
  if [ "$dry_run" = true ]; then
    log "  [dry-run] $src -> $dst"
    return 0
  fi
  rm -rf "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -R "$src" "$dst"
  log "  已安装: $dst"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --target)  resolve_target "${2:-}"; explicit_target=true; shift 2 ;;
    --dest)    add_target "${2:-}"; explicit_target=true; shift 2 ;;
    --project) mode="project"; shift ;;
    --dry-run) dry_run=true; shift ;;
    --force)   force=true; shift ;;
    --list)    explicit_target=false; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "未知参数: $1（用 --help 查看用法）" ;;
  esac
done

[ "$explicit_target" = true ] || detect_targets

if [ ${#targets[@]} -eq 0 ]; then
  warn "未探测到任何 agent 环境。"
  log ""
  log "请用下列方式之一指定目标："
  log "  ./install.sh --target claude        # Claude Code"
  log "  ./install.sh --project --target cursor"
  log "  ./install.sh --dest <你的技能目录>  # 其他 agent"
  exit 1
fi

log "AI-Native Workflow v$VERSION 安装 ($mode)"
log ""

for t in "${targets[@]}"; do
  log "目标: $t"
  for s in "${SKILLS[@]}"; do
    copy_dir "$REPO_DIR/skills/$s" "$t/$s"
    # 模板随 workflow-init 一起铺，保证技能目录自包含
    if [ "$s" = "workflow-init" ]; then
      copy_dir "$REPO_DIR/templates" "$t/workflow-init/templates"
    fi
  done
  log ""
done

if ! command -v backlog >/dev/null 2>&1; then
  warn "未检测到 backlog 命令。安装它才能使用任务看板：npm i -g backlog.md"
fi

log "完成。下一步："
log "  1. cd 到你的项目目录"
log "  2. 对 agent 说「初始化工作流」"
log "  3. 按 README 第 3 步跑通第一条任务"
log ""
log "卸载：删除上述目录中的 workflow-init / backlog-sdd-bridge 即可。"
