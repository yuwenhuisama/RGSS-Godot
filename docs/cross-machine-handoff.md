# RGSS-Godot 跨机器交接手册

本文档记录从当前开发机迁移至新机器的完整交接要求、验证记录与实验资产规范。

## 1. 代码仓库与基础依赖

### 1.1 仓库克隆
新机器执行递归克隆（包含子模块）：
```bash
git clone --recurse-submodules -b main git@github.com:yuwenhuisama/RGSS-Godot.git
```
文档更新前的代码基线：`f45ee8c85535c36936a713fd50279fa2a7a26600`；更新前已核对远端 `main` 同为此提交。新机器应拉取后续文档提交，而非回退到此基线。
后续提交追溯请使用 `git log` 或 `HEAD`，不硬编码预测最终 SHA。
如果本地终端策略启用了 `$env:GIT_MASTER='1';`，在 PowerShell 中按需设置即可，常规 git 命令同样有效。

### 1.2 运行时与工具链
- **.NET SDK**: .NET 8 目标框架（已在 .NET 10.0.204 SDK 下验证编译）
- **Godot**: Godot 4.6.1 mono 专版（如 `Godot_v4.6.1-stable_mono_win64_console.exe`）
- **MRuby.Library 0.2.0**: csproj 声明 `ExcludeAssets="contentFiles"`，避免 NuGet 自带二进制覆盖本地原生库。
- **Native ABI**: mruby 4.0 单一原生权威库位于 `Plugins/windows/`，包含 `libmruby_x64.dll` 与扩展 gem。
- **外部源码与构建依赖**: 头文件硬编码路径 `E:/Projects/mruby-for-dotnet/mruby`、被忽略的 host import library 和 Onigmo 静态库仅在重新编译 native 扩展时需要；逐项核对各 `xmake.lua`。CI 的 host 来源为 `mruby-for-dotnet` 的 `v0.2.0`。marshal 子模块锁定提交为 `851c8b76183ae30dfea0aef6d959ae13e0d45c6d`，其余以父仓库 gitlink 为准，勿自动升级到分支最新提交。
- `RGSS-Godot.csproj` 有条件使用 `E:\Godot\GodotSharp`，新机器应核对其是否误指向旧安装。`mruby-ext/AGENTS.md` 中的 `Assets/Plugins/windows` 是旧路径，本项目运行库实际位于根目录 `Plugins/windows/`。
- **Kernel.eval 补丁**: `RGSS/main.rb` 开头注入 `module Kernel; module_function :eval; end`，保证伤害公式与动态求值正常。
- **外部仓库 Medot**: 属独立外部仓库，需单独克隆自有分支，其路线图历史结论未在此处重新验证。

## 2. 路径配置规范 (rm_conf.json)

文件位置在工程根目录，格式为 JSON（支持 UTF-8 BOM/无 BOM）：
```json
{
  "rtp_path": "F:/Softwares/RPG Maker VX Ace/RTP",
  "project_path": "E:/Projects",
  "legacy_mode": true,
  "legacy_mode_width": 544,
  "legacy_mode_height": 416,
  "cn_ver_rmva": true
}
```
**关键规则**：
- 建议将 `project_path` 配成**包含 `RMProject` 目录的绝对父路径**（如 `E:/Projects`），程序会拼接 `RMProject/`。直接传入以 `RMProject` 结尾的路径也会被归一化为父路径；不要配成 `Data/`。相对路径相对于进程可执行文件目录解析，不是相对于仓库根目录，详见 `Scripts/RMProjectPath.cs`。
- 仓库默认提交值曾为 `E:/Projects/RGSS-Unity/Assets/StreamingAssets`。当前开发机实际路径为 `E:/Projects`（对应 `E:/Projects/RMProject`）。
- 新机器部署时请**本地修改**配置；合法持有的游戏 `RMProject/Data/`（包含 `Scripts.rvdata2`）、Graphics、Audio 及所需 RTP 资产必须另行迁移，不随代码克隆获得，不提交版权游戏内容。
- `Scripts/GlobalConfig.cs` 优先读取可执行文件旁的 `rm_conf.json`，然后才是项目目录及工作目录；遇到改配置不生效时先检查旧配置遮蔽。

## 3. 构建与测试验证

### 3.1 构建命令
先进入新克隆仓库根目录，将 `$Godot` 替换为新机器实际安装路径：
```powershell
$Godot = "E:\Godot\Godot_v4.6.1-stable_mono_win64_console.exe"
& $Godot --version
dotnet restore
dotnet build RGSS-Godot.csproj --no-restore
```
当前脏工作树下实测结果：.NET 10.0.204 构建 0 错误、5 警告。

### 3.2 自动化测试与场景树验证
分别运行 GUT 测试套件及三个独立 SceneTree 测试：
```powershell
# 1. GUT 单元测试套件（实测 1 通过，3 忽略）
& $Godot --headless --path . -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gexit

# 2. RGSS API 兼容性测试（实测 83/83 通过）
& $Godot --headless --path . -s tests/test_rgss_api.gd

# 3. 伤害公式与 eval 测试（实测 5/5 通过）
& $Godot --headless --path . -s tests/test_eval_damage_fix.gd

# 4. 对象释放压力测试（实测 PASS）
& $Godot --headless --path . -s tests/test_stress_dispose.gd
```

### 3.3 无头启动验证与已知日志
运行无头引导验证：
```powershell
& $Godot --headless --path . --quit-after 30
```
- **通过标记**: 正常输出 `SCRIPTS_LOADED:OK`、`MAIN_LOADED:OK`，进入 `Running RGSS3 main loop...` 且进程退出码为 0。
- **尚未解决的问题，不能按干净启动通过处理**:
  - `GameRenderManager.cs:1394` 在 headless dummy renderer 中捕获纹理时报 `ERROR: Parameter "t" is null`，未证明存在有效回退
  - 示例音频 `Theme1.ogg` 加载失败
  - 退出时引擎报告 `ObjectDB leak`

### 3.4 状态说明
当前全新克隆环境尚未跑过全量自动化验证，当前工作树中修改过的 native marshal DLL 也未推送到远端，新机器必须重新确认这些二进制文件。

## 4. 本地未提交文件保留清册

当前开发机存在 5 项预先存在的未提交改动，交接时保持原样，切勿随意丢弃：
1. `.sisyphus/notepads/rmva-template-support/learnings.md`: 本地开发记录
2. `Plugins/windows/` 下的 marshal DLL 二进制
3. `opencode.json`: 本地配置
4. `project.godot`: window aspect 移除改动
5. `rm_conf.json`: 本地工程路径设定

以上不在本次文档提交内。若需复现当前二进制，单独安全备份修改的 marshal DLL；当前 SHA256 为 `e63bc2ce9067c56c2f54b3ad0e242a781e4a3daf6207ae0325087ece51ad7f81`，大小 61952 字节。先验证 Git 版本，再按需要比对本地版本；本文不保证二者行为相同。

**安全提示**：
- 切勿读取或复制 `opencode` 凭据、API Token 等机密文件。
- `.godot/`、生成的 `.import` 元数据、`node_modules/` 等构建缓存无需迁移。不要整目录盲传 `oh-my-tokens.json` 等可能含凭据的文件；如需代理工具配置，逐项审查后单独配置。

## 5. Wan 2.2 离线精灵实验资产迁移

### 5.1 实验根目录
所有实验文件位于未跟踪目录：
`E:\Projects\RGSS-Godot\.sprite-inspection-f6224097632b4e5fa4aaa03e86679a36\`

### 5.2 必须复制的文件与目录清单
当前尚未创建归档文件，请使用手动文件拷贝：
1. **源图片**: `source-left0.png`、`source-left1.png`、`source-left2.png`
2. **全局 Intent 锁**:
   - `clean-A-neutral-global-submission-intent.json`
   - `clean-neutral-B-global-submission-intent.json`
3. **两个运行目录完整内容**:
   - `wan22-clean-A-neutral-18e8e4425f0e45dc9a823690e6e1c05b/`
   - `wan22-clean-neutral-B-1951e3f0eeff4b71b8b25f89142d83c9/`
   包含其中的 `output/raw/`（各 17 帧）、`graph.json`、脚本、manifest、报告、APNG、`stitch/` 等。
4. **排除项**: `cache/`、`database/comfyui.db`、`temp/`、`base/` 等本地临时运行时目录。
5. **绝对路径映射处理**: `mapping-full-34.json` 中的 `E:\Projects...` 属于不可变证据，切勿就地修改，迁移后在新环境按相对作业路径解析。

### 5.3 关键模型与运行环境参数
- **推理环境**: ComfyUI-Portable v0.39.0，Python 3.13.14，PyTorch 2.9.0+cu130，RTX 4090 24GB
- **原机器 runtime**: `F:\AI\ComfyUI-Qwen21-v0.39.0-20261009\ComfyUI_windows_portable`；查看或处理已有帧无需部署整个生成环境，未来生成才需要。以上为历史记录，不是新机器已安装状态。
- **模型目录**: `F:\Downloads\wan2.2`（外部独立依赖，非 Git 管理，未来若需重新生成需单独部署）
- **确切模型文件名**:
  - 高噪扩散模型: `wan2.2_i2v_high_noise_14B_fp8_scaled.safetensors`
  - 低噪扩散模型: `wan2.2_i2v_low_noise_14B_fp8_scaled.safetensors`
  - 文本编码器: `umt5_xxl_fp8_e4m3fn_scaled.safetensors`
  - VAE: `wan_2.1_vae.safetensors`
- **采样参数**:
  - 输入处理: 48x64 原图最近邻放大 10 倍至 480x640，放置在 (0,96) 坐标，背景灰度 RGB(128,128,128)，画布 480x832
  - 采样步数 20（前 10 步 high，后 10 步 low），Seed 20261020，CFG 3.5，Shift 5.0，Euler/Simple，16fps，17 帧

### 5.4 实验评估现状与后续限制
- **生成记录**: 实际仅执行了 2 次 POST 提交（A->Neutral 17 帧 + Neutral->B 17 帧），未进行第三次 POST，亦未请求重新生成。
- **拼接结果**:
  - 推荐优先序列: `stitch/joined-full-34.apng`（34 帧，约 17.1MB，2.125 秒，保留完整 P0..P16 与 N0..N16）
  - 备用序列: `stitch/joined-candidate-33.apng`（33 帧，约 16.9MB，2.0625 秒，略过近中立帧 N0）
- **视觉评审结论**:
  - 仅纯素体模板技术测试，无外衣、头发、最终图集提取，无游戏集成。
   - 第一段中间行走帧未通过姿态验收；接缝仅做过静态审查，未进行游戏内角色验证。
   - 未观察连续播放，也未验证无缝循环。34 帧推荐仅针对静态接缝，不推翻第一段姿态问题。模板固有约 2 原生像素的上下差异已获用户接受，放大后约 20 像素，未做对齐、混合或插帧；APNG 为 16fps 单次播放。
  - 视觉检查仅限多模态看图（如 multimodal-looker），当前主模型不直接读取图片数据。
  - **后续动作**: 未经用户明确授权，绝对禁止自动执行第三次 POST；后续若需推进，必须先对已有序列做回放评审并选择关键帧。

## 6. 跨机器迁移检查清单

- [ ] **代码库与 Git**:
  - 克隆包含 submodules 的 main 分支
  - 检查 submodules 处于锁定提交状态
  - 确认 5 项本地未提交文件按需同步，不泄露凭据
- [ ] **开发环境**:
  - 安装 .NET 8 SDK
  - 配置 Godot 4.6.1 mono 引擎路径
  - 校验 `Plugins/windows/` 原生 mruby 库
- [ ] **本地游戏资产**:
  - 本地配置 `rm_conf.json` 指向正确的 RMProject 父目录与 RTP 路径
  - 运行 dotnet build 与四项无头场景测试确认通过
- [ ] **精灵实验资产**:
   - 复制 3 张源图、2 个 intent 文件及 2 个运行目录的 raw/report/stitch 输出
   - 验证文件哈希，保持历史 intent 锁不变，严禁重复运行已完成任务

生成脚本、模型配置和历史 manifest 含 `E:` / `F:` 绝对路径，复制并不等于可直接运行。只为未来获授权的新任务创建新目录和新预算，重新核对路径与 preflight；不得删除旧锁、复用旧 runner 或改写历史证据。
