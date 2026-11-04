# AI-Native 开发工作流

> 让 AI 写代码不跑偏：**任务进看板、决定进记录、完成靠断言**。
> 把 [Backlog.md](https://github.com/MrLesk/Backlog.md) 的任务状态机和 Agent Skills 的工程纪律，用一份 `AGENTS.md` 钉在一起。

**适合**：能在终端跑命令的开发者；从单人小工具到多人多里程碑项目都能用，按项目规模切换模式，不换约定。
**不适合**：不想维护任务看板、只希望 AI 直接给代码的场景。

---

## 30 秒了解

三层分工，各管一件事：

| 层 | 承载物 | 回答的问题 |
|---|---|---|
| 任务层 | Backlog.md（`backlog/`） | 做什么、做到哪、**凭什么算完成** |
| 纪律层 | Agent Skills（`/spec` → `/plan` → `/build` → `/test` → `/review` → `/ship`） | 每一步**怎么把事做对** |
| 契约层 | `AGENTS.md` + `CONTEXT.md` | agent **读哪三处、不许做什么** |

三条铁律（轻量模式也不破）：

1. **事实源只有三处**：`CONTEXT.md`（项目事实）、`backlog decision`（已做的决定）、`backlog task`（任务与状态）。任何 agent 不依赖聊天记忆。
2. **验收断言必须可证伪**：写成"无权限用户被 403 拒绝"，而不是"权限功能正常"；未全勾不得转 `Done`。
3. **执行者不自批**：审查交给独立 persona 或人。

> **三条铁律默认在「提示层」生效。** 它们写在 `AGENTS.md` 契约里，模型通常遵守，但**没有强制力保证**。可机械判定的部分（AC 全勾、`Blocked` 带原因、`Done` 带 reviewer）才能下沉到 hook / CI；反证这类不可判定的，只能靠人工抽样。层级划分与哪些能硬化见 [`docs/03-gates.md` §二](docs/03-gates.md)。本仓库只铺契约，不代装 hook / CI。

---

## 前置要求

| 依赖 | 要求 | 必需 |
|---|---|---|
| Node.js | ≥ 18 | 是 |
| Git | 任意较新版本 | 是 |
| Backlog.md | `npm i -g backlog.md`（本文示例基于 v1.55） | 是 |
| 编码 agent | 任一支持 `AGENTS.md` 的 agent（Claude Code / Cursor / Codex / CodeBuddy …） | 是 |
| Agent Skills | 在所用 agent 的插件市场安装任一 SDD/TDD 技能包，或自行提供 | **可选**：没装也能用主干，装了才有 `/spec` `/build` 等命令 |

---

## 快速开始

### 第 1 步 · 安装技能（一次性）

技能目录是纯静态文件，**安装 = 复制目录**：没有安装脚本要跑，也不碰你项目里的任何文件。**在你自己的项目「外面」执行**，别把本仓库 `clone` 进项目目录（会形成嵌套仓库）。

```bash
# 取一份仓库，留着以便日后 git pull 升级
git clone --depth 1 https://github.com/Carson-Lianng/ai-native-workflow.git ~/tools/ai-native-workflow

# 装到 Claude Code（全局）：把 skills/ 下两个目录复制过去
mkdir -p ~/.claude/skills
cp -R ~/tools/ai-native-workflow/skills/* ~/.claude/skills/
```

其它环境只换目标路径：

| 环境 | 目标路径 |
|---|---|
| Claude Code | `~/.claude/skills/` |
| CodeBuddy | `~/.codebuddy/skills/` |
| Cursor | `<项目>/.cursor/skills/`（Cursor 没有全局技能目录） |
| 其它支持 `AGENTS.md` 的 agent | 你所用 agent 的技能目录 |

装到项目级，把目标换成 `<项目>/.claude/skills/` 这类路径即可。

**升级时先删再复制。** `cp -R` 是**合并**，仓库里已删除的文件会残留在你的技能目录里，被 agent 继续当成有效指令执行：

```bash
git -C ~/tools/ai-native-workflow pull
rm -rf ~/.claude/skills/workflow-init ~/.claude/skills/backlog-sdd-bridge
cp -R ~/tools/ai-native-workflow/skills/* ~/.claude/skills/
```

装完确认落点：`ls ~/.claude/skills/`。

### 第 2 步 · 初始化某个项目

在**你的项目目录**里对 agent 说一句：

> 初始化工作流

`workflow-init` 技能会依次完成：`backlog init` → 铺 `AGENTS.md` / `CONTEXT.md` / `backlog/config.yml` → 建首次提交。**已存在的文件一律先问、绝不覆盖。**

没有 agent 或想手动铺，等价于：

```bash
backlog init "项目名" --defaults --agent-instructions none
cp <本仓库>/skills/workflow-init/templates/AGENTS.md <本仓库>/skills/workflow-init/templates/CONTEXT.md .
```

> `--defaults` 不能省：没有 TTY 时 `backlog init` 会要求交互式向导并直接失败。`--agent-instructions none` 是为了用本仓库的 `AGENTS.md` 模板替换 backlog 自带的版本。

### 第 3 步 · 跑通第一条任务（5 分钟，可直接照抄）

```bash
# 1. 记一个决定（事实源之一）
backlog decision create "任务统一用 backlog 管理" -s accepted

# 2. 建一条任务：AC 可证伪 + 允许改动的路径
backlog task create "给 README 补安装说明" \
  -d "Touches: README.md" \
  --ac "README 出现 3 步安装命令" \
  --ac "命令在 macOS/Linux 可直接执行" \
  -l needs-review --priority high

# 3. 领票开工（把「你的名字」换成你的标识，别照抄 @me）
backlog task edit TASK-1 -s "In Progress" -a 你的名字

# 4. 逐条勾验收断言（1-based 序号）
backlog task edit TASK-1 --check-ac 1 --check-ac 2

# 5. 审查通过后收尾：先写证据 note，再置 Done（-l 会替换全部标签，追加用 --add-label）
backlog task edit TASK-1 --notes "Evidence: ac=2/2; reviewer=<审查者>; test=两条命令在 macOS 直接可执行"
backlog task edit TASK-1 --add-label reviewed -s "Done"

# 6. 看板确认
backlog board
```

看到 `TASK-1` 落到 `Done` 列，链路就通了。

---

## 两种模式

同一套约定，只差"拆不拆里程碑、开不开多模型、门禁多严"。

| | 轻量模式 | 完整模式 |
|---|---|---|
| 适用 | 单人、单里程碑、边界清楚、数周内交付 | 多人 / 多里程碑、多模块并行、跨系统集成 |
| 里程碑 | 不拆，直接建 task | `backlog milestone add` 分阶段 |
| 模型 | 单 agent 直跑 | 主 agent 编排 + 执行模型 + 独立审查 |
| DoD | 3 项 | 5 项（含五轴审查、反证） |
| 隔离 | 单分支 | 每任务一个 git worktree |
| 上线前 | 自审 + 人工抽查 | 三 persona 交叉审 + 整体 Review |

切换到完整模式不重写任何约定，只加里程碑与审查层。操作手册见 [`docs/02-modes.md`](docs/02-modes.md)。

---

## 支持环境

技能目录按宿主约定放置，复制到对应路径即可：

| 环境 | 全局技能目录 | 项目级技能目录 |
|---|---|---|
| Claude Code | `~/.claude/skills/` | `.claude/skills/` |
| Cursor | — | `.cursor/skills/` |
| CodeBuddy | `~/.codebuddy/skills/` | `.codebuddy/skills/` |
| 其他支持 `AGENTS.md` 的 agent | 你所用 agent 的技能目录 | 同左 |

指令文件统一用 `AGENTS.md`（Claude Code、Cursor、Codex 均识别）。非技能型 agent 仍可用全部功能，只是"说一句就初始化"需改为手动执行第 2 步的命令。

---

## 仓库结构

```
README.md                  本文：5 分钟上手

skills/                    复制到 agent 的技能目录（见第 1 步）
  workflow-init/           说一句「初始化工作流」即铺好整套
    templates/             铺进你的项目，是模板的唯一真源（随技能一起安装）
      AGENTS.md            agent 操作契约　→ 项目根
      CONTEXT.md           项目事实文件　→ 项目根
      backlog.config.yml   完整模式 DoD / 状态 / 标签　→ 合并进 backlog/config.yml
      backlog.config.lite.yml  轻量模式 DoD（3 项）　→ 合并进 backlog/config.yml
  backlog-sdd-bridge/      把 SDD 六阶段与 backlog 命令串联

docs/                      原理与手册
  01-workflow.md           三件套协同、设计原则、五环节
  02-modes.md              轻量 / 完整模式操作手册
  03-gates.md              DoD、AC、labels、反证、执行层级
  04-antipatterns.md       反模式与落地 Checklist

LICENSE                    MIT
```

---

## 文档

| 文档 | 内容 |
|---|---|
| [`docs/01-workflow.md`](docs/01-workflow.md) | 三件套协同、核心设计原则、五环节骨架 |
| [`docs/02-modes.md`](docs/02-modes.md) | 轻量 / 完整模式完整操作手册 |
| [`docs/03-gates.md`](docs/03-gates.md) | 门禁：DoD、AC、labels、反证纪律、执行层级 |
| [`docs/04-antipatterns.md`](docs/04-antipatterns.md) | 7 条反模式 + 落地 Checklist |

---

## 设计原则

1. **事实源单一化**——同一件事只在一处记录，冲突时 `CONTEXT.md` > `backlog decision` > 对话。
2. **状态机即看板**——中断后靠 `backlog board` / `task list --json` 恢复现场，不靠回忆。
3. **门禁落在 DoD**——规则写进 DoD，检查靠 `--check-ac`，门禁是"未全勾不转 Done"（默认提示层，硬化方式见 `docs/03-gates.md` §二）。
4. **分层模型分工**——编排、执行、审查由不同角色承担，执行者不自批。
5. **按规模分档**——轻量与完整共用约定，只调厚度。
6. **换模型不换流程**——用同一批真实任务横向对比，替换单个位置，不推倒重来。

---

## 语言与贡献

文档为**中文**，不维护英文版本。Issue / PR 中英文均可。

提 PR 时请遵守两条：一个 PR 只做一件事；改动涉及 `backlog` 命令的，先在本地真实执行一遍，并把 `backlog --version` 写进 PR 描述。

## License

[MIT](LICENSE)
