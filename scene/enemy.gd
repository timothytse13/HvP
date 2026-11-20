#TODO: Implement raycast2D for obstruction for vision check
#TODO: Make the enemy have smarter vision sense
extends CharacterBody2D

signal died

enum State {
	APPROACH,
	ATTACK,
	RETREAT,
	PATROL
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

var current_state = State.PATROL

var patrol_points: Array[Node2D] = []
var current_patrol_index: int = 0 # Position
var patrol_initialized: bool = false


func _ready() -> void:
	player = get_parent().get_node("Player")
	
	var points = get_tree().current_scene.get_node("PatrolPoints")
	for point in points.get_children():
		patrol_points.append(point)

func approach() -> void:
	var distance = global_position.distance_to(player.global_position)
	#print("Distance: ", distance)
	if distance <= 30: # Distance between player and enemy before stopping
		print("Entering attack")
		current_state = State.ATTACK
		return
	move_to_player()

func attack() -> void:
	var distance = global_position.distance_to(player.global_position)
	#print("Attack distance: ", distance)
	
	if distance > 24:
		#print("Closing distance in attack state")
		attack_started = false
		$WindupTimer.stop()
		$AttackPivot/AttackArea/Polygon2D.hide()
		move_to_player()
		return
	
	velocity = Vector2.ZERO
	move_and_slide()
	
	if not attack_started:
		
		$WindupTimer.start()
		$AttackPivot/AttackArea/Polygon2D.show()
		attack_started = true
		return
		
	if $AttackTimer.is_stopped() and $WindupTimer.is_stopped():
		
		print("attack timer stopped")
		print("Bodies detected: ", $AttackPivot/AttackArea.get_overlapping_bodies().size())
		
		for body in $AttackPivot/AttackArea.get_overlapping_bodies():
			if body.is_in_group("Player"):
				body.take_damage(10)
				print("Enemy succesfully attacked player")
				
		attack_count = attack_count + 1
		$AttackTimer.start()
		attack_started = false
		$AttackPivot/AttackArea/Polygon2D.hide()
		
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

func patrol() -> void:
	if patrol_points.is_empty():
		return
	if not patrol_initialized:
		find_closest_patrol_point()
		return
	if nav_agent.is_navigation_finished(): #on demand for loop. Processes next patrol point one by one
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		nav_agent.target_position = patrol_points[current_patrol_index].global_position
		return # Return immediately so as to not process more tha one patrol point
		
	var next_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	velocity = direction * SPEED
	move_and_slide()
	
func _physics_process(delta: float) -> void:
	if not player:
		return
	
	match current_state:
		State.APPROACH:
			approach()
			rotate_towards_player(delta)
		State.ATTACK:
			attack()
			rotate_towards_player(delta)
		State.RETREAT:
			retreat()
		State.PATROL:
			patrol()
			rotate_towards_direction(delta)

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
	
func _on_vision_cone_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		print("Saw body")

func rotate_towards_player(delta: float) -> void:
	var target_angle = global_position.angle_to_point(player.global_position)
	$AttackPivot.rotation = lerp_angle(
		$AttackPivot.rotation,
		target_angle,
		5.0 * delta
	)

func rotate_towards_direction(delta: float) -> void:
	var target_angle = velocity.angle()
	$AttackPivot.rotation = lerp_angle(
		$AttackPivot.rotation,
		target_angle,
		5.0 * delta
	)
	
# Finds the closest patrol point, then starts in an loop. So if the closest is Point 3, then the patrol will be 3 -> 1 -> 2 -> 3 -> 1 ->2 ...
func find_closest_patrol_point() -> void:
	var closest_distance = INF
	
	for i in range(patrol_points.size()):
		var distance = global_position.distance_to(patrol_points[i].global_position)
		if distance < closest_distance:
			closest_distance = closest_distance
			current_patrol_index = i
			
	nav_agent.target_position = patrol_points[current_patrol_index].global_position
	patrol_initialized = true
