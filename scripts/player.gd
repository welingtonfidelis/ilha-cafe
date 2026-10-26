class_name Player
extends CharacterBody3D
## Aventureiro jogável: câmera em terceira pessoa, movimento, mira, blasters e granada.
## Joga com teclado e mouse ou com controle; com controle há auxílio de mira e vibração.
## O modelo vem do KayKit Adventurers; todos usam o mesmo esqueleto (Rig_Medium),
## então trocar de personagem reaproveita animações, encaixe do blaster e tudo mais.
## Os blasters e a granada ficam em Weapons (scripts/weapons.gd).

signal hit_confirmed(region: String, damage: float)
signal character_changed(char_name: String)
signal input_device_changed(gamepad: bool)
signal health_changed(hearts: int, max_hearts: int)
signal damaged
signal dizzy_started
signal respawned
signal ammo_changed
signal weapon_changed(index: int)
signal reload_started(duration: float)
signal out_of_ammo
## Apertou a tecla ou seta de um blaster que ainda não ganhou.
signal weapon_locked(id: String)

## Os dois personagens jogáveis: o menino de boné amarelo (Protagonist_B) e a menina de boné branco e óculos
## (Protagonist_A) do pacote "The Protagonists" (KayKit Mystery Monthly Series 5). Usam o mesmo Rig_Medium dos
## esqueletos e das animações do KayKit.
const CHARACTERS := {
	"menino": "res://assets/characters/protagonists/Protagonist_B.glb",
	"menina": "res://assets/characters/protagonists/Protagonist_A.glb",
}
const CAMERA_LENGTH := 5.5
const CAMERA_LENGTH_AIM := 3.4
const CAMERA_LENGTH_SCOPE := 2.6
## Instante das animações de mira do KayKit em que o braço está estendido (medido amostrando a mão):
## na de uma mão o braço fica erguido de 0,36 a 0,98 s; na de duas, de 0,27 a 1,47 s.
const AIM_POSE_1H := 0.6
const AIM_POSE_2H := 0.8
const PITCH_MIN := -1.1345  # -65°
const PITCH_MAX := 0.6981  # 40°

## Malhas que somem: armas e escudos originais (todos usam blaster) e acessórios de fantasia
## (capacete, capa, chapéu, aljava, máscara), que destoam da cidade.
const HIDDEN_MESH_HINTS := ["Sword", "Shield", "Axe", "Staff", "Bow", "Crossbow", "Dagger", "Mug", "Book",
		"Helmet", "Visor", "Cape", "Hat", "Quiver", "Mask"]

@export var run_speed := 6.0
@export var aim_speed := 3.5
## Correndo (Shift segurado, ou L3 no controle até parar de andar).
@export var sprint_speed := 9.5
@export var jump_velocity := 9.0
@export var mouse_sensitivity := 0.0025

@export_group("Vida")
@export var max_hearts := 5
## Depois de levar um golpe, fica um tempo sem levar outro (pisca enquanto isso).
@export var invulnerable_time := 1.2
@export var respawn_invulnerable_time := 2.5

@export_group("Controle")
## Giro da câmera no analógico direito, em radianos por segundo (horizontal, vertical).
@export var stick_speed := Vector2(3.2, 2.2)
## Fração da velocidade do analógico enquanto mira.
@export var stick_aim_factor := 0.55
## Auxílio de mira: só com controle e mirando. Ângulo em que um alvo "segura" a mira.
@export var aim_assist_angle_deg := 7.0
## Força do puxão suave em direção ao alvo.
@export var aim_assist_pull := 3.5
## Puxão mais forte logo que aperta o gatilho de mira.
@export var aim_assist_snap := 9.0
@export var vibration := true

var character_name := ""
var aiming := false
var using_gamepad := false
## Desligado enquanto um menu está aberto, para o analógico não mexer o boneco.
var input_enabled := true
## Usados pelo modo de captura automática para mirar e atirar sem mouse.
var force_aim := false
var force_fire := false
## Nos testes automáticos, ignora golpes (para o tonto não travar o teste).
var god_mode := false
var hearts := 5
var dizzy := false
## Quem deu o último golpe (nome do esqueleto, "flecha" ou "bolha"); usado nos testes.
var last_hit_by := ""

## Blaster na mão (índice em Weapons.DEFS) e munição de cada um: id -> {mag, reserve}.
## reserve = -1 é estoque infinito.
var weapon_index := 0
## Blasters que o aventureiro já tem (id -> true). Na arena dos testes, todos; na história, ganhos aos poucos.
var unlocked := {}
var ammo := {}
var grenades := 0
var reloading := false
var reload_total := 0.0

var visual: Node3D
var model: Node3D
var anim_tree: AnimationTree
var muzzle: Marker3D
var camera_pivot: Node3D
var camera_pitch: Node3D
var spring_arm: SpringArm3D
var camera: Camera3D

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0
var _fire_cooldown := 0.0
var _aim_hold := 0.0
var _aim_amount := 0.0
var _snap_time := 0.0
var _yaw := 0.0
var _pitch := -0.2
var _air_state := "chao"
## L3 liga a corrida no controle; desliga ao parar de andar ou mirar.
var _sprint_toggle := false
var sprinting := false
var _joy_device := 0
var _invulnerable := 0.0
var _knockback := Vector3.ZERO
var _head: BoneAttachment3D
var _hand: BoneAttachment3D
var _stars: Node3D
var _reload_left := 0.0
var _auto_reload_delay := 0.0
var _switch_left := 0.0
var _throw_cooldown := 0.0
var _melee_cooldown := 0.0
## Pirulitão na mão (só aparece durante o golpe; o blaster some nesse instante).
var _lollipop: Node3D
var _node_melee_speed: AnimationNodeTimeScale
var _node_aim: AnimationNodeAnimation
var _shake := 0.0
var _recoil: Node3D
var _kick := 0.0
var _node_reload: AnimationNodeAnimation
var _node_run: AnimationNodeAnimation


func _ready() -> void:
	collision_layer = 1 << 1
	collision_mask = 1 | (1 << 2) | Townsperson.LAYER
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 2.2
	shape.shape = capsule
	shape.position.y = 1.1
	add_child(shape)
	visual = Node3D.new()
	visual.name = "Visual"
	visual.rotation.y = PI  # começa de costas para a câmera
	add_child(visual)
	_build_camera()
	_build_stars()
	hearts = max_hearts
	for def in Weapons.DEFS:
		ammo[def.id] = {"mag": def.pente, "reserve": def.estoque}
		unlocked[def.id] = true
	grenades = Weapons.GRENADE.inicio
	if character_name == "":
		set_character("menino")


## Quatro estrelinhas que giram sobre a cabeça quando o aventureiro fica tonto.
func _build_stars() -> void:
	_stars = Node3D.new()
	_stars.name = "Estrelinhas"
	_stars.top_level = true
	_stars.visible = false
	add_child(_stars)
	var mesh := Fx.star_mesh(0.24, 0.1, 0.08)
	var mat := Fx.flat_material(Color("#ffd23f"))
	# Sempre de frente para a câmera, para nunca aparecer de perfil.
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	for i in 4:
		var star := MeshInstance3D.new()
		star.mesh = mesh
		star.material_override = mat
		star.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var a := TAU * i / 4.0
		star.position = Vector3(cos(a), 0, sin(a)) * 0.6
		_stars.add_child(star)


func _build_camera() -> void:
	camera_pivot = Node3D.new()
	camera_pivot.name = "CameraPivot"
	# Os personagens KayKit têm cabeça grande (topo em ~2,4 m); a câmera fica acima e ao lado.
	camera_pivot.position.y = 2.3
	add_child(camera_pivot)
	camera_pitch = Node3D.new()
	camera_pivot.add_child(camera_pitch)
	spring_arm = SpringArm3D.new()
	spring_arm.spring_length = CAMERA_LENGTH
	spring_arm.collision_mask = 1
	spring_arm.margin = 0.2
	spring_arm.position = Vector3(1.25, 0.35, 0.0)
	camera_pitch.add_child(spring_arm)
	camera = Camera3D.new()
	camera.fov = 70.0
	camera.current = true
	spring_arm.add_child(camera)


func set_character(char_name: String) -> void:
	if not CHARACTERS.has(char_name):
		return
	if model:
		model.queue_free()
	character_name = char_name
	model = load(CHARACTERS[char_name]).instantiate()
	visual.add_child(model)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		for hint in HIDDEN_MESH_HINTS:
			if hint in mi.name:
				mi.visible = false
	AnimUtil.add_pose("tiro", "Ranged_1H_Aiming", AIM_POSE_1H, "Pose_1H")
	AnimUtil.add_pose("tiro", "Ranged_2H_Aiming", AIM_POSE_2H, "Pose_2H")
	var ap := AnimUtil.make_player(model, ["geral", "mov", "mov2", "tiro", "luta"])
	anim_tree = _build_anim_tree(model, ap)
	_air_state = ""
	var sk: Skeleton3D = model.find_child("Skeleton3D", true, false)
	_hand = BoneAttachment3D.new()
	_hand.name = "MaoDireita"
	_hand.bone_name = "handslot.r"
	sk.add_child(_hand)
	_head = BoneAttachment3D.new()
	_head.name = "Cabeca"
	_head.bone_name = "head"
	sk.add_child(_head)
	_equip_model()
	_lollipop = load(Weapons.MELEE.modelo).instantiate()
	_lollipop.name = "Pirulitao"
	_lollipop.scale = Vector3.ONE * Weapons.MELEE.escala
	_lollipop.visible = false
	var melee_hand := BoneAttachment3D.new()
	melee_hand.bone_name = "handslot.r"
	sk.add_child(melee_hand)
	melee_hand.add_child(_lollipop)
	_apply_weapon_animations()
	if dizzy:
		anim_tree.set("parameters/estado/transition_request", "tonto")
	reloading = false
	character_changed.emit(char_name)


func _anim(anim_name: String) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = StringName(anim_name)
	return node


func _upper_body_oneshot(fade_in: float, fade_out: float) -> AnimationNodeOneShot:
	var node := AnimationNodeOneShot.new()
	node.filter_enabled = true
	for path in AnimUtil.upper_body_paths():
		node.set_filter_path(path, true)
	node.fadein_time = fade_in
	node.fadeout_time = fade_out
	return node


## Árvore de animação:
## locomoção (blend 2D) -> chão/ar -> pose de mira parada só no tronco -> recarga e arremesso
## só no tronco -> golpe recebido (corpo todo) -> normal/tonto.
## O tiro não tem animação de corpo: o coice é feito no próprio blaster (_update_recoil), para a
## cabeça e os braços não repetirem o mesmo movimento a cada disparo.
## A pose de mira, a recarga e a corrida trocam conforme o blaster (uma ou duas mãos).
func _build_anim_tree(root: Node, ap: AnimationPlayer) -> AnimationTree:
	var tree := AnimationTree.new()
	tree.name = "AnimationTree"
	root.add_child(tree)
	tree.anim_player = tree.get_path_to(ap)

	var bt := AnimationNodeBlendTree.new()

	var loco := AnimationNodeBlendSpace2D.new()
	loco.min_space = Vector2(-1, -1)
	loco.max_space = Vector2(1, 1)
	_node_run = _anim("mov/Running_A")
	loco.add_blend_point(_anim("geral/Idle_A"), Vector2.ZERO, -1, &"parado")
	loco.add_blend_point(_anim("mov/Walking_A"), Vector2(0, 0.55), -1, &"andando")
	loco.add_blend_point(_node_run, Vector2(0, 1), -1, &"correndo")
	loco.add_blend_point(_anim("mov2/Walking_Backwards"), Vector2(0, -0.6), -1, &"de_costas")
	loco.add_blend_point(_anim("mov2/Running_Strafe_Left"), Vector2(-1, 0), -1, &"lado_esquerdo")
	loco.add_blend_point(_anim("mov2/Running_Strafe_Right"), Vector2(1, 0), -1, &"lado_direito")
	bt.add_node(&"loco", loco, Vector2(0, 0))

	bt.add_node(&"ar", _anim("mov/Jump_Idle"), Vector2(0, 200))
	var ground_air := AnimationNodeTransition.new()
	ground_air.input_count = 2
	ground_air.set_input_name(0, "chao")
	ground_air.set_input_name(1, "ar")
	ground_air.xfade_time = 0.15
	bt.add_node(&"chao_ar", ground_air, Vector2(250, 100))
	var pace := AnimationNodeTimeScale.new()
	bt.add_node(&"ritmo", pace, Vector2(120, 0))
	bt.connect_node(&"ritmo", 0, &"loco")
	bt.connect_node(&"chao_ar", 0, &"ritmo")
	bt.connect_node(&"chao_ar", 1, &"ar")

	var aim_blend := AnimationNodeBlend2.new()
	aim_blend.filter_enabled = true
	for path in AnimUtil.upper_body_paths():
		aim_blend.set_filter_path(path, true)
	bt.add_node(&"mira", aim_blend, Vector2(500, 100))
	_node_aim = _anim("tiro/Pose_1H")
	bt.add_node(&"pose_mira", _node_aim, Vector2(250, 300))
	bt.connect_node(&"mira", 0, &"chao_ar")
	bt.connect_node(&"mira", 1, &"pose_mira")

	bt.add_node(&"recarga", _upper_body_oneshot(0.08, 0.15), Vector2(1000, 100))
	_node_reload = _anim("tiro/Ranged_1H_Reload")
	bt.add_node(&"anim_recarga", _node_reload, Vector2(750, 300))
	bt.connect_node(&"recarga", 0, &"mira")
	bt.connect_node(&"recarga", 1, &"anim_recarga")

	bt.add_node(&"arremesso", _upper_body_oneshot(0.05, 0.15), Vector2(1250, 100))
	bt.add_node(&"anim_arremesso", _anim("geral/Throw"), Vector2(1000, 300))
	bt.connect_node(&"arremesso", 0, &"recarga")
	bt.connect_node(&"arremesso", 1, &"anim_arremesso")

	# Pirulitão: golpe de lado só no tronco, um pouco mais rápido que a animação original.
	bt.add_node(&"pancada", _upper_body_oneshot(0.04, 0.15), Vector2(1375, 100))
	bt.add_node(&"anim_pancada", _anim("luta/Melee_1H_Attack_Slice_Horizontal"), Vector2(1125, 450))
	_node_melee_speed = AnimationNodeTimeScale.new()
	bt.add_node(&"ritmo_pancada", _node_melee_speed, Vector2(1250, 450))
	bt.connect_node(&"ritmo_pancada", 0, &"anim_pancada")
	bt.connect_node(&"pancada", 0, &"arremesso")
	bt.connect_node(&"pancada", 1, &"ritmo_pancada")

	var hit := AnimationNodeOneShot.new()
	hit.fadein_time = 0.05
	hit.fadeout_time = 0.15
	bt.add_node(&"golpe", hit, Vector2(1500, 100))
	bt.add_node(&"anim_golpe", _anim("geral/Hit_A"), Vector2(1250, 300))
	bt.connect_node(&"golpe", 0, &"pancada")
	bt.connect_node(&"golpe", 1, &"anim_golpe")

	var dizzy_state := AnimationNodeTransition.new()
	dizzy_state.input_count = 2
	dizzy_state.set_input_name(0, "normal")
	dizzy_state.set_input_name(1, "tonto")
	dizzy_state.xfade_time = 0.2
	bt.add_node(&"estado", dizzy_state, Vector2(1750, 100))
	bt.add_node(&"anim_tonto", _anim("geral/Death_A"), Vector2(1500, 300))
	bt.connect_node(&"estado", 0, &"golpe")
	bt.connect_node(&"estado", 1, &"anim_tonto")

	bt.connect_node(&"output", 0, &"estado")
	tree.tree_root = bt
	tree.active = true
	return tree


## Troca o modelo na mão pelo blaster atual (encaixe vindo de Weapons.DEFS).
func _equip_model() -> void:
	if not is_instance_valid(_hand):
		return
	for c in _hand.get_children():
		_hand.remove_child(c)  # sai já, para o novo poder se chamar "Blaster"
		c.queue_free()
	var def := current_weapon()
	# O coice gira e recua este nó; o blaster fica dentro dele com o encaixe fixo.
	_recoil = Node3D.new()
	_recoil.name = "Coice"
	_hand.add_child(_recoil)
	var holder := Node3D.new()
	holder.name = "Blaster"
	holder.position = def.pos
	holder.rotation_degrees = Weapons.ROTATION
	holder.scale = Vector3.ONE * def.escala
	_recoil.add_child(holder)
	holder.add_child(load(Weapons.MODEL_DIR % def.modelo).instantiate())
	muzzle = Marker3D.new()
	muzzle.name = "BocaDoCano"
	muzzle.position = def.boca
	holder.add_child(muzzle)


func _apply_weapon_animations() -> void:
	var hands := "2H" if current_weapon().maos == 2 else "1H"
	_node_aim.animation = StringName("tiro/Pose_%s" % hands)
	_node_reload.animation = StringName("tiro/Ranged_%s_Reload" % hands)
	_node_run.animation = &"mov2/Running_HoldingRifle" if hands == "2H" else &"mov/Running_A"


func _input(event: InputEvent) -> void:
	detect_device(event)


## Descobre se o jogador está no controle ou no teclado/mouse, para as dicas dos menus,
## o auxílio de mira e a vibração. Com o jogo pausado, quem chama é o menu (main.gd).
func detect_device(event: InputEvent) -> void:
	var gamepad := using_gamepad
	if event is InputEventJoypadButton:
		gamepad = true
		_joy_device = event.device
	elif event is InputEventJoypadMotion and absf(event.axis_value) > 0.35:
		gamepad = true
		_joy_device = event.device
	elif event is InputEventKey or event is InputEventMouseButton:
		gamepad = false
	elif event is InputEventMouseMotion and event.relative.length() > 2.0:
		gamepad = false
	if gamepad != using_gamepad:
		using_gamepad = gamepad
		input_device_changed.emit(gamepad)


func _unhandled_input(event: InputEvent) -> void:
	if not _can_control():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := mouse_sensitivity * _zoom_factor()
		_yaw -= event.relative.x * sens
		_pitch = clampf(_pitch - event.relative.y * sens, PITCH_MIN, PITCH_MAX)
	elif event.is_action_pressed("recarregar"):
		reload()
	elif event.is_action_pressed("granada"):
		throw_grenade()
	elif event.is_action_pressed("corpo_a_corpo"):
		melee()
	elif event.is_action_pressed("arma_proxima"):
		switch_weapon(next_weapon_index(1))
	elif event.is_action_pressed("arma_anterior"):
		switch_weapon(next_weapon_index(-1))
	else:
		for i in Weapons.count():
			if event.is_action_pressed("arma_%d" % (i + 1)):
				var id: String = Weapons.get_def(i).id
				if has_weapon(id):
					switch_weapon(i)
				else:
					weapon_locked.emit(id)


func _physics_process(delta: float) -> void:
	var control := _can_control()
	var was_aiming := aiming
	aiming = not dizzy and (force_aim or (control and Input.is_action_pressed("mirar")))
	if aiming and not was_aiming:
		_snap_time = 0.25

	_look_with_stick(delta)
	camera_pivot.rotation.y = _yaw
	camera_pitch.rotation.x = _pitch

	var smooth := 1.0 - exp(-12.0 * delta)
	var zoomed := is_zoomed()
	var target_len := CAMERA_LENGTH_SCOPE if zoomed else (CAMERA_LENGTH_AIM if aiming else CAMERA_LENGTH)
	var target_fov: float = current_weapon().zoom if zoomed else (55.0 if aiming else 70.0)
	spring_arm.spring_length = lerpf(spring_arm.spring_length, target_len, smooth)
	camera.fov = lerpf(camera.fov, target_fov, smooth)

	var input := Vector2.ZERO
	if control:
		input = Input.get_vector("esquerda", "direita", "frente", "tras")
	var cam_basis := camera_pivot.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()
	var dir := right * input.x + forward * -input.y
	if dir.length() > 1.0:
		dir = dir.normalized()

	if control and Input.is_action_just_pressed("correr_alternar"):
		_sprint_toggle = not _sprint_toggle
	if input.length() < 0.2 or aiming or dizzy:
		_sprint_toggle = false
	sprinting = not aiming and input.length() > 0.2 and (_sprint_toggle or (control and Input.is_action_pressed("correr")))
	var speed := aim_speed if aiming else (sprint_speed if sprinting else run_speed)
	var horizontal := Vector3(velocity.x, 0, velocity.z) - _knockback
	horizontal = horizontal.lerp(dir * speed, 1.0 - exp(-14.0 * delta))
	_knockback = _knockback.lerp(Vector3.ZERO, 1.0 - exp(-5.0 * delta))
	velocity.x = horizontal.x + _knockback.x
	velocity.z = horizontal.z + _knockback.z
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif control and Input.is_action_just_pressed("pular"):
		velocity.y = jump_velocity
		Sfx.play(get_parent(), "pulo")
	move_and_slide()

	# O modelo do KayKit olha para +Z; o resto da Godot considera -Z como frente.
	var face_dir := Vector3.ZERO
	if dizzy:
		pass
	elif aiming or _aim_hold > 0.0:
		face_dir = forward
	elif dir.length() > 0.1:
		face_dir = dir
	if face_dir != Vector3.ZERO:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(face_dir.x, face_dir.z), 1.0 - exp(-14.0 * delta))

	_fire_cooldown -= delta
	_aim_hold -= delta
	_switch_left -= delta
	_throw_cooldown -= delta
	_melee_cooldown -= delta
	_update_reload(delta)
	var wants_fire := not dizzy and (force_fire or (control and Input.is_action_pressed("atirar")))
	if wants_fire and _fire_cooldown <= 0.0:
		fire()

	_update_invulnerability(delta)
	_update_animation(delta)
	_update_recoil(delta)
	_update_shake(delta)


## Tremor rápido da câmera (o Ossão batendo no chão, por exemplo).
func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)
	rumble(0.4, 0.5, 0.2)


func _update_shake(delta: float) -> void:
	_shake = move_toward(_shake, 0.0, delta * 1.5)
	camera.h_offset = randf_range(-1.0, 1.0) * _shake * 0.4
	camera.v_offset = randf_range(-1.0, 1.0) * _shake * 0.4


## Coice no blaster: a boca sobe e a arma recua um pouco, voltando rápido. No osso da mão,
## X é a frente e Y é para cima, então girar em Z levanta o cano.
func _update_recoil(delta: float) -> void:
	_kick = move_toward(_kick, 0.0, delta * 9.0)
	if is_instance_valid(_recoil):
		var k := ease(minf(_kick, 1.0), 0.6)
		_recoil.position = Vector3(-0.09, 0.02, 0.0) * k
		_recoil.rotation = Vector3(0.0, 0.0, 0.32 * k)


func _can_control() -> bool:
	return input_enabled and not dizzy


# --- blasters ----------------------------------------------------------------

func current_weapon() -> Dictionary:
	return Weapons.get_def(weapon_index)


func mag() -> int:
	return ammo[current_weapon().id].mag


## Estoque do blaster atual (-1 = infinito).
func reserve() -> int:
	return ammo[current_weapon().id].reserve


## Mirando com o Pé-de-Moleque: aproxima a câmera e diminui a sensibilidade.
func is_zoomed() -> bool:
	return aiming and current_weapon().zoom > 0.0


func _zoom_factor() -> float:
	return current_weapon().zoom / 55.0 if is_zoomed() else 1.0


## Quanto resta de munição limitada (pente + estoque de todos), de 0 a 1. Usado na queda de caixas.
func limited_ammo_fraction() -> float:
	var have := 0.0
	var cap := 0.0
	for def in Weapons.DEFS:
		if Weapons.infinite(def) or not has_weapon(def.id):
			continue
		have += ammo[def.id].mag + ammo[def.id].reserve
		cap += def.pente + def.estoque_max
	return have / cap if cap > 0.0 else 1.0


func has_weapon(id: String) -> bool:
	return unlocked.get(id, false)


## Próximo blaster que o aventureiro tem, andando `step` (1 ou -1) na lista. Se só tem um, é o mesmo.
func next_weapon_index(step: int) -> int:
	for k in range(1, Weapons.count() + 1):
		var i := wrapi(weapon_index + step * k, 0, Weapons.count())
		if has_weapon(Weapons.get_def(i).id):
			return i
	return weapon_index


## Deixa só os blasters da lista (a história começa só com a Paçoca).
func keep_only_weapons(ids: Array) -> void:
	for def in Weapons.DEFS:
		unlocked[def.id] = def.id in ids
	if not has_weapon(current_weapon().id):
		weapon_index = Weapons.index_of(ids[0])
		_equip_model()
		_apply_weapon_animations()
	ammo_changed.emit()


## Ganha um blaster novo: já vem carregado e vai para a mão.
func unlock_weapon(id: String) -> void:
	var def := Weapons.get_def(Weapons.index_of(id))
	unlocked[id] = true
	ammo[id].mag = def.pente
	if def.estoque >= 0:
		ammo[id].reserve = maxi(ammo[id].reserve, def.estoque)
	switch_weapon(Weapons.index_of(id))
	ammo_changed.emit()


## Um coração a mais no máximo, e cheio.
func add_max_heart() -> void:
	max_hearts += 1
	hearts = max_hearts
	health_changed.emit(hearts, max_hearts)


func switch_weapon(index: int) -> void:
	index = wrapi(index, 0, Weapons.count())
	if index == weapon_index or dizzy or not has_weapon(Weapons.get_def(index).id):
		return
	_cancel_reload()
	weapon_index = index
	_switch_left = 0.3
	_fire_cooldown = maxf(_fire_cooldown, 0.3)
	_equip_model()
	_apply_weapon_animations()
	Sfx.play(get_parent(), "troca_arma", 0.0, 0.0)
	weapon_changed.emit(index)
	ammo_changed.emit()


## Dispara o blaster atual. Sem bala no pente, recarrega (ou avisa que acabou a munição).
func fire() -> bool:
	if dizzy or reloading or _switch_left > 0.0:
		return false
	var def := current_weapon()
	var a: Dictionary = ammo[def.id]
	if a.mag <= 0:
		_fire_cooldown = 0.35
		if a.reserve != 0:
			reload()
		else:
			Sfx.play(get_parent(), "sem_municao", 0.0, 0.0)
			out_of_ammo.emit()
		return false
	a.mag -= 1
	_fire_cooldown = def.intervalo
	_aim_hold = 0.6
	_kick = minf(_kick + def.coice, 1.5)
	# Um pouquinho de subida na câmera nos tiros fortes, para dar peso sem atrapalhar a mira.
	_pitch = clampf(_pitch + 0.004 * def.coice, PITCH_MIN, PITCH_MAX)
	var hit_target := false
	for k in def.tiros:
		hit_target = _shoot_ray(_spread_dir(def.espalha), def) or hit_target
	if is_instance_valid(muzzle):
		Fx.muzzle_flash(muzzle)
	Sfx.play(get_parent(), def.som, -3.0)
	if hit_target:
		rumble(0.45, 0.25, 0.12)
	else:
		rumble(0.2 if def.tiros == 1 else 0.4, 0.0 if def.tiros == 1 else 0.3, 0.07)
	ammo_changed.emit()
	if a.mag == 0 and a.reserve != 0:
		_auto_reload_delay = 0.25
	return true


## Direção do tiro: o centro da tela, com um sorteio dentro de um cone para escopeta e rajada.
func _spread_dir(degrees: float) -> Vector3:
	var forward := -camera.global_basis.z
	if degrees <= 0.0:
		return forward
	var r := sqrt(randf()) * tan(deg_to_rad(degrees))
	var a := randf() * TAU
	return (camera.global_basis * Vector3(cos(a) * r, sin(a) * r, -1.0)).normalized()


## O tiro sai do centro da tela (a mira), não do cano: assim a mira nunca mente.
func _shoot_ray(dir: Vector3, def: Dictionary) -> bool:
	var from := camera.global_position
	var reach: float = def.alcance
	var to := from + dir * reach
	var query := PhysicsRayQueryParameters3D.create(from, to, 1 | Hurtbox.LAYER)
	query.collide_with_areas = true
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var world := get_parent()
	var end := to
	var hit_target := false
	if hit:
		end = hit.position
		var collider: Object = hit.collider
		if collider is Hurtbox:
			var hb := collider as Hurtbox
			hb.receive_hit(def.dano, end)
			hit_confirmed.emit(hb.region, def.dano * hb.multiplier)
			Fx.confetti(world, end, (30 if hb.multiplier > 1.0 else 16) / def.tiros + 4, 5.0)
			hit_target = true
		else:
			Fx.dust(world, end)
	if is_instance_valid(muzzle):
		Fx.tracer(world, muzzle.global_position, end, def.cor)
	return hit_target


## Recarrega antes de zerar (R ou X) ou sozinho quando o pente acaba.
func reload() -> bool:
	if dizzy or reloading or _switch_left > 0.0:
		return false
	var def := current_weapon()
	var a: Dictionary = ammo[def.id]
	if a.mag >= def.pente or a.reserve == 0:
		return false
	reloading = true
	reload_total = def.recarga
	_reload_left = def.recarga
	_auto_reload_delay = 0.0
	if is_instance_valid(anim_tree):
		anim_tree.set("parameters/recarga/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	Sfx.play(get_parent(), "recarga", 0.0, 0.0)
	reload_started.emit(def.recarga)
	return true


## De 0 a 1 enquanto recarrega; -1 fora da recarga (para a barrinha na mira).
func reload_progress() -> float:
	return 1.0 - _reload_left / reload_total if reloading else -1.0


func _update_reload(delta: float) -> void:
	if _auto_reload_delay > 0.0:
		_auto_reload_delay -= delta
		if _auto_reload_delay <= 0.0:
			reload()
	if not reloading:
		return
	_reload_left -= delta
	if _reload_left > 0.0:
		return
	reloading = false
	var def := current_weapon()
	var a: Dictionary = ammo[def.id]
	var need: int = def.pente - a.mag
	var take: int = need if a.reserve < 0 else mini(need, a.reserve)
	a.mag += take
	if a.reserve >= 0:
		a.reserve -= take
	ammo_changed.emit()


func _cancel_reload() -> void:
	if reloading and is_instance_valid(anim_tree):
		anim_tree.set("parameters/recarga/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	reloading = false
	_auto_reload_delay = 0.0


## Joga um Brigadeiro (G ou RB) em arco na direção da mira.
func throw_grenade() -> bool:
	if dizzy or grenades <= 0 or _throw_cooldown > 0.0 or reloading:
		return false
	grenades -= 1
	_throw_cooldown = 1.0
	_aim_hold = 0.9
	if is_instance_valid(anim_tree):
		anim_tree.set("parameters/arremesso/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	Sfx.play(get_parent(), "arremesso", 0.0, 0.0)
	ammo_changed.emit()
	# A granada sai da mão no meio da animação de arremesso.
	get_tree().create_timer(0.45).timeout.connect(_release_grenade)
	return true


func _release_grenade() -> void:
	if not is_inside_tree():
		return
	var from := global_position + Vector3.UP * 2.0 + visual.global_basis.z * 0.6
	if is_instance_valid(_hand):
		from = _hand.global_position + Vector3.UP * 0.3
	var dir := -camera.global_basis.z
	var launch: Vector3 = dir * Weapons.GRENADE.forca + Vector3.UP * 5.5
	get_parent().add_child(Grenade.create(from, launch, self))


## Golpe com o Pirulitão (F ou R3): interrompe a recarga, vira para a mira e acerta no meio do movimento.
func melee() -> bool:
	if dizzy or _melee_cooldown > 0.0:
		return false
	_melee_cooldown = Weapons.MELEE.intervalo
	_aim_hold = Weapons.MELEE.duracao
	if reloading:
		reloading = false
		_reload_left = 0.0
		if is_instance_valid(anim_tree):
			anim_tree.set("parameters/recarga/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_ABORT)
	if is_instance_valid(anim_tree):
		anim_tree.set("parameters/ritmo_pancada/scale", 1.6)
		anim_tree.set("parameters/pancada/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	_show_lollipop(true)
	Sfx.play(get_parent(), "golpe_ar", -2.0)
	get_tree().create_timer(Weapons.MELEE.impacto).timeout.connect(_melee_strike)
	get_tree().create_timer(Weapons.MELEE.duracao).timeout.connect(_show_lollipop.bind(false))
	return true


func _show_lollipop(on: bool) -> void:
	if is_instance_valid(_lollipop):
		_lollipop.visible = on
	if is_instance_valid(_recoil):
		_recoil.visible = not on


## Quem está na frente leva o golpe (uma vez cada, de preferência no corpo); bolhas perto estouram.
## Devolve quantos foram acertados.
func _melee_strike() -> int:
	if not is_inside_tree() or dizzy:
		return 0
	var forward := -camera_pivot.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var center := global_position + Vector3.UP * 1.1 + forward * Weapons.MELEE.alcance
	var sphere := SphereShape3D.new()
	sphere.radius = Weapons.MELEE.raio
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, center)
	query.collision_mask = Hurtbox.LAYER
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var chosen := {}
	for h in get_world_3d().direct_space_state.intersect_shape(query, 32):
		var hb := h.collider as Hurtbox
		if hb == null or not hb.is_active() or hb.owner_target == null:
			continue
		var who: Node = hb.owner_target
		if not chosen.has(who) or (chosen[who] as Hurtbox).multiplier > hb.multiplier:
			chosen[who] = hb
	var world := get_parent()
	for who in chosen:
		var hb: Hurtbox = chosen[who]
		var point := hb.aim_point()
		hb.receive_hit(Weapons.MELEE.dano, point)
		hit_confirmed.emit(hb.region, Weapons.MELEE.dano * hb.multiplier)
		Fx.confetti(world, point, 22, 5.0)
	for node in world.get_children():
		if (node is Projectile and node.kind == Projectile.Kind.BOLHA) or node is BossMestre.ShieldBubble:
			if (node as Node3D).global_position.distance_to(center) < Weapons.MELEE.raio + 0.8:
				node.pop()
	if not chosen.is_empty():
		Sfx.play(world, "bonk", -2.0)
		rumble(0.5, 0.4, 0.12)
	return chosen.size()


## Caixa de munição: um pente de cada blaster de estoque limitado e uma granada.
## Devolve false se não coube nada (aí a caixa fica no chão).
func add_ammo_crate() -> bool:
	var changed := false
	for id in Weapons.CRATE_AMMO:
		if id == "granadas" or not has_weapon(id):
			continue
		var def := Weapons.get_def(Weapons.index_of(id))
		var a: Dictionary = ammo[id]
		var before: int = a.reserve
		a.reserve = mini(a.reserve + Weapons.CRATE_AMMO[id], def.estoque_max)
		changed = changed or a.reserve != before
	if grenades < Weapons.GRENADE.max:
		grenades = mini(grenades + Weapons.CRATE_AMMO.granadas, Weapons.GRENADE.max)
		changed = true
	if changed:
		rumble(0.25, 0.0, 0.1)
		ammo_changed.emit()
	return changed


# --- vida --------------------------------------------------------------------

## Pisca enquanto está invulnerável; com o aventureiro tonto, as estrelinhas giram sobre a cabeça.
func _update_invulnerability(delta: float) -> void:
	_invulnerable -= delta
	if _invulnerable > 0.0 and not dizzy:
		visual.visible = fmod(_invulnerable, 0.16) > 0.08
	else:
		visual.visible = true
	if dizzy and is_instance_valid(_head):
		_stars.global_position = _head.global_position + Vector3.UP * 0.9
		_stars.rotate_y(delta * 3.5)
		for star in _stars.get_children():
			star.rotate_y(delta * 6.0)


func is_dizzy() -> bool:
	return dizzy


## Recebe um golpe de esqueleto, flecha ou bolha. Tira um coração, empurra para longe de quem
## bateu e deixa um tempo invulnerável. Sem corações, fica tonto (nunca morre).
func take_damage(amount: int, from: Vector3, source := "") -> void:
	if god_mode or dizzy or _invulnerable > 0.0:
		return
	hearts = maxi(hearts - amount, 0)
	last_hit_by = source
	_invulnerable = invulnerable_time
	var away := global_position - from
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else -visual.global_basis.z
	_knockback = away * 7.0
	velocity.y = maxf(velocity.y, 3.5)
	if is_instance_valid(anim_tree):
		anim_tree.set("parameters/golpe/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	rumble(0.7, 0.6, 0.25)
	Sfx.play(get_parent(), "bonk")
	health_changed.emit(hearts, max_hearts)
	damaged.emit()
	if hearts == 0:
		_become_dizzy()


func _become_dizzy() -> void:
	dizzy = true
	aiming = false
	_aim_hold = 0.0
	_cancel_reload()
	if is_instance_valid(anim_tree):
		anim_tree.set("parameters/estado/transition_request", "tonto")
	_stars.visible = true
	Sfx.play(get_parent(), "tonto", 0.0, 0.0)
	dizzy_started.emit()


## Volta no ponto de retorno com os corações cheios.
func respawn(at: Vector3) -> void:
	global_position = at
	velocity = Vector3.ZERO
	_knockback = Vector3.ZERO
	hearts = max_hearts
	dizzy = false
	_stars.visible = false
	_invulnerable = respawn_invulnerable_time
	if is_instance_valid(anim_tree):
		anim_tree.set("parameters/estado/transition_request", "normal")
	Sfx.play(get_parent(), "reaparecer", 0.0, 0.0)
	health_changed.emit(hearts, max_hearts)
	respawned.emit()


## Devolve corações; com a vida cheia não pega (o coração fica no chão).
func heal(amount: int) -> bool:
	if dizzy or hearts >= max_hearts:
		return false
	hearts = mini(hearts + amount, max_hearts)
	rumble(0.25, 0.0, 0.1)
	health_changed.emit(hearts, max_hearts)
	return true


func rumble(weak: float, strong: float, duration: float) -> void:
	if vibration and using_gamepad:
		Input.start_joy_vibration(_joy_device, weak, strong, duration)


# --- câmera e animação -------------------------------------------------------

## Analógico direito gira a câmera, com curva suave perto do centro.
## Com controle e mirando, o auxílio de mira freia o giro perto de um alvo e puxa de leve.
func _look_with_stick(delta: float) -> void:
	var look := Vector2.ZERO
	if _can_control():
		look = Input.get_vector("olhar_esquerda", "olhar_direita", "olhar_cima", "olhar_baixo")
	look *= look.length()
	var factor := (stick_aim_factor if aiming else 1.0) * _zoom_factor()
	var target := _aim_assist_target() if (aiming and using_gamepad) else Vector3.INF
	if target != Vector3.INF:
		factor *= 0.5
		var d := target - camera.global_position
		var strength := aim_assist_snap if _snap_time > 0.0 else aim_assist_pull
		var t := 1.0 - exp(-strength * delta)
		_yaw = lerp_angle(_yaw, atan2(-d.x, -d.z), t)
		_pitch = lerpf(_pitch, atan2(d.y, Vector2(d.x, d.z).length()), t)
	_snap_time -= delta
	_yaw -= look.x * stick_speed.x * factor * delta
	_pitch = clampf(_pitch - look.y * stick_speed.y * factor * delta, PITCH_MIN, PITCH_MAX)


## Alvo mais perto do centro da mira, dentro do ângulo do auxílio e visível.
func _aim_assist_target() -> Vector3:
	var cam_pos := camera.global_position
	var cam_fwd := -camera.global_basis.z
	var best := Vector3.INF
	var best_angle := deg_to_rad(aim_assist_angle_deg)
	for node in get_tree().get_nodes_in_group(Hurtbox.AIM_GROUP):
		var hb := node as Hurtbox
		if hb == null or not hb.is_active():
			continue
		var point := hb.aim_point()
		var to := point - cam_pos
		if to.length() > 45.0:
			continue
		var angle := cam_fwd.angle_to(to)
		if angle < best_angle:
			best_angle = angle
			best = point
	if best != Vector3.INF:
		var query := PhysicsRayQueryParameters3D.create(cam_pos, best, 1)
		query.exclude = [get_rid()]
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty():
			return Vector3.INF
	return best


func _update_animation(delta: float) -> void:
	if not is_instance_valid(anim_tree):
		return
	var horizontal := Vector3(velocity.x, 0, velocity.z)
	var local := visual.global_transform.basis.inverse() * horizontal
	# Com o modelo olhando para +Z, a direita dele fica em -X.
	var blend := Vector2(-local.x, local.z) / run_speed
	if blend.length() > 1.0:
		blend = blend.normalized()
	anim_tree.set("parameters/loco/blend_position", blend)
	anim_tree.set("parameters/ritmo/scale", 1.35 if sprinting else 1.0)
	var air := "chao" if is_on_floor() else "ar"
	if air != _air_state:
		_air_state = air
		anim_tree.set("parameters/chao_ar/transition_request", air)
	var want := 1.0 if (aiming or _aim_hold > 0.0) else 0.0
	_aim_amount = move_toward(_aim_amount, want, delta * 8.0)
	anim_tree.set("parameters/mira/blend_amount", _aim_amount)


## Aponta a câmera para um ponto do mundo (usado pela captura automática).
## Mede a partir da câmera, que fica deslocada para o ombro; chamado a cada quadro, converge.
func aim_at(point: Vector3) -> void:
	var d := point - camera.global_position
	_yaw = atan2(-d.x, -d.z)
	_pitch = atan2(d.y, Vector2(d.x, d.z).length())


func get_yaw() -> float:
	return _yaw


func set_yaw(value: float) -> void:
	_yaw = value
