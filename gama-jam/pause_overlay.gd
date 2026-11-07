extends CanvasLayer

const PRESS_OFFSET_Y := 10.0
const PRESS_ANIM_TIME := 0.12
const SLIDE_DURATION := 0.55
const TREE_HEIGHT := 1080.0

const TEX_BTN_PEQUENO_NORMAL := preload("res://assets/tela_de_pause/botao_pequeno/normal.png")
const TEX_BTN_PEQUENO_APERTADO := preload("res://assets/tela_de_pause/botao_pequeno/apertado.png")
const TEX_BTN_GRANDE_NORMAL := preload("res://assets/tela_de_pause/botao_grande/normal.png")
const TEX_BTN_GRANDE_APERTADO := preload("res://assets/tela_de_pause/botao_grande/apertado.png")
const TEX_FULLSCREEN_ON := preload("res://assets/tela_de_pause/tela_de_configuracoes/fullscreen_on.png")
const TEX_FULLSCREEN_OFF := preload("res://assets/tela_de_pause/tela_de_configuracoes/fullscreen_off.png")

const SLIDER_MIN_X := 115.0
const SLIDER_MAX_X := 470.0

@onready var tronco_container: Node2D = $TroncoContainer
@onready var btn_home: TextureButton = $TroncoContainer/ArvorePausa/BotaoHome
@onready var btn_reiniciar: TextureButton = $TroncoContainer/ArvorePausa/BotaoReiniciar
@onready var btn_configuracoes: TextureButton = $TroncoContainer/ArvorePausa/BotaoConfiguracoes
@onready var btn_continuar: TextureButton = $TroncoContainer/ArvorePausa/BotaoContinuar
@onready var btn_voltar: TextureButton = $TroncoContainer/ArvoreConfiguracoes/BotaoVoltar
@onready var btn_fullscreen: TextureButton = $TroncoContainer/ArvoreConfiguracoes/BotaoFullscreen
@onready var icone_check: Sprite2D = $TroncoContainer/ArvoreConfiguracoes/BotaoFullscreen/IconeCheck
@onready var painel_volume: Control = $TroncoContainer/ArvoreConfiguracoes/PainelVolume
@onready var pino_volume: Sprite2D = $TroncoContainer/ArvoreConfiguracoes/PainelVolume/Pino

var _in_settings := false
var _is_animating := false
var _dragging_volume := false
var _slide_tween: Tween
var _base_child_y: Dictionary = {}
var _normal_textures: Dictionary = {}
var _pressed_textures: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_setup_button(btn_home, _on_home_pressed)
	_setup_button(btn_reiniciar, _on_reiniciar_pressed)
	_setup_button(btn_configuracoes, _on_configuracoes_pressed)
	_setup_button(btn_continuar, _on_continuar_pressed)
	_setup_button(btn_voltar, _on_voltar_pressed)
	_setup_button(btn_fullscreen, _on_fullscreen_pressed)

	painel_volume.gui_input.connect(_on_painel_volume_gui_input)
	_sync_fullscreen_icon()
	_sync_volume_knob_from_bus()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			get_viewport().set_input_as_handled()
			if not visible:
				set_paused(true)
			elif _in_settings:
				_slide_to_settings(false)
			else:
				set_paused(false)

func set_paused(paused: bool) -> void:
	if paused:
		_in_settings = false
		if _slide_tween and _slide_tween.is_valid():
			_slide_tween.kill()
		tronco_container.position.y = 0.0
		_sync_fullscreen_icon()
		_sync_volume_knob_from_bus()
		visible = true
		get_tree().paused = true
	else:
		visible = false
		get_tree().paused = false

func _setup_button(btn: TextureButton, callback: Callable) -> void:
	_normal_textures[btn] = btn.texture_normal
	_pressed_textures[btn] = btn.texture_pressed
	var child_offsets := {}
	for child in btn.get_children():
		if child is Node2D:
			child_offsets[child] = child.position.y
	_base_child_y[btn] = child_offsets

	btn.button_down.connect(func() -> void: _set_button_visual_pressed(btn, true))
	btn.button_up.connect(func() -> void:
		if not _is_animating:
			_set_button_visual_pressed(btn, false)
	)
	btn.pressed.connect(func() -> void: _trigger_button_action(btn, callback))

func _set_button_visual_pressed(btn: TextureButton, is_pressed: bool) -> void:
	btn.texture_normal = _pressed_textures[btn] if is_pressed else _normal_textures[btn]
	var offsets: Dictionary = _base_child_y.get(btn, {})
	for child in offsets.keys():
		if is_instance_valid(child):
			child.position.y = offsets[child] + (PRESS_OFFSET_Y if is_pressed else 0.0)

func _trigger_button_action(btn: TextureButton, callback: Callable) -> void:
	if _is_animating:
		return
	_is_animating = true
	_set_button_visual_pressed(btn, true)
	await get_tree().create_timer(PRESS_ANIM_TIME, true).timeout
	_set_button_visual_pressed(btn, false)
	_is_animating = false
	callback.call()

func _on_continuar_pressed() -> void:
	set_paused(false)

func _on_home_pressed() -> void:
	set_paused(false)
	get_tree().reload_current_scene()

func _on_reiniciar_pressed() -> void:
	set_paused(false)
	get_tree().reload_current_scene()

func _on_configuracoes_pressed() -> void:
	_slide_to_settings(true)

func _on_voltar_pressed() -> void:
	_slide_to_settings(false)

func _slide_to_settings(to_settings: bool) -> void:
	_in_settings = to_settings
	var target_y := -TREE_HEIGHT if to_settings else 0.0
	if _slide_tween and _slide_tween.is_valid():
		_slide_tween.kill()
	_slide_tween = create_tween()
	_slide_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_slide_tween.set_trans(Tween.TRANS_CUBIC)
	_slide_tween.set_ease(Tween.EASE_IN_OUT)
	_slide_tween.tween_property(tronco_container, "position:y", target_y, SLIDE_DURATION)

func _on_fullscreen_pressed() -> void:
	var is_full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_WINDOWED if is_full else DisplayServer.WINDOW_MODE_FULLSCREEN
	)
	_sync_fullscreen_icon()

func _sync_fullscreen_icon() -> void:
	var is_full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	icone_check.texture = TEX_FULLSCREEN_ON if is_full else TEX_FULLSCREEN_OFF

func _on_painel_volume_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging_volume = event.pressed
		if _dragging_volume:
			_update_volume_from_local_x(event.position.x)
	elif event is InputEventMouseMotion and _dragging_volume:
		_update_volume_from_local_x(event.position.x)

func _update_volume_from_local_x(local_x: float) -> void:
	var knob_x := clampf(local_x - 20.0, SLIDER_MIN_X, SLIDER_MAX_X)
	pino_volume.position.x = knob_x
	var ratio := (knob_x - SLIDER_MIN_X) / (SLIDER_MAX_X - SLIDER_MIN_X)
	AudioServer.set_bus_mute(0, ratio <= 0.01)
	if ratio > 0.01:
		AudioServer.set_bus_volume_db(0, linear_to_db(ratio))

func _sync_volume_knob_from_bus() -> void:
	var ratio := 0.0 if AudioServer.is_bus_mute(0) else clampf(db_to_linear(AudioServer.get_bus_volume_db(0)), 0.0, 1.0)
	pino_volume.position.x = lerpf(SLIDER_MIN_X, SLIDER_MAX_X, ratio)
