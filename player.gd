extends CharacterBody2D


const SPEED = 900.0
const JUMP_VELOCITY = -900.0


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	keep_on_screen()


# Stop the dog from leaving the left, right or top edge of the screen.
func keep_on_screen() -> void:
	var screen := get_viewport().get_visible_rect()
	var shape: CollisionShape2D = $CollisionShape2D
	var half: Vector2 = (shape.shape as RectangleShape2D).size / 2

	var min_x := screen.position.x + half.x - shape.position.x
	var max_x := screen.end.x - half.x - shape.position.x
	global_position.x = clampf(global_position.x, min_x, max_x)

	var min_y := screen.position.y + half.y - shape.position.y
	if global_position.y < min_y:
		global_position.y = min_y
		# Bonk the ceiling so the dog falls back down.
		velocity.y = maxf(velocity.y, 0.0)

	# Fell off the bottom: start this level over.
	if global_position.y + shape.position.y - half.y > screen.end.y:
		get_tree().reload_current_scene.call_deferred()
