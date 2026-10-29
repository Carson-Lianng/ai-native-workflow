---
name: workflow-init
description: 把一个新项目（或已有项目）初始化为 AI-Native 开发工作流：Backlog.md 任务看板 + AGENTS.md/CONTEXT.md 契约 + 桥接技能。当用户要开新项目、搭建或初始化开发工作流、初始化 backlog，或说出「新项目」「初始化工作流」「搭工作流」「搭环境」「初始化项目」「bootstrap」「init workflow」「scaffold」等语义时触发。一次性完成：backlog init、铺模板、接头文件、建版本基线。
---

# 工作流初始化器（workflow-init）

把一个项目初始化成 AI-Native 开发工作流。**说一次关键语义，整套铺好。**

## 触发方式

- **自然语言**：用户说「初始化工作流 / 搭工作流 / 新项目，初始化一下 / bootstrap / scaffold」等，按 description 自动激活。
- **显式点名**：直接说「用 workflow-init 初始化」。

## 前置：先确认，再执行

初始化前先问清（都有缺省值，不必每项都追问）：

| 问题 | 缺省 |
|---|---|
| 项目名 | 当前目录名 |
| 模式：轻量（DoD 3 项）或完整（DoD 5 项） | 轻量 |
| 是否初始化 Git 仓库 | 是（已在仓库内则跳过） |
| 是否已有 `AGENTS.md` / `backlog/` | 有则询问是否合并 |

## 初始化步骤（幂等、安全、绝不覆盖）

### 步骤 1：环境检查

```bash
node --version                      # 需 ≥ 18
backlog --version                   # 缺失则 npm i -g backlog.md
git rev-parse --git-dir 2>/dev/null || git init
```

### 步骤 2：Backlog.md 初始化

```bash
backlog init "<项目名>"
```

- 生成 `backlog/`、`backlog/config.yml`、`AGENTS.md`。
- 若 `backlog/` 或 `AGENTS.md` 已存在：**先询问，绝不覆盖**。

### 步骤 3：合并配置（不是覆盖）

从本技能的 `templates/` 目录取：

| 模板 | 目标 | 动作 |
|---|---|---|
| `AGENTS.md` | 项目根 `AGENTS.md` | 已有则**合并**（保留用户原有段落），没有则复制 |
| `CONTEXT.md` | 项目根 `CONTEXT.md` | 不存在才复制，存在则保留 |
| `backlog.config.yml` 或 `backlog.config.lite.yml` | `backlog/config.yml` | **合并键值**，不覆盖 `backlog init` 生成的其他键 |

> `templates/` 位于本技能目录内，由 `install.sh` 在安装时铺好；若缺失，从仓库根目录的 `templates/` 取。

### 步骤 4：接入桥接技能

把同级的 `backlog-sdd-bridge` 技能目录放到**与 `workflow-init` 相同的父目录**（`install.sh` 已自动完成，通常无需干预）。确认其 `SKILL.md` 存在即可。

### 步骤 5：建版本基线

仅在 Git 可用时：

```bash
git add -A && git commit -m "chore: init ai-native workflow"
```

### 步骤 6：交接口令

向用户报告三件事：

1. 已铺好哪些文件（逐条列出，标注「新建 / 合并 / 已存在跳过」）。
2. 当前模式与 DoD 项数。
3. 下一步：直接说需求，agent 会用 `interview-me` 一次一个问题澄清，然后把 spec 落 `docs/`、拆票进 `backlog`。

## 硬规则

1. 每步写入前先检查目标是否已存在；已存在 → 询问 / 合并，**绝不覆盖**。
2. 只写当前项目目录，不动项目以外的文件。
3. 完成后必须给出「已改动的文件清单 + 下一步」。
4. 不触碰用户已有的 `.cursor/rules`、`.claude/settings.json` 等无关配置。
5. 环境缺依赖时给出安装命令并**停下等确认**，不自动全局安装。
