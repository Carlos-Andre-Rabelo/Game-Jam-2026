extends Node2D

## Configurações de transparência
const TRANSPARENT_ALPHA: float = 0.45 # 45% de opacidade (entre 40% e 50%)
const OPAQUE_ALPHA: float = 1.0       # 100% de opacidade original
const FADE_DURATION: float = 0.25     # Duração suave da transição em segundos

@onready var sprite: Sprite2D = $Sprite2D
@onready var area_copa: Area2D = $Area2D

var _fade_tween: Tween
var _bodies_in_canopy: Array[Node2D] = []
var _is_transparent: bool = false

func _ready() -> void:
	set_physics_process(false)
	
	if area_copa:
		area_copa.body_entered.connect(_on_body_entered)
		area_copa.body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	_check_transparency_state()

func _on_body_entered(body: Node2D) -> void:
	if not _is_player(body):
		return
	
	if not _bodies_in_canopy.has(body):
		_bodies_in_canopy.append(body)
	
	# Ativa o processamento apenas enquanto houver corpos na área da copa
	set_physics_process(true)
	_check_transparency_state()

func _on_body_exited(body: Node2D) -> void:
	if not _is_player(body):
		return
	
	_bodies_in_canopy.erase(body)
	
	if _bodies_in_canopy.is_empty():
		# Desativa verificação a cada frame para máxima performance
		set_physics_process(false)
		_fade_to(OPAQUE_ALPHA)
	else:
		_check_transparency_state()

func _is_player(body: Node2D) -> bool:
	return body.is_in_group("player") or body is CharacterBody2D or body.name == "Nana"

func _check_transparency_state() -> void:
	# Remove referências a corpos eventualmente destruídos
	_bodies_in_canopy = _bodies_in_canopy.filter(func(b: Node2D) -> bool: return is_instance_valid(b))
	
	if _bodies_in_canopy.is_empty():
		set_physics_process(false)
		if _is_transparent:
			_fade_to(OPAQUE_ALPHA)
		return
	
	# Verifica se algum jogador na copa está de fato atrás da base da árvore
	var should_be_transparent := false
	for body in _bodies_in_canopy:
		if _is_behind_tree(body):
			should_be_transparent = true
			break
	
	if should_be_transparent and not _is_transparent:
		_fade_to(TRANSPARENT_ALPHA)
	elif not should_be_transparent and _is_transparent:
		_fade_to(OPAQUE_ALPHA)

func _is_behind_tree(body: Node2D) -> bool:
	var player_feet_y := body.global_position.y
	if body.has_node("CollisionShape2D"):
		var col: CollisionShape2D = body.get_node("CollisionShape2D")
		player_feet_y = col.global_position.y
	
	# A origem global (0, 0) da árvore está posicionada na base do tronco/raízes
	return player_feet_y < global_position.y

func _fade_to(target_alpha: float) -> void:
	_is_transparent = (target_alpha < 0.9)
	
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	
	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_SINE)
	_fade_tween.set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(sprite, "self_modulate:a", target_alpha, FADE_DURATION)
