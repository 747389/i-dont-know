extends CharacterBody3D

const SPEED: float = 15.0
const JUMP_VELOCITY: float = 5.0

@export var mouse_sensitivity: float = 0.009
@export var max_look_angle: float = 90.0
@export var head: Node

var x_rotation: float = 0.0
var start_time: int = 0
var course_started: bool = false
var next_control: int = 1


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		x_rotation -= event.relative.y * mouse_sensitivity

		x_rotation = clamp(
			x_rotation,
			deg_to_rad(-max_look_angle),
			deg_to_rad(max_look_angle)
		)
		head.rotation.x = x_rotation


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir: Vector2 = Input.get_vector("A", "D", "W", "S")
	var input_vector: Vector3 = Vector3(input_dir.x, 0, input_dir.y)
	var direction: Vector3 = (transform.basis * input_vector).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.has_meta("Start"):
		start_time = Time.get_ticks_msec()
		course_started = true
		next_control = 1
		print("GO")
		area.queue_free()

	if area.has_meta("control") and course_started:
		if area.control_number == next_control:
			next_control += 1
			print("Control ", area.control_number, " collected!")
			area.queue_free()
		else:
			print("Wrong control! Need control ", next_control)

	if area.has_meta("Finish"):
		if area.control_number == next_control:
			course_started = false

			var elapsed: float = float(Time.get_ticks_msec() - start_time) / 1000.0
			var minutes: int = int(elapsed / 60.0)
			var seconds: int = int(elapsed) % 60
			var milliseconds: int = int(elapsed * 1000) % 1000
			print("Time taken: %02d:%02d:%03d" % [minutes, seconds, milliseconds])
			start_time = 0
			area.queue_free()
		else:
			print("Wrong control Need control ", next_control)
