extends Area3D

@export var control_number: int = 0


func _ready() -> void:
	Global.finsh_control = control_number
