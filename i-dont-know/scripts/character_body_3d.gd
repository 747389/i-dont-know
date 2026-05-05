extends CharacterBody3D

@export var mouse_sensitivity: float = 0.009
@export var max_look_angle: float = 90.0
@export var head: Node
var x_rotation: float = 0.0
var time: float = 0.0
var started: bool = false
var next_control: int = 0
const SPEED = 15.0
const JUMP_VELOCITY = 5.0


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
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("A", "D", "W", "S")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.has_meta("Start"):
		time = Time.get_ticks_msec()
		started = true
		next_control = 1
		print("GO")
		area.queue_free()
		
	if area.has_meta("control") and started:
		if area.control_number == next_control:
			next_control += 1
			print("Control ", area.control_number, " collected!")
			area.queue_free()
		else:
			print("Wrong control! Need control ", next_control) 
	
	if area.has_meta("Finish"):
		if area.control_number == next_control:
			started = false
			var elapsed = (Time.get_ticks_msec() - time) / 1000.0
			var minutes = int(elapsed) / 60
			var seconds = int(elapsed) % 60
			var milliseconds = int(elapsed * 1000) % 1000
			print("Time taken: %02d:%02d:%03d" % [minutes, seconds, milliseconds])
			time = 0.0
			area.queue_free()
		else:
			print("Wrong control Need control ", next_control)
