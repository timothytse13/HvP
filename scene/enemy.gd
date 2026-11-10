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
var attack_started: bool = false
var retreat_started: bool = false

var current_state = State.APPROACH

func _ready() -> void:
	player = get_parent().get_node("Player")

func approach() -> void:
	var distance = global_position.distance_to(player.global_position)
	#print("Distance: ", distance)
	if distance <= 30: # Distance between player and enemy before stopping
		print("Entering attack")
		current_state = State.ATTACK
		return
	move_to_player()

#TODO: So far the enemy is relentless will instantly deal damage to player the moment the player body enters hitbox. Fix with timer probably
#TODO: Enemy also attacks, then sits there since no movement logic for pursuit. Fix with check for attack distance then attack
func attack() -> void:
	var distance = global_position.distance_to(player.global_position)
	#print("Attack distance: ", distance)
	
	if distance > 24:
		#print("Closing distance in attack state")
		attack_started = false
		$WindupTimer.stop()
		$AttackArea/Polygon2D.hide()
		move_to_player()
		return
	
	velocity = Vector2.ZERO
	move_and_slide()
	
	if not attack_started:
		facing_direction = global_position.direction_to(player.global_position)
		$AttackArea.position = facing_direction * 30
		
		$WindupTimer.start()
		$AttackArea/Polygon2D.show()
		attack_started = true
		return
		
	if $AttackTimer.is_stopped() and $WindupTimer.is_stopped():
		
		print("attack timer stopped")
		print("Bodies detected: ", $AttackArea.get_overlapping_bodies().size())
		
		for body in $AttackArea.get_overlapping_bodies():
			if body.is_in_group("Player"):
				body.take_damage(10)
				print("Enemy succesfully attacked player")
				
		attack_count = attack_count + 1
		$AttackTimer.start()
		attack_started = false
		$AttackArea/Polygon2D.hide()
		
		if attack_count >= 2:
			print("Entering retreat")
			current_state = State.RETREAT

# TODO: The enemy should essentially be relentless until damaged sufficiently, then enter retreat to heal and enter patrol/come back to last known position
# TODO: Eventually discard attack_count in attack() and have a check in enemy take_damage() to determine when to enter retreat
func retreat() -> void:
	if not retreat_started:
		# For an hypothetical coordinate of our player (100, 100) and enemy (200, 100). We get (200 - 100, 100-100) to get 100 on x. That is a vector direction
		# Normalizing gives us a unit vector (i.e. the length, Vector2(1,0). Now we have a direction
		var run_direction = (global_position - player.global_position).normalized()
		# With that direction we can choose the distance and let the nav agent handle the obstacles.
		nav_agent.target_position = global_position + run_direction * 150
		retreat_started = true
	
	if nav_agent.is_navigation_finished():
		velocity = Vector2.ZERO
		move_and_slide()
		return
	
	var next_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	velocity = direction * SPEED
	move_and_slide()
	return

func _physics_process(delta: float) -> void:
	if not player:
		return
	match current_state:
		State.APPROACH:
			approach()
		State.ATTACK:
			attack()
		State.RETREAT:
			retreat()

func take_damage(amount: int) -> void:
	health = health - amount
	$HealthBar.value = health
	if health <= 0:
		die()
		
func die() -> void:
	died.emit()
	queue_free()

# Use this for all movement related code related to finding the player
func move_to_player() -> void:
	nav_agent.target_position = player.global_position
	var next_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	velocity = direction * SPEED
	move_and_slide()
