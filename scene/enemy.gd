extends CharacterBody2D


const SPEED = 150.0


var player: CharacterBody2D

func _ready() -> void:
	player = get_parent().get_node("Player")

# TODO: remember to consolodate layer masks for collisions later
func _physics_process(delta: float) -> void:
	if player:
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * SPEED	
		move_and_slide()
