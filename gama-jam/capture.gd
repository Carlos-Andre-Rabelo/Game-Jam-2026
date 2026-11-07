extends SceneTree

func _init() -> void:
	var vp := get_root()
	var scene := load("res://lobby.tscn").instantiate()
	vp.add_child(scene)
	for i in range(5):
		await process_frame

	var pause: CanvasLayer = scene.get_node("PauseOverlay")
	assert(pause != null, "PauseOverlay node missing")
	assert(not pause.visible, "PauseOverlay should start hidden")

	pause.set_paused(true)
	assert(pause.visible and paused, "Game should be paused and overlay visible")

	var btn_cfg: TextureButton = pause.get_node("TroncoContainer/ArvorePausa/BotaoConfiguracoes")
	var icon_cfg: Sprite2D = btn_cfg.get_node("Icone")
	var base_y := icon_cfg.position.y
	pause._set_button_visual_pressed(btn_cfg, true)
	assert(is_equal_approx(icon_cfg.position.y, base_y + 10.0), "Button press state must shift icon +10px")
	pause._set_button_visual_pressed(btn_cfg, false)
	assert(is_equal_approx(icon_cfg.position.y, base_y), "Button release state must restore icon y")

	pause._on_configuracoes_pressed()
	assert(pause._in_settings, "Should transition to settings state")

	pause.set_paused(false)
	assert(not pause.visible and not paused, "Game should unpause cleanly")
	print("ALL PAUSE OVERLAY CHECKS PASSED")
	quit()
