# marumaru 仓库协作备忘

本丸同人陪伴小游戏（刀剑乱舞），Godot 4.7.2 + GDScript，像素风。
项目在 `D:\Dev\marumaru`，GitHub 私仓 `DbDB68/marumaru`（分支 master）。

## 跑法

- 编辑器：`D:\Godot\Godot_v4.7.2-stable_win64.exe`，导入 `D:\Dev\marumaru\project.godot`，F5 运行
- 无头验证：`D:\Godot\Godot_v4.7.2-stable_win64_console.exe --headless --path D:\Dev\marumaru --quit-after 60`

## 回归测试（改动后必须跑）

```
# 对话系统
godot --headless --path D:\Dev\marumaru --script res://tools/test_dialog.gd
# 日程表
godot --headless --path D:\Dev\marumaru --script res://tools/test_schedule.gd
# 远征番茄钟
godot --headless --path D:\Dev\marumaru --script res://tools/test_expedition.gd
# 双人小剧场数据
godot --headless --path D:\Dev\marumaru --script res://tools/test_banter.gd
# 场景切换（按现实时刻断言 NPC 位置，注意当前时刻对应的日程）
godot --headless --path D:\Dev\marumaru res://tools/test_switch.tscn
# 小剧场实况冒烟（生成两位刀男摆一起，应触发搭话）
godot --headless --path D:\Dev\marumaru res://tools/test_banter_live.tscn
```

## 结构

- `scenes/` 场景：`main.tscn`（主屋）、`courtyard.tscn`（庭院）、`npcs/<id>.tscn`（刀男）、`door.tscn`、`dialog_box.tscn`、`expedition_panel.tscn`
- `scripts/`：`game.gd`（Autoload Game，切场景+时钟）、`expedition.gd`（Autoload Expedition）、`schedule.gd`（class_name Schedule，读日程 JSON）、`banter.gd`（双刀小剧场，room.gd 每房间实例化）、`npc.gd`、`player.gd`、`room.gd`、`door.gd`、`dialog_box.gd`
- `data/schedules.json` 刀男日程：from/activity/room(main|courtyard)/pos/mode(wander|stay)/lines，用户可手改
- `data/interactions.json` 双人小剧场对白：键为字典序 `id1+id2`，值是若干段 `[{who, text}, ...]`
- `tools/gen_placeholders.py` 占位素材生成器（PIL），改完重跑覆盖 `assets/sprites/`
- 存档：`user://expedition.json`（远征状态，离线结算用）

## 约定

- 新刀男入住 = `data/schedules.json` 加一段 + `scenes/npcs/<id>.tscn` + 画皮（`tools/gen_placeholders.py`）
- 新双人互动 = `data/interactions.json` 加一段（键按字典序 `id1+id2`）；两位得有同房间时段才会触发
- commit 带署名尾巴：AI co-author 使用实际参与该提交的模型标识；不同模型不得继承或冒用其他模型署名。多人/多模型共同参与时可分别署名。
- 推送：commit 后直接 push 到 master，不用逐次问；force-push / 仓库公开 / 删数据要先问老大
