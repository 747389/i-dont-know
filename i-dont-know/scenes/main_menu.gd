extends Node2D


# Go to levle 1
func _on_button_pressed() -> void:
	get_tree().call_deferred("change_scene_to_file", "res://level/level.tscn")
