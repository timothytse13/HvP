extends CharacterBody2D

signal died

enum State {
	APPROACH,
	ATTACK,
	RETREAT
}


const SPEED = 150.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var player: CharacterBody2D
var enemy_scene: PackedScene = preload("res://scene/enemy.tscn")
var facing_direction: Vector2 = Vector2.DOWN

var max_health: int = 100
var health: int = max_health
var attack_count: int = 0

var current_state = State.APPROACH

func _ready() -> void:
	player = get_parent().get_node("Player")

func approach() -> void:
	var distance = global_position.distance_to(player.global_position)
	nav_agent.target_position = player.global_position
	print("Distance: ", distance)
	if distance <= 22: # Distance between player and enemy before stopping
		#velocity = Vector2.ZERO
		#move_and_slide() #eventually transition to next state
		current_state = State.ATTACK
		#return
	var next_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	velocity = direction * SPEED
	move_and_slide()

#TODO: So far the enemy is relentless will instantly deal damage to player the moment the player body enters hitbox. Fix with timer probably
#TODO: Enemy also attacks, then sits there since no movement logic for pursuit. Fix with check for attack distance then attack
func attack() -> void:
	if $AttackTimer.is_stopped():
		print("attack timer stopped")
		facing_direction = global_position.direction_to(player.global_position)
		$AttackArea.position = facing_direction * 30
		print("Bodies detected: ", $AttackArea.get_overlapping_bodies().size())
		for body in $AttackArea.get_overlapping_bodies():
			if body.is_in_group("Player"):
				body.take_damage(10)
				print("Enemy succesfully attacked player")
		attack_count = attack_count + 1
		$AttackTimer.start()
		if attack_count >= 2:
			print("Entering retreat")
			current_state = State.RETREAT

func _physics_process(delta: float) -> void:
	if not player:
		return
	match current_state:
		State.APPROACH:
			approach()
		State.ATTACK:
			attack()
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

# Use this for all movement related code
func move_to_player() -> void:
	pass
