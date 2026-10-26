extends Area2D

# Leave empty to go to the next level in Game.LEVELS,
# or pick a specific map to jump to instead.
@export_file("*.tscn") var next_scene: String = ""


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D:
		return
	set_deferred("monitoring", false)
	if next_scene != "":
		get_tree().change_scene_to_file.call_deferred(next_scene)
	else:
		Game.next_level()
