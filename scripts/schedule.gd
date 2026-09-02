class_name Schedule
## 刀男日程表查询：按现实时间决定刀男在哪个房间、干什么、说什么
## 数据在 data/schedules.json，格式见该文件；新刀男照抄一段改内容即可

const DATA_PATH := "res://data/schedules.json"


static func _data() -> Dictionary:
	var f := FileAccess.open(DATA_PATH, FileAccess.READ)
	if f == null:
		push_error("日程表读取失败: " + DATA_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}


static func all_npc_ids() -> Array:
	return _data().keys()


## 查某个刀男在指定时刻的日程槽；hour/minute 不传则用现实时间
## 返回 {from, activity, room, pos, mode, lines}；查无此人返回 {}
static func current_slot(npc_id: String, hour := -1, minute := -1) -> Dictionary:
	if hour < 0:
		var t := Time.get_time_dict_from_system()
		hour = t.hour
		minute = t.minute
	var entries: Array = _data().get(npc_id, [])
	if entries.is_empty():
		return {}
	var now := hour * 60 + minute
	var best: Dictionary = entries[entries.size() - 1]  # 默认用最后一段（跨午夜回卷）
	for e in entries:
		var parts: PackedStringArray = str(e.get("from", "00:00")).split(":")
		var start := int(parts[0]) * 60 + int(parts[1])
		if start <= now:
			best = e
		else:
			break
	return best
