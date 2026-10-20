extends CharacterBody2D


const SPEED = 100.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var player: CharacterBody2D
var enemy_scene: PackedScene = preload("res://scene/enemy.tscn")


func _ready() -> void:
	player = get_parent().get_node("Player")

func _physics_process(delta: float) -> void:
	if not player:
		return
	#print("Found player")	
	nav_agent.target_position = player.global_position
	var next_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	
	#print("enemy: ", global_position, " | Next: ", next_position, " | Direction: ", direction)
	
	velocity = direction * SPEED	
	move_and_slide()
