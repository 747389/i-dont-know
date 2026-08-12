extends Area3D

@export var control_number: int = 0


func _ready() -> void:
	control_number = Global.finsh_control
