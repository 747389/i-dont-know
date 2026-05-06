extends CharacterBody3D

# Player camera settings that can be adjusted from the Godot editor.
@export var mouse_sensitivity: float = 0.009
@export var max_look_angle: float = 90.0
@export var head: Node

# Stores the player's vertical look angle so it can be clamped.
var x_rotation: float = 0.0

# Stores the race timer state and which control point should be collected next.
var time: float = 0.0
var started: bool = false
var next_control: int = 1

# Movement values for the player controller.
const SPEED = 15.0
const JUMP_VELOCITY = 5.0


# Runs once when the player loads into the scene.
func _ready():
	# Locks the mouse to the game window so mouse movement controls the camera.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# Handles mouse movement before the normal input system uses it.
func _unhandled_input(event):
	# Turns the player left/right and moves the camera up/down when the mouse moves.
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		x_rotation -= event.relative.y * mouse_sensitivity

		# Stops the player from looking too far up or down.
		x_rotation = clamp(
			x_rotation,
			deg_to_rad(-max_look_angle),
			deg_to_rad(max_look_angle)
			)
		head.rotation.x = x_rotation


# Runs every physics frame to control gravity, jumping, and player movement.
func _physics_process(delta: float) -> void:
	# Applies gravity when the player is in the air.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Makes the player jump if the jump key is pressed while on the ground.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Reads WASD input and converts it into movement based on the player's facing direction.
	var input_dir := Input.get_vector("A", "D", "W", "S")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		# Smoothly slows the player down when no movement keys are being pressed.
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	# Moves the CharacterBody3D using the velocity calculated above.
	move_and_slide()


# Runs when the player enters a start, control, or finish area.
func _on_area_3d_area_entered(area: Area3D) -> void:
	# Starts the race timer when the player enters the start area.
	if area.has_meta("Start"):
		time = Time.get_ticks_msec()
		started = true
		next_control = 1
		print("GO")
		area.queue_free()
		
	# Checks if the player has collected the next correct control point.
	if area.has_meta("control") and started:
		if area.control_number == next_control:
			next_control += 1
			print("Control ", area.control_number, " collected!")
			area.queue_free()
		else:
			# Tells the player which control they need if they enter the wrong one.
			print("Wrong control! Need control ", next_control) 
	
	# Ends the race only if the finish area is reached after all required controls.
	if area.has_meta("Finish"):
		if area.control_number == next_control:
			started = false

			# Converts the elapsed milliseconds into a readable minutes:seconds:milliseconds time.
			var elapsed = (Time.get_ticks_msec() - time) / 1000.0
			var minutes = int(elapsed) / 60
			var seconds = int(elapsed) % 60
			var milliseconds = int(elapsed * 1000) % 1000
			print("Time taken: %02d:%02d:%03d" % [minutes, seconds, milliseconds])
			time = 0.0
			area.queue_free()
		else:
			# Stops the player from finishing before they collect the next required control.
			print("Wrong control Need control ", next_control)
