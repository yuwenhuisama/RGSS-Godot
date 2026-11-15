# RMVA per-item evidence index

Current recorded acceptance: **57 / 57** within documented measured scope (see [current-status.md](current-status.md)). This index preserves all 55 original items
and the two added items. A representative runner is an entry into the topic,
not proof that one command covers every branch. The linked report owns the
original measurements, actual executions, visual findings and scope limits.
Accepted means accepted only for that documented versioned scope.

Run Godot owners with the .NET editor from the project root using
`godot --headless --path . -s tests/<runner>` for nonvisual contracts. Rendered,
input and fullscreen owners belong inside guests (keep them windowed unless running dedicated fullscreen acceptance); use each report for flags
and prerequisites. Never treat headless rendering as image evidence.

| Item | Requested behavior | Recorded status | Representative entry | Evidence report |
|---|---|---|---|---|
| A01 | 修复 Ruby 异常 报告 与 测试 判定 | Accepted within report scope | `tests/test_ruby_errors.gd` | [ruby-runtime-verification.md](ruby-runtime-verification.md) |
| A02 | 核验 现有 API 测试 初始化 与 断言 | Accepted within report scope | `tests/test_rgss_api.gd` | [api-inventory.md](api-inventory.md) |
| A03 | 统一 独立 测试 入口 与 失败 返回 | Accepted within report scope | `tools/run_tests.gd` | [api-inventory.md](api-inventory.md) |
| A04 | 修复 CI 测试 失败 阻断 行为 | Accepted within report scope | `tools/run_tests.gd` | [api-inventory.md](api-inventory.md) |
| A05 | 建立 官方 接口 实现 与 验收 台账 | Accepted within report scope | `tests/test_rgss_api.gd` | [api-inventory.md](api-inventory.md) |
| A06 | 建立 原版 对照 工程 与 验证 证据 | Accepted within report scope | `tools/prepare_original_fixture.rb` | [original-baseline.md](original-baseline.md) |
| B01 | 补齐 Bitmap 实际 字体 尺寸 度量 | Accepted within report scope | `tests/test_font_metrics.gd` | [font-short-layout-verification.md](font-short-layout-verification.md) |
| B02 | 补齐 字体 名称 选择 与 回退 | Accepted within report scope | `tests/test_font_metrics.gd` | [api-inventory.md](api-inventory.md) |
| B03 | 补齐 字体 样式 与 实际 绘制 | Accepted within report scope | `tests/run_primitive_reference.gd` | [font-short-layout-verification.md](font-short-layout-verification.md) |
| B04 | 核验 基础 数据 类型 与 接口 语义 | Accepted within report scope | `tests/test_value_semantics.gd` | [api-inventory.md](api-inventory.md) |
| B05 | 核验 对象 属性 引用 与 资源 生命周期 | Accepted within report scope | `tests/test_resource_lifecycle.gd` | [reset-resource-verification.md](reset-resource-verification.md) |
| B06 | 补齐 键盘 映射 与 原版 系统键 | Accepted within report scope | `tests/test_game_settings.gd` | [api-inventory.md](api-inventory.md) |
| B07 | 补齐 视频 播放 与 游戏 恢复 | Accepted within report scope | `tests/test_movie_playback.gd` | [api-inventory.md](api-inventory.md) |
| B08 | 补齐 MIDI 播放 与 初始化 行为 | Accepted within report scope | `tests/test_midi_playback.gd` | [software-midi-verification.md](software-midi-verification.md) |
| B09 | 补齐 WMA 与 原版 音频 格式 | Accepted within report scope | `tests/test_audio_formats.gd` | [audio-decoder-distribution.md](audio-decoder-distribution.md), [macos-verification.md](macos-verification.md) |
| C01 | 核验 Bitmap 图像 操作 与 原版 结果 | Accepted within report scope | `tests/run_primitive_reference.gd` | [original-baseline.md](original-baseline.md) |
| C02 | 核验 文字 布局 混排 与 裁剪 | Accepted within report scope | `tests/test_font_short_layout.gd` | [font-short-layout-verification.md](font-short-layout-verification.md) |
| C03 | 核验 Sprite 变换 原点 与 排序 | Accepted within report scope | `tests/run_render_reference.gd` | [original-baseline.md](original-baseline.md) |
| C04 | 核验 Sprite 特效 与 持续 帧数 | Accepted within report scope | `tests/run_render_reference.gd` | [original-baseline.md](original-baseline.md) |
| C05 | 核验 Viewport 裁剪 叠加 与 特效 | Accepted within report scope | `tests/run_render_reference.gd` | [original-baseline.md](original-baseline.md) |
| C06 | 核验 Plane 平铺 滚动 与 混合 | Accepted within report scope | `tests/run_render_reference.gd` | [original-baseline.md](original-baseline.md) |
| C07 | 核验 Window 组成 细节 与 内容 裁剪 | Accepted within report scope | `tests/test_window_transparency.gd` | [window-cursor-shape-verification.md](window-cursor-shape-verification.md) |
| C08 | 核验 Window 动画 透明度 与 闪烁 | Accepted within report scope | `tests/test_window_activation.gd` | [window-activation-verification.md](window-activation-verification.md) |
| C09 | 核验 菜单 背景 回归 与 场景 返回 | Accepted within report scope | `tests/test_menu_round_trip.gd` | [menu-operations-verification.md](menu-operations-verification.md) |
| C10 | 核验 Graphics 效果 快照 与 转场 | Accepted within report scope | `tests/test_graphics_snapshot.gd` | [graphics-verification.md](graphics-verification.md) |
| C11 | 核验 帧 循环 等待 与 场景 切换 | Accepted within report scope | `tests/test_frame_loop.gd` | [graphics-verification.md](graphics-verification.md) |
| C12 | 核验 分辨率 缩放 全屏 与 窗口 | Accepted within report scope | `tests/test_original_fullscreen.gd` | [fullscreen-mode-verification.md](fullscreen-mode-verification.md) |
| D01 | 核验 全部 图块 类型 与 自动 图块 | Accepted within report scope | `tests/run_render_reference.gd` | [tilemap-verification.md](tilemap-verification.md) |
| D02 | 核验 地图 遮挡 循环 与 滚动 | Accepted within report scope | `tests/test_map_camera.gd` | [tilemap-verification.md](tilemap-verification.md) |
| D03 | 核验 角色 行走 跳跃 与 载具 | Accepted within report scope | `tests/test_character_motion.gd` | [character-verification.md](character-verification.md) |
| D04 | 核验 全部 地图 事件 命令 与 执行 | Accepted within report scope | `tests/test_event_control.gd` | [event-command-verification.md](event-command-verification.md) |
| D05 | 核验 消息 交互 输入 与 等待 | Accepted within report scope | `tests/test_message_window.gd` | [message-window-verification.md](message-window-verification.md) |
| D06 | 核验 地图 图片 天气 与 屏幕 效果 | Accepted within report scope | `tests/test_map_screen_render.gd` | [map-screen-render-verification.md](map-screen-render-verification.md) |
| D07 | 核验 全部 默认 菜单 操作 流程 | Accepted within report scope | `tests/test_menu_operations.gd` | [menu-operations-verification.md](menu-operations-verification.md) |
| D08 | 核验 商店 名称 输入 与 默认 场景 | Accepted within report scope | `tests/test_shop_name_operations.gd` | [shop-name-verification.md](shop-name-verification.md) |
| D09 | 核验 地图 长期 运行 与 密集 事件 | Accepted within report scope | `tests/test_dense_map_runtime.gd` | [dense-map-verification.md](dense-map-verification.md) |
| E01 | 核验 完整 战斗 开始 与 结束 流程 | Accepted within report scope | `tests/test_battle_flow.gd` | [battle-flow-verification.md](battle-flow-verification.md) |
| E02 | 核验 战斗 规则 伤害 与 状态 | Accepted within report scope | `tests/test_battle_damage.gd` | [battle-damage-verification.md](battle-damage-verification.md) |
| E03 | 核验 技能 物品 效果 与 公共 事件 | Accepted within report scope | `tests/test_battle_effects.gd` | [battle-effect-verification.md](battle-effect-verification.md) |
| E04 | 核验 战斗 事件 强制 行动 与 顺序 | Accepted within report scope | `tests/test_battle_schedule.gd` | [battle-schedule-verification.md](battle-schedule-verification.md) |
| E05 | 核验 战斗 动画 日志 与 视觉 表现 | Accepted within report scope | `tests/test_battle_animation_pixels.gd` | [battle-animation-verification.md](battle-animation-verification.md) |
| E06 | 核验 BGM BGS 循环 切换 与 渐弱 | Accepted within report scope | `tests/test_audio_loop.gd` | [audio-loop-verification.md](audio-loop-verification.md) |
| E07 | 核验 ME 暂停 BGM 与 恢复 | Accepted within report scope | `tests/test_audio_me.gd` | [audio-me-verification.md](audio-me-verification.md) |
| E08 | 核验 SE 并发 路径 与 RTP 回退 | Accepted within report scope | `tests/test_audio_se.gd` | [se-playback-verification.md](se-playback-verification.md) |
| F01 | 核验 全部 RPG 数据 类型 与 字段 | Accepted within report scope | `tests/test_rpg_database.gd` | [rpg-defaults-verification.md](rpg-defaults-verification.md) |
| F02 | 核验 原版 存档 与 Godot 存档 互通 | Accepted within report scope | `tests/test_save_interchange.gd` | [save-interchange-verification.md](save-interchange-verification.md) |
| F03 | 核验 存档 列表 覆盖 损坏 与 读取 | Accepted within report scope | `tests/test_save_slots.gd` | [save-slots-verification.md](save-slots-verification.md) |
| F04 | 核验 Marshal 引用 序列化 与 文本 编码 | Accepted within report scope | `tests/test_marshal_values.gd` | [marshal-values-verification.md](marshal-values-verification.md) |
| F05 | 核验 Ruby 运行时 与 实际 脚本 差异 | Accepted within report scope | `tests/test_defined_runtime.gd` | [ruby-compiler-verification.md](ruby-compiler-verification.md) |
| F06 | 核验 重置 异常 与 资源 清理 | Accepted within report scope | `tests/test_game_close.gd` | [reset-resource-verification.md](reset-resource-verification.md) |
| F07 | 建立 第三方 脚本 版本 与 测试 集 | Accepted within report scope | `tests/test_third_party_core.gd` | [third-party-script-verification.md](third-party-script-verification.md) |
| F08 | 核验 原生 扩展 依赖 与 支持 范围 | Accepted within report scope | `tests/test_native_extensions.gd` | [native-extension-verification.md](native-extension-verification.md), [macos-verification.md](macos-verification.md) |
| F09 | 建立 真实 游戏 全流程 兼容 测试 集 | Accepted within report scope | `tests/test_save_slots.gd` | [project-flow-acceptance.md](project-flow-acceptance.md) |
| F10 | 核验 桌面 平台 发布 与 原生 库 | Accepted within report scope | `tools/run_linux_release_export.ps1`; `tools/test_macos_game_install.sh` | [file-binary-encoding-verification.md](file-binary-encoding-verification.md), [macos-verification.md](macos-verification.md) |
| F11 | 核验 干净 安装 性能 与 长期 泄漏 | Accepted within report scope | `tests/test_dense_map_runtime.gd` | [installation-resource-verification.md](installation-resource-verification.md), [macos-verification.md](macos-verification.md) |

| Added item | Status | Evidence / remaining condition |
|---|---|---|
| Clean owned fixture projects and temporary resources | Accepted within recorded scope | Seven original projects, 329 experimental directories and 26 tail files removed after archive/SHA256 verification; only six explicitly retained source/toolchain/reparse directories remain. Receipts: `.omo/evidence/authorized-fixture-cleanup`, `remaining-fixtures-cleanup`, `cleanup-tail-removed`. |
| WMA decoder in each platform package | Accepted within report scope | Windows/Linux payload audit and actual package decode pass; Mac arm64 native build, exact WAV/package cache, ten-file audit and actual output pass. [Distribution report](audio-decoder-distribution.md), [Mac report](macos-verification.md). |

Latest combined execution evidence is in [File IO verification](file-binary-encoding-verification.md)
and [Software MIDI verification](software-midi-verification.md). Linux final
package passes offline WMA/native/File/MIDI. Windows successful export has the
same 217 runtime files/EXE/PCK as the isolated guest passing package; final base
coverage comprises 21 passed owners plus the corrected-fixture defined owner
passing separately. Historical failed runs remain visible.

For the concise current compatibility summary, see [current-status.md](current-status.md).
The ledger and historical milestone archive live in [open-acceptance-ledger.md](open-acceptance-ledger.md).
None of the documented limits (Apple Silicon only, no Intel Mac, no notarization, no factory-reset macOS claim, or 7 existing C# warnings) is replaced by a blanket compatibility claim.
