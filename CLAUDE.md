# 使用方式

在实现任何请求之前，必须执行以下默认流程：

### 第一步：grill-with-docs（需求拷问 + 术语对齐）
- 逐条追问，每次只问一个问题
- 给出你的推荐答案让我选择
- 对照现有文档（CONTEXT.md、ADR）校验术语一致性
- 如果问题可以通过查代码回答，先查代码再问
- 模糊术语必须当场澄清，更新 CONTEXT.md
- 重要决策写成 ADR
- 确认达到共识后再进入下一步

### 第二步：to-prd（产出正式文档）
- 不追问、不访谈，直接综合已有信息
- 识别需要构建的模块
- 按 PRD 模板产出文档并发布到 issue tracker

**只有完成以上两步，确认需求得到完整记录后，才能开始实现。**

## Agent skills

### Issue tracker

GitHub Issues。见 `docs/agents/issue-tracker.md`。

### Triage labels

默认 5 标签体系。见 `docs/agents/triage-labels.md`。

### Domain docs

单上下文模式，`CONTEXT.md` + `docs/adr/`。见 `docs/agents/domain.md`。
