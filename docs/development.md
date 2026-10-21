# 开发进展与工程验证记录

本文档汇总当前工作区经实际运行命令验证的进展、测试表现与遗留问题。相关交接材料请参考 [docs/cross-machine-handoff.md](cross-machine-handoff.md)，演进规划请参考 [.sisyphus/plans/editor-evolution-roadmap.md](../.sisyphus/plans/editor-evolution-roadmap.md)。

## 1. 代码基线与运行环境

- 主线基线 SHA：`f45ee8c`。
- .NET 宿主 SDK：`10.0.204`，项目编译目标为 `net8.0`（通过 `Godot.NET.Sdk 4.6.1`）。
- Godot 引擎版本：`Godot_v4.6.1-stable_mono_win64_console.exe`（`4.6.1.stable.mono.official.14d19694e`）。
- mruby 架构：采用托管包 `MRuby.Library 0.2.0`（对应 mruby 4.0），已发布 4 个原生扩展 gem（`marshal`、`glob`、`regexp`、`zlib`），锁版 `marshal` 提交至 `851c8b7`。
- 核心补丁：`RGSS/main.rb` 包含 `Kernel.eval` 补丁，确保伤害公式中显式接收者求值正常生效；渲染与 Fiber 兼容性补丁按实际代码与日志落地。
- 编辑器定位说明：Medot 编辑器属于独立外部仓库，需在其专属交接流程中推进。本仓库未实现任何编辑器产品，规划文档仅做架构参考。

## 2. 当前编译与验证结果

注意：以下数据来自当前本地脏工作区（dirty worktree）。干净克隆（fresh clone）尚未独立验证，请勿将通过结果视为干净提交状态。

### C# 项目编译

执行命令：
```sh
dotnet build RGSS-Godot.csproj --no-restore
```
- 结果：exit code 0。
- 警告数量：5 处（CS0618: Bitmap 19 行；CS8604: Kernel 40 行、UnityModule 87 行；CS8619: Font 48 行与 74 行）。

### GUT 测试套件与独立测试

1. GUT 9.6 批处理命令：
   ```sh
   godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit
   ```
   仅运行并通过 1 个 sample 测试；3 个独立 `SceneTree` 脚本因不继承 `GutTest` 而被忽略，不能将此命令视为全量测试通过。
2. 独立 API 测试：
   ```sh
   godot --headless --path . -s tests/test_rgss_api.gd
   ```
   测试通过（83/83，exit code 0）。
3. 伤害公式求值测试：
   ```sh
   godot --headless --path . -s tests/test_eval_damage_fix.gd
   ```
   测试通过（5/5，exit code 0）。
4. 资源释放压力测试：
   ```sh
   godot --headless --path . -s tests/test_stress_dispose.gd
   ```
   输出 `STRESS_PASS`，exit code 0。

### 引擎引导与运行现状（Headless Boot）

执行命令：
```sh
godot --headless --path . --quit-after 30
```
- 引导标记：成功打印 `SCRIPTS_LOADED:OK`、`MAIN_LOADED:OK` 以及 `Running RGSS3 main loop...`。
- 引导缺陷（未达到干净启动）：
  - 提示 `Parameter 't' is null` 错误，位于 headless 模式下 dummy 捕获（`GameRenderManager.CaptureFrozenTextureNow:1394`）。
  - 音频加载失败：`AUDIO_LOAD_FAIL: E:\Projects/RMProject/Audio/BGM/Theme1.ogg`。
  - 进程退出时检测到 ObjectDB 资源泄漏警告。

## 3. 工作区未提交状态（Dirty Worktree）

当前本地工作区包含尚未提交或处于临时状态的资产：
- 已修改的 `marshal` DLL（文件大小为 61952 字节）。
- `rm_conf` 项目配置路径指向 `E:/Projects`（主线跟踪基线为 `E:/Projects/RGSS-Unity/Assets/StreamingAssets`）。

## 4. 独立实验：Wan FLF 动作生成（非引擎模块）

本节记录独立的 Wan FLF 图像/视频生成探索实验，与 RGSS 运行时引擎解耦：
- 生成批次：A → neutral 17 帧，neutral → B 17 帧；两段累计 2 次实际 POST，共 34 个原帧。
- 静态接缝审查建议优先保留完整 34 帧拼接 `joined-full-34.apng`；33 帧备选 `joined-candidate-33.apng` 仅略去第二段首帧 N0。两段 neutral 端点并非精确重复帧。
- 规格参数：480x832 分辨率，16 fps 单次播放，仅做静态审查，未做连续回放评估。
- 质量结论：仅有静态接缝偏好，不构成整段验收；第一片段中间帧姿态仍不可靠，连续播放及循环均未验证。
- 模板状态：已接受模板存在约 2 像素上下轻微晃动（2px bob），未做额外对齐，无服装外观覆盖，未导出 RMVA 行走图图集（sheet），未集成至游戏工程。详细清单见 [docs/cross-machine-handoff.md](cross-machine-handoff.md)。
