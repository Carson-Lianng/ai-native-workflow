# AI-Native 开发工作流：Backlog.md × Agent Skills × 五环节骨架

> 把你已在用的两套工具，用《2026年 我的 AI-Native 软件开发工作流》的骨架整合成一套工作流。
> **轻量模式**驾驭小型项目，**完整模式**驾驭复杂项目，两种模式共用同一套约定，按规模切换、不重写。

---

## 零、新项目一键初始化（触发语义）

开新项目时，不必手动跑一堆命令。把 `workflow-init` 技能装到全局技能目录（Claude Code 放 `~/.claude/skills/`，本工作台放 `~/.codebuddy/skills/`），之后只需说出关键语义即可触发：

> "初始化工作流" / "搭工作流" / "新项目，初始化一下" / "bootstrap workflow" / "scaffold"

agent 会激活 `workflow-init`，自动完成：`backlog init` → 铺 AGENTS.md / CONTEXT.md / config 模板 → 装 Agent Skills + 桥接技能 → 建版本基线 → 提示进入 `interview-me` 需求澄清。详细步骤见 `skills/workflow-init/SKILL.md`。

---

## 一、三件套如何协同（总览）

| 组件 | 你已有的定位 | 在本工作流中的职责 | 对应文章思想 |
|---|---|---|---|
| **Backlog.md**（MrLesk） | 开发看板 | **水平的"任务状态机 + 事实层"**：任务、里程碑、依赖、DoD、决定记录、看板 | CONTEXT.md / tickets / loop engineering |
| **Agent Skills**（Chrome 团队） | SDD / TDD 规范 | **垂直的"工程纪律层"**：spec→plan→build→test→review→ship 生命周期 + 质量门禁 + 反借口 + persona | grill / to-spec / TDD / review / harness |
| **文章五环节** | （本次引入） | **编排骨架**：编排 / 判断 / 执行 / 审查 / 验收 + 分层模型 + 反证 | 整套 |

一句话记忆：

> **Agent Skills 管"怎么把事做对"，Backlog.md 管"做什么、做到哪了、凭什么算完成"，文章骨架管"谁来做、谁来查、谁来拍板"。**

---

## 二、核心设计原则（6 条）

1. **事实源单一化**：已做的决定 → `backlog decision`；项目约束与术语 → `CONTEXT.md`；任务 → `backlog task`。**任何模型不依赖聊天记忆，只读这三处。**
2. **状态机即看板**：Backlog.md 的状态流转（`To Do → In Progress → Done / Blocked`）就是 loop engineering。中断后从 `backlog board` / `task list --json` 一眼看出哪些已验收、哪些在修、哪些缺外部条件。
3. **门禁落在 DoD**：Agent Skills 的质量门禁 → Backlog.md 的 `definition_of_done`（项目级默认 + 每任务 `--dod`）。**规则、检查、门禁是三件事**：写进 DoD 是规则，`--check-ac` 是检查，未全勾不转 `Done` 是门禁。
4. **分层模型分工**：主 agent 编排 + 执行模型干活 + 独立审查（`code-reviewer` / `test-engineer` / `security-auditor` 三个 persona）。**执行者不自批**。
5. **按规模分档**：轻量模式 vs 完整模式，只差"拆不拆里程碑、开不开多模型、门禁多严"，不换底层约定。
6. **换模型不换流程**：换模型时用同一批真实任务对比质量/成本/等待/人工介入，替换某个位置，不推倒重来。

---

## 三、生命周期映射表（核心）

| 阶段 | Agent Skills 命令 | Backlog.md 操作 | 五环节 | 门禁（DoD / AC） |
|---|---|---|---|---|
| 澄清需求 | `/spec`（interview-me + idea-refine + spec-driven-development） | 产出的 spec 存 `docs/`，决定写 `backlog decision` | 编排 + 判断 | spec 含"成功如何判断 / 明确不做 / 边界" |
| 拆解 | `/plan`（planning-and-task-breakdown） | `backlog milestone add` 建里程碑；每原子任务 `backlog task create` | 编排 | 每票 `--ac` 可反驳、`--dep` 前置、`--plan` 实施计划 |
| 实现 | `/build`（incremental-implementation + TDD） | `backlog task edit <id> -s "In Progress" -a @me` | 执行 | 每切片：失败测试→最小实现→重构→提交 |
| 验证 | `/test`（test-driven-development + browser-testing） | `backlog task edit <id> --check-ac <n>` 逐条标记 | 执行 | 检查通过 + **反证**（见 §四） |
| 审查 | `/review`（code-review-and-quality，五轴） | 通过后再转状态；审查不过打回 `In Progress` | 审查 | 正确性/设计/安全/测试/体验 五轴 |
| 发布 | `/ship`（shipping-and-launch，三 persona 并行） | 全勾后 `-s "Done"`，周期清理 `backlog task archive` | 验收 | 真实界面/CLI/API 走一遍，留证据 |

> 复杂项目在 `/review` 之后、`/ship` 之前追加一层**整体 Review**：看跨票影响、接口一致性、数据/状态流转、权限边界、性能代价、是否符合 CONTEXT.md。

---

## 四、门禁与 DoD 落地（Backlog.md 承载）

### 4.1 项目级 DoD 默认项（写入 `backlog.config.yml`）

```yaml
backlog_directory: backlog
task_prefix: TASK
definition_of_done:
  - 测试通过且无回归
  - 所有验收断言已逐条 --check-ac 标记完成
  - 五轴审查通过（正确性/设计/安全/测试/体验）
  - 决定与文档已更新（backlog decision / docs）
  - 关键检查已做反证
```

> 轻量模式改用精简版 `templates/backlog.config.lite.yml`：DoD 仅 3 项（测试通过 / AC 全勾 / 决定与文档已更新），砍掉"五轴审查"与"反证"。

### 4.2 验收断言 = AC，门禁状态 = labels

- **AC（`--ac`）承载可反驳的验收断言**：每条写成"能证伪"的句子（如"无权限用户提交被 403 拒绝"，而非"权限功能正常"）。
- **labels 承载门禁流转**：`needs-review` → `reviewed`、`needs-test` → `tested`、`blocked`（缺凭据/需人决策）。
- **`--dep` 承载 Blocked by**，**`--plan` 或 description 首行承载 Touches**（如 `Touches: src/api, src/db`）。

### 4.3 反证纪律（文章最锋利的一条，写进你的习惯）

> 只看绿色退出码/全勾，不足以证明门禁可信。每个关键检查做一次反证：**已知正确输入能通过 → 故意构造一个目标缺陷后能因正确原因失败 → 恢复后再次通过。** 三条都满足，门禁才算可信。

---

## 五、轻量模式（小型项目）

适用：单人、单里程碑、边界清楚、几周内交付的小工具/小功能/独立脚本/售前 demo。

**特征**：不拆多里程碑、单模型主 agent 直跑、门禁从简、不做 worktree 隔离。

### 操作手册

```bash
# 0. 初始化（一次性）
npm i -g backlog.md
backlog init "项目名"                # 选 CLI instructions（生成 AGENTS.md）；Cursor 加 --agent-instructions cursor
backlog config                      # 设 DoD 精简为 3 项：测试通过 / AC 全勾 / 决定与文档已更新

# 1. 需求澄清（/spec，先用 interview-me 一次一个问题逐轮追问）
#    agent 追问：用户是谁、边界、明确不做、成功怎么判断、现有约束
#    决定写：backlog decision add "..."；约束沉淀到 CONTEXT.md

# 2. 拆票（/plan）—— 轻量模式只用一个默认里程碑，直接建 task
backlog task create "实现用户登录" -d "..." --ac "合法凭据可登录" --ac "非法凭据显示错误" --priority high -l needs-review

# 3. 实现 + 验证（/build + /test）
backlog task edit TASK-1 -s "In Progress" -a @me
#    TDD：先写失败测试→最小实现→重构；然后：
backlog task edit TASK-1 --check-ac 1 --check-ac 2   # 逐条标记

# 4. 审查（/review）—— 五轴自审 + 人工抽查
#    通过后：backlog task edit TASK-1 -l reviewed -s "Done"

# 5. 验收（/ship）—— 真实跑一遍
#    网页用浏览器、API 用 curl、CLI 启动真实程序；200 但不符合目标=失败

# 6. 周期清理
backlog board                        # 终端看板
backlog task archive TASK-1          # 归档已完成
```

**轻量模式三条红线**（再小也不破）：① 决定进 decision、不进聊天；② AC 必须可证伪；③ 验收必须真跑一遍。

---

## 六、完整模式（复杂项目）

适用：多人/多里程碑、多模块并行、跨系统集成、需要合规与权限边界的大中型项目。

**特征**：里程碑组织 + 分层模型 + 独立审查（3 persona）+ 并发准入 + 反证 + worktree 隔离。

### 操作手册

```bash
# 0. 初始化（开启完整配置）
backlog init "项目名"
backlog config   # 设完整 DoD 6 项；开启 checkActiveBranches / remoteOperations
#    建立版本基线：CONTEXT.md + backlog/ + docs/ + .claude/ + .cursor/ 全部纳入 Git

# 1. 里程碑规划（对应文章"按里程碑组织多份 spec"）
backlog milestone add "M1 用户与权限"
backlog milestone add "M2 数据与报表"

# 2. 每里程碑：/spec 先用 interview-me 一次一个问题澄清 → 产出 spec.md 存 docs/spec-m1.md，决定写 decision

# 3. 拆票（/plan）—— 原子任务带 Touches / Blocked by
backlog task create "实现登录 API" \
  -d "Touches: src/api/auth, src/db/user" \
  --ac "合法凭据返回 token" --ac "无权限被 403 拒绝" \
  --dep TASK-1 -l m1 needs-review --priority high --plan "1. 建表 2. 实现 3. 测试"
#   并发准入：路径不相交 + 依赖满足 + 无共享资源冲突（DB/测试账号/端口），否则串行

# 4. 并行执行（分层模型 + worktree 隔离）
#    主 agent 编排；执行模型在各 git worktree 分支独立干：
backlog task edit TASK-2 -s "In Progress" -a @executor-1
#    每个执行 agent 只读自己的 task + 相关 spec，回传执行回执，不宣布"整项完成"

# 5. 独立审查（/review，执行者不自批）
#    触发 code-reviewer / security-auditor / test-engineer 三 persona 交叉审
#    通过 → reviewed；不过 → 打回 In Progress + 写清问题

# 6. 整体 Review（逐票审查解决局部问题，整体审查解决组合问题）
#    跨票影响 / 接口一致性 / 数据与状态流转 / 权限边界 / 性能 / 是否符合 CONTEXT.md

# 7. 验收（/ship）—— user-validate-flow 覆盖完整用户验收条件
#    每条断言留命令结果/截图/状态证据；必要时固化为回归用例

# 8. 状态可恢复（loop engineering）
backlog task list --json             # 机器可读状态导出，脚本/CI 可消费
backlog task edit TASK-5 -s "Blocked" # 缺凭据/需人决策 → 明确停下，记录阻塞原因，不无限重试
backlog task archive TASK-1          # 已验收归档（保留 ID 与依赖链，可 restore）
```

### 分层模型分工表

| 文章角色 | 落到谁 | 职责 | 硬边界 |
|---|---|---|---|
| 主模型（编排） | 主 agent / 你 | 拆里程碑、调度、判断优先级 | 不做实现细节 |
| advisor（判断） | 架构分歧/审查冲突时请强模型 | 给第二判断 | 只在分歧时按需调用 |
| 执行模型 | 各 worktree 里的执行 agent | 按 task 干活、跑检查、回证据 | **不改需求、不改验收标准** |
| 审查模型 | code-reviewer / security-auditor / test-engineer | 独立找行为错误/安全/并发/遗漏 | **不能审自己的代码** |

---

## 七、反模式提醒

1. **超大上下文文件**：别把 20+ 个 SKILL.md 全塞进 AGENTS.md；用 Agent Skills 的渐进披露（discovery→activation→execution）按需加载。
2. **约束过重变噪音**：模型变强后删掉无效提示词，只保留"承担边界和证据"的约束。
3. **把判断外包给模型**：3 个 persona 交叉审降低盲区，但最终验收由你拍板。
4. **绿色退出码幻觉**：全勾 ≠ 正确，关键检查必做反证。
5. **执行者自批**：审查必须独立于执行。
6. **手改任务文件**：一律走 `backlog` CLI/MCP/Web，否则字段元数据不一致。
7. **一套约定两处重复**：CONTEXT.md 与 AGENTS.md 分工明确——AGENTS.md 放"怎么操作"，CONTEXT.md 放"项目事实"；decision 放"已做的决定"。

---

## 八、落地 Checklist

- [ ] 新项目：说「初始化工作流」触发 `workflow-init` 一键铺好（推荐）；手动方式见下
- [ ] `backlog init` 完成，选 CLI instructions（Claude Code）或 `--agent-instructions cursor`（Cursor）
- [ ] Agent Skills 装好：Claude Code 用 `/plugin install agent-skills@addy-agent-skills`；Cursor 把 `skills/` 拷到 `.cursor/skills/`
- [ ] `backlog config` 设好项目级 DoD
- [ ] `CONTEXT.md` 建好（术语 / 约束 / 开放问题 / 被否方案）
- [ ] 套用本目录 `templates/` 下的 `AGENTS.md`、`CONTEXT.md`，并按模式选用 `backlog.config.yml`（完整）或 `backlog.config.lite.yml`（轻量）
- [ ] 装桥接技能 `skills/backlog-sdd-bridge/`（让 /spec /plan /build 自动落 backlog 命令）
- [ ] 选定模式：轻量 or 完整，按 §五/§六 走一遍
- [ ] 建立版本基线：全部纳入 Git，功能改动前先更新 CONTEXT.md 再动

---

## 附：交付文件说明

| 文件 | 用途 |
|---|---|
| `templates/AGENTS.md` | 双环境（Claude Code + Cursor）AI 指令：告诉 agent 这套约定怎么操作 |
| `templates/CONTEXT.md` | 项目事实文件模板：决定/术语/约束/开放问题/被否方案 |
| `templates/backlog.config.yml` | Backlog.md 配置：目录、ID 前缀、完整模式 DoD（6 项） |
| `templates/backlog.config.lite.yml` | 轻量模式配置：DoD 精简为 3 项 |
| `skills/backlog-sdd-bridge/SKILL.md` | 桥接技能：把 Agent Skills 生命周期与 backlog 命令串起来 |
| `skills/workflow-init/SKILL.md` | **初始化器**：说出关键语义即触发，一键铺好整套工作流（自包含模板与桥接技能） |
