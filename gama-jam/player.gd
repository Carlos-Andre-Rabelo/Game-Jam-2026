extends CharacterBody2D

const SPEED := 300.0

# === CONTROLE DE VELOCIDADE DOS FRAMES (FPS) ===
const IDLE_FPS := 3.75 # <-- MUDE AQUI a velocidade dos frames parado (+25%)
const RUN_FPS := 8.0  # <-- MUDE AQUI a velocidade dos frames correndo

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("player")
	anim.sprite_frames.set_animation_speed("idle", IDLE_FPS)
	anim.sprite_frames.set_animation_speed("run", RUN_FPS)

func _physics_process(_delta: float) -> void:
	var dir := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	).normalized()

	velocity = dir * SPEED
	move_and_slide()

	if dir.x < 0:
		anim.flip_h = true
	elif dir.x > 0:
		anim.flip_h = false

	if dir != Vector2.ZERO:
		anim.play("run")
	else:
		anim.play("idle")
