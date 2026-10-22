extends Node2D

var enemy_scene: PackedScene = preload("res://scene/enemy.tscn")
var enemy_spawned : bool = false # Used to cap enemy spawn at 1

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
	#enemy_spawned = true     # make sure to uncomment in real gameplay, spawn infinitely for debug purpose
