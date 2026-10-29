---
name: backlog-sdd-bridge
description: 把 spec-driven development（Agent Skills 六阶段）与 Backlog.md 看板串联。当需要把需求澄清为 spec、拆解为任务、更新任务状态、标记验收断言、做独立审查时使用。触发词：spec、interview-me、plan、build、test、review、ship、backlog、里程碑、验收断言、DoD、拆票。
---

# Backlog × SDD 桥接技能

把「Agent Skills 管怎么把事做对」和「Backlog.md 管做什么、做到哪、凭什么算完成」串成一条可执行链路。

## 职责

保证三处事实源一致、状态机可恢复、门禁可信：

- 事实源：`CONTEXT.md`（项目事实）> `backlog decision`（已做决定）> 对话。
- 状态机：只用 `backlog` CLI 流转状态，绝不手改 `backlog/` 任务文件。
- 门禁：DoD（`definition_of_done`）+ AC（`--ac`）+ 反证。

## 阶段映射

### 1. 澄清需求（对应 /spec）

- 先用 `interview-me` 技能：一次只问一个问题，逐轮追问用户，直到需求清晰。
- 追问覆盖：用户是谁、边界在哪、哪些明确不做、成功怎么判断、现有约束。
- 产出 spec 存 `docs/spec-<slug>.md`。
- 每个决定落地：`backlog decision add "<决定>"`；术语/约束/被否方案写回 `CONTEXT.md`。

### 2. 拆解（对应 /plan）

- 里程碑：`backlog milestone add "M1 <目标>"`。
- 原子任务：

```bash
backlog task create "<标题>" \
  -d "Touches: <允许修改的路径>" \
  --ac "<可证伪的验收断言>" --ac "<…>" \
  --dep <前置任务ID> \
  -l <里程碑标签,needs-review> \
  --priority <high|medium|low> \
  --plan "1. … 2. …"
```

- 拆票达标判据：**一个没参与讨论的执行 agent，拿到任务说明就能开始，并有办法证明自己做对了。**
- 并发准入：路径不相交 + 依赖满足 + 无共享资源冲突（DB / 测试账号 / 端口），否则串行。

### 3. 实现（对应 /build）

- 领票：`backlog task edit <id> -s "In Progress" -a @me`。
- 遵守 TDD：先写失败测试 → 确认失败 → 最小实现 → 重构 → 提交。
- **不重新定义需求，不因实现困难偷偷改验收标准。**

### 4. 验证（对应 /test）

- 跑测试，并对每个关键检查做反证（正确输入通过 → 构造缺陷应失败 → 恢复通过）。
- 逐条标记：`backlog task edit <id> --check-ac <n>`。

### 5. 审查（对应 /review）

- 触发独立 persona：`code-reviewer` / `security-auditor` / `test-engineer`，交叉审。
- **执行者不自批。**
- 通过：`backlog task edit <id> -l reviewed`；不过：打回 `-s "In Progress"` 并写清问题。

### 6. 验收与发布（对应 /ship）

- 真实界面 / CLI / API 走一遍，每条断言留证据（命令结果 / 截图 / 状态）。
- 复杂项目先做整体 Review：跨票影响、接口一致性、数据与状态流转、权限边界、性能、是否符合 CONTEXT.md。
- 全部 DoD 满足 + AC 全勾：`backlog task edit <id> -s "Done"`；周期清理 `backlog task archive <id>`。

## 硬规则

1. 绝不手改 `backlog/` 任务文件，一律 CLI / MCP / Web。
2. 事实源冲突时 `CONTEXT.md` 优先。
3. 关键检查必做反证，只看绿色退出码 / 全勾不可信。
4. 缺凭据 / 需人决策 → `-s "Blocked"` 并记录原因，不无限重试。
5. 多模型交叉审查降低盲区，但最终验收由人拍板。
