# marumaru 仓库协作备忘

本丸同人陪伴小游戏（刀剑乱舞），Godot 4.7.2 + GDScript，像素风。
项目在 `E:\marumaru`，GitHub 私仓 `DbDB68/marumaru`（分支 master）。

## 跑法

- 编辑器：`D:\Godot\Godot_v4.7.2-stable_win64.exe`，导入 `E:\marumaru\project.godot`，F5 运行
- 无头验证：`D:\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path E:\marumaru --quit-after 60`

## 回归测试（改动后必须跑）

```
# 对话系统
godot --headless --path E:\marumaru --script res://tools/test_dialog.gd
# 日程表
godot --headless --path E:\marumaru --script res://tools/test_schedule.gd
# 远征番茄钟
godot --headless --path E:\marumaru --script res://tools/test_expedition.gd
# 场景切换（按现实时刻断言 NPC 位置，注意当前时刻对应的日程）
godot --headless --path E:\marumaru res://tools/test_switch.tscn
```

## 结构

- `scenes/` 场景：`main.tscn`（主屋）、`courtyard.tscn`（庭院）、`npcs/<id>.tscn`（刀男）、`door.tscn`、`dialog_box.tscn`、`expedition_panel.tscn`
- `scripts/`：`game.gd`（Autoload Game，切场景+时钟）、`expedition.gd`（Autoload Expedition）、`schedule.gd`（class_name Schedule，读日程 JSON）、`npc.gd`、`player.gd`、`room.gd`、`door.gd`、`dialog_box.gd`
- `data/schedules.json` 刀男日程：from/activity/room(main|courtyard)/pos/mode(wander|stay)/lines，用户可手改
- `tools/gen_placeholders.py` 占位素材生成器（PIL），改完重跑覆盖 `assets/sprites/`
- 存档：`user://expedition.json`（远征状态，离线结算用）

## 约定

- 新刀男入住 = `data/schedules.json` 加一段 + `scenes/npcs/<id>.tscn` + 画皮（`tools/gen_placeholders.py`）
- commit 带署名尾巴：`Co-authored-by: k3 <k3@users.noreply.github.com>`
- 推送：commit 后直接 push 到 master，不用逐次问；force-push / 仓库公开 / 删数据要先问老大
