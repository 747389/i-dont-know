extends Node3D

const START_COLLTION_LAYER: int = 0

@export var start_area: StaticBody3D


# Disabel the colltion of the start box when the course is started
func _physics_process(_delta: float) -> void:
	if Global.course_started:
		start_area.collision_layer = START_COLLTION_LAYER
