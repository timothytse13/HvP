extends CharacterBody2D


const SPEED = 300.0
#const JUMP_VELOCITY = -400.0

var facing_direction: Vector2 = Vector2.DOWN



func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	velocity = direction * SPEED
	move_and_slide()
	if direction != Vector2.ZERO:
		facing_direction = direction
		$AttackArea.position = facing_direction * 30

func attack() -> void:
	for body in $AttackArea.get_overlapping_bodies():
		print("Body detected", body.name)
		print("Body group is", body.is_in_group("Enemy"))
		if body.is_in_group("Enemy"):
			body.take_damage(10)
			print("Enemy Hit")
			
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		attack()
		print("Executed attack")
