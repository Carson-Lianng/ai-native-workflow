# AGENTS.md — AI 协作指令

> 本文件告诉 agent「**怎么操作**」。项目事实看 `CONTEXT.md`，已做的决定看 `backlog decision`，任务与状态看 `backlog` CLI。
> 原则：**任何 agent 不依赖聊天记忆，只读这三处事实源。**

## 事实源（优先级从高到低）

1. `CONTEXT.md` —— 术语、约束、开放问题、被否方案（项目事实）
2. `backlog decision list` —— 已做的决定
3. `backlog task list` / `backlog board` —— 任务与状态

冲突时：`CONTEXT.md` > `backlog decision` > 对话上下文。

## 生命周期与命令对应

| 阶段 | 纪律层命令（装了 Agent Skills 才有） | Backlog.md 操作 |
|---|---|---|
| 澄清需求 | `/spec`（先用 `interview-me` 一次一个问题） | spec 存 `docs/`；决定用 `backlog decision create "<决定>" -s accepted` |
| 拆解 | `/plan` | `backlog milestone add` 建里程碑；`backlog task create` 建原子任务 |
| 实现 | `/build` | `backlog task edit <id> -s "In Progress" -a <你的名字>` |
| 验证 | `/test` | `backlog task edit <id> --check-ac <n>` 逐条标记 |
| 审查 | `/review` | 独立 persona 审查，通过 `--add-label reviewed`，不过打回 `In Progress` |
| 发布 | `/ship` | 全勾后 `-s "Done"`，周期 `backlog task archive` |

没装 Agent Skills 时，左侧命令按同语义手动执行，右侧 backlog 操作不变。

## 任务字段约定

- **验收断言 = `--ac`**：每条写成可证伪的句子（「无权限用户被 403 拒绝」，而非「权限正常」）。
- **Blocked by = `--dep`**：前置任务依赖。
- **Touches = `-d` 首行**：`Touches: src/api, src/db`（本任务允许修改的路径）。
- **门禁标签**：创建时用 `-l needs-review`；之后**追加**用 `--add-label`（`-l` 会替换全部标签）。
- **DoD**：项目级默认见 `backlog/config.yml`，每任务可用 `--dod` 增补。

## 硬规则（不可违反）

1. **绝不手改 `backlog/` 下的任务文件**，一律用 `backlog` CLI / MCP / Web。
2. **执行者不改需求、不改验收标准**；实现困难时上报，不偷偷降低标准。
3. **执行者不自批**：审查必须由独立 persona（`code-reviewer` / `security-auditor` / `test-engineer`，若有）或人完成。
4. **关键检查必做反证**：正确输入通过 → 故意构造缺陷应失败 → 恢复后通过。
5. **缺凭据 / 需人决策**：`backlog task edit <id> -s "Blocked"`（需先在 `statuses` 中声明）并写清原因，不无限重试。
6. **约束宁缺毋滥**：模型变强后删除无效提示词，只保留承担边界和证据的约束。

### 每条规则的执行层级

层级含义：**提示**（本文件承载，模型通常遵守但无保证）/ **hook**（本地 git hook）/ **CI**（远端必过项）/ **人工**（人看证据拍板）。

| # | 规则 | 可机械判定 | 本模板给到 | 零例外还需接入 |
|---|---|---|---|---|
| 1 | 不手改 `backlog/` | 弱 | 提示 | CI 弱检测（误报率高，可不做） |
| 2 | 不改需求 / AC | 中 | 提示 | CI 查 AC 行被单方删除 |
| 3 | 执行者不自批 | 是（`reviewer` ≠ assignee） | 提示 + 人工 | CI 校验 Done 的 `Evidence` note |
| 4 | 关键检查必做反证 | 否 | 提示 + 人工 | 不可机械化，只能人工抽样 |
| 5 | Blocked 必须写原因 | 是（note 非空） | 提示 | hook / CI |
| 6 | 约束宁缺毋滥 | — | 元规则 | 不适用 |

**默认只铺提示层。** 「零例外还需接入」那一列要项目自行配置；不配置时，这些规则是**约定**，不是强制门禁。第 4 条不可机械判定，**不要**硬做成脚本——造假 note 也能通过，反而毁掉反证的可信度。

## Done 的证据记录

置 `Done` 前，用一条 `--notes` 追加证据（固定前缀 `Evidence:`，后续 hook / CI 依赖这个格式）：

```bash
backlog task edit TASK-1 --notes "Evidence: ac=3/3; reviewer=@code-reviewer; test=npm test 34 passed; ship=curl /api/login 200"
```

| 字段 | 必填 | 说明 |
|---|---|---|
| `ac=<勾选数>/<总数>` | 是 | 与 `--check-ac` 的实际状态一致 |
| `reviewer=<审查者>` | 是 | 独立 persona 或人；**与 `-a` 的 assignee 相同 = 自批，视为未通过** |
| `test=<命令与结果>` | 是 | 跑过的检查及关键输出，不写「测试通过」这种空话 |
| `ship=<验收证据>` | 完整模式必填 | 真实界面 / CLI / API 走完的结果 |

没有这条记录，状态照样能被改成 `Done`，但没人能复核它凭什么算完成——这恰恰是「绿色退出码不可信」的另一面。
