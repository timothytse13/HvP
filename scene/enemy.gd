extends CharacterBody2D

signal died

enum State {
	APPROACH,
	ATTACH,
	RETREAT
}


const SPEED = 150.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var player: CharacterBody2D
var enemy_scene: PackedScene = preload("res://scene/enemy.tscn")

var max_health: int = 100
var health: int = max_health

var current_state = State.APPROACH

func _ready() -> void:
	player = get_parent().get_node("Player")

func approach() -> void:
	var distance = global_position.distance_to(player.global_position)
	nav_agent.target_position = player.global_position
	print("Distance: ", distance)
	if distance <= 75: # Distance between player and enemy before stopping
		velocity = Vector2.ZERO
		move_and_slide() #eventually transition to next state
		return
	var next_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	velocity = direction * SPEED
	move_and_slide()

func attack() -> void:
	# Move closer to player
	# Attack function
	# Retreat
	pass

func _physics_process(delta: float) -> void:
	if not player:
		return
	match current_state:
		State.APPROACH:
			print("Entered approach")
			approach()
		State.ATTACH:
			pass
		State.RETREAT:
			pass

func take_damage(amount: int) -> void:
	health = health - amount
	$HealthBar.value = health
	if health <= 0:
		die()
		
func die() -> void:
	died.emit()
	queue_free()
