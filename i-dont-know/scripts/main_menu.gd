extends CanvasLayer

const METHOD : StringName = &"change_scene_to_packed"
const LEVEL_1 := preload("res://level/level.tscn")


# Go to level 1
func _on_button_pressed() -> void:
	get_tree().call_deferred(METHOD, LEVEL_1)
