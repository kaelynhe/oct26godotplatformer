extends CanvasLayer

# Every level in order. The white dog on each one sends you to the next.
const LEVELS: Array[String] = [
	"res://main.tscn",
	"res://level2.tscn",
	"res://level3.tscn",
	"res://level4.tscn",
	"res://level5.tscn",
	"res://level6.tscn",
	"res://level7.tscn",
	"res://level8.tscn",
	"res://level9.tscn",
	"res://level10.tscn",
]

var elapsed := 0.0
var finished := false

@onready var level_label: Label = $LevelLabel
@onready var time_label: Label = $TimeLabel
@onready var win_box: Control = $WinBox
@onready var win_label: Label = $WinBox/Panel/WinLabel


func _process(delta: float) -> void:
	if not finished:
		elapsed += delta

	var number := current_level_index() + 1
	level_label.text = "Level %d / %d" % [number, LEVELS.size()] if number > 0 else ""
	time_label.text = "Time " + format_time(elapsed)

	if finished and Input.is_action_just_pressed("Jump"):
		restart()


func current_level_index() -> int:
	var scene := get_tree().current_scene
	return LEVELS.find(scene.scene_file_path) if scene else -1


func next_level() -> void:
	if finished:
		return
	var next := current_level_index() + 1
	if next > 0 and next < LEVELS.size():
		get_tree().change_scene_to_file.call_deferred(LEVELS[next])
	else:
		finished = true
		win_label.text = "You found all the dogs!\nTime %s\nPress Space to play again" % format_time(elapsed)
		win_box.show()


func restart() -> void:
	elapsed = 0.0
	finished = false
	win_box.hide()
	get_tree().change_scene_to_file.call_deferred(LEVELS[0])


func format_time(seconds: float) -> String:
	return "%02d:%05.2f" % [int(seconds) / 60, fmod(seconds, 60.0)]
