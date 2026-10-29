# TODO: FIX ENEMY SPAWN POSITIONS


extends Node2D

var enemy_scene: PackedScene = preload("res://scene/enemy.tscn")
var enemy_spawned : bool = false # Used to cap enemy spawn at 1

var current_enemy: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func pause_game() -> void:
	get_tree().paused = not get_tree().paused
	$Pause.visible = get_tree().paused

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		pause_game()


func _on_enemy_spawn_timeout() -> void:
	if enemy_spawned:
		return
	var enemy = enemy_scene.instantiate()
	$Objects.add_child(enemy)
	var pos = $EnemySpawnPos.get_children().pick_random()
	enemy.position = pos.position
	print("Enemy has spawned at: ", pos.name)
	enemy_spawned = true     # make sure to uncomment in real gameplay, spawn infinitely for debug purpose
	current_enemy = enemy
	enemy.died.connect(_on_enemy_died)

func _on_button_pressed() -> void:
	if is_instance_valid(current_enemy):
		current_enemy.take_damage(50)
		
func _on_enemy_died() -> void: #function checks to see if enemy has died, if died then start respawn timer
	enemy_spawned = false
	current_enemy = null
	$Timer/EnemySpawn.start()
	


func _on_player_died() -> void:
	get_tree().change_scene_to_file("res://scene/Title.tscn")
