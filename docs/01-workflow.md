# 01 · 三件套如何协同

## 三个组件，三种职责

| 组件 | 职责 | 承载 |
|---|---|---|
| **Backlog.md** | 水平的「任务状态机 + 事实层」 | 任务、里程碑、依赖、DoD、决定记录、看板 |
| **Agent Skills** | 垂直的「工程纪律层」 | spec → plan → build → test → review → ship 生命周期 + 质量门禁 + 反借口 |
| **五环节骨架** | 编排层 | 谁来做、谁来查、谁来拍板 |

一句话记忆：

> **Agent Skills 管「怎么把事做对」，Backlog.md 管「做什么、做到哪了、凭什么算完成」，五环节骨架管「谁来做、谁来查、谁来拍板」。**

## 五环节定义

| 环节 | 含义 | 落到谁 |
|---|---|---|
| 编排 | 拆解目标、排优先级、分派任务 | 主 agent 或人 |
| 判断 | 遇到架构分歧 / 审查冲突时给第二意见 | 强模型，按需调用 |
| 执行 | 按任务说明干活、跑检查、回传证据 | 执行 agent |
| 审查 | 独立挑错：行为、安全、并发、遗漏 | 独立 persona 或人 |
| 验收 | 真实环境走一遍，拍板是否交付 | 人 |

## 核心设计原则

1. **事实源单一化**：已做的决定 → `backlog decision`；项目约束与术语 → `CONTEXT.md`；任务 → `backlog task`。**任何模型不依赖聊天记忆，只读这三处。**
2. **状态机即看板**：状态流转就是 loop engineering。中断后从 `backlog board` / `backlog task list --json` 一眼看出哪些已验收、哪些在修、哪些缺外部条件。
3. **门禁落在 DoD**：质量门禁 → Backlog.md 的 `definition_of_done`（项目级默认 + 每任务 `--dod`）。**规则、检查、门禁是三件事**：写进 DoD 是规则，`--check-ac` 是检查，未全勾不转 `Done` 是门禁。
4. **分层模型分工**：主 agent 编排 + 执行模型干活 + 独立审查 persona。**执行者不自批。**
5. **按规模分档**：轻量 / 完整模式只差「拆不拆里程碑、开不开多模型、门禁多严」，不换底层约定。
6. **换模型不换流程**：换模型时用同一批真实任务对比质量 / 成本 / 等待 / 人工介入，替换某个位置，不推倒重来。

## 生命周期映射表

| 阶段 | Agent Skills 命令 | Backlog.md 操作 | 环节 | 门禁 |
|---|---|---|---|---|
| 澄清需求 | `/spec`（interview-me + idea-refine + spec-driven-development） | spec 存 `docs/`；决定写 `backlog decision create` | 编排 + 判断 | spec 含「成功如何判断 / 明确不做 / 边界」 |
| 拆解 | `/plan`（planning-and-task-breakdown） | `backlog milestone add` 建里程碑；每原子任务 `backlog task create` | 编排 | 每票 AC 可反驳、`--dep` 前置、`--plan` 实施计划 |
| 实现 | `/build`（incremental-implementation + TDD） | `backlog task edit <id> -s "In Progress" -a @me` | 执行 | 每切片：失败测试 → 最小实现 → 重构 → 提交 |
| 验证 | `/test`（test-driven-development + browser-testing） | `backlog task edit <id> --check-ac <n>` 逐条标记 | 执行 | 检查通过 + **反证**（见 `03-gates.md`） |
| 审查 | `/review`（code-review-and-quality，五轴） | 通过后 `--add-label reviewed`；不过打回 `In Progress` | 审查 | 正确性 / 设计 / 安全 / 测试 / 体验 |
| 发布 | `/ship`（shipping-and-launch） | 全勾后 `-s "Done"`，周期 `backlog task archive` | 验收 | 真实界面 / CLI / API 走一遍，留证据 |

> 复杂项目在 `/review` 之后、`/ship` 之前追加一层**整体 Review**：看跨票影响、接口一致性、数据 / 状态流转、权限边界、性能代价、是否符合 `CONTEXT.md`。

## 三处事实源的边界

| 文件 | 放什么 | 不放什么 |
|---|---|---|
| `AGENTS.md` | agent 怎么操作：命令映射、字段约定、硬规则 | 项目业务事实 |
| `CONTEXT.md` | 项目事实：目标、术语、约束、开放问题、被否方案 | 具体任务进度 |
| `backlog decision` | 已做的决定及其理由 | 尚未拍板的讨论 |
| `backlog task` | 任务、状态、验收断言 | 讨论过程 |

冲突时的优先级：`CONTEXT.md` > `backlog decision` > 对话上下文。
