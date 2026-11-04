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
backlog init "<项目名>" --defaults --agent-instructions none
```

- `--defaults`：**必须带**。agent 执行时没有 TTY，缺了会报 `Initialization needs an interactive terminal for setup choices`。
- `--agent-instructions none`：不生成 backlog 自带的 `AGENTS.md`，避免与模板冲突；用户明确要求保留 backlog 指引时，改用 `--agent-instructions agents`，再按步骤 3 的「三种情况」处理。
- 生成 `backlog/` 与 `backlog/config.yml`（无 `AGENTS.md`）。
- 若 `backlog/` 已存在：**先询问，绝不覆盖**（重跑 `backlog init` 会重置配置）。

### 步骤 3：合并配置（不是覆盖）

从本技能的 `templates/` 目录取：

| 模板 | 目标 | 动作 |
|---|---|---|
| `AGENTS.md` | 项目根 `AGENTS.md` | 按下方「三种情况」处理 |
| `CONTEXT.md` | 项目根 `CONTEXT.md` | 不存在才复制，存在则保留 |
| `backlog.config.yml` 或 `backlog.config.lite.yml` | `backlog/config.yml` | **合并键值**，不覆盖 `backlog init` 生成的其他键 |

#### `AGENTS.md` 的三种情况

1. **不存在** → 整份复制。
2. **由 `backlog init` 生成**（文件里有 `<!-- BACKLOG.MD GUIDELINES START -->` / `END` 标记）→ 把模板内容**追加到 `END` 标记之后**，标记内一个字都不改。
3. **用户自己写的** → 在末尾追加一节 `## AI-Native 工作流约定`；与原有段落冲突时先问用户保留哪一版。

> 不要整份替换，也不要把模板插进两条标记之间——`backlog` 升级时会覆盖那段内容。

> `templates/` 位于本技能目录内（`skills/workflow-init/templates/`），随技能一起安装，不需要从别处取。

### 步骤 4：接入桥接技能

把同级的 `backlog-sdd-bridge` 技能目录放到**与 `workflow-init` 相同的父目录**（安装时两个目录一起复制即可）。确认其 `SKILL.md` 存在即可。

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
6. 所有命令必须能在**无 TTY 的非交互环境**跑完（`backlog init` 之类补 `--defaults`），不要依赖交互式向导。
