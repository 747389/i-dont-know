extends Area3D


@export var control_number: int = 0


# Set the finsh controal number
func _ready() -> void:
	control_number = Global.finsh_control
