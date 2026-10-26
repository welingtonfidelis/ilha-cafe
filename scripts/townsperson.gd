class_name Townsperson
extends CharacterBody3D
## Morador da ilha (personagens das Mystery Monthly do KayKit, no mesmo Rig_Medium do aventureiro).
## Fica na sua atividade: parado, sentado no banco ou no chão, torcendo, trabalhando, andando de um
## ponto a outro ou tocando. Quando o aventureiro chega perto, olha, acena e fala uma frase curta num
## balão. Com uma onda de esqueletos por perto, torce pelo aventureiro; quando a região é vencida,
## comemora. Fica numa camada própria: o aventureiro esbarra nele, mas tiros, granadas, flechas e
## esqueletos passam direto. No fim do jogo os esqueletos viram convidados da festa com o mesmo script
## (model_path aponta para o modelo do esqueleto e model_scale aumenta os guardiões).

const MODELS := "res://assets/characters/moradores/%s.glb"
const VARIANTS := "res://assets/characters/moradores/texturas/%s.png"
const ITEMS := "res://assets/props/%s.gltf"
const LAYER := 1 << 4
const GREET_RADIUS := 4.5
const TALK_COOLDOWN := 16.0
const WALK_SPEED := 1.1
const CROWD_LINES := ["Vai!", "Você consegue!", "Cuidado!", "Isso aí!", "Mira na cabeça!"]
## Atividades em que o morador fica de pé e pode virar, acenar e comemorar.
const STANDING := ["parado", "torcendo", "trabalhando", "andando", "tocando", "cortando", "pescando", "dancando"]
## Passos da dança (não há dança no KayKit): torcida, provocação dos esqueletos, pulinho e aceno, com um
## giro de vez em quando.
const DANCE_MOVES := [&"festa/Cheering", &"especial/Skeletons_Taunt", &"mov/Jump_Full_Short", &"festa/Waving"]

@export var model_name := "Farmer_A"
## Caminho completo do modelo (res://...glb); quando vazio, usa model_name na pasta dos moradores.
@export var model_path := ""
@export var model_scale := 1.0
## Malhas do modelo que ficam escondidas (a coroa do Mestre Ossinho, por exemplo).
@export var hide_meshes := PackedStringArray()
## Textura alternativa do mesmo modelo (nome do arquivo em texturas/, sem .png); vazio é a original.
@export var variant := ""
## parado, sentado_banco, sentado_chao, torcendo, trabalhando, andando, tocando, cortando, pescando, dancando
@export var activity := "parado"
## Objeto na mão direita (caminho do .gltf dentro de assets/props/, sem extensão, ou um res:// completo),
## vazio é nenhum.
@export var item := ""
## Rotação do item na mão (graus).
@export var item_rotation := Vector3.ZERO
@export var item_scale := 1.0
@export var lines := PackedStringArray()
## Só para "andando": vai e volta entre a posição inicial e este ponto.
@export var walk_to := Vector3.INF

var player: Player
var visual: Node3D
var ap: AnimationPlayer
var _bubble: Label3D
var _home := Vector3.ZERO
var _walk_target := Vector3.ZERO
var _pause := 0.0
var _near := false
var _talk_cooldown := 0.0
var _next_line := 0
var _emote_timer := 0.0
## Tempo restante de um gesto (acenar) tocando por cima da atividade.
var _gesture := 0.0
## Tempo restante de comemoração (região vencida).
var _party := 0.0
## Uma onda de esqueletos perto: torce pelo aventureiro.
var crowd := false
var _crowd_timer := 0.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0
var _dance_timer := 0.0
var _dance_step := 0
## Descendo de balão (convidados da festa): fica parado no ar até pousar.
var _dropping := false
## Vara de pescar: a linha do modelo (com a boia e o anzol como filhos) é esticada até a água.
var _fishing_line: Node3D
const WATER_Y := -0.6
const LINE_LENGTH := 1.91


func _ready() -> void:
	add_to_group(&"moradores")
	collision_layer = LAYER
	collision_mask = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4 * model_scale
	capsule.height = 1.8 * model_scale
	shape.shape = capsule
	shape.position.y = 0.9 * model_scale
	add_child(shape)
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	var model: Node3D = load(model_path if model_path != "" else MODELS % model_name).instantiate()
	model.scale = Vector3.ONE * model_scale
	visual.add_child(model)
	for mesh_name in hide_meshes:
		var mesh := model.find_child(mesh_name, true, false) as Node3D
		if mesh:
			mesh.visible = false
	# A animação de sentar no chão vira o corpo 90° para a direita: o modelo compensa.
	if activity == "sentado_chao":
		model.rotation.y = PI / 2.0
	if variant != "":
		_apply_variant(model, load(VARIANTS % variant))
	ap = AnimUtil.make_player(model, ["geral", "mov", "festa", "ferramentas", "especial"])
	if item != "":
		var sk: Skeleton3D = model.find_child("Skeleton3D", true, false)
		var hand := BoneAttachment3D.new()
		hand.bone_name = "handslot.r"
		sk.add_child(hand)
		var held: Node3D = load(item if item.begins_with("res://") else ITEMS % item).instantiate()
		held.rotation_degrees = item_rotation
		held.scale = Vector3.ONE * item_scale
		hand.add_child(held)
		_fishing_line = held.find_child("fishing_rod_line", true, false)
	_bubble = Label3D.new()
	_bubble.font_size = 44
	_bubble.outline_size = 12
	_bubble.outline_modulate = Color(0.12, 0.08, 0.2, 0.9)
	_bubble.modulate = Color(1, 1, 1)
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.no_depth_test = true
	_bubble.pixel_size = 0.005
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.width = 520.0
	_bubble.position.y = 2.45 * model_scale
	_bubble.visible = false
	add_child(_bubble)
	_home = global_position
	_walk_target = walk_to if walk_to != Vector3.INF else _home
	_emote_timer = randf_range(3.0, 9.0)
	_talk_cooldown = randf_range(0.0, 2.0)
	ap.play(_base_anim())
	ap.seek(randf() * 1.5, true)


## Troca a textura de todas as malhas pela variante (o modelo usa um material só).
func _apply_variant(model: Node, tex: Texture2D) -> void:
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		for i in mesh.get_surface_count():
			var mat := mesh.surface_get_material(i)
			if mat is StandardMaterial3D:
				var copy: StandardMaterial3D = mat.duplicate()
				copy.albedo_texture = tex
				mi.set_surface_override_material(i, copy)


func _base_anim() -> StringName:
	if _party > 0.0 and activity in STANDING:
		return &"festa/Cheering"
	if crowd and activity in ["parado", "torcendo", "andando"]:
		return &"festa/Cheering"
	match activity:
		"sentado_banco":
			return &"festa/Sit_Chair_Idle"
		"sentado_chao":
			return &"festa/Sit_Floor_Idle"
		"torcendo":
			return &"festa/Cheering"
		"trabalhando":
			return &"ferramentas/Working_A"
		"tocando":
			return &"ferramentas/Holding_A"
		"dancando":
			return DANCE_MOVES[_dance_step % DANCE_MOVES.size()]
		"cortando":
			return &"ferramentas/Chopping"
		"pescando":
			return &"ferramentas/Fishing_Idle"
		"andando":
			return &"mov/Walking_A" if _pause <= 0.0 else &"geral/Idle_A"
	return &"geral/Idle_A"


func _process(_delta: float) -> void:
	if is_instance_valid(_fishing_line):
		_drop_line()


## A linha sai da ponta da vara reta para baixo até a água; a boia fica na superfície balançando e o
## anzol um pouco abaixo. Os filhos são compensados da escala da linha para não esticarem junto.
func _drop_line() -> void:
	var tip := _fishing_line.global_position
	var depth := maxf(tip.y - WATER_Y, 0.3)
	var stretch := (depth + 0.35) / LINE_LENGTH
	_fishing_line.global_basis = Basis.from_scale(Vector3(1.0, stretch, 1.0))
	var bob := sin(Time.get_ticks_msec() * 0.003) * 0.04
	for child in _fishing_line.get_children():
		var c := child as Node3D
		if c == null:
			continue
		var below := depth - bob if c.name == "fishing_rod_floater" else depth + 0.3
		c.position = Vector3(0, -below / stretch, 0)
		c.scale = Vector3(1.0, 1.0 / stretch, 1.0)


func _physics_process(delta: float) -> void:
	if _dropping:
		return
	_talk_cooldown -= delta
	_gesture = maxf(_gesture - delta, 0.0)
	_party = maxf(_party - delta, 0.0)
	var to_player := Vector3.INF
	if is_instance_valid(player):
		to_player = player.global_position - global_position
		to_player.y = 0.0
	var near := to_player != Vector3.INF and to_player.length() < GREET_RADIUS
	var standing := activity in STANDING
	if activity == "andando":
		_walk(delta, near)
	elif activity == "dancando" and _gesture <= 0.0 and _party <= 0.0:
		_dance(delta)
	if near and activity in ["parado", "torcendo", "andando"]:
		_face(to_player.normalized(), delta)
	if near and not _near:
		_greet()
	_near = near
	if crowd:
		_crowd_timer -= delta
		if _crowd_timer <= 0.0:
			_crowd_timer = randf_range(5.0, 10.0)
			if randf() < 0.5:
				say(CROWD_LINES[randi() % CROWD_LINES.size()], 1.8)
	elif standing and _gesture <= 0.0 and _party <= 0.0 and activity == "parado":
		_emote_timer -= delta
		if _emote_timer <= 0.0:
			_emote_timer = randf_range(6.0, 12.0)
			_gesture = 2.2
			ap.play(&"festa/Waving" if randf() < 0.5 else &"geral/Interact", 0.25)
	if _gesture <= 0.0:
		var base := _base_anim()
		if ap.current_animation != base:
			ap.play(base, 0.3)


func _walk(delta: float, near: bool) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0
	var to := _walk_target - global_position
	to.y = 0.0
	if near or crowd or _party > 0.0 or _gesture > 0.0:
		velocity.x = 0.0
		velocity.z = 0.0
	elif _pause > 0.0:
		_pause -= delta
		velocity.x = 0.0
		velocity.z = 0.0
	elif to.length() < 0.4:
		_pause = randf_range(1.5, 3.5)
		_walk_target = _home if _walk_target != _home else walk_to
	else:
		var dir := to.normalized()
		velocity.x = dir.x * WALK_SPEED
		velocity.z = dir.z * WALK_SPEED
		_face(dir, delta)
	move_and_slide()


func _dance(delta: float) -> void:
	_dance_timer -= delta
	if _dance_timer > 0.0:
		return
	_dance_step = randi() % DANCE_MOVES.size()
	_dance_timer = randf_range(1.6, 2.6)
	ap.play(_base_anim(), 0.25)
	if randf() < 0.35:
		var tw := visual.create_tween()
		tw.tween_property(visual, "rotation:y", visual.rotation.y + TAU, 0.7).set_trans(Tween.TRANS_SINE)


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-6.0 * delta))


func _greet() -> void:
	if _talk_cooldown > 0.0 or crowd:
		return
	_talk_cooldown = TALK_COOLDOWN
	if activity in ["parado", "andando", "torcendo"]:
		_gesture = 2.0
		ap.play(&"festa/Waving", 0.25)
	if not lines.is_empty():
		say(lines[_next_line % lines.size()], 4.0)
		_next_line += 1


## Mostra uma frase no balão em cima da cabeça por alguns segundos.
func say(text: String, seconds: float) -> void:
	_bubble.text = text
	_bubble.visible = true
	_bubble.modulate.a = 1.0
	var tw := _bubble.create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(_bubble, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: _bubble.visible = false)


## Região vencida: comemora por um tempo, com confete.
func celebrate(seconds: float, line := "") -> void:
	_party = seconds
	_gesture = 0.0
	Fx.confetti(get_parent(), global_position + Vector3.UP * 2.0, 16, 2.5)
	if line != "":
		say(line, 3.0)


## Toca uma animação por cima da atividade por alguns segundos (cena final, convidados chegando).
func gesture(anim: StringName, seconds: float, blend := 0.25) -> void:
	_gesture = seconds
	ap.play(anim, blend)


## Convidado da festa chegando de balão: nasce lá no alto com três balões, desce devagar balançando e,
## ao pousar, os balões estouram em confete e ele começa a atividade. Devolve o tempo da descida.
func drop_in(height: float, seconds: float, delay := 0.0) -> float:
	var land := global_position
	_dropping = true
	global_position = land + Vector3.UP * height
	var balloons := Fx.balloons(2.6 * model_scale)
	add_child(balloons)
	ap.play(&"festa/Waving", 0.2)
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_property(self, "global_position", land, seconds).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(visual, "rotation:z", 0.1, seconds * 0.25).set_trans(Tween.TRANS_SINE)
	tw.tween_property(visual, "rotation:z", 0.0, 0.3)
	tw.tween_callback(func() -> void:
		Fx.confetti(get_parent(), global_position + Vector3.UP * (2.8 * model_scale + 1.8), 26, 3.0)
		Sfx.play_at(get_parent(), "estouro", global_position + Vector3.UP * 3.0, -6.0)
		balloons.queue_free()
		_dropping = false
		ap.play(_base_anim(), 0.3))
	return delay + seconds + 0.3


func is_dropping() -> bool:
	return _dropping


func is_talking() -> bool:
	return _bubble.visible


func is_celebrating() -> bool:
	return _party > 0.0
