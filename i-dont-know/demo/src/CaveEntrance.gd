extends Area3D

const PLAYER_NAME: String = "Player"
const DIM_LIGHT: float = 0.1
const BRIGHT_LIGHT: float = 1.0
const FADE_TIME: float = 0.33

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.name == PLAYER_NAME:
		var env: WorldEnvironment = get_node_or_null("../../Environment/WorldEnvironment")
		if env:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(env.environment, "ambient_light_energy", DIM_LIGHT, FADE_TIME)
	

func _on_body_exited(body: Node3D) -> void:
	if body.name == PLAYER_NAME:
		var env: WorldEnvironment = get_node_or_null("../../Environment/WorldEnvironment")
		if env:
			var tween: Tween = get_tree().create_tween()
			tween.tween_property(env.environment, "ambient_light_energy", BRIGHT_LIGHT, FADE_TIME)
