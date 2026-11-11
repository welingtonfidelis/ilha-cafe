extends SceneTree
## Gera as figurinhas do álbum (item 7 da lista de melhorias): cada guardião, cada tipo da turma dos esqueletos e cada
## peixe, de três quartos, com luz e fundo transparente, em assets/ui/figurinhas/<grupo>_<id>.png. Os guardiões e os
## esqueletos são montados pelas próprias classes do jogo (o Boss e o SkeletonEnemy, parados na pose de espera); os
## peixes pelo Fish, de lado.
## Uso (precisa de janela): godot --path . -s res://tools/gerar_figurinhas.gd

const OUT := "res://assets/ui/figurinhas/"
const SIZE := Vector2i(320, 320)


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.9, 0.9, 1.0)
	env.environment.ambient_light_energy = 0.85
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, 35, 0)
	sun.light_energy = 1.15
	vp.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -140, 0)
	fill.light_energy = 0.35
	vp.add_child(fill)
	var cam := Camera3D.new()
	cam.fov = 28.0
	vp.add_child(cam)
	cam.current = true
	for k in 6:
		await process_frame
	var trabalhos := []
	for id in Album.GUARDIOES:
		trabalhos.append(["guardiao_" + id, "guardiao", id])
	for spec: Dictionary in Album.TURMA:
		trabalhos.append(["tipo_" + spec.id, "tipo", spec.id])
	for spec: Dictionary in Pescaria.PEIXES:
		trabalhos.append(["peixe_" + spec.id, "peixe", spec.id])
	for t in trabalhos:
		var no := _montar(t[1], t[2])
		vp.add_child(no)
		no.process_mode = Node.PROCESS_MODE_DISABLED
		_posar(no, t[1])
		await process_frame
		# O confete e as faíscas que os bonecos soltam ao nascer ficam soltos no mundo: saem antes da foto.
		for solto in vp.get_children():
			if not solto in [env, sun, fill, cam, no]:
				solto.free()
		var box := _caixa(no)
		var meio := box.get_center()
		var alto := maxf(box.size.y, maxf(box.size.x, box.size.z))
		var longe := alto * 0.5 / tan(deg_to_rad(cam.fov) * 0.5) * 1.12
		var lado := Vector3(-1.0, 0.16, -0.12) if t[1] == "peixe" else Vector3(0.42, 0.14, 1.0)
		cam.look_at_from_position(meio + lado.normalized() * longe, meio)
		for k in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.save_png(ProjectSettings.globalize_path(OUT + t[0] + ".png"))
		print("figurinha: ", t[0])
		no.free()
	quit()


func _montar(grupo: String, id: String) -> Node3D:
	match grupo:
		"guardiao":
			var b: Boss = (Story.GUARDIANS[Album.GUARDIOES[id].guardiao] as GDScript).new()
			return b
		"tipo":
			var e := SkeletonEnemy.new()
			e.type_name = id
			e.start_awake = true
			return e
	var f := Fish.new()
	f.model_name = id
	f.cardume = false
	return f


## Parado na pose de espera (a primeira animação de "Idle" que o boneco tiver), ou nadando, no peixe.
func _posar(no: Node3D, grupo: String) -> void:
	for ap: AnimationPlayer in no.find_children("*", "AnimationPlayer", true, false):
		var lista := ap.get_animation_list()
		var escolha := ""
		for nome in lista:
			var n := String(nome)
			if grupo == "peixe" and n.ends_with("Swimming_Normal"):
				escolha = n
			elif grupo != "peixe" and (n.ends_with("Skeletons_Idle") or n.ends_with("Idle_A") or n.ends_with("Idle")) and escolha == "":
				escolha = n
		# O Pistoleiro aparece mirando, para o blaster de quindim aparecer.
		if no is SkeletonEnemy and (no as SkeletonEnemy).config.has("blaster"):
			for nome in lista:
				if String(nome).ends_with("Ranged_1H_Aiming"):
					escolha = String(nome)
		if escolha != "":
			ap.play(StringName(escolha))
			ap.seek(0.4, true)


func _caixa(no: Node3D) -> AABB:
	var caixa := AABB()
	var primeiro := true
	for m: MeshInstance3D in no.find_children("*", "MeshInstance3D", true, false):
		if not m.is_visible_in_tree():
			continue
		var a: AABB = m.global_transform * m.get_aabb()
		caixa = a if primeiro else caixa.merge(a)
		primeiro = false
	return caixa
