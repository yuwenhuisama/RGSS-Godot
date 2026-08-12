# Medot Editor 演进路线图

> **状态**: 路线图文档，非执行计划。本轮仅交付分析与决策，不含任何实现。
> **产出方式**: 基于本会话对 `E:\Projects\Medot\editor` 与 `E:\Projects\RGSS-Godot` 的实证调查（explore / librarian / plan agents），所有现状断言均带 `file:line` 引用。
> **核心决策**: §3 给出 Godot 架构建议；§7 给出立即行动项；§8 列出需要你拍板的问题。
> **姊妹文档**: `ai-game-dev-environment.md`（已标记 38/38 完成，但其中若干模块从未接线，见 §2 Bucket C）、`rmva-template-support.md`、`unity-to-godot-migration.md`。

---
## §1 执行摘要

这套 authoring surface 已经不是原型，规模、测试和质量门都站得住，`59,716` source lines、`150` spec files、`1,311` tests passing，`eslint 0`、`vue-tsc 0`、build 0，且 `any` 已经 project-wide banned，以上基线见 §2 Bucket A，但这些数字本身也带着 `NEEDS VERIFICATION` 的标记。

RMVA event-command coverage 看起来几乎补齐了，约 `115` 个 codes 都有 handlers，真正的差距不在数量，而在 verification 只覆盖了 `65` 个 codes，见 §2 Bucket B。

现在最危险的不是“还有没有功能”，而是 fidelity 叙事本身失真。`exporter.ts:32` 创建的 `droppedFields` 从未被填充，`exporter.ts:48` 却据此计算 `roundTripEqual`，所以这个结果会在 export 已经坏掉时仍然报成功，`goldenCorpus.spec.ts:105` 也还是 `it.skipIf(!fixturesPresent)` 的 dormant test，见 §2 Bucket D。

AI agent 目前没有脑子，`DatabaseEditor.vue:14-19,256-258` 只会回退到返回 `'[]'` 的 stub，没有任何 LLM client 代码接上来，见 §2 Bucket C。

art generation 仍然是 greenfield，仓库里没有 ComfyUI、diffusion、`txt2img` 或 `img2img`，见 §2 Bucket D。

Godot 不是悬案了，§3 已经把它从“要不要用”改成“控制边界怎么定”，结论是先走 staged hybrid，以 external Godot process 为锚点，保留 Canvas 2D 和现有 `.rvdata2` export，延后 Godot-project exporter，见 §3.3 与 §3.5。

---

## §2 现状评估

当前产品的真实位置很清楚：authoring surface 已经很强，规模、类型、测试和 build gate 都站得住（NEEDS VERIFICATION: supplied scale and gate facts include no file:line citation），但 RMVA round-trip 的 headline fidelity guarantee 现在是假的，依据是 `exporter.ts:32` 和 `exporter.ts:48`。RMVA command handler 覆盖看起来接近完整，真正缺口不是 handler 数量，而是 verification 没有覆盖到全部路径，registry 在 `eventCoalesce.ts:2771-2877` 和 `eventStructural.ts:60-105`，oracle 覆盖在 `rgssOracle.spec.ts:396-907`。AI agent 的人机协作界面和 patch 流程已经成型，见 `src/agent/FillAgent.ts:8-18`、`src/agent/FillAgent.ts:102-111`、`src/agent/FillAgent.ts:205-275`、`src/components/agent/FillReviewPanel.vue:153-287`，但没有 LLM client，所以没有 brain，断点在 `DatabaseEditor.vue:14-19` 与 `DatabaseEditor.vue:256-258`；image generation 则是零实现，没有 ComfyUI、diffusion、txt2img 或 img2img（NEEDS VERIFICATION: supplied absence claim includes no file:line citation）。

### Bucket A: 已建成且已验证

Editor 本体已经是一个相当大的 Vue 3 + TypeScript + Vite + Tauri 产品，位置在 `E:\Projects\Medot\editor`，Rust backend 位于 `src-tauri`，规模是 59,716 source lines，不含 tests，测试侧有 150 spec files 和 20,940 test lines（NEEDS VERIFICATION: supplied scale facts include no file:line citation）。`rmva-support` plugin 也不是 demo，合计 21,506 lines，其中 components 8,797 lines，database 6,368 lines，nodes 6,051 lines（NEEDS VERIFICATION: supplied plugin line counts include no file:line citation）。当前质量门全部为 green：`eslint` 为 0，ignore list 为空，`vue-tsc` 为 0，1,311 tests passed，2 skipped，build exit code 为 0（NEEDS VERIFICATION: supplied gate results include no file:line citation）。`any` 已在 project-wide ban 下从 `src/` 完全清除，只剩 3 个 `eslint-disable` comments，且没有一个是为 `no-explicit-any` 服务（NEEDS VERIFICATION: supplied lint inventory includes no file:line citation）。

RMVA database import 覆盖已经落地。13 张 RMVA database tables 全部进入 import mapping，入口在 `importer.ts:27-40`，字段映射覆盖在 `mapper.ts:198-471`。Event command registry 也已经接近完整，所有 labeled RGSS3 command code，约 115 个，都有 handler，registry 范围在 `eventCoalesce.ts:2771-2877` 和 `eventStructural.ts:60-105`。所以当前 RMVA command 层的核心事实不是缺 handler，而是已有 handler 的 verification 覆盖不足。

`RGSS Oracle` 是当前代码库里最硬的资产。`rgssOracle.spec.ts:396-907` 通过真实 RMVA `Game.exe` 验证了 65 个 unique command codes，方式是向 `Scripts.rvdata2` 注入 test-runner，批量执行 command，再 diff global-state snapshots。这个 oracle 已经证明自己能抓到长期潜伏的问题：本次 session 它发现 2 个已经静默通过数月的 stale expectations，code `301` 会在 stack depth 1 push `Scene_Battle`，code `339` 会让 interpreter 继续运行（NEEDS VERIFICATION: supplied session finding includes no additional file:line citation beyond `rgssOracle.spec.ts:396-907`）。这里的价值很直接，verification 不是 mock，不是 snapshot 自嗨，而是拿真实 RMVA runtime 对行为做裁判。

AI agent 的前半段是真实存在并已接入 UI 的。`src/agent/FillAgent.ts:8-18`、`src/agent/FillAgent.ts:102-111`、`src/agent/FillAgent.ts:205-275` 会从 table schema 和 user intent 构造 prompt，调用 `llm.complete()`，解析 JSON rows，计算 DB patch，校验 integrity，并支持 `applyProposal()` 与 `rollback()`。`src/components/agent/FillReviewPanel.vue:153-287` 是真实 user-facing modal，支持 per-row accept/reject，通过 `SchemaForm` 做 in-place editing，显示 integrity badge，并提供 `Approve All` 与 `Cancel+rollback`。这套 human-in-the-loop review pattern 已经在 shipping surface 上成立。

Extension surface 也已经可用。`PluginManifest` 通过 `workspaces: [{id,label,icon,component}]` 暴露 workspace contribution，定义在 `plugins/types/index.ts:13-27` 与 `plugins/types/index.ts:69-81`。`App.vue:112-165` 会把 plugin components resolve 进 `WorkspaceRegistry`，而 registry 本身在 `workspace/WorkspaceRegistry.ts:6-58`。新增 workspace 不需要 core surgery，这是当前架构里清楚且干净的扩展点。

### Bucket B: 已建成但未验证

RMVA command implementation 的 coverage 高，但 verification 没跟上。仍有约 50 个 implemented codes 没有 oracle verification：`101`、`103`、`104`、`105`、`108`、`115`、`117`、`118`、`119`、`132`、`133`、`138`、`202`、`203`、`204`、`206`、`212`、`213`、`214`、`217`、`221`、`222`、`230`、`231`、`232`、`233`、`234`、`235`、`242`、`243`、`244`、`246`、`249`、`250`、`251`、`261`、`323`、`351`、`352`、`353`、`354`、`355`、`401`、`405`、`408`、`505`、`601`、`602`、`603`、`604`（NEEDS VERIFICATION: supplied missing-oracle list includes no per-code file:line citation）。这批 code 已经实现，但没有进入 `rgssOracle.spec.ts:396-907` 的真实 runtime 验证闭环。

Fuzz coverage 也不是完整的。14 个 implemented codes 不在 `eventFuzz.gen.ts:11-17` 的 generator 范围内：`103`、`104`、`281`、`282`、`283`、`331`、`332`、`333`、`334`、`335`、`336`、`337`、`339`、`405`。这意味着 fuzz 对这些实现没有形成输入压力。结合 oracle 未覆盖清单，当前 verification 的真实形态是局部强，整体不完整。

UI editability 里有多处已读入、已展示或已 passthrough 的能力，但编辑能力没有验证成完整 authoring loop。Event page metadata，包括 appearance conditions、graphics、trigger，是 read-only，page add/remove 被 deferred，位置在 `RmvaMapEventEditor.vue:14-16`。If-branch condition editing 是 read-only，branch restructuring 被 deferred，位置在 `eventStructural.ts:19-21`。Choices 限制为 4 options，malformed cases 走 passthrough fallback，位置在 `eventStructural.ts:287-297` 与 `eventStructural.ts:318-338`。`rmva.command` generic node 是 read-only passthrough，位置在 `nodes/RmvaCommandNode.ts:57`。`moveRoute` 仍把 nested move-command sublanguage 保持 opaque，范围在 `eventCoalesce.ts:1177-1253`。这些不是空白，但也不是完成的可编辑体验。

### Bucket C: 已建成但未接线/死代码

AI agent 最大的断点很明确：没有任何 LLM client implementation。`DatabaseEditor.vue:14-19` 与 `DatabaseEditor.vue:256-258` 只读取 `window.__medotLLM?.complete`，没有就 fallback 到返回 `'[]'` 的 stub。没有任何代码提供这个 bridge。结论是 agent architecturally complete，但 brain 没接上；当前用户看见的是一个有 review workflow 的 agent shell，不是一个能真正生成有效内容的 AI system。

`ToolRegistry` 已经有实现，但没进入 running app。`src/agent/ToolRegistry.ts:1-75` 提供 `register`、`call`、`list` tool registry，但引用只来自 sibling adapter modules 和 `adapters.spec.ts`（NEEDS VERIFICATION: supplied reference inventory includes no file:line citation for `adapters.spec.ts`）。这段代码是 dead code。资产 adapter 也一样，`src/agent/adapters/assetTools.ts:251-380` 已经有 `asset.removeBackground`、`asset.createSpriteSheet`、`asset.videoToGif`、`asset.chromaKey`，并且 path-guarded 到 project dir，但没有接进 app，所以也是 dead code。

Godot adapter 是树上最有价值的 dead code。`src/agent/adapters/engineTools.ts:16-21` 与 `src/agent/adapters/engineTools.ts:57-153` 通过 Tauri 调用 `plugin:godot-mcp|<op>`，暴露 `engine.create_scene`、`engine.add_node`、`engine.run_project`、`engine.get_debug_output`。`adapters/index.ts:28-30` 还确认了 forwarding 到 `godot-mcp`。但这条链没有接入 running app。它已经表达了正确方向：agent 能操纵 engine，而不是只写 JSON。但今天它没有产品路径。

Godot scene serialization 也只停在 helper 层。`lib/mapStitchSerialize.ts:162-178` 有一个未使用的 `godotSceneTscn()` helper，可以 emit `.tscn` text，但它没有被 export path 引用。当前 export path 不是 Godot project，而是 RMVA `.rvdata2`：`exporter.ts:21-49` 调到 `mapExport.ts:114-121`，再到 Tauri `dump_rvdata2`，位置是 `src-tauri/src/lib.rs:117-120`。

FrameRonin 的一部分能力也属于 built but not wired。服务配置存在，`medot.config.json` 与 Tauri `get_client_config` 暴露 `localhost:15678`，后者范围在 `src-tauri/src/lib.rs:1345-1455`，前端由 `services/serverConfig.ts:41-55` 加载。但 `services/FrameRoninWorkflows.ts:173-225` 的 `comprehensiveVideoProcess` 是 partially-stubbed，能够返回 empty `Blob`，且没有接入 app。这里不能被说成 generation pipeline，它只是一个未接线的 media processing workflow fragment。

### Bucket D: 完全未建成

RMVA export 的 headline fidelity guarantee 现在是假的。`exporter.ts:32` 声明 `const droppedFields = new Set<string>()`，但这个 set 从未被填充，整个文件没有任何 `.add()` call，只有 4 处 references，分别在 `exporter.ts:7`、`exporter.ts:32`、`exporter.ts:45`、`exporter.ts:48`。`exporter.ts:48` 用 `roundTripEqual: droppedFields.size === 0` 计算结果，所以 `roundTripEqual` 是 hardcoded true。只要 `droppedFields` 永远为空，产品就会无条件报告 round-trip success，包括 export 已经坏掉的时候。这个 fidelity guarantee 是 vacuous，不是工程事实。

真正的 RMVA round-trip corpus guard 也没有建成。`goldenCorpus.spec.ts:105` 的 real round-trip test 是 `it.skipIf(!fixturesPresent)`。这个 test 会导入 official SampleMap event pages，跑 `importEventCommands -> commandListToFlow -> flowToCommandList -> exportEventCommands`，再对 source 做 `marshalEqual`。但 `__fixtures__/` 只有 4 个文件：`Actors.rvdata2` 283B、`Map001.rvdata2` 1507B、`System.rvdata2` 1625B、`generate_fixtures.rb`（NEEDS VERIFICATION: supplied fixture inventory includes no file:line citation）。运行该 spec 的结果是 `1 passed | 1 skipped`（NEEDS VERIFICATION: supplied run result includes no file:line citation）。所以真正的 corpus test 是 dormant，从未在 CI 里保护过任何东西。

Database export 没有实现。`exporter.ts:42-49` 把 `dbFilesWritten: 0` hardcode 掉，当前 export 只写 maps，不写 database files。换句话说，import side 已经覆盖 13 张 RMVA database tables，位置在 `importer.ts:27-40` 与 `mapper.ts:198-471`，但 export side 对 database 没有对应实现。这不是 parity gap，而是缺失功能。

Godot runtime integration 没有建成。Editor 不会直接 spawn 或 embed Godot binary，没有找到相关实现（NEEDS VERIFICATION: supplied absence claim includes no file:line citation）。地图渲染今天是 HTML Canvas 2D，使用 offscreen layer canvases 和 manual compositing，位置在 `RmvaMapEditor.vue:47`、`RmvaMapEditor.vue:54-57`、`RmvaMapEditor.vue:155-177`、`RmvaMapEditor.vue:219-254`。Godot 没有参与 rendering。当前导出 artifact 也是 RMVA `.rvdata2`，路径是 `exporter.ts:21-49`、`mapExport.ts:114-121`、`src-tauri/src/lib.rs:117-120`，不是 Godot project。

`E:\Projects\RGSS-Godot` 本身确实是 Godot 4.6 .NET/C# project root，`project.godot:1-36` 设置了 `run/main_scene="res://Scenes/Boot.tscn"`。`README:1-7` 说明它是 RPG Maker VX Ace 的 RGSS3 runtime，从 Unity port 到 Godot 4.6。pure-Ruby RGSS layer 跑在 embedded `mruby` VM 上，`mruby-ext/` 会构建 4 个 native gems，`marshal`、`glob`、`regexp`、`zlib`，作为 DLLs 被 `RubyScriptManager.cs` P/Invoke。但这个 Godot runtime project 和 editor 当前 export/rendering path 没有形成产品闭环。

Image generation 完全没有建成。代码库里不存在 image generation code，没有 ComfyUI，没有 diffusion，没有 `txt2img`，没有 `img2img`（NEEDS VERIFICATION: supplied absence claim includes no file:line citation）。FrameRonin 不是 generation service，它只是 media processing：background removal、spritesheet assembly、video/gif conversion、chroma key。它的配置链是 `medot.config.json` 加 Tauri `get_client_config`，后者在 `src-tauri/src/lib.rs:1345-1455`，前端读取在 `services/serverConfig.ts:41-55`。把它当作 art generation 会误导 roadmap。

---

## §3 Godot 架构决策

## 3.1 决策边界

这里要决定的不是“要不要用 Godot”，而是 editor 与 Godot 的**控制边界**。`RGSS-Godot` 已经是 Godot 4.6 `.NET/C#` project，入口为 `res://Scenes/Boot.tscn`（`E:/Projects/RGSS-Godot/project.godot:11-15`）；其 pure-Ruby RGSS layer 运行于 embedded `mruby`，render layer 已落在 `SubViewport` 与 `.gdshader` 上（`E:/Projects/RGSS-Godot/README.md:3-7`）。四个 native gems 由 `RubyScriptManager.cs` P/Invoke（`E:/Projects/RGSS-Godot/mruby-ext/AGENTS.md:1-11`）。因此 Godot engine 资产已经存在，真正悬而未决的是：editor 应生成它、驱动它，还是把它嵌进自己的 authoring loop。

同时必须保护现有 editor 的事实边界。RMVA map editor 目前以 HTML Canvas 2D、四个 offscreen canvas 和手工 compositing 工作（`E:/Projects/Medot/editor/src/plugins/rmva-support/components/RmvaMapEditor.vue:47-57`、`E:/Projects/Medot/editor/src/plugins/rmva-support/components/RmvaMapEditor.vue:147-177`、`E:/Projects/Medot/editor/src/plugins/rmva-support/components/RmvaMapEditor.vue:218-254`）；正式 export 则重建 `RPG::Map` graph 后调用 Tauri `dump_rvdata2`（`E:/Projects/Medot/editor/src/plugins/rmva-support/exporter.ts:21-49`、`E:/Projects/Medot/editor/src/plugins/rmva-support/mapExport.ts:99-120`、`E:/Projects/Medot/editor/src-tauri/src/lib.rs:117-120`）。这两条链不应因“采用 Godot”而被无意改写。

## 3.2 四种关系的比较

| 选项 | 成本 | 解锁什么 | 关闭什么 / 后续代价 | 与现有资产的关系 | 主要风险 |
|---|---|---|---|---|---|
| **(a) Godot as export target** | 需要定义 editor model → Godot scenes/resources/scripts 的完整、可版本化 compiler，并负责 asset import、project template、增量 export、错误定位与 compatibility tests；不是“输出一个 `.tscn`”就完成。 | 产出可脱离 RMVA 的 Godot project；用户可进入 Godot editor 继续开发，产品真正拥有第二个 delivery target。 | 一旦承诺生成可编辑 project，schema 与 node topology 会成为外部 contract；round-trip、用户手改保护、Godot version migration 都会使以后更换映射困难。双 target 的每个 feature 都要回答 `.rvdata2` 与 Godot 两套语义。 | 不应替换现有 `.rvdata2` 链，而应成为 sibling exporter。已有 `godotSceneTscn()` 能生成简单 `Node2D`/`Sprite2D` scene（`E:/Projects/Medot/editor/src/lib/mapStitchSerialize.ts:162-178`），且 Map Stitch UI 已调用它保存 `.tscn`（`E:/Projects/Medot/editor/src/components/panels/MapStitchPanel.vue:543-555`）；但它不在 RMVA export path 中，不能证明 game project export 已经存在。`RGSS-Godot` 可作为 template/runtime，而非重新实现 engine。 | 最大风险是“看起来能 export、实际语义不等价”：event timing、resource UID、Ruby/C# boundary、custom scripts 与 Godot import behavior 都可能失真。目标 project 是 disposable build artifact 还是 user-owned source project 也属 `NEEDS VERIFICATION`。 |
| **(b) Godot as external process** | 先把已有 dead adapter 接进实际 `ToolRegistry` lifecycle，再补 sidecar discovery、project binding、process lifecycle、timeout/cancel、log/result protocol 和 smoke tests。四个 operations 已存在：`engine.create_scene`、`engine.add_node`、`engine.run_project`、`engine.get_debug_output`（`E:/Projects/Medot/editor/src/agent/adapters/engineTools.ts:57-153`）；当前 production search 只见 adapter barrel 的注册函数，而实际调用覆盖在 tests（`E:/Projects/Medot/editor/src/agent/adapters/index.ts:35-51`、`E:/Projects/Medot/editor/src/agent/adapters/adapters.spec.ts:126-180`）。所以成本是 wiring + hardening，不是 greenfield，但 installed Tauri plugin/sidecar 是否可用仍为 `NEEDS VERIFICATION`。 | 一键 preview/run、采集 debug output、以 `godot --headless` 作为 CI/regression host，以及让 AI tools 操作真实 engine。runtime 已文档化 headless boot 与 GUT invocation（`E:/Projects/RGSS-Godot/README.md:15-27`）。 | 不会自动提供“可交付 Godot project export”，也不会让 authoring viewport 与 runtime 像素级同源；跨 process 调试比 in-process API 粗。若先把 protocol 稳定下来，反而不会关闭未来 (a)，其 run/test contract 可被 (a) 复用。 | process 泄漏、并发 run、路径与 Godot version 差异、headless 和 GPU render 差异、sidecar error 丢失。必须把“命令已发送”和“游戏达到可断言状态”区分开。 |
| **(c) Godot embedded as rendering backend** | 需要替换 Canvas painting、offscreen caching、pointer hit-test、overlay/grid、zoom、asset loading，并设计 Tauri webview 与 embedded native Godot surface 的窗口、input、focus、DPI、lifecycle 和 packaging integration；这是 editor rendering subsystem rewrite。 | authoring preview 可以与 engine renderer 更接近，并可能直接复用 Godot scene/render primitives。 | 会主动淘汰现有 Canvas 2D 优化与测试面；editor UX 被 Godot frame lifecycle 和 embedding constraints 绑定。以后升级 Godot 或恢复 browser-native editor 都更难。 | 对 `.rvdata2` export 没有直接帮助；对 `RGSS-Godot` 也不等于复用其 gameplay semantics，因为 authoring canvas 仍需一套编辑态 selection/overlay model。runtime 的 render convention 已专门规定 postprocess chain、single `CanvasLayer` 和 RMVA `z_index`（`E:/Projects/RGSS-Godot/docs/render-conventions.md:5-12`、`E:/Projects/RGSS-Godot/docs/render-conventions.md:31-39`），把它嵌入 editor 会把 runtime-specific constraints 带进 authoring surface。 | 最高风险是投入巨大却只得到“另一个 map renderer”；native embedding feasibility、跨平台窗口模型与 Tauri 支持均为 `NEEDS VERIFICATION`。更严重的是 visual similarity 可能掩盖 gameplay/timing 不等价。 |
| **(d) staged hybrid** | 第一阶段承担 (b) 的 wiring 与 test harness；只在 evidence gate 通过后承担 (a)；Canvas renderer 保持不动。需要额外维护清晰 boundary 与阶段准入指标。 | 先获得真实 Godot preview/headless regression，后续仍保留第二 export target 的选项；风险和价值可以逐阶段验证。 | 短期内接受 authoring render 与 runtime render 两套实现，无法宣称 WYSIWYG；若缺少 gate，hybrid 容易变成三个半成品。 | `.rvdata2` 继续是 RMVA compatibility target；`RGSS-Godot` 是 external runtime/test host；未来 Godot project exporter 是独立 sibling。Godot 的 cooperative Fiber pump 本来就由 `_Process` 驱动（`E:/Projects/RGSS-Godot/docs/fiber-frame-loop-proposal.md:8-26`），external process 保持了这一 engine-owned frame boundary。 | 架构漂移与重复模型。缓解方式是规定唯一 canonical editor model、两个显式 exporter、一个 versioned run/test protocol，而不是让 preview 反向写 editor state。 |

## 3.3 推荐：以 (b) 为锚点的 staged hybrid

**明确建议：现在选择 (d)，但第一阶段只实施 (b)；保留 Canvas 2D authoring renderer 与现有 `.rvdata2` exporter，(a) 仅作为被需求证据触发的可选第二 target，并在可预见范围内拒绝 (c)。工作量判断：第一阶段为 Short；完整 (a) 为 Large；(c) 为 Large 且当前收益不足。**

推理链如下：

1. vision 要求的是“editor 是 AI-driven modern game development editor，Godot 是 engine”，这首先要求 editor 能可靠地**命令真实 engine 并解释结果**，不要求 engine 住进 editor window。已有 adapter 已把 tool call 转成 `plugin:godot-mcp|<op>`（`E:/Projects/Medot/editor/src/agent/adapters/engineTools.ts:13-21`），且 `projectPath` 在注册时绑定并传给 Godot（`E:/Projects/Medot/editor/src/agent/adapters/engineTools.ts:52-77`）。因此 (b) 是最短的 identity proof。
2. vision 同时要求 automated game regression testing。external process 能直接利用已有 `godot --headless` surface（`E:/Projects/RGSS-Godot/README.md:15-27`），而 (a) 只有在 export correctness 已经建立后才可能提供同等价值；(c) 则几乎不改善 regression observability。
3. (b) 不碰两条高价值既有链：Canvas authoring 与 `.rvdata2` export。它把失败域限制在 process integration，而不是同时改 editor interaction、rendering semantics 和 delivery artifact。
4. (a) 的 latent enabler 只证明“能写一些 `.tscn` 文本”，不能证明完整 game semantics。没有真实 non-RMVA consumer、editable-output contract 与 acceptance corpus 前，双 target 成本先于价值出现。
5. (c) 买到的是 renderer proximity，不是 semantic equivalence。现有 runtime 甚至仍在处理 `Graphics.update` frame-barrier compatibility，文档指出错误实现可导致 animation 一帧跑完或 loop hang（`E:/Projects/RGSS-Godot/docs/fiber-frame-loop-proposal.md:75-105`）；把 Godot surface 嵌进 editor 并不能解决这类 engine behavior，反而会牺牲成熟 authoring surface。

阶段 gate 应可证伪：Phase 1 仅交付 production wiring、preview/run、structured logs、headless smoke test 与可靠 cancellation；Phase 2 才增加 state-snapshot regression harness；只有出现真实用户要求“脱离 RMVA、在 Godot editor 继续维护”，并且一个 representative project 能稳定生成、运行、定位 export error，才立项 (a)。任何阶段都不以 (c) 为默认终点。

## 3.4 自动化回归测试的技术路径

### Verdict：推广 oracle 的原则，不照搬 RMVA 注入机制

现有 RGSS oracle 最值得复用的是**职责分离**：engine side 只是 executor 与 state snapshot producer，typed expectations 和 structured diff 留在 TypeScript。当前 harness 把 runner 插到 `Scripts.rvdata2` 的 `Main` 前（`E:/Projects/Medot/editor/scripts/provision-rgss-oracle.rb:291-298`），在一个 process 内反复重建 game objects、驱动 interpreter、最后写 JSON（`E:/Projects/Medot/editor/scripts/provision-rgss-oracle.rb:220-270`）；TypeScript 定义完整 `OracleSnapshot` contract（`E:/Projects/Medot/editor/src/plugins/rmva-support/database/rgssOracle.spec.ts:16-105`），并用 `toEqual` 给出 structured diff（`E:/Projects/Medot/editor/src/plugins/rmva-support/database/rgssOracle.spec.ts:388-393`）。65 个 command-code coverage 集中在同一个 suite（`E:/Projects/Medot/editor/src/plugins/rmva-support/database/rgssOracle.spec.ts:396-907`）。

应把这个模式推广为 **Godot headless state oracle**，但不能声称可以原样移植。`Scripts.rvdata2` injection 是 RMVA-specific；Godot + `.NET` + `mruby` 应从何处注入 cases、何时 reset globals、如何等待 Fiber/frame、如何稳定导出 snapshot，当前没有已确立接口，全部标记为 `NEEDS VERIFICATION`。第一项 spike 应只回答这些问题，并证明 timeout、crash、Ruby exception 与 malformed snapshot 能被 TypeScript 区分。若无法在同一 process 安全重置 global state，则宁可 one-case-per-process，牺牲速度换 isolation，不能假定 RMVA 的 batching property 自动成立。

### 四种机制各自负责什么

**1. State oracle：主干。**最适合 deterministic semantics：switch/variable、inventory、event branch、scene transition、save/load graph、Ruby/C# binding result、固定 frame 后的位置与 interpreter termination。它能抓到“值对但类型错”“branch 走错”“global state 泄漏”“等待永不结束”等错误。它抓不到 sprite 少 1 px、shader tone 错、font/layout 差异、短暂 flicker，也不能判断手感；若 snapshot 点选错，还可能把 timing regression 压扁成相同终态。

**2. Screenshot / pixel diff：窄而必要的 visual contract。**用于固定 asset、固定 viewport、固定 frame 的 tile compositing、`z_index`、fade/transition、shader 与 UI rendering。它能抓 state oracle 看不到的 clipping、sampling seam、wrong layer、color drift；但 font rasterization、GPU/driver、platform color 与 nondeterministic particles 会造成 false positive，headless renderer 也不当然等于玩家 GPU，属 `NEEDS VERIFICATION`。不应拿 pixel diff 证明 event semantics。

**3. Input replay：少量 end-to-end journey。**适合验证 boot → title → new game → movement → interaction → save 这类 wiring，以及 focus、mapping、scene availability。它能抓“按钮存在但不可操作”“input 到错 viewport”“某帧丢输入”等 integration fault；但 replay 对 frame pacing、focus 与异步 loading 敏感，失败常发生在症状点而非 root cause。固定输入序列也不能证明“feel”，例如 acceleration 虽变差但最终位置相同；需要记录 checkpoint/state，而不是只判进程退出码。

**4. In-engine unit tests（GUT / GoDotTest style）：底层补充。**runtime 已启用 GUT plugin（`E:/Projects/RGSS-Godot/project.godot:30-32`），README 也给出 headless GUT command（`E:/Projects/RGSS-Godot/README.md:23-27`）。它适合 C# / GDScript-adjacent pure logic、resource parser、node lifecycle 与小型 binding contract，失败定位最快；但 mock node tree 不能证明完整 `mruby` globals、真实 exported editor data 或跨 frame gameplay。GoDotTest 是否适配当前 Godot 4.6 `.NET` stack 为 `NEEDS VERIFICATION`，不应在 roadmap 中预选 framework。

因此测试金字塔应是：大量 in-engine unit tests 保底层，state oracle 覆盖跨 Ruby/C#/Godot 的 deterministic behavior，少量 input replay 覆盖 journey，再用一小组受控 pixel golden 保护 render conventions。四者是互补层，不应选一个取代其余三个；其中 state oracle 是 regression pillar 的核心，因为它最契合 typed expectations、structured diff 和 AI 可诊断输出，但 visual、timing 与 feel 必须由其他机制承担。

## 3.5 决策记录

采纳：external Godot process 作为 preview、run 与 headless regression host。保留：Canvas 2D 为 authoring renderer，RMVA `.rvdata2` 为当前 compatibility export。延后：Godot-project exporter，等待真实 consumer 与 editable-output contract。拒绝：在可预见 horizon 内把 Godot embedded 为 editor rendering backend，因为其 rewrite 成本、平台风险与 lock-in 显著高于可验证收益。

---

## §4 分阶段路线图

本路线图采用“先取得可信获客入口，再兑现产品身份，最后验证差异化”的顺序。所有阶段共用一条不可豁免的 Definition of Done：**单元测试通过不等于完成**。`.sisyphus/plans/ai-game-dev-environment.md` 曾以 38/38 COMPLETE 宣称 `ToolRegistry`、FrameRonin / godot-mcp adapters 与 end-to-end wiring 已完成，但 `ToolRegistry.ts:1-75`、`assetTools.ts:251-380`、`engineTools.ts:16-21,57-153` 在 `src/agent/` 外没有 production consumer。故每个阶段都必须通过“接线验收”：指出真实 production import/caller，从用户可达入口执行一次真实行为，并观察到 UI、工程文件、外部 process 或 service 的可见结果；mock、孤立 adapter test 或绿色 unit suite 均不能替代该证据。

### Phase 1（M）：修复 RMVA 保真度真相

**目标。** 先消除会误导用户与后续 agent 的两个 fidelity defect：无条件为真的 `roundTripEqual`（`exporter.ts:32,45,48`），以及固定为零的 `dbFilesWritten`（`exporter.ts:42-49`）。本阶段是 pillar #1 的第一段，也是获客前必须建立的信任底座。

**进入条件。** 当前基线可复现：eslint 0、`vue-tsc` 0、1,311 tests passed + 2 skipped、build exit 0，且 `any` 继续 project-wide 禁用；具体 gate command 名称为 `NEEDS VERIFICATION`。

**工作项。** 1）真实 corpus guard：在改 `exporter.ts` 前，先启用 `goldenCorpus.spec.ts:105`，补充合法来源的 representative fixtures，并亲眼看到 `vitest run goldenCorpus.spec.ts` 因现有丢失或差异而**诚实失败**；一个仍会 skip 或无论实现如何都通过的 test 不算开始。随后定义允许 normalization 与必须保留字段的可审计 contract。2）dropped-field accounting：先加入针对已知不可表达字段的 exporter test，断言 `roundTripEqual === false` 且 `droppedFields` 含精确路径，并确认它在现状下变红；再让 `exporter.ts:32,45,48` 从实际 diff 收集结果。3）database export：先为 13 张已导入表建立 import → edit → export → reload 的 golden test，断言非零 `dbFilesWritten` 和关键字段语义等价，并确认因 `exporter.ts:42-49` 的 0 而失败；再实现与 map export 同级的 DB 输出。corpus 的许可、规模与 CI 可运行性均为 `NEEDS VERIFICATION`。

**依赖顺序。** 1 先固定裁判；2 与 3 使用同一差异模型，先完成 2 的报告 contract，再让 3 汇入报告。**可并行部分。** fixtures 的许可/采集可与 DB mapping inventory 并行；红测建立后，map/event diff 与各 DB table serializer 可并行，但最终必须合流到同一 export report。

**退出条件。** `vitest run goldenCorpus.spec.ts` 必须显示零 skipped、真实 fixtures 全绿；DB round-trip suite 显示 13/13 tables 写出并 reload；项目全量 lint、typecheck、1,311+ tests 与 build 均为 exit 0。接线验收必须从 shipping Export UI 导出一个含地图和数据库修改的工程，重新导入后得到可解释的零差异或明确 `droppedFields`，并验证 production UI 实际展示 `roundTripEqual` 与 `dbFilesWritten`，而不是只直接调用 exporter。

### Phase 2（L）：把 RMVA 做成生产级获客入口

**目标。** 在扩大格式面之前，把 RMVA 的 event verification 与可编辑闭环做深，使“可导入、可编辑、可安全导出”成为可测承诺，而非 handler 数量宣传。

**进入条件。** Phase 1 的 corpus、差异报告和 DB export 连续通过，且不再存在 vacuous success。

**工作项。** 1）oracle coverage：对约 50 个尚未验证的 implemented codes，**每碰一个 handler 前**先在 `rgssOracle.spec.ts:396-907` 写其真实 RGSS expectation，并观察现有实现变红或明确证明测试能被故意 mutation 打红；然后才修 handler/expectation。2）fuzz breadth：先为 `eventFuzz.gen.ts:11-17` 外的 14 个 codes（103、104、281–283、331–337、339、405）写 coverage assertion，确认它因缺失生成样本而红，再扩 generator 与 shrink diagnostics。3）authoring loop：针对 page metadata（`RmvaMapEventEditor.vue:14-16`）、if restructuring（`eventStructural.ts:19-21`）、generic command（`nodes/RmvaCommandNode.ts:57`）及 opaque `moveRoute`（`eventCoalesce.ts:1177-1253`），每项先增加 UI edit → serialize → RGSS/corpus round-trip 的失败 test，再逐项开放编辑；choices 的大于四项与 malformed contract 为 `NEEDS VERIFICATION`。

**依赖顺序。** oracle contract 在前，fuzz 扩面其次；只有对应 command 的 oracle 与 fuzz 都可信后，才开放该 command 的结构编辑。**可并行部分。** 独立 code family 的 oracle cases、generator cases 和不同 UI feature 可由不同工作流并行，但同一 code 必须遵守 oracle → fuzz → UI 的顺序。

**退出条件。** oracle command matrix 对约 50 个缺口归零，14 个 fuzz 缺口归零；相关 `vitest` suites、full test、lint、typecheck、build 全绿。接线验收要求用户在真实 map event editor 修改至少一项 page metadata、if、generic command 与 `moveRoute`，导出后由真实 `Game.exe` oracle 或 corpus 验证行为，并可从 UI 看见失败差异；production consumer 与用户行为必须留作 release evidence。

### Phase 3（M）：接通 external Godot 运行与回归宿主

**目标。** 按 §3 的 staged hybrid，将已有 dead godot-mcp bridge 接入产品：Godot 作为 external process 提供 preview、run、structured logs 与 headless smoke；Canvas 2D 继续作为 authoring renderer，`.rvdata2` 仍是当前 compatibility export，不引入 embedded renderer。

**进入条件。** Phase 1 已建立可信 export artifact；目标机器的 Godot 4.6、Tauri plugin/sidecar discovery 与 `plugin:godot-mcp` 可用性均完成 `NEEDS VERIFICATION`。

**工作项。** 1）production wiring：在解除 `engineTools.ts:16-21,57-153` dead 状态前，先写从真实 workspace command 到 `ToolRegistry` 再到 adapter 的 integration smoke，并确认它因零 production consumer 而红。2）lifecycle：先写启动、timeout、cancel、并发拒绝、crash 与 Ruby exception 的 process tests，确认至少 cancellation 在现状下失败，再实现 versioned result/log protocol。3）headless smoke：先让 CI 执行 `godot --headless --path . --quit-after 30` 并断言 boot marker；缺 binary、hang 与非零退出必须产生不同失败，测试先红后接入。4）state oracle spike：先写 TypeScript contract test 区分 timeout、crash、malformed snapshot 和 assertion diff，再验证 Godot + mruby 的 injection/reset 点；安全复用 process 与 one-case-per-process 的选择为 `NEEDS VERIFICATION`。

**依赖顺序。** wiring → lifecycle → headless smoke → state oracle；不可用 state oracle 掩盖不可靠 process control。**可并行部分。** protocol schema、Godot-side snapshot spike 与 UI run panel 可并行，但 UI 只能在真实 adapter 可调用后转绿。

**退出条件。** integration suite 与 headless command exit 0，cancel 后无残留 process，debug output 在 UI 可见。接线验收要求用户从 shipping workspace 启动 `E:/Projects/RGSS-Godot`，看到 boot/log，停止运行，并使一个刻意失败的 headless case 在 editor 中呈现 structured diff。任何仅在 `adapters.spec.ts` 通过的实现不得出阶段。

### Phase 4（L）：交付有脑、有审查的 editor agent

**目标。** 兑现 pillars #2/#3 的产品身份：先建立真实 LLM client，再让 agent 通过 proposal-first workflow 调用已接线工具；复用 `FillReviewPanel.vue:153-287` 的 accept/reject/edit/rollback，不允许默认直接写工程或运行高影响命令。

**进入条件。** provider、BYOK/托管/local、隐私、预算、审计与 key ownership 已形成产品决定；否则保持 blocked，因为 `DatabaseEditor.vue:14-19,256-258` 的 `'[]'` stub 不是 client。

**工作项。** 1）LLM vertical slice：先写 UI integration test，要求真实配置下发出一次可观测 completion、无配置时显示 actionable error；确认它因 `window.__medotLLM` stub 而红，再实现正式 client contract。2）review governance：先写拒绝不落盘、批准才落盘、rollback 恢复原状态的 E2E test，并 mutation 验证其能失败，再把 database、scene、test actions 统一为 proposal。3）tool execution：在让 agent 消费 `ToolRegistry.ts:1-75` 前，先写“用户指令 → model tool call → review → `engine.run_project` → structured result”的 failing integration test；随后只开放有路径/命令 allowlist、diff 与审计的 tools。

**依赖顺序。** client → review contract → tool execution；不能继续先造 adapters。**可并行部分。** provider adapter、审计存储和 review UI 可并行，待 client contract 稳定后汇合。

**退出条件。** provider contract、governance 与 tool E2E 全绿；全量质量门 exit 0。接线验收由用户输入真实意图，看到非空 proposal，编辑并拒绝一次确认无副作用，再批准一次并观察工程变更或 Phase 3 Godot run；日志须证明真实 production consumer，而非 test-only import。

### Phase 5（L）：建立受约束的美术生成流水线

**目标。** 启动 pillar #4。**优先级已由用户确定：前期以接商业生图接口（托管 API，BYOK）为首要任务**；自部署 ComfyUI 为后续能力，不阻塞本阶段。以 `ImageGenerationProvider` contract 按 §5.4 的能力分层建模，生成结果必须经 recipe、后处理、验证、review 才能导入。现有 FrameRonin（`services/serverConfig.ts:41-55`）仅定位为 post-processing，不冒充 generation。**图块集不走生成路线**，改为「AI 生成基础图块 + 程序化扩展」（见 §5.4）。

**进入条件。** Phase 4 的 client、权限、审计与 review contract 可复用；**BYOK 模式已确定**（用户在编辑器内填写自己的 secret key，费用与配额由用户自理，我方不转售），故 provider 费用责任明确。自部署相关的 ComfyUI 环境支持不作为本阶段准入条件。

**工作项。** 0）**现成方案评估（前置）**：先评估 PixelLab 等既有服务能否直接承担生成（见 §6 生态调研结论），并选定后处理库而非自研；只有确认不可用才自建对应环节。1）provider slice：先写 contract tests，并按 §5.4 的**能力分层**建模（`supportsStructuralControl` / `supportsReferenceConditioning` / `supportsSeed` / `supportsAlpha`），让 Tier 1 布局锁定与 Tier 2 参考引导各有至少一个真实 provider 通过；ComfyUI 作为可选后端而非硬需求。2）FrameRonin wiring：先写真实 service integration，要求非空 image/blob 与可取消失败；确认 `assetTools.ts:251-380` 零 consumer 或 `FrameRoninWorkflows.ts:173-225` 空 `Blob` 使其失败，再接 background removal、sheet assembly 等后处理。3）asset recipe：先为角色 3x4/12 帧、尺寸、alpha、重复帧和导入路径写拒绝性 tests，再实现 machine-checkable validation；tile/autotile 精确规则为 `NEEDS VERIFICATION`。4）import review：先写 reject/rollback 不污染 project、approve 才新增 asset 的 E2E red test，再复用 Phase 4 review。

**依赖顺序。** provider → FrameRonin → recipe validation → review/import。**可并行部分。** hosted 与 ComfyUI adapters、各 recipe validator 可并行；未通过统一 contract 的 provider 不进入 UI。

**退出条件。** contract、真实 service、recipe 与 import E2E 全绿。接线验收要求用户生成一个角色 sheet，看到 provider/成本/recipe metadata，经真实 FrameRonin 后处理，故意提交错误 grid 时被阻断，批准合格版本后在项目 asset browser 可见。只有 mock 图片通过不算完成。

### Phase 6（XL）：以 AI canvas 验证差异化

**目标。** 启动 pillar #5，交付**素材关系 DAG 画布**（规格见 §5.5）：节点为素材产物、边为参考关系、套为标签视图；通过 plugin workspace 扩展点（`plugins/types/index.ts:13-27,69-81`、`App.vue:112-165`、`workspace/WorkspaceRegistry.ts:6-58`）接入。**成本判断已下调**：交互层复用既有 Vue Flow 节点图（`EventLogicEditor.vue` 已跑通并有测试覆盖），本阶段主要新增的是节点产物语义（多候选、陈旧标记、溯源）与落盘事务，而非自研画布。

**进入条件。** Phase 5 的代表性 corpus 已证明单项资产 pipeline 可用；整套一致性阈值、人工审核容量与可接受重生成成本为 `NEEDS VERIFICATION`。

**工作项。** 1）workspace wiring：先写 plugin contribution 到可导航 canvas 的 UI integration test，确认在 workspace 未注册时变红，再接入 production registry。2）production graph：先写 save/reload、lineage、rerun 与版本选择的 failing model tests，再实现可追溯 DAG；**必须覆盖三条 §5.5 特有语义**——节点持有多候选并可切换选中项、上游变更后下游标记 stale 而非自动重跑（防止丢失不可复现的满意结果）、落盘为复制且记录来源。另需实现套装清单的**对账**：引用失效时标记而非静默消失。3）落盘冲突检测：先写失败测试断言同名素材放置时能区分「覆盖自有文件」与「遮蔽 RTP 素材」两种情况（依据 `graphicResolver.ts` 的扁平、大小写不敏感、项目优先索引），再实现放置 UI。4）**既有功能节点化**：逐个把 `lib/` 纯函数（`spriteSheetBuild` / `spriteSheetAdjust` / `scatterSlice` / `superSplitTransparent` / `imageMatte` / `imageConvert` / `gifFrames`）包装为变换节点；**每个节点先写「该节点输出与对应旧面板输出等价」的失败测试**，通过后才算该能力迁移完成。既有 8 个 lib spec 是这批测试的基线，不得回归。5）**旧面板下线（并存后执行）**：仅当能力对齐清单全部勾选、且画布路径经真实用户操作验证后，才从 UI 移除对应面板；`AudioCompressPanel` 与 `MapStitchPanel` 的工程产物导出部分**不在下线范围**。3）set generation：先以角色 12 帧和 representative tileset corpus 写整套通过率、风格漂移与部分拒绝的 acceptance test，观察当前 pipeline 未达标；随后才增加 reference/seed/批量编排。4）set import：先写“部分批准、整套回滚、无孤儿文件”的 red E2E，再实现 transaction-like import。

**依赖顺序。** workspace → graph → set generation → transactional import。**可并行部分。** graph persistence、canvas interaction 与一致性 metrics 可并行；但没有 corpus gate 不得宣称“一键整套可用”。

**退出条件。** canvas E2E 可重载并复现 lineage，代表性 corpus 达到预先书面约定阈值，具体数值为 `NEEDS VERIFICATION`。接线验收要求用户从真实 workspace 创建集合、运行 generation/post-process、拒绝部分结果、重跑并批准导入，随后在项目中找到完整且无孤儿的资产；production telemetry 须显示真实 provider 与 import consumer。

### Phase 7（可选，XL）：证据触发的目标扩展

**目标。** 只在核心路线成熟后评估两个独立选项：Godot project export target，以及 RMXP/RMVX generalization；二者不捆绑，也都不改变“拒绝 embedded Godot renderer、保留 Canvas 2D”的决策。

**进入条件。** Godot export 必须先同时出现真实用户要求“脱离 RMVA 并在 Godot editor 继续维护”、明确 user-owned editable-output contract、稳定 canonical model，以及 representative project 能重复生成、运行并把 export error 定位回源模型；还须有 target matrix 证明双 exporter 维护成本可承受。RMXP/RMVX 必须先满足 RMVA corpus/oracle 持续全绿、地图与 13 张 DB 的可审计 round-trip、共享抽象不会掩盖版本语义、存在真实需求及合法测试工程；格式差异均为 `NEEDS VERIFICATION`。

**工作项。** 1）Godot exporter evidence spike：先写 representative project golden，要求 deterministic generation、headless boot、state oracle 与用户手改保护，并确认现有 `godotSceneTscn()`（`mapStitchSerialize.ts:162-178`）不足而红；只有该 test 可稳定转绿才立项 sibling exporter。2）RMXP/RMVX feasibility：每个版本先用合法 corpus 写 import → edit → export → native runtime oracle 的 failing compatibility suite，再设计共享 abstraction；禁止先抽象后找证据。

**依赖顺序。** 两项各自先需求/evidence gate，再 spike，再立项；均不得阻塞 Phase 1–6。**可并行部分。** 两个 feasibility track 可彼此并行，但不得共享尚未由各版本 corpus 证明的 serializer semantics。

**退出条件。** 可选项只有在各自 representative E2E、full quality gates 与真实用户试点都通过后才从“实验”升级为 target。接线验收分别要求用户打开并继续编辑生成的 Godot project 后成功 headless run，或在对应原生 RMXP/RMVX runtime 中运行往返工程；仅生成文件、unit tests 通过或 adapter 被注册均不算交付。

---

## §5 五大支柱逐项分析

## 5.1 RMVA 生产级兼容插件

### 现状

`rmva-support` 已有 21,506 行，13 张数据库表均已建立导入映射，入口见 `importer.ts:27-40`，字段映射主体见 `mapper.ts:198-471`。事件命令注册表也基本完整，约 115 个 code 均已有处理器，相关注册与结构化处理见 `eventCoalesce.ts:2771-2877` 和 `eventStructural.ts:60-105`；因此“补齐缺失 handler”不是当前主路径。已有 RGSS oracle 使用真实 `Game.exe` 验证 65 个 code，覆盖和断言见 `rgssOracle.spec.ts:396-907`，且本轮已发现两个月前遗留的过时预期。

但现有导出链路仍只导出 `.rvdata2`：`exporter.ts:21-49` 调用 `mapExport.ts:114-121`，再进入 Tauri 层 `src-tauri/src/lib.rs:117-120`。该能力应被视为 RMVA 兼容插件的基础，而非已经满足“生产级往返保真”的证明。

### 缺口

最关键的缺口是保真度证据失效。`exporter.ts:32` 初始化 `droppedFields`，却没有任何 `.add()` 调用；`exporter.ts:48` 据此计算 `roundTripEqual: droppedFields.size === 0`，实际将 `roundTripEqual` 硬编码为真。更严重的是，真实 golden corpus 测试在 `goldenCorpus.spec.ts:105` 使用 `it.skipIf(!fixturesPresent)`，而 `__fixtures__/` 仅有 4 个文件，运行结果为“1 passed | 1 skipped”。同时，`exporter.ts:42-49` 将 `dbFilesWritten` 固定为 0，数据库导出尚未实现。

验证广度也不足：约 50 个已实现事件 code 尚未经过 oracle 验证，包括 101、103、104、105、108、115、117-119、132、133、138、202-204、206、212-214、217、221、222、230-235、242-244、246、249-251、261、323、351-355、401、405、408、505、601-604；另有 14 个 code 不在 fuzz 生成器范围内（103、104、281-283、331-337、339、405），范围定义见 `eventFuzz.gen.ts:11-17`。用户可编辑性也未闭环：事件页元数据只读 `RmvaMapEventEditor.vue:14-16`，if 分支重构被明确推迟 `eventStructural.ts:19-21`，choices 最多 4 项并以 passthrough 降级 `eventStructural.ts:287-297,318-338`，通用 `rmva.command` 节点只读 `nodes/RmvaCommandNode.ts:57`，`moveRoute` 子语言仍是不透明块 `eventCoalesce.ts:1177-1253`。

### 关键技术决策

本路线图应将 RMVA 单独加深到生产质量，而将 RMXP/RMVX 泛化明确推迟。近期目标不是扩大格式面，而是建立可量化的 RMVA fidelity contract：每次导出必须产出真实 `droppedFields`、数据库文件写入结果和可解释差异；golden corpus 必须从可跳过的检查变为 CI 必跑资产；高风险事件 code 应以真实 RGSS oracle、fuzz 和 corpus 三层交叉验证。代价是短期交付会集中在测试资产、导出器和编辑器语义，而非“更多版本支持”；收益是避免把尚未被证实的兼容性复制到两种格式。

编辑器侧应优先按可逆 AST/结构编辑推进，而不再依赖 passthrough 作为长期主路径。choices、if 分支和 `moveRoute` 需要各自定义可编辑的语义模型、序列化规则与降级诊断。其权衡是实现复杂度上升，但否则“可导入”会被误解为“可安全修改后导出”。数据库导出也必须与地图导出作为同一 release gate，而不是后补功能。

开始 RMXP/RMVX 前至少应同时满足：RMVA 的 corpus 和 oracle 覆盖达到预先约定门槛并持续通过；导入、编辑、导出的数据库与地图往返均有可审计差异报告；共享抽象已被证明不会掩盖版本语义；并且存在真实用户需求与可获得的合法测试工程。具体 RMXP/RMVX 数据格式和事件语义差异为 `NEEDS VERIFICATION`，不得以当前 RMVA 实现直接假定可复用。

### 待定问题

RMVA “生产级”的可接受差异集是什么，哪些字段允许规范化、哪些必须字节级或语义级等价？golden corpus 的来源、许可、规模及是否能包含商用工程，均为 `NEEDS VERIFICATION`。真实 `Game.exe` oracle 的运行环境是否可在 CI 稳定、合法地运行也为 `NEEDS VERIFICATION`。最后，插件的用户承诺应限定为“导入查看”“可编辑”还是“全量安全往返”，必须在发布前以可测合同写清。

## 5.2 AI 驱动编辑器与 Godot 引擎定位

### 现状

仓库 `E:\Projects\RGSS-Godot` 本身是 Godot 4.6 的 .NET/C# 项目，定位为从 Unity 移植的 RGSS3 runtime，见 `project.godot:1-36` 与 `README:1-7`；Ruby 层运行于嵌入式 mruby，并有 4 个 native gem 经 P/Invoke 调用，见 `mruby-ext/AGENTS.md:1-24`。但当前 editor 并未使用 Godot 渲染地图，而是通过 HTML Canvas 2D 完成，见 `RmvaMapEditor.vue:47,54-57,155-177,219-254`。它导出的是 `.rvdata2`，不是 Godot 工程，链路见 `exporter.ts:21-49`、`mapExport.ts:114-121`、`src-tauri/src/lib.rs:117-120`。

仓库中有未使用的 `.tscn` 发射器 `godotSceneTscn()`，位于 `lib/mapStitchSerialize.ts:162-178`。同时 godot-mcp bridge 已存在却无生产使用：`engineTools.ts:16-21,57-153` 定义 `engine.create_scene`、`add_node`、`run_project`、`get_debug_output` 等工具，适配器注册见 `adapters/index.ts:28-30`。

### 缺口

产品叙事与实际边界不一致：runtime 已是 Godot，但 editor 的渲染、数据模型和导出路径仍面向 RMVA `.rvdata2`。因此“Godot 是游戏引擎”目前不是 editor 的已兑现工作流。闲置的 `.tscn` emitter 和 dead bridge 说明曾有连接方向，但没有定义可支持的 Godot 项目模型、同步方向、导入导出契约或用户可见入口。

### 关键技术决策

本节不重复 §3 的 Godot 架构结论；这里的执行决策是将 editor 身份拆为明确的两个可验证产品面：AI 驱动的创作工作台，以及 Godot runtime/project 的受控目标。应先选定一个 canonical project representation，再规定 RMVA 与 Godot 仅能通过显式转换器进入或离开该表示；否则每项地图和事件功能都可能形成两套隐式真相。选择 canonical representation 的代价是要迁移既有 editor 操作与测试，收益是可把 AI agent 的写入、预览和回归都约束在同一模型上。

Godot bridge 不应再以“模块存在”计为完成。是否直接操纵 `.tscn`、调用 Godot editor API，还是只生成受版本控制的资源，需要以 §3 的架构为准；三者在可重现性、调试可见性和编辑器耦合上取舍不同。无论选择何者，都必须先有从 UI 或 agent 到 Godot 项目的真实闭环，而非单元测试通过。

### 待定问题

Godot 目标是运行原 RGSS 内容、迁移成原生 Godot 游戏，还是同时支持两者？不同答案会决定 canonical representation 和转换责任。`godotSceneTscn()` 的生成质量、覆盖范围以及是否适配 Godot 4.6 为 `NEEDS VERIFICATION`。Godot 工程是每个用户本地管理还是由 editor 自动创建，也需要与 §3 的部署和安全边界一起确定。

## 5.3 Editor 内 AI agent

### 现状

`FillAgent.ts:8-18,102-111,205-275` 是真实接线的数据库填充 agent：它以 schema 和 intent 构造 prompt，经 `llm.complete()` 获取结果，解析 JSON rows，生成 DB patch，执行完整性校验，并支持 `applyProposal()`/`rollback()`；`DatabaseEditor.vue` 与 `importer.ts:4` 对其共有 9 个生产引用。`FillReviewPanel.vue:153-287` 已是 shipping 的人工复核弹窗，具备逐行接受/拒绝、内嵌 `SchemaForm` 编辑、完整性 badge、Approve All 与 Cancel+rollback。这是后续场景搭建、代码修改、数据填写、自动化回归和资产操作应复用的已验证治理模式。

但第一步被 LLM client 缺口阻塞：`DatabaseEditor.vue:14-19,256-258` 读取 `window.__medotLLM?.complete`，不存在时退化为返回 `'[]'` 的 stub；仓库没有任何代码提供该 client。`ToolRegistry.ts:1-75` 在 `src/agent/` 之外没有生产 import；路径受保护的 `asset.removeBackground`、`createSpriteSheet`、`videoToGif`、`chromaKey` 位于 `assetTools.ts:251-380`，同样未接线。先前计划 `.sisyphus/plans/ai-game-dev-environment.md` 标记 38/38 COMPLETE，宣称 ToolRegistry、FrameRonin/godot-mcp adapters 和端到端接线已完成，但这些模块没有生产 consumer：这是“测试通过即完成”、缺少真实集成验收的直接反例。

### 缺口

当前没有可用模型调用、身份与密钥归属、成本边界或 provider 策略，因而 agent 无法执行真实动作。更进一步，agent 的现存成功案例只覆盖受限的数据库 proposal/review；场景、代码、测试和资产需要各自的权限模型、可逆性、产物预览和失败恢复。dead tool abstractions 不能被当作能力已交付。

### 关键技术决策

首先交付一个正式 LLM client contract，而不是继续向 UI 注入 `window.__medotLLM`。它必须明确 hosted/local provider、用户或产品承担 API key 与成本、会话授权、审计记录和模型能力下限。这是产品决策与工程决策的组合：BYOK 降低平台成本但增加配置摩擦；平台托管改善体验但引入账单、滥用和隐私责任；本地模型保护数据但会限制质量与硬件覆盖。

所有 agent action 应以 `FillReviewPanel` 的 proposal-first、可编辑、可拒绝、可 rollback 范式为默认接口，而非直接写文件或执行引擎命令。可自动执行的低风险动作必须有显式 allowlist；代码、场景和运行测试的高影响动作应提供 diff、日志、产物预览及人类批准。ToolRegistry 和 adapters 只在被真实 UI/agent flow 消费，并经过真实 Godot/FrameRonin 交互测试后才可计为完成。每个 phase 增加 integration gate：从用户指令到模型调用、工具执行、review、落盘或回滚，必须有端到端证据，单元测试不足以放行。

### 待定问题

首发 agent 的顺序是先数据填写、场景搭建、代码修改还是回归测试？应按可审计性与可回滚性排序，而不是按演示吸引力。代码 agent 可操作的语言、目录和测试命令白名单为 `NEEDS VERIFICATION`。用户 prompt、项目内容及资产是否允许发送至 hosted provider，以及审计数据留存多久，均需产品与合规决策。

## 5.4 美术资产生成：GPT-image API 与本地 ComfyUI

### 现状

仓库中没有任何图像生成代码：未发现 ComfyUI、diffusion、`txt2img` 或 `img2img` 实现；本支柱是明确的 greenfield。已有 FrameRonin 服务配置在 `services/serverConfig.ts:41-55`，Tauri 的 `get_client_config` 实现在 `src-tauri/src/lib.rs:1345-1455`，但它只做媒体处理，不做生成。其背景移除、spritesheet 拼装、video/gif、chroma key 工具定义在 `assetTools.ts:251-380`，虽尚未接线，却恰好可组成生成后的后处理链。`FrameRoninWorkflows.ts:173-225` 的 `comprehensiveVideoProcess` 仍部分 stub，且可能返回空 `Blob`，也未接线。

### 缺口

缺少 provider 抽象、请求队列、认证与成本控制、本地 ComfyUI discovery/health check、模型与 workflow 版本化、生成结果存储、透明背景和格式校验，以及向项目导入的受控路径。更根本的是，没有把自然语言图片输出转换为 RPG 可用资产的约束流水线；单图生成不等于可用的角色行走图或 tileset。

### 关键技术决策

**修正记录：先前判断有误。** 本节原先假定「ControlNet 类结构条件控制是 local ComfyUI 独有，托管 API 只有 prompt + 参考图 + mask」，并据此建议按「能力不对等」二分设计。该假定已被调研推翻。

**托管 API 确实提供结构控制**：Stability AI 公开 REST 暴露 `Control Structure`（保持构图/布局）、`Control Sketch`（边缘/轮廓引导）与 `Style Transfer`，且 style preset 中直接包含 `pixel-art` 与 `tile-texture`（https://platform.stability.ai/docs/api-reference）；fal.ai 的 Z-Image Turbo ControlNet 显式暴露 `preprocess: none|canny|depth|pose` 与 conditioning scale、起止窗口（https://fal.ai/docs/model-api-reference/image-generation-api/z-image-turbo-controlnet），FLUX general 另暴露 `controlnets` 与 `ip_adapters`。

**但并非所有托管 API 都有**：OpenAI image API 无结构控制，仅 mask 编辑，且其文档自承 mask 编辑为 prompt 驱动、不保证严格遵循 mask 形状；`gpt-image-2` **不支持透明背景**，对游戏素材是硬伤（https://developers.openai.com/api/docs/guides/image-generation）。BFL 的 `flux-pro-1.0-canny` / `-depth` 端点**已废弃**，开放权重仍在但属自托管。Google Imagen **已公告于 2026-08-17 停止服务**，须迁移至 Gemini，且输出带 SynthID 水印。

因此正确的抽象不是「托管 vs 本地」二分，而是**按能力分层**：

- **Tier 1 布局锁定**（结构条件控制）：Stability Control 端点、fal ControlNet 系、本地 ComfyUI。用于角色表、图块集等刚性格式资产。
- **Tier 2 参考引导**（reference/character conditioning）：OpenAI、Gemini、BFL Kontext/FLUX.2 多参考、Ideogram、Luma。用于立绘、概念图等无严格网格要求的素材。
- **Tier 3 纯提示词**：以上任意。

关键产品影响：**ComfyUI 因此从 v1 硬需求降级为可选后端**——Stability 与 fal 的托管 API 已能承担布局锁定，用户不必为使用核心功能而自行部署 GPU 环境。ComfyUI 保留为高级/离线/成本敏感场景的通道。`ImageGenerationProvider` contract 应以**能力声明**建模（如 `supportsStructuralControl` / `supportsReferenceConditioning` / `supportsSeed` / `supportsAlpha`），由 UI 依能力筛选可用 provider，而非按最小公分母抹平差异。

生成必须与后处理、约束验证和导入组成一个 pipeline。FrameRonin 可承担背景移除、拼表与格式处理，但其未接线工具须先做真实 service integration，且对可能空 `Blob` 的 workflow 建立可观测失败结果。角色 sheet 的 3x4 grid、每角色 12 帧是领域约束；tileset/autotile 的固定布局、精确尺寸与 palette 规则的具体数字为 `NEEDS VERIFICATION`。系统应将这些规则表示为 machine-checkable asset recipes，而不是交给 prompt 碰运气。

### 自部署路线：用户自理 ComfyUI，我们交付工作流与 LoRA（用户决策）

**优先级（用户已确定）：前期以接商业生图接口为首要任务。** 自部署为后续能力，不阻塞 Phase 5 主线。

**分工边界。** 用户自行部署 ComfyUI、安装模型、提供显卡；产品交付的是**数据资产**（工作流 JSON、LoRA、节点依赖清单、许可声明），而非运行时。选择自部署的用户被视为有能力解决自身环境问题，故不承诺替其兜底安装与驱动问题。

此边界带来一个直接结论：**不需要在编辑器内嵌本地推理运行时**（`stable-diffusion.cpp` / Candle 一类）。该方案原本是为"零门槛本地生成"设计的，既然不追求该目标，可整体省去这部分工程。

**但两项责任无法转移给用户**：

1. **工作流会随生态腐坏。** ComfyUI 自定义节点接口与模型格式变动频繁，今天可用的工作流数月后可能失效。这不是用户的部署问题，而是**我方分发的资产过期**。因此工作流必须**版本化**、声明所依赖的节点及版本，并具备"在当前 ComfyUI 上是否仍可运行"的可验证手段。
2. **分发物的许可责任在我方。** 用户会拿生成物售卖商业游戏，而链条源头是我们提供的文件。**每一个分发的 LoRA、每一个工作流引用的基础模型，都必须是商用安全的**，并在 UI 中显示其许可与商用状态。

**已确认的许可雷区（不得分发或默认引用）**：
- `milliyin/pixel_art_characters_lora_flux_nf4` —— CC BY-NC，禁止商用
- InstantID 依赖的 InsightFace 模型 —— 禁止商用
- InfiniteYou 模型权重 —— CC BY-NC
- FLUX.1 dev —— 非 Apache，商用需另行付费授权
- SD3.5 —— 社区许可，附带营收上限

**商用安全的基础模型**（本地默认只应从此列表选取）：FLUX.1 schnell（Apache-2.0）、Qwen-Image-2512（Apache-2.0）、Z-Image / Z-Image-Turbo（Apache-2.0，官方称 Turbo 可在 16GB 消费级设备运行）。

**自部署硬件门槛（社区实测，非官方指标，标记为 `NEEDS VERIFICATION`）**：8GB 显存属预览级而非产品级；12GB（RTX 3060）跑 SDXL 约 20-32 秒，叠加 1 个 ControlNet 占用约 10.6GB，叠加 2 个即接近溢出；每个 ControlNet 额外占用约 1-3GB。而**布局锁定 + 身份保持所必需的正是 ControlNet + IP-Adapter + LoRA 这一组合**，故实际舒适线在 16GB 以上。这进一步支持"托管优先"的排序。

### 自训练 RMVA 专用 LoRA 的可行性评估

**结论：技术上可行，但不建议前期投入。**

**硬件充足。** 开发机为 RTX 4090 / 24GB（`nvidia-smi` 实测 24564 MiB）。SDXL 或 FLUX 的 LoRA 训练通常 12-16GB 即可，24GB 允许更大 batch、更高分辨率且无需激进量化。硬件不是瓶颈。

**数据是真瓶颈，且存在法律阻断。** 本机 RTP（`F:/Softwares/RPG Maker VX Ace/RTP`，路径来自 `rm_conf.json` 的 `rtp_path`）实测素材量：Characters 48 个文件（其中 31 张为 8 角色表，约合 248 个角色）、Tilesets 22、Battlers 74、Faces 12、Animations 93。

两个问题：
1. **数量与多样性不足。** 248 个角色对训练"能生成任意新角色"的通用 LoRA 仍偏少，且全部出自官方美术、风格高度同质。训练结果很可能只是复读 RTP 画风，而用户要的是原创角色。
2. **版权阻断（决定性）。** RTP 素材是 Enterbrain 版权资产，授权范围限于"在 RPG Maker 制作的游戏中使用"。以其训练模型并分发，几乎确定超出授权；而用户会将生成物用于商业游戏，风险最终回流至我方。**手边唯一现成的训练数据，恰恰是不能用于训练的那一份。**

**若要训练，可行路径**：
- 改用开放许可素材：**LPC（Liberated Pixel Cup）** 为 CC-BY-SA / GPL，角色量大且本身即标准化行走图布局；OpenGameArt 的 CC0 集；Kenney 素材（CC0）。调研中的 `PIXEL-T2I` 即基于 LPC 构建，证明路径可行。
- 需格式转换：LPC 为 4 行 x 9 帧，RMVA 为 4 行 x 3 帧，需切分重排——这恰是确定性代码的工作，`lib/` 已有同类能力。
- **更务实的目标是训"结构"而非"画风"**：让模型学会输出"3x4 网格、每格一帧、行序下左右上、透明背景"这一布局约定，画风交由用户提示词或参考图决定。所需数据量显著更小，不依赖特定版权素材，且与"结构控制 + 参考图"架构一致。

**建议顺序**：先精选转发商用安全的现成 LoRA（如 Apache-2.0 的 `Limbicnation/pixel-art-lora`），把画布与后处理链路跑通；待有真实用户反馈、明确现成方案的具体缺口后，再针对该缺口训练。若确要投入，**第一步应是小规模验证**——用 LPC 转换为 RMVA 布局，训一个结构 LoRA，测"输出符合 3x4 网格"的通过率，用数天回答"值不值得"，而非先建管线再发现效果不足。

### 图块集应走程序化路线，而非生成路线（架构级修正）

**先前将图块集当作生成问题处理，是错的。** Wang / blob / autotile 本质是**算法问题**：给定少量基础图块，完整变体集可被**确定性地计算出来**，无需模型遵守刚性布局。

已确认的开源程序化工具：

| 工具 | 能力 | 许可 | URL |
|---|---|---|---|
| Wangscape | 地形图块 → 程序化角落 Wang 图块集（alpha 掩码） | MIT | https://github.com/Wangscape/Wangscape |
| godot-tile-generator-webapp | **15 图块 → 47 图块 blob 集**，含 top-down/平台掩码 | 未标注 | https://github.com/DanTrz/godot-tile-generator-webapp |
| itsjavi/autotiler | 15 → 47 blob，并导出 Godot 资源 | 未标注 | https://github.com/itsjavi/autotiler |
| TileToad | 生成**过渡、悬崖、瀑布**等地形组合 | 未标注 | https://github.com/NatanaelAntonioli/TileToad |
| eishiya/tiled-expand-autotile | 直接处理 **RMVA A1-A4**，展开为 Tiled 地形 | 未标注 | https://github.com/eishiya/tiled-expand-autotile |
| Arpiyi | 支持 **VX Ace A2**，从简单图自动生成全部角/边组合 | 未标注 | https://github.com/aleokdev/arpiyi |

**因此正确架构为**：

```
AI 生成 1 张无缝基础图块（用户 GPU 或托管 API）
        ↓
程序化扩展为完整 autotile 集（我方编辑器内，确定性、可测、零随机）
```

这比要求扩散模型遵守 A1-A4 刚性布局可靠一个数量级，且**确定性部分不依赖用户显卡**。

**诚实标注**：调研未找到任何工具可直接产出完整且正确的 VX Ace A1-A4 集，末端仍需适配步骤；上表多数工具的许可未在检索结果中标明，**分发或集成前必须逐个核对**，标记为 `NEEDS VERIFICATION`。

**同一分工原则适用于角色**：AI 生成主控图（重活，交用户 GPU 或托管 API），切分 / 对齐 / 调色板量化 / 透明处理（精确活，交我方 `lib/` 确定性函数）。

### 待定问题

首发是否支持 reference image、`img2img`、inpainting、seed 锁定和批量变体？各功能影响 provider 最小公分母。默认资产许可证、训练数据声明与商业使用责任为 `NEEDS VERIFICATION`。ComfyUI 是连接用户现有实例还是由产品安装/管理，亦决定支持成本与安全边界。

## 5.5 素材关系画布：DAG 式生成与"套"的组织

> 本节在用户明确设计意图后完整重写。原先"无限画布"是一个模糊的 UI 概念，现在它有确定的数据模型：**一张素材关系 DAG**，节点是素材产物，边是参考关系。

### 用户确定的设计意图（决策，非推测）

- **画布是节点图，不是看板。** 对已有素材节点连线并附加 prompt，生成新素材；参考关系即边。这与 ComfyUI 的交互心智一致，但粒度不同（见下"三层分离"）。
- **"套"是自由定义的**，不绑定 Actor 记录；一个素材可同时属于多套（**选项 C**）。因此"套"是**视图过滤/标签**，不是物理容器。
- **落盘是复制 + 记录来源**，不是移动或绑定。画布是工作台（含未采用候选与历史版本），工程目录是成品区。
- **生成靠对话 + 人工逐项筛选推进**，不做"一键生成整套"。

### 现状

无画布、无生成实现，本支柱是 greenfield。但交互层**不是从零开始**：编辑器已在事件命令编辑中使用 Vue Flow 节点图（`@vue-flow/core` 为 dependency，`EventLogicEditor.vue` 为完整流程图编辑器，`rmva-support/nodes/` 下有 114 个节点文件）。节点、连线、拖拽、缩放、右键菜单、序列化这套交互已跑通并有测试覆盖。

Workspace 扩展点干净可用：`PluginManifest.workspaces`（`plugins/types/index.ts:13-27,69-81`）经 `App.vue:112-165` 注入 `WorkspaceRegistry`（`workspace/WorkspaceRegistry.ts:6-58`），新增 workspace 无需改造 core shell。

FrameRonin 的既有处理能力（`services/serverConfig.ts:41-55`、`src-tauri/src/lib.rs:1345-1455`、`assetTools.ts:251-380`）可作为生成后的后处理环节，但它不是生成服务。

### 关键事实：RMVA 里不存在"套"

RMVA 的素材引用是**扁平字符串字段**，只存 basename（无扩展名、无目录）：`characterName` → `Graphics/Characters/`（`schemas/schemas.ts:15`）、`faceName` → `Graphics/Faces/`（`schemas/schemas.ts:17`）、`battlerName` → `Graphics/Battlers/`（`schemas/schemas.ts:140`）、`animation1Name`/`animation2Name` → `Graphics/Animations/`（`schemas/schemas.ts:202,204`）。

因此一个角色的"一套素材"在数据层**本就分散在 4 个目录的 4 个独立文件**里，引擎从不知道它们同属一个角色。"套"是**编辑器侧引入的、引擎没有的抽象**，导出后不留任何痕迹。

推论：**套装归属必须由编辑器侧清单持久化**。曾考虑"从 Actor 记录反推"以避免额外状态，但该方案在"套自由定义、不绑定角色"的前提下**不成立**，已排除。清单需要**对账机制**：打开画布时校验引用是否仍存在，缺失项标记为失效而非静默消失。

### 关键约束：素材命名空间是扁平且大小写不敏感的

`graphicResolver.ts` 的索引逻辑决定了三件事：

1. **只扫目标子目录一层，不递归**（`buildGraphicIndex`，`graphicResolver.ts:60-75`）。用户不能在 `Characters/` 下再建子目录分类，引擎与解析器都找不到。
2. **以 `stripExt(name).toLowerCase()` 为键**（`graphicResolver.ts:68`）。`Hero.png` 与 `hero.png` 冲突，先扫到的胜出。
3. **项目目录优先于 RTP**（`graphicResolver.ts:44-54`、`graphicResolver.ts:69-71`）。用户生成的 `hero.png` 会**静默覆盖** RTP 同名素材。

因此"右键 → 指定放到哪个文件夹"实质是**在扁平命名空间里选一个桶**，且文件名须在该桶内唯一（大小写不敏感）。UI 必须在放置时要求确认文件名并**实时检测冲突**，明确区分"覆盖你已有的文件"与"遮蔽 RTP 素材"两种情况；否则用户会在无感知的情况下破坏工程。

反向利用：既然同目录内文件名必须唯一，套装内素材天然需要可区分命名，UI 应**基于套装名自动建议文件名**（如 `hero_walk`、`hero_face`）并允许修改。

### 三层分离（避免把扩散模型细节暴露给游戏作者）

ComfyUI 的图是**流水线内部**（采样器、VAE、ControlNet）。本画布的图应是**素材之间的关系**，高一个粒度。两者混同会迫使用户理解炼丹细节，与产品定位冲突。

```
第 1 层  素材关系图（用户默认视图）
         节点 = 一件素材，边 = 参考关系
第 2 层  生成配方 recipe（可展开）
         provider / 模型 / prompt / reference / 后处理 / 格式约束
第 3 层  执行引擎（用户不可见）
         ComfyUI workflow 或托管 API 调用
```

托管 API 与 ComfyUI 的能力差异被封装在第 3 层，与 §5.4 的三层能力模型对应。

### 与事件图的本质差异：节点产物昂贵且非确定

事件节点重跑免费且确定；素材节点重跑**要花钱、要等待、且每次结果不同**。由此产生三个事件图不需要面对的设计约束：

1. **节点须持有多个候选产物。** 节点不是"一张图"，而是"一次生成任务 + N 个候选 + 一个被选中项"。UI 需支持翻看候选与切换选择。
2. **失效策略必须与常规 DAG 相反。** 上游 prompt 变更后，下游应标记为**陈旧（stale）等待用户决定**，而非自动重算。原因是素材生成不可复现，自动重跑可能丢掉一个再也生不出来的好结果。这是本领域的特殊约束，务必不要照搬构建系统的语义。
3. **图必须可持久化且可重放。** 节点须记录 provider、模型、seed（若支持）、prompt、reference、后处理参数与格式 recipe；否则"溯源"只记录了关系而无法复现。

### 一致性问题在此变形，但结构上有解

先前讨论的是"12 帧之间是否同一角色"。本设计把它扩大为**跨素材类型的一致性**：行走图（小尺寸像素画）、立绘（大尺寸半身）、战斗图三者需看起来是同一人，而分辨率、画风、构图完全不同。这比帧间一致性更难，无法靠"一次生成整张表"取巧。

但 DAG 结构恰好给出正确解法：**同一套内先确定一张主控图（通常是立绘，信息最丰富），其余素材以其为 reference 生成**。参考图条件化是当前一致性最有效的手段，且 Stability、fal、Ideogram、Luma 均在托管 API 中支持（见 §5.4）。画布 UI 天然表达该依赖——重生成衍生素材时 reference 由入边确定，无需用户手动指定。

对话式推进还使上下文自然累积：用户说"再暗一点""换成侧面"时，agent 已持有主控图、已批准素材与套内其他项，这些正是 reference 条件化所需输入。**对话历史即 reference 链。**

### 画布同时承接既有图像编辑功能（用户决策）

用户决定：**把现有图像编辑功能变成节点融合进画布，并从 UI 层面下线原有面板**。这把画布从"AI 生成工具"升级为**统一图像工作台**——AI 生成只是节点来源的一种。

**边界（用户已确认）**：
- **画布不管理音频。** `AudioCompressPanel.vue`（766 行）不迁入，保持独立。
- **`MaterialLibrary` 保留**，不并入画布。画布从素材库拖取，素材库继续承担文件系统浏览与导入职责，画布只管"正在编辑的这些"。

**关键事实：算法层已与 UI 分离，迁移成本远低于面板行数所示。**

现有面板合计约 13,393 行（`ImageProcessingPanel.vue` 1,727 / `SpriteSheetPanel.vue` 2,365 / `ScatterSlicePanel.vue` 1,989 / `MapStitchPanel.vue` 1,283 / `GifProcessingPanel.vue` 1,092 / `AudioCompressPanel.vue` 766 / `VideoProcessingPanel.vue` 551 / `WatermarkPanel.vue` 497），但**真正的图像处理逻辑不在面板里**，而在 `src/lib/` 的纯函数模块中（约 1,600 行），且**已有 8 个 spec 覆盖**：

| 模块 | 导出能力（可直接包装为节点） |
|---|---|
| `spriteSheetBuild.ts:352` | `computeSheetLayout` / `composeSpriteSheet` / `extractFrames` / `serializeAtlas` / `buildFramesetManifest` |
| `spriteSheetAdjust.ts:231` | `splitSpriteSheet` / `recombineFrames` / `frameCropDrawParams` / `encodeFramesToGif` |
| `scatterSlice.ts:269` | `detectScatteredRegions` / `orderBoxes` / `resizeSprite` / `sampledBackgroundColorFromData` |
| `superSplitTransparent.ts:172` | `superSplitByTransparent` / `detectTransparentFrames` / `findTransparentRows` / `findTransparentCols` |
| `imageMatte.ts:59` / `imageConvert.ts:68` | `chromaKeyRgba` / `applyChromaKeyToBlob` / `convertImageFormat` |
| `gifFrames.ts:135` | `decodeGifToFrames` / `compositeFrame` / `filesToImageData` |

这些纯函数的签名天然就是节点形态（输入图像 + 参数 → 输出图像）。面板中的大部分行数是布局、状态、预览与拖拽，而这些正是要被画布取代的部分。因此本项工作**主要是重写 UI 壳，不是重写算法**。

**附带收益**：先前建议引入外部后处理库（SpriteFusion Pixel Snapper 等，见 §6 生态调研结论）。但 `superSplitTransparent` 的透明间隙切帧与 `scatterSlice` 的区域检测**已经覆盖生成后处理的核心需求**，且有测试。应优先复用自有实现，仅在确有缺口时才引入外部依赖。

**拖拽契约已存在，无需新造**：`services/fsSystem.ts:75-141` 定义 `MaterialDragPayload` 与 `setMaterialDragData` / `setMaterialDragList` / `getMaterialDragData` / `getMaterialDragList`，当前被全部 8 个面板消费。画布直接复用该契约即可从 `MaterialLibrary` 接收素材。

**必须保留、不属于"图像编辑"的部分**：`MapStitchPanel` 中的 `godotSceneTscn()` 与 `layeredPsdBlob()`（`lib/mapStitchSerialize.ts:154`）输出 `.tscn` 与分层 PSD，属于**工程产物导出**而非素材编辑，不应作为画布变换节点下线。

**节点类型因此自然分为三类**：

```
来源节点：MaterialLibrary 拖入 / AI 生成 / 文件导入
变换节点：色度键、切分、合成、缩放、水印、抽帧…（← 复用既有 lib 纯函数）
汇出节点：复制进工程 Graphics 子目录 / 导出 PSD / 导出 tscn
```

**这实质降低了 pillar #5 的风险**：画布不再完全押注于生成质量。即使 AI 生成效果不达预期，它作为图像处理工作台**已有独立价值**，因为承载的是已经在用、已有测试覆盖的功能。

**迁移必须并存而非先删后建。** 现有面板是**当前可用功能**，画布是**尚不存在的功能**，且画布依赖 Phase 5 的 provider 层。若先下线面板，用户会经历一段既无面板也无可用画布的空窗期。正确顺序为：

1. 画布先作为**新 workspace** 加入（plugin contribution，不动现有面板）
2. 逐个把 `lib/` 纯函数包装为节点，**每包装一个，即在画布中验证其可替代对应面板的功能**
3. 全部能力对齐并通过验收后，才从 UI 移除旧面板

如此任何时刻都存在可用路径，且"节点能否真正替代面板"是**可验证的**，不是一次性赌注。下线旧面板应有明确的能力对齐清单作为准入条件。

### 缺口

缺少：DAG 数据模型与持久化、节点候选管理、陈旧标记与重跑编排、asset recipe 的机器可校验表达、套装清单与对账、放置时的命名冲突检测、跨素材类型一致性评分、生成产物的溯源记录、以及"批准后导入工程"的事务化流程（部分批准、整套回滚、无孤儿文件）。**另需**：把既有 `lib/` 图像函数包装为变换节点、复用 `MaterialDragPayload` 契约接收素材库拖入、以及旧面板下线前的能力对齐清单。

更根本的是：**没有证据表明当前模型能稳定产出同一角色的跨类型一致素材集**。这是该支柱的核心价值，不是 UI 布局能补足的问题。

### 关键技术决策

复用 Vue Flow 与既有节点图交互，而非自研画布——这使 Phase 6 的成本判断从"造一个无限画布"下调为"复用图编辑器 + 新增节点类型 + 补齐产物/候选/陈旧语义"。

治理复用 `FillReviewPanel.vue:153-287` 的 proposal-first 范式：把"表格行"换成"图片候选"，accept/reject/edit/rollback 骨架不重造。落盘走复制而非移动，画布对工程只增不改，误操作不会破坏在用素材。

"套"实现为标签与视图过滤而非物理容器，允许跨套复用风格锚点图（如统一画风的参考图被多角色引用）。因放置是节点自身属性、与所属套数无关，一个素材只落盘一次，**多套引用不产生导出歧义**。

### 待定问题

节点图是否需要支持手工图层、笔刷与像素编辑？若需要，范围将从资产编排扩大为完整图形编辑器，应明确拒绝或单独立项。

套装清单的存储位置与格式（工程内还是编辑器侧）、以及与 `.rvdata2` 导出的隔离方式为 `NEEDS VERIFICATION`。整套一致性的客观验收标准、人工审核容量与可接受重生成成本亦为 `NEEDS VERIFICATION`——这些数字决定 Phase 6 能否宣称"整套可用"。

角色 3x4/12 帧、整表 4x2/8 角色、`$` 与 `!` 前缀语义已由官方文档确认（见 §6 风险第 2 条），但 autotile 的 48 变体计数仍为 `NEEDS VERIFICATION`。

## §6 风险登记册

| 风险描述 | 可能性 | 影响 | 早期预警信号 | 缓解策略 | 处置(接受\|缓解\|推迟) |
| --- | --- | --- | --- | --- | --- |
| **整套资产风格/角色一致性不可达。** 单张插图容易，连贯的 12 帧 walk cycle 或同一光照、palette、透视的 tileset 则难一个数量级；当前模型可能无法完全解决。若过度承诺，会直接击穿 pillar 5 的核心价值主张。 | 高 | 极高 | 同一 recipe 的帧间角色特征漂移；人工审核反复拒绝；重生成次数和成本上升而通过率不升。 | 将该能力作为实验性、量化验证的假设；先建立代表性角色和 tileset corpus，测量整套通过率；采用 reference、固定 recipe/seed（若支持）、逐项 review 与一致性检查；未达门槛不宣称“一键整套可用”。 | 缓解 |
| **RMVA 格式刚性与生成结果冲突。** 生成模型不会天然给出 3x4 grid、精确 tile 尺寸或固定 autotile layout；透明背景、切片和 palette 一致性也不能只靠 prompt。**规格已确认（见本表下方"RMVA 格式规格"），可写成确定性校验，故可能性下调为中高**；但 autotile 自动生成仍无解。 | 中高 | 高 | 导入后帧数、尺寸、透明通道或布局校验频繁失败；需人工切图和重排的比例持续偏高。 | 把 asset recipe、切片、布局检查和不合格阻断作为生成 pipeline 的必经步骤；复用并完成 FrameRonin 后处理集成；精确 tile/autotile 规则先标记并完成 `NEEDS VERIFICATION`。 | 缓解 |
| **LLM client 缺口使 pillar 3 在第一步停滞。** `window.__medotLLM` 目前只会落到返回 `'[]'` 的 stub，见 `DatabaseEditor.vue:14-19,256-258`。这同时是 API key 归属、成本、local/hosted、隐私的产品决策，而不是单纯缺一段连接代码。 | 高 | 极高 | 继续新增 tool 或 UI，但真实模型调用数为零；演示只能依赖 mock；密钥和账单归属在开发末期才被讨论。 | 在扩展 agent 前定稿 provider、BYOK/托管/local 策略、权限、审计和预算；先交付真实 client 的最小垂直切片，再扩展工具。 | 缓解 |
| **双目标维护负担失控。** 若 editor 同时承担 `.rvdata2` 导出和 Godot 目标，每个事件命令、地图特性和资源规则都可能需要两套翻译和两套回归。 | 中高 | 极高 | 新功能 PR 同时修改多个无共享契约的 exporter；修复一端后另一端回归；转换差异无法解释。 | 依 §3 先确定 canonical representation 和各 target 的显式转换契约；每项功能建立 target matrix 与端到端测试；若价值未被证实，推迟第二目标的写入支持。 | 缓解 |
| **下线现有图像编辑面板造成功能空窗或回退。** 现有 8 个面板是当前可用功能（约 13,393 行 UI），画布尚不存在且依赖 Phase 5 provider 层；若先删后建，用户将失去既有能力。 | 中高 | 高 | 画布尚未覆盖全部能力时就安排面板下线；用户报告"以前能做的现在做不了"；能力对齐清单缺失或凭印象勾选。 | 强制并存迁移：画布先作为新 workspace 加入，逐个把 `lib/` 纯函数包装为节点并以"与旧面板输出等价"的测试验收，全部对齐后才移除旧 UI；`AudioCompressPanel` 与 `MapStitchPanel` 的工程导出不在下线范围。既有 8 个 lib spec 为不可回归基线。 | 缓解 |
| **“标记完成但未接线”的过程复发。** 计划称 ToolRegistry、FrameRonin/godot-mcp adapters、E2E 已完成，但 `ToolRegistry.ts:1-75` 和 `assetTools.ts:251-380` 没有生产 consumer；模块孤立测试绿并不等于产品可用。 | 高 | 高 | checklist 以文件/单测为完成依据；UI 无入口、遥测无调用；验收无法从用户指令走到真实副作用。 | 每个 phase 增设 integration gate：真实 UI/agent 指令、真实 provider/service、review、批准/回滚或导入的可复现证据；将生产 consumer 和用户可达入口纳入 Definition of Done。 | 缓解 |
| **RMVA “兼容”承诺先于 fidelity 证明。** `roundTripEqual` 当前没有记录丢弃字段，数据库导出为 0，golden corpus 可跳过；在此状态扩大用户引入会放大数据损坏风险。 | 中高 | 极高 | `roundTripEqual` 持续全绿但 corpus 仍很小或被 skip；用户工程出现未解释字段丢失；oracle/fuzz 覆盖不增长。 | 修正 dropped-field accounting；实现数据库导出；把 golden corpus 与真实 oracle 覆盖设为发布门槛；优先完成 RMVA，RMXP/RMVX 保持推迟。 | 缓解 |
| **依赖将于 2026-08-17 停服的 Imagen，或选中不支持透明背景的 provider。** Google 已公告 Imagen 停服并要求迁移至 Gemini；OpenAI `gpt-image-2` 不支持透明背景，而游戏素材几乎都需要 alpha 通道。 | 中 | 高 | 选型时只看生成质量、未核对 alpha 支持与生命周期公告；上线后素材需逐张抠背景。 | 把 **alpha 支持**与 **provider 生命周期状态**列为 provider 准入的硬性检查项；`ImageGenerationProvider` 的能力声明中包含 `supportsAlpha`；对不支持 alpha 的 provider 强制串接 FrameRonin 背景移除，并在 UI 标注额外成本。 | 缓解 |
| **分发的 LoRA 或工作流许可不当，导致用户商业游戏侵权。** 用户会将生成物售卖，而链条源头是我方提供的文件。已确认雷区：`milliyin/pixel_art_characters_lora_flux_nf4`（CC BY-NC）、InstantID 依赖的 InsightFace 模型（禁商用）、InfiniteYou 权重（CC BY-NC）、FLUX.1 dev（非 Apache）、SD3.5（营收上限）。 | 中 | 极高 | 分发清单未逐项核对许可；UI 未显示商用状态；以「用户自己负责」搪塞。 | 将许可核验设为分发硬门槛，只分发商用安全资产（FLUX.1 schnell / Qwen-Image-2512 / Z-Image 均为 Apache-2.0）；在 UI 显示每个工作流与 LoRA 的许可与商用状态。 | 缓解 |
| **以 RTP 素材训练 LoRA 触发版权问题。** RTP 为 Enterbrain 版权资产，授权限于「在 RPG Maker 制作的游戏中使用」，用其训练并分发模型几乎确定超出授权。而这是本机唯一现成的训练数据（Characters 48 文件 / 约 248 角色）。 | 中 | 极高 | 以「反正只是训练」合理化；未评估授权即启动数据清洗。 | 前期不自训；若要训，改用 LPC（CC-BY-SA/GPL）或 CC0 素材，并优先训「布局结构」而非「画风」。 | 推迟 |
| **分发的 ComfyUI 工作流随生态更新而腐坏。** 自定义节点接口与模型格式变动频繁，我方分发的工作流数月后可能失效；这属我方资产过期，不可归因于用户环境。 | 高 | 中 | 用户报告「你们的工作流跑不起来」；工作流未声明依赖节点版本；无法回答「这个工作流在当前 ComfyUI 上是否仍可运行」。 | 工作流版本化并声明依赖节点及版本；建立可验证手段定期校验；自部署整体延后于托管路线，缩小前期暴露面。 | 缓解 |
| **本地 ComfyUI 支持成本被低估。** local workflow、GPU/驱动、模型版本和安全访问会产生大量环境差异；当前仓库没有 generation 代码。 | 中 | 高 | 支持请求集中于安装、显存、workflow 或模型兼容；同一 prompt 在不同本机结果不可重现。 | 先以稳定 hosted provider 验证产品流程；ComfyUI 采用受限 adapter、health check、版本记录和明确支持矩阵；无资源支持时推迟“托管安装”承诺。 | 推迟 |
| **资产生成的版权、隐私和成本责任未决。** Hosted 模型可能接收用户项目内容与 reference，批量重生成也可能产生不可预测费用。 | 中 | 高 | 上线前仍未定义默认 provider、数据保留与用户授权；预算超限或用户不愿提交素材。 | 在 client contract 中记录 provider、数据流、成本估算与明确确认；支持可见的消耗记录和取消；法律/许可证具体要求为 `NEEDS VERIFICATION` 后再发布商用承诺。 | 缓解 |

### RMVA 格式规格（已由官方来源确认，取代先前的 NEEDS VERIFICATION）

生成管线的确定性校验层必须按下列规格实现。这些数字来自官方文档，不再是推测。

**角色表 charset**（来源：官方博客 https://www.rpgmakerweb.com/blog/charsets-structure-and-avoiding-traps）
- 单角色 **4 行 x 3 列 = 12 帧**；中列为站立帧，左右列为行走帧
- 行序固定为 **下 / 左 / 右 / 上**
- 常规整表含 **8 个角色**，排布为 **4 列 x 2 行**
- `$` 前缀 = 单角色表；`!` 前缀 = 取消垂直偏移与草丛半透明；可组合为 `!$`
- 默认格 32x32 时：单角色 **96x128**，整表 **384x256**（通式：格 WxH 则单角色 3W x 4H，整表 12W x 8H）

**图块集 tileset**（来源：官方日文素材页 https://rpgmakerofficial.com/product/products/rpgvx/material/ ；英文手册 https://rpgmaker.fixato.org/Manual/RPGVXAce/rpgvxace/6100_resource.html）
- 单图块 **32x32**
- A1 `512x384`、A2 `512x384`、A3 `512x256`、A4 `512x480`、A5 `256x512`
- B / C / D / E 各 `512x512`（16x16 个图块）
- A1-A4 为 autotile 图集（非平铺图块），A5 为普通地面图块，B-E 为上层图块

**仍未确认**：autotile 的 **48 变体计数**为社区说法，官方页面仅确认「6 图案基础结构」，保持 `NEEDS VERIFICATION`。此外 **autotile 的自动生成在业界尚无可用方案**，不应纳入近期承诺。

### 生态调研结论（决定「造还是用」）

三份独立调研得出一致结论：**「prompt → 可直接使用的 RMVA 精灵表」至今无人做到**。SD-πXL 论文（https://arxiv.org/html/2410.06236）明确承认现有扩散方法不能保证严格调色板与清晰像素边界；公开证据中找不到量化基准，模型卡的 "game-ready" 属自述；零人工清理的管线基本是营销话术，迭代重跑加人工筛选是常态。这印证了本路线图「人在回路为必需而非可选」的前提。

**应优先评估而非自研的现成方案**：
- **PixelLab**（https://www.pixellab.ai/docs）——最贴近本支柱目标：4/8 向角色动画精灵、top-down 图块集、Wang tileset 无缝过渡，且有 API 与 MCP。若其 API 足够，pillar #4 可直接接入，把力量集中到 #5 的画布与工程集成，那才是差异化所在。
- **后处理层不应自研**：`SpriteFusion Pixel Snapper`（https://github.com/Hugo-Dz/spritefusion-pixel-snapper，含 Rust/Python/WASM/CLI）负责逻辑像素尺寸检测、网格对齐与调色板量化；`ComfyUI-PixelArt-Unfaker`（https://github.com/CalaKuad1/ComfyUI-PixelArt-Unfaker）修复「假像素画」；`comfyui_sprite_sheet_extractor`（https://github.com/ugotworms/comfyui_sprite_sheet_extractor）含跨帧调色板锁定，正对色彩漂移。
- **架构参考**：`mor-o/comfyui-2d-character-pipeline`（https://github.com/mor-o/comfyui-2d-character-pipeline，77 stars，2026-06 活跃）实现单张角色图到分层精灵表的全流程，且以 API JSON 驱动而非可视化图，与本路线图第 3 层执行引擎的设想同构。

---

## §7 立即行动项

1. 先把 `goldenCorpus.spec.ts:105` 从 skip 状态改成可运行的真实 corpus test，再修 `exporter.ts` 里的 `droppedFields` 和 `roundTripEqual` 计算。原因很简单，当前那个 vacuous `roundTripEqual` 会主动误导任何依赖它的人，它在 export 已经坏掉时也会报成功，这比没有检查还糟，因为它会制造虚假的信心。

2. 为 `exporter.ts` 补上能失败、能解释、能回归的差异报告，再让 `dbFilesWritten` 从硬编码 0 变成真实输出统计。顺序不能反，因为没有先能打红的 corpus test，就无法证明 exporter 的修复不是自我安慰。

3. 把约 `50` 个尚未 oracle 验证的 RMVA command codes 往前推进，优先补最容易回归的 code family，再扩到剩余清单。理由是 handler 覆盖看起来已经足够，但真正的风险在未验证路径，§2 Bucket B 已经说明了这个缺口。

4. 给 `DatabaseEditor.vue` 选择并接入真实 LLM client，连同 API key 归属、成本和 provider 策略一起定下来。没有这一步，pillar #3 仍然停在 `'[]'` stub，agent 只能做假动作。

5. 把 `engineTools.ts` 的 `godot-mcp` bridge 接进真实 production consumer，并加上从 UI 到外部 process 的 integration gate。它现在是 dead code，必须先能被用户路径触发，才能谈 preview、run 和 debug output。

6. 为 Godot external process 建立 headless smoke、cancel、crash 和 structured log 的真实测试，再把它挂进 release gate。这样才能让 §3 选定的 staged hybrid 变成可执行事实，而不是只停留在架构结论。

7. 把 RMVA editor 里那些只读或 passthrough 的编辑点，按 oracle 覆盖和 corpus 结果逐个解锁。先证实行为，再开放编辑，不然可编辑性只是表面能力。

---

## §8 需要你决定的问题

1. LLM client 由谁提供，API key 和成本归谁，走 hosted 还是 local？这会直接决定 pillar #3 能否启动，也会决定审计、隐私和滥用责任落在哪一边。

2. ~~self-hosted ComfyUI 是否 v1 硬需求~~ **已决定**：前期以商业生图接口（BYOK 托管）为首要任务，自部署延后；且自部署采用「用户自理环境、我方交付工作流与 LoRA」的边界（见 §5.4）。剩余待定：自部署能力具体排在哪个版本？

3. hosted image API 选哪一家，预算上限是多少？需要先接受一个现实，当前没有 public API 能保证跨帧 character/style consistency，所以这个选择只能决定成本和接入方式，不能单独解决一致性问题，见 §6 风险登记册第 1 条。

4. Godot-project export target 是不是产品承诺的一部分，还是永远只把 Godot 当 runtime 和 preview host？§3 建议先推迟 export target，但如果它从来不是业务目标，就应该把这点写死，避免团队继续向不存在的交付物投入。

5. RMXP/RMVX 支持到底是一个真实业务目标，还是只是愿望？什么证据才足以启动它，比如真实用户、合法测试工程、持续需求，还是别的门槛？

6. 生成 art 的手工清理比例能接受到什么程度？如果 `30%` 的生成 sprite 需要人工修补，这个功能对你来说还值不值，还是应该继续压低自动通过率再上线？

7. 对基于阈值的 visual regression，容忍多少 flaky？§3 已经说了 deterministic state assertions 只覆盖一部分回归面，视觉测试更脆，太严会让 CI 不稳，太松又会放过真实回归。

8. 之前的 `.sisyphus/plans/ai-game-dev-environment.md` 已经出现过 `38/38 COMPLETE` 但实际包含零 production consumer 的死模块，`ToolRegistry.ts`、`assetTools.ts`、`engineTools.ts` 都是这个问题的例子，见 §4 开篇与 §5.3。以后 `done` 是否必须重新定义为“有 production consumer，加上用户可观察行为”，而不是“单测都绿了”？

9. 是否先评估并直接接入 PixelLab 这类现成服务（见 §6 生态调研结论），把自研力量集中在画布与工程集成上？这会显著缩短 pillar #4 的路径，但引入外部依赖与其定价、可用性风险。

10. 素材关系画布是否需要支持手工图层、笔刷与像素编辑？若需要，范围将从「资产编排」扩大为「完整图形编辑器」，应单独立项而非并入 Phase 6。

11. 套装清单存在工程内还是编辑器侧？存工程内便于随工程迁移，但会污染 `.rvdata2` 导出物的目录洁净度；存编辑器侧则换机器/换人协作时会丢失套装组织。

12. 是否投入自训练 RMVA 专用 LoRA？评估见 §5.4：硬件充足（RTX 4090/24GB），但 RTP 数据存在版权阻断且多样性不足。若投入，建议先做 LPC 小规模验证（训布局结构而非画风）再决定；若不投入，则精选转发商用安全的现成 LoRA。

13. 分发工作流与 LoRA 时，许可核验由谁负责、以何种流程执行？这直接关系到用户商业游戏的合规性，不能默认「用户自负」。

14. 你希望第一阶段先偏向信任底座，还是先偏向可见功能？换句话说，是先把证据链补齐，再扩大面，还是允许部分新能力先以受限形态露出？