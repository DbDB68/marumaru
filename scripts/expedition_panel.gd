extends CanvasLayer
## 远征面板：E 键开关；选时长派出，或取消远征

@onready var panel: PanelContainer = $Panel
@onready var status: Label = $Panel/VBox/Status
@onready var start_buttons: HBoxContainer = $Panel/VBox/StartButtons
@onready var cancel_button: Button = $Panel/VBox/BottomButtons/Cancel


func _ready() -> void:
	add_to_group("expedition_panel")
	panel.hide()
	$Panel/VBox/StartButtons/B25.pressed.connect(func() -> void: Expedition.start(25))
	$Panel/VBox/StartButtons/B45.pressed.connect(func() -> void: Expedition.start(45))
	$Panel/VBox/StartButtons/B60.pressed.connect(func() -> void: Expedition.start(60))
	cancel_button.pressed.connect(_on_cancel)
	$Panel/VBox/BottomButtons/Close.pressed.connect(close)


func _process(_delta: float) -> void:
	if panel.visible:
		_refresh()


func toggle() -> void:
	panel.visible = not panel.visible
	if panel.visible:
		_refresh()


func close() -> void:
	panel.hide()


func is_open() -> bool:
	return panel.visible


func _refresh() -> void:
	var active := Expedition.is_active()
	if active:
		var s := Expedition.remaining_seconds()
		status.text = "远征中：还剩 %02d:%02d" % [s / 60, s % 60]
	elif Expedition.has_pending_report():
		status.text = "远征部队回来了！"
	else:
		status.text = "未派出。选个时长："
	for b in start_buttons.get_children():
		b.disabled = active
	cancel_button.disabled = not active


func _on_cancel() -> void:
	Expedition.cancel()
	_refresh()
