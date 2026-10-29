---
name: workflow-init
description: 把 AI-Native 开发工作流（Backlog.md + Agent Skills + 五环节骨架）初始化到一个新项目。当用户要开始新项目、搭建或初始化开发工作流、初始化 backlog，或说出"新项目""开个项目""初始化工作流""搭工作流""搭环境""初始化项目""bootstrap""init workflow""scaffold"等关键语义时触发。一次性完成：backlog init、铺模板、装技能、建版本基线。
---

# 工作流初始化器（workflow-init）

把一个全新（或已有）项目初始化成 AI-Native 开发工作流。**说一次关键语义，整套铺好。**

## 安装位置（常驻全局，一次装好）

- Claude Code：`~/.claude/skills/workflow-init/`
- 本工作台（WorkBuddy）：`~/.codebuddy/skills/workflow-init/`

装在全局后，任意新项目都能靠 description 语义触发，无需每个项目重复安装本技能。

## 触发方式

- **自然语言**：用户说"初始化工作流 / 搭工作流 / 新项目，初始化一下 / bootstrap / scaffold"等，本技能按 description 自动激活。
- **显式点名**：直接说"用 workflow-init 初始化"。

## 前置：先确认，再执行

初始化前先问清（有缺省值，不必每项都追问）：

1. **项目名**（缺省取当前目录名）
2. **模式**：`轻量`（小型项目，DoD 3 项）或 `完整`（复杂项目，DoD 6 项）
3. **是否用 Git**（缺省是；纯本地/非代码项目可 `--no-git`）
4. **运行环境**：Claude Code / Cursor / 两者（决定指令文件与技能目录）

## 初始化步骤（幂等、安全、绝不覆盖用户已有文件）

### 步骤 1：环境检查
- `backlog --version`，未安装则 `npm i -g backlog.md`。
- 需 Git 且不在仓库内：`git init`。

### 步骤 2：Backlog.md 初始化
- `backlog init "<项目名>"`（选 CLI instructions；Cursor 环境加 `--agent-instructions cursor`）。
- 若已存在 backlog 目录或 AGENTS.md：**先询问，绝不覆盖**。

### 步骤 3：铺模板（从本技能 `templates/` 复制）
- `CONTEXT.md` → 项目根（已存在则保留）
- `AGENTS.md` → 项目根（已存在则合并/追加，不覆盖）
- 配置：完整模式用 `templates/backlog.config.yml`，轻量模式用 `templates/backlog.config.lite.yml` → 项目根 `backlog.config.yml`

### 步骤 4：装技能
- **Agent Skills**（Chrome 团队）：
  - Claude Code：`/plugin install agent-skills@addy-agent-skills`
  - Cursor：把 agent-skills 的 `skills/` 拷到 `.cursor/skills/`，规则放 `.cursor/rules/`
- **桥接技能 backlog-sdd-bridge**（本技能已打包）：
  - 复制 `assets/skills/backlog-sdd-bridge/` 到项目 `.claude/skills/backlog-sdd-bridge/`（Claude Code）或 `.cursor/skills/backlog-sdd-bridge/`（Cursor）

### 步骤 5：建版本基线
- 用了 Git 才做：`git add -A && git commit -m "chore: init ai-native workflow"`。
- 之后约定：功能改动前先更新 CONTEXT.md 再动工。

### 步骤 6：启动第一条需求澄清
- 提示用户：现在可直接说需求，agent 会用 `interview-me` 一次一个问题澄清，随后把 spec 落 milestone、拆票进 backlog。

## 硬规则

1. 每步写入前先检查目标是否已存在；已存在 → 询问/合并，**绝不覆盖**。
2. 只写项目目录，不动项目外文件。
3. 完成后给出「已铺好哪些文件 + 下一步怎么做」的清单。
4. 不改动用户已有的 `.cursor/rules`、AGENTS.md 等无关内容。
