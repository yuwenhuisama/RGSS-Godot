# 行走图生图研究历史

## 阅读边界

目标是从动作模板与角色外观描述得到可用于 RMVA 的角色行走图，既保留模板动作，又保持跨帧身份、服装、方向和像素质量。本记录按研究分支整理，不将目录创建顺序当作完整时间线。

本次整理只读取历史会话与文本证据，没有重新生图或查看图片。以下视觉结论均转述原审查记录；技术执行成功、格式验证、候选可读、模板一致、用户接受、播放验收是不同状态。准备阶段 README 可能未更新，应结合后续 history、report、审查及明确审批读取。

原始实验均未纳入 Git。下列相对链接在本机有效，新机器需按[交接手册](cross-machine-handoff.md)迁移对应目录。本文本身可随代码迁移，原始会话不应未经脱敏公开提交。

## 1. 早期模板约束与外观迁移

早期研究在另一个仓库 `E:\Projects\Medot\editor` 下进行，证据目录包括：

- `.omo/evidence/template-grounded-pixel-walk-20260914-down2/manifest.json`：模板负责姿态、脚位和尺度，另一张图只负责外观，明确 `noInventMotion`，不照搬外观参考的站姿或镜头。
- `.omo/evidence/template-grounded-pixel-walk-20260918-left1-physical-2/manifest.json` 与 `PROTOCOL.md`：研究 left1 和短剑的连接、允许前景与禁止占用的负空间；该包是离线准备证据，不是 HTTP/GPU 推理成功证明。

这一时期角色是亮蓝短发、红围巾、深色外套、靴子和短剑。后续棕发、蓝夹克、无武器的冒险者是不同外观实验，不能混为同一套提示词或验收标准。

会话线索：`ses_ed1cf8e16ffehUhmOVwpFuCB55` 讨论 gray-template/control；`ses_f46fc1929ffe1um7TYkLEiiuRh` 检查模板及 left1 结构；`ses_f4c3360aeffeP8Q0GEj2izrB0t` 检查 IG03 短剑与透明区域。这些 ID 是来源索引，不是随 Git 提供的会话文件。

FLUX 环境曾作为已有路线保留。Qwen 调研会话 `ses_ee1a9b381ffeNtRYJDnTvO2E06` 中，用户提出“继续行走图生成的研究”，并认为 Qwen-Image-2.1 值得尝试；当时讨论的推进顺序是保留 Flux2 环境与证据，核实官方能力、许可证和 ComfyUI 支持，再做有限的 left1 验证。用户提到的“好像只需要 7B”是当时猜测，不在本文升级为已核实规格。

本仓库 `evidence/` 还保留 FLUX、Qwen ControlNet、PixelLab 和 Hunyuan 相关截图文件。此次未查看这些图片，也未恢复足够文字来重建它们的完整比较结论，因此不宣称哪种服务或模型已被证明最佳，也不将本文当作最新选型报告。

## 2. 原生像素绘制与分层对照

本机实验根目录下有 `redraw-v1/`、`redraw-v2/`、`walk-v2/`、`front-v1/`、`rear-v1/`、`combined-v1/` 等分支，以及 `00-base-body-head.png` 至 `40-scarf.png` 的分层输入。

[redraw-v2/README.md][redraw] 记录了眼睛、头发、袖口和下巴的局部绘制修正；[walk-v2/README.md][walk] 记录 48x64 三格左向候选、固定调色板、二值 alpha、几何约束和 `0,1,2,1`、每格 150ms 的 GIF 包装。

这些是程序化像素绘制与数值验证，不是扩散模型自动保姿态的成功证据。固定调色板、源几何或 GIF 解码一致也不等于动作获得审美验收。walk-v2 当时未观看连续播放；其说明将头颈的 +2 位移与整帧平移分开，不能直接用它解释所有后续生成漂移。

## 3. Qwen 单帧提示词与控制图分支

目录 `control-registration-*`、`prompt-control-singleframe-*`、`prompt-control-noref-*`、`prompt-control-gray-A-*`、`prompt-control-crown-A-*`、`prompt-control-appearance-A-*` 保存了配准、参考图/灰度控制和外观提示词对照。

重要的状态陷阱是：准备 README 写着 NOPOST，不代表后续一定未执行。例如 appearance-A 后续已有 parent-gate、`run/A/attempt.json`、history 和成功结果。

[appearance-A 执行结果][control-result] 表明一次 A 请求成功；[最终 verdict][control-verdict] 仍为 STOP。记录中的观察是头发双尖、眼睛、紧凑侧向站姿和夹克/裤子区分有所改善，但后髋附近红块仍在，具体物体身份不明确。不能把红块直接认定为背包；记录以其违反无髋部红色附件的外观要求拒绝该候选。

透明区域有所恢复，但仍有大量部分 alpha，边框不全为零；没有做 alpha 修复，也没有因此通过透明质量验收。仅改提示词不能据此认定解决了所有结构或透明问题。

补查后续实际 `run/` 与 `acceptance/verdict.json`，其余四个有明确结果的分支如下，不能沿用准备 README 的零请求状态：

| 分支 | 改动与实际执行 | 最终记录 |
| --- | --- | --- |
| [singleframe][single] | 固定彩色模板和 Canny/Union，仅改 A/B 外观文字；各一次请求成功 | A 外观接近；B 只改变部分头发/兜帽，躯干和腿仍像裸模板，双外观验证 STOP。姿态视觉接近不等于像素几何相等。 |
| [noref][noref] | 移除 RGB 参考及其 VAE 参考条件，保留边缘控制；A/B 各一次成功 | B 衣服出现，但动作偏离、边缘变软且透明度失败；原图均无全透明像素。只支持该组条件的权衡，不证明单一根因。 |
| [gray-A][gray] | 灰度 RGBA 参考并修改提示词，一次 A 成功 | 站姿改善，但头发呈帽状、服装分界不足；无全透明像素，STOP。参考与提示词同时改变，不是纯消融。 |
| [crown-A][crown] | 仅放松头顶区域的 Canny 边缘，一次 A 成功 | 眼睛可读性改善，圆帽式头发和不透明背景仍未解决，STOP。未画入新发丝，也没有证明灰度参考是唯一原因。 |

这些记录位于各实验的直接目录；`offline-fixtures/` 内的拷贝、测试 attempt 或重复 prompt ID 不算额外真实生成。配准准备分支本身的最终模型执行未在本次单独定案；继续前仍需核对其证据。

## 4. 2026-10-14：整张图编辑、放大与 VAE 诊断

### 原尺寸整张基线

[whole-sheet 基线报告][whole-base]：以完整 256x256、4x4 图作为单参考，四个 seed 1001–1004 均完成。设置为 Qwen 原生编辑、25 steps、CFG 1、Euler/simple、denoise 1，无逐格修图、ControlNet 或额外外观叠加。

执行成功，但生成图出现更多颜色与部分透明像素，像素边缘和逐格动作一致性未获得通过。这里的“Gem-style”不代表复现了无法获得的完整 Google 指令或原始成功案例。

### 最近邻 4 倍输入对照

[upscale4 报告][whole-up] 用 1024 输入做两个 seed 对照。输入放大不是修好生成图，也不证明任意更大尺寸必然更好；应与相同设置的原尺寸记录比较，不能将观感变化当作普遍能力结论。

### 只测 VAE，不跑扩散采样

[VAE 诊断报告][vae] 完成原尺寸与 1024 两次编码解码。源可见区域加权 RGB MAE 分别约 22.666 与 4.238；可见区域 alpha MAE 约 6.376 与 1.104。这里衡量的是重建误差，不是角色外观是否正确。

结论仅为 VAE 重建损失可能参与退化，较大输入在该对照下重建误差较低；没有证明先前失败完全由 VAE 引起，更没有证明默认 25 steps/CFG 1 有缺陷。

### 清理错误的提示词假设

[appearance prompt][whole-prompt] 去掉未经证实的行方向分配与“行走”假设，仅要求按参考保留每格位置、比例、朝向和姿态，再替换角色外观。外观为棕色双尖短发、蓝短夹克、红色短颈巾、炭灰裤、棕腰带和靴子，禁止武器、包及髋部附件。

[报告][whole-appearance] 记录两个 seed 技术成功，但逐格轮廓、比例和姿态未保持；[监督结论][whole-stop] 停止本次有限实验，未接受任何一个作为生产行走图。原始输出未重绘、调色或修透明度。提示词纠正有价值，但不等于结构约束已经成立。

## 5. 2026-10-17 起：Wan 动画后抽帧

会话 `ses_eb5af3f4effeKytxL7hs7Toy6V` 中，用户质疑侧向结果为什么变正面，并提出“先生成行走动画然后抽帧”和本地视频方案。Wan 是由此展开的候选路线，而非当时已验证成功的最终选择。

- [首次启动失败][wan-start-fail]：准备/startup 超时，HTTP readiness 使用不兼容的 `Invoke-RestMethod -AsHashtable`；0 POST、未开始推理，不是 Wan 模型失败。仅有预分配 UUID 不代表已提交。
- [随后左向实验][wan-left]：完成 49 个原帧，但报告为 STOP，8 个缩小样本只是诊断，不是已验证的步行动画。
- [三个方向分别生成][wan-three]：3 次请求完成，随后提取九个姿态并镜像右向，实际产出了格式有效的 144x256 `$BrownAdventurer.png` 候选。[最终 ACCEPTANCE][wan-three-accept] 仅给静态/mockup 暂定通过，保留面部、背向头发及动作分离问题；没有生产、美术播放或引擎验收。

这意味着历史上并非“从未产出过 RMVA 格式图”，而是曾有候选文件，但不能将格式通过写成最终质量通过。该候选的固定裁切、近灰背景去除与镜像是显式后处理，也不能称为原始生成透明度不变。

[三方向同时生成][wan-sim] 的一次请求技术成功，静态审查却发现方向塌缩及不足的行走相位，停止最终选帧/抽图。一次请求同时要求外观变化、三视图和动画，没有因此证明可替代分阶段验证。

## 6. 先接受穿好衣服的静帧，再只做运动

[早期两阶段准备失败][stage-fail] 为 0 POST，原因是 `TextEncodeQwenImage21.images` 输入检查未通过，不是生成质量失败。

修正后的 [Qwen 三视图静帧初审][stage-stop] 指出双发尖和围巾问题，先给 STOP。审查额外提出的“缺内搭/开襟”并非已确认提示词的独立违例，不应事后加标准。

随后 [parent-visual-approval.json][stage-approve] 记录用户明确接受当前布局与外观，覆盖该张参考图的艺术 gate；审批绑定输出 SHA256 `4ec8b54963d71f88c9e257ee8a29332958b33c6eb99c34c6a08ee023f40becc5`。这不是接受所有后续生成，也不是该分支仍永久停止。

继而执行一次 [motion-b800…][stage-motion]，保留 33 个原帧及三条方向 lane 的裁切。静态审查报告服装从首帧已存在、三方向维持，没有从裸模板逐步长出衣服的问题；极端步幅仍有脚/衣摆模糊。没有锁定三格选帧，也没有这一分支的最终 48x64 图集或连续播放验收。

此路线修正的是起始条件和任务拆分，不是证明所有运动、像素质量或模板一致性都已解决。

## 7. Qwen 九姿态、左向三格与纠偏

[九姿态实验][nine] 将已接受的三视图编辑配置扩成 3x3、960x1152 的 A/neutral/B 模板。一次请求完成，外观与方向大体保留，但静态审查认为三方向都退化为接近站立，缺乏相反迈步，停止行走图提取。文字“保留姿态”不是额外的硬结构控制。

[左向三格后续对照][triplet]：一次 Qwen 请求输出 960x384，布局和动作提示词均改变，不是单变量消融。曾提取 144x64 三格候选并因动作可读而通过候选审查，但随后同尺度对照发现 A/B 步幅和摆臂比模板夸张，接近跨步/跑姿；neutral 较接近。后续 STOP 明确撤回早先“符合模板”的判断。[候选 ACCEPTANCE][triplet-accept] 保留这一覆盖关系，技术提取仍有效，模板一致性失败。

[双参考 A 修正][correction] 将模板设为姿态参考、旧 A 设为外观参考。一次请求技术成功，静态审查却报告人物变小/上移、脚底位置变化、紧凑姿态未恢复且蓝夹克/裤子部分丢失，姿态与外观均 FAIL。未替换旧 A，也未用它重组行走图。该结果只否定这一次软参考配置，不证明模型普遍无能，也未隔离具体失败原因。

## 8. 最近：干净模板首尾帧的小过渡

改为先隔离动作控制，不混入目标外观：A → neutral、neutral → B，各 17 帧。一次 UTF-8/准备预检失败为 0 POST；修正后的两段各 1 次实际请求，合计 2 次，仅指这一分支，不是全部历史累计。

规格为原 48x64 最近邻放大 10 倍、放在 480x832 灰背景的 `(0,96)`，seed 20261020、20 steps、高低噪声各 10 步、CFG 3.5、shift 5、Euler/simple、16fps。

[第一段审查][clean-a] 认为首尾约束有限可行，但中间姿态未通过；[第二段与接缝审查][clean-b] 建议优先完整 34 帧拼接，33 帧备选略去第二段首帧，不能称其为逐像素重复帧。

用户接受模板自身约 2 原生像素的纵向差异，不做对齐、混合、插帧或修帧。保留高度差不代表已经证明模型完全无漂移。两版 APNG 均为单次播放，静态审查不证明时间连贯性或无缝循环。这一分支是干净模板测试，不能冒充前面已穿衣参考的运动实验。

## 9. 交接时应保留的判断

- 不把“HTTP success”“格式正确”“外观大致像”“模板动作一致”或“用户接受某张图”混为一项通过。
- 对照必须统一画布、缩放和裁切；人物更生动不等于模板姿态更准确。审查视觉估计不升级为骨骼/关键点数值。
- appearance-only 提示词、灰度参考、边缘控制与双参考均需检查实际图和最终审查；不能仅凭图中存在这些节点就称为硬姿态保证。
- 起始图已经穿好衣服后再生成运动，解决了特定的渐进换装起点问题，但动作和像素质量仍需独立评估。
- 后续先审查已有播放、决定是否选帧；任何新推理都需新的明确授权和预算，不删除历史 intent/lock 重跑。
- 原始提示词和参数以各请求为准。早期报告与后期 system-stats 的软件版本并不完全一致，不拼接成一套从未存在的统一环境。

## 本机证据索引

以下链接均相对本文，依赖迁移未跟踪实验目录；不表示这些文件已随文档提交或上传。

[redraw]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/redraw-v2/README.md
[walk]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/walk-v2/README.md
[control-result]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/prompt-control-appearance-A-67b377b18f454455812ea38fb72ed734/run/A/result.json
[control-verdict]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/prompt-control-appearance-A-67b377b18f454455812ea38fb72ed734/acceptance/verdict.json
[single]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/prompt-control-singleframe-68cb42b89edb471e8cef46af4df6b282/acceptance/verdict.json
[noref]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/prompt-control-noref-3bd789e9475147d3b7f2b38c8aeb7b90/acceptance/verdict.json
[gray]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/prompt-control-gray-A-90fb613af5bb4ea8bac4a27be6d670fa/acceptance/verdict.json
[crown]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/prompt-control-crown-A-927d0ef3ef854fddad53527e97c6ed23/acceptance/verdict.json
[whole-base]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/whole-sheet-gem-baseline-20261014-a71c9e/REPORT.md
[whole-up]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/whole-sheet-gem-upscale4-20261014-b83f21/REPORT.md
[vae]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/whole-sheet-diagnostic-20261014-d9c4a7/REPORT.md
[whole-prompt]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/whole-sheet-appearance-20261014-c4e82b/prompt.txt
[whole-appearance]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/whole-sheet-appearance-20261014-c4e82b/REPORT.md
[whole-stop]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/whole-sheet-appearance-20261014-c4e82b/SUPERVISOR-VERDICT.md
[wan-start-fail]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/wan22-walk-20261017-efdc2e1d362e4184a6e12640a5ec2690/TERMINAL-REPORT.md
[wan-left]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/wan22-walk-20261017-89e8268bd8c44f97820dd8625ac52da9/report.json
[wan-three]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/wan22-three-direction-76b8322a9a5240cabd7fcca3045fb06a/report.json
[wan-three-accept]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/wan22-three-direction-76b8322a9a5240cabd7fcca3045fb06a/rmva-output-8b8d61e2f89047ccba845fdd5e1f1a7c/ACCEPTANCE.md
[wan-sim]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/wan22-simultaneous-e139e6fca35944078f1f32d9370e00a7/VISUAL-REVIEW.md
[stage-fail]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/two-stage-three-view-fa81d5c64005453286828b8369d5c8f0/report.json
[stage-stop]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/two-stage-three-view-eda6f7efdeb140d1beeb6ce63802e6fb/VISUAL-GATE.md
[stage-approve]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/two-stage-three-view-eda6f7efdeb140d1beeb6ce63802e6fb/parent-visual-approval.json
[stage-motion]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/two-stage-three-view-eda6f7efdeb140d1beeb6ce63802e6fb/motion-b800a5204000488f8ae99ecb3aeda3f1/VISUAL-REVIEW.md
[nine]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/qwen-nine-pose-884ef136f75843f298f1b182727d4b46/VISUAL-REVIEW.md
[triplet]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/qwen-left-triplet-968f803f24914fd7918d289e8825a7d0/TEMPLATE-COMPARISON.md
[triplet-accept]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/qwen-left-triplet-968f803f24914fd7918d289e8825a7d0/candidate-left-20261018-a7e391c2/ACCEPTANCE.md
[correction]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/qwen-left-A-correction-45ea8acbe7e04eee99eb4dbc07ee5b4e/VISUAL-REVIEW.md
[clean-a]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/wan22-clean-A-neutral-18e8e4425f0e45dc9a823690e6e1c05b/VISUAL-REVIEW.md
[clean-b]: ../.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36/wan22-clean-neutral-B-1951e3f0eeff4b71b8b25f89142d83c9/VISUAL-REVIEW.md
