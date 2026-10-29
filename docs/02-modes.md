# 02 · 两种模式操作手册

两种模式共用同一套约定。切换模式只增删厚度，不重写规则。

| | 轻量模式 | 完整模式 |
|---|---|---|
| 适用 | 单人、单里程碑、边界清楚、数周内交付 | 多人 / 多里程碑、多模块并行、跨系统集成、需权限与合规边界 |
| 特征 | 单 agent 直跑、门禁从简、单分支 | 里程碑组织 + 分层模型 + 独立审查 + 并发准入 + 反证 + worktree 隔离 |
| DoD | 3 项 | 5 项 |

---

## 一、轻量模式

### 0. 初始化（一次性）

```bash
npm i -g backlog.md          # 未安装时
backlog init "项目名"        # 生成 backlog/ 与 AGENTS.md
```

把本仓库的 `templates/AGENTS.md`、`templates/CONTEXT.md` 复制到项目根，把 `templates/backlog.config.yml` 中的 `definition_of_done` 与 `statuses` 合并进 `backlog/config.yml`。

`backlog init` 常用参数：

| 参数 | 说明 |
|---|---|
| `--agent-instructions <claude\|agents\|cursor\|none>` | 生成哪类指令文件；Cursor 与 Claude Code 都读 `AGENTS.md` |
| `--check-branches <true\|false>` | 单人单分支建议 `false` |
| `--zero-padded-ids <n>` | 需要 `TASK-001` 时设 `3` |

### 1. 需求澄清（`/spec`）

先用 `interview-me` 一次只问一个问题，逐轮追问：用户是谁、边界在哪、哪些明确不做、成功怎么判断、现有约束。

```bash
backlog decision create "首版只支持邮箱登录，不做第三方" -s accepted
```

术语、约束、被否方案写回 `CONTEXT.md`。

### 2. 拆票（`/plan`）

轻量模式只用一个默认里程碑，直接建任务：

```bash
backlog task create "实现邮箱登录" \
  -d "Touches: src/auth" \
  --ac "合法凭据返回 200 并下发会话" \
  --ac "错误密码返回 401 且不泄漏用户是否存在" \
  --plan "1. 建表 2. 实现校验 3. 补测试" \
  -l needs-review --priority high
```

### 3. 实现 + 验证（`/build` + `/test`）

```bash
backlog task edit TASK-1 -s "In Progress" -a @me
# TDD：先写失败测试 → 确认失败 → 最小实现 → 重构 → 提交
backlog task edit TASK-1 --check-ac 1 --check-ac 2
```

### 4. 审查（`/review`）

五轴自审 + 人工抽查。通过：

```bash
backlog task edit TASK-1 --add-label reviewed -s "Done"
```

> `-l` 会**替换**全部标签。追加门禁标签必须用 `--add-label`，否则里程碑标签会被清掉。

### 5. 验收（`/ship`）

真实跑一遍：网页用浏览器、API 用 `curl`、CLI 启动真实程序。**返回 200 但不符合目标 = 失败。**

### 6. 周期清理

```bash
backlog board                 # 终端看板
backlog task archive TASK-1   # 归档已完成（保留 ID 与依赖链，可 restore）
```

### 轻量模式三条红线

1. 决定进 `backlog decision`，不进聊天记录。
2. AC 必须可证伪。
3. 验收必须真跑一遍。

---

## 二、完整模式

### 0. 初始化

```bash
backlog init "项目名"
```

在 `backlog/config.yml` 中补齐：

```yaml
definition_of_done:
  - 测试通过且无回归
  - 所有验收断言已逐条 --check-ac 标记完成
  - 五轴审查通过（正确性/设计/安全/测试/体验）
  - 决定与文档已更新（backlog decision / docs）
  - 关键检查已做反证

statuses: ["To Do", "In Progress", "Blocked", "Done"]
labels: ["needs-review", "reviewed", "needs-test", "tested", "blocked"]
check_active_branches: true
remote_operations: true
```

> `Blocked` 不是默认状态，需显式写进 `statuses`；不想改状态列表时，退回用 `blocked` 标签表达。

建立版本基线：`CONTEXT.md` + `backlog/` + `docs/` + agent 配置目录全部纳入 Git。

### 1. 里程碑规划

```bash
backlog milestone add "M1 用户与权限"
backlog milestone add "M2 数据与报表"
```

### 2. 每里程碑澄清需求（`/spec`）

用 `interview-me` 逐轮追问 → 产出 `docs/spec-m1.md` → 关键决定写 `backlog decision create`。

### 3. 拆票（`/plan`）

```bash
backlog task create "实现登录 API" \
  -d "Touches: src/api/auth, src/db/user" \
  --ac "合法凭据返回 token" \
  --ac "无权限用户被 403 拒绝" \
  --dep TASK-1 \
  --plan "1. 建表 2. 实现 3. 测试" \
  -l m1,needs-review --priority high -m "M1 用户与权限"
```

**并发准入三条件**（全满足才并行，否则串行）：

1. `Touches` 路径不相交
2. `--dep` 依赖已满足
3. 无共享资源冲突（数据库 / 测试账号 / 端口）

### 4. 并行执行（分层模型 + worktree 隔离）

```bash
backlog task edit TASK-2 -s "In Progress" -a @executor-1
```

每个执行 agent 在独立 worktree 分支上工作，只读自己的任务与相关 spec，回传执行回执，**不宣布整项完成**。

### 5. 独立审查（`/review`）

触发 `code-reviewer` / `security-auditor` / `test-engineer` 交叉审：

```bash
backlog task edit TASK-2 --add-label reviewed      # 通过
backlog task edit TASK-2 -s "In Progress"          # 不过：打回并写清问题
```

### 6. 整体 Review

逐票审查解决局部问题，整体审查解决组合问题：跨票影响、接口一致性、数据与状态流转、权限边界、性能代价、是否符合 `CONTEXT.md`。

### 7. 验收（`/ship`）

覆盖完整用户验收条件，每条断言留命令结果 / 截图 / 状态证据，必要时固化为回归用例。

### 8. 状态可恢复

```bash
backlog task list --json                     # 机器可读状态导出，脚本 / CI 可消费
backlog task edit TASK-5 -s "Blocked"        # 缺凭据 / 需人决策：明确停下并写清原因
backlog task archive TASK-1                  # 已验收归档
```

---

## 三、分层模型分工

| 角色 | 落到谁 | 职责 | 硬边界 |
|---|---|---|---|
| 编排 | 主 agent / 人 | 拆里程碑、调度、判断优先级 | 不做实现细节 |
| 顾问 | 强模型 | 架构分歧 / 审查冲突时给第二判断 | 只在分歧时按需调用 |
| 执行 | 各 worktree 里的执行 agent | 按任务干活、跑检查、回证据 | 不改需求、不改验收标准 |
| 审查 | `code-reviewer` / `security-auditor` / `test-engineer` | 独立找行为错误 / 安全 / 并发 / 遗漏 | 不能审自己的代码 |

## 四、模式切换

- **轻量 → 完整**：补 `statuses`、`labels`、`check_active_branches`；把已有任务挂到新建里程碑；开 worktree 隔离。历史任务无需重建。
- **完整 → 轻量**：保留既有任务与决定记录，只停用多 persona 审查与 worktree，DoD 降为 3 项。

切换只影响后续任务的执行厚度，不追溯改写历史。
