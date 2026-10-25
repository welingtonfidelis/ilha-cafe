class_name Player
extends CharacterBody3D
## Aventureiro jogável: câmera em terceira pessoa, movimento, mira e tiro com blaster.
## Joga com teclado e mouse ou com controle; com controle há auxílio de mira e vibração.
## O modelo vem do KayKit Adventurers; todos usam o mesmo esqueleto (Rig_Medium),
## então trocar de personagem reaproveita animações, encaixe do blaster e tudo mais.

signal hit_confirmed(region: String, damage: float)
signal character_changed(char_name: String)
signal input_device_changed(gamepad: bool)

const CHARACTERS := {
	"Knight": "res://assets/characters/adventurers/Knight.glb",
	"Barbarian": "res://assets/characters/adventurers/Barbarian.glb",
	"Mage": "res://assets/characters/adventurers/Mage.glb",
	"Ranger": "res://assets/characters/adventurers/Ranger.glb",
	"Rogue": "res://assets/characters/adventurers/Rogue.glb",
	"Rogue_Hooded": "res://assets/characters/adventurers/Rogue_Hooded.glb",
}
const BLASTER_SCENE := "res://assets/weapons/blaster-a.glb"
const CAMERA_LENGTH := 5.5
const CAMERA_LENGTH_AIM := 3.4
const PITCH_MIN := -1.1345  # -65°
const PITCH_MAX := 0.6981  # 40°

## Malhas que são arma ou escudo original do pacote; somem porque todos usam blaster.
const HIDDEN_MESH_HINTS := ["Sword", "Shield", "Axe", "Staff", "Bow", "Crossbow", "Dagger", "Mug", "Book"]

@export var run_speed := 6.0
@export var aim_speed := 3.5
@export var jump_velocity := 9.0
@export var mouse_sensitivity := 0.0025
@export var fire_interval := 0.22
@export var damage := 1.0

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

@export_group("Blaster")
## Ajuste do blaster no osso handslot.r. Calculado por tools/weapon_axes.gd: na pose de mira
## o eixo X do osso aponta para a frente, então o cano (+Z do blaster) gira 90° em Y.
@export var weapon_position := Vector3(0.12, 0.1, 0.0)
@export var weapon_rotation_deg := Vector3(0, 90, 0)
@export var weapon_scale := 1.0

var character_name := ""
var aiming := false
var using_gamepad := false
## Desligado enquanto um menu está aberto, para o analógico não mexer o boneco.
var input_enabled := true
## Usados pelo modo de captura automática para mirar e atirar sem mouse.
var force_aim := false
var force_fire := false

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
var _joy_device := 0


func _ready() -> void:
	collision_layer = 1 << 1
	collision_mask = 1 | (1 << 2)
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
	if character_name == "":
		set_character("Knight")


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
	var ap := AnimUtil.make_player(model, ["geral", "mov", "mov2", "tiro"])
	anim_tree = _build_anim_tree(model, ap)
	_air_state = ""
	_attach_blaster(model)
	character_changed.emit(char_name)


func _anim(anim_name: String) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = StringName(anim_name)
	return node


## Árvore de animação:
## locomoção (blend 2D) -> chão/ar -> pose de mira só no tronco -> tiro só no tronco.
func _build_anim_tree(root: Node, ap: AnimationPlayer) -> AnimationTree:
	var tree := AnimationTree.new()
	tree.name = "AnimationTree"
	root.add_child(tree)
	tree.anim_player = tree.get_path_to(ap)

	var bt := AnimationNodeBlendTree.new()

	var loco := AnimationNodeBlendSpace2D.new()
	loco.min_space = Vector2(-1, -1)
	loco.max_space = Vector2(1, 1)
	loco.add_blend_point(_anim("geral/Idle_A"), Vector2.ZERO, -1, &"parado")
	loco.add_blend_point(_anim("mov/Walking_A"), Vector2(0, 0.55), -1, &"andando")
	loco.add_blend_point(_anim("mov/Running_A"), Vector2(0, 1), -1, &"correndo")
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
	bt.connect_node(&"chao_ar", 0, &"loco")
	bt.connect_node(&"chao_ar", 1, &"ar")

	var aim_blend := AnimationNodeBlend2.new()
	aim_blend.filter_enabled = true
	for path in AnimUtil.upper_body_paths():
		aim_blend.set_filter_path(path, true)
	bt.add_node(&"mira", aim_blend, Vector2(500, 100))
	bt.add_node(&"pose_mira", _anim("tiro/Ranged_1H_Aiming"), Vector2(250, 300))
	bt.connect_node(&"mira", 0, &"chao_ar")
	bt.connect_node(&"mira", 1, &"pose_mira")

	var shoot := AnimationNodeOneShot.new()
	shoot.filter_enabled = true
	for path in AnimUtil.upper_body_paths():
		shoot.set_filter_path(path, true)
	shoot.fadein_time = 0.03
	shoot.fadeout_time = 0.12
	bt.add_node(&"tiro", shoot, Vector2(750, 100))
	bt.add_node(&"anim_tiro", _anim("tiro/Ranged_1H_Shoot"), Vector2(500, 300))
	bt.connect_node(&"tiro", 0, &"mira")
	bt.connect_node(&"tiro", 1, &"anim_tiro")

	bt.connect_node(&"output", 0, &"tiro")
	tree.tree_root = bt
	tree.active = true
	return tree


func _attach_blaster(root: Node) -> void:
	var sk: Skeleton3D = root.find_child("Skeleton3D", true, false)
	var attachment := BoneAttachment3D.new()
	attachment.name = "MaoDireita"
	attachment.bone_name = "handslot.r"
	sk.add_child(attachment)
	var holder := Node3D.new()
	holder.name = "Blaster"
	holder.position = weapon_position
	holder.rotation_degrees = weapon_rotation_deg
	holder.scale = Vector3.ONE * weapon_scale
	attachment.add_child(holder)
	holder.add_child(load(BLASTER_SCENE).instantiate())
	muzzle = Marker3D.new()
	muzzle.name = "BocaDoCano"
	muzzle.position = Vector3(0, 0.06, 0.45)
	holder.add_child(muzzle)


## Descobre se o jogador está no controle ou no teclado/mouse, para as dicas na tela,
## o auxílio de mira e a vibração.
func _input(event: InputEvent) -> void:
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
	if not input_enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sensitivity
		_pitch = clampf(_pitch - event.relative.y * mouse_sensitivity, PITCH_MIN, PITCH_MAX)


func _physics_process(delta: float) -> void:
	var was_aiming := aiming
	aiming = force_aim or (input_enabled and Input.is_action_pressed("mirar"))
	if aiming and not was_aiming:
		_snap_time = 0.25

	_look_with_stick(delta)
	camera_pivot.rotation.y = _yaw
	camera_pitch.rotation.x = _pitch

	var smooth := 1.0 - exp(-12.0 * delta)
	spring_arm.spring_length = lerpf(spring_arm.spring_length, CAMERA_LENGTH_AIM if aiming else CAMERA_LENGTH, smooth)
	camera.fov = lerpf(camera.fov, 55.0 if aiming else 70.0, smooth)

	var input := Vector2.ZERO
	if input_enabled:
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

	var speed := aim_speed if aiming else run_speed
	var horizontal := Vector3(velocity.x, 0, velocity.z).lerp(dir * speed, 1.0 - exp(-14.0 * delta))
	velocity.x = horizontal.x
	velocity.z = horizontal.z
	if not is_on_floor():
		velocity.y -= _gravity * delta
	elif input_enabled and Input.is_action_just_pressed("pular"):
		velocity.y = jump_velocity
	move_and_slide()

	# O modelo do KayKit olha para +Z; o resto da Godot considera -Z como frente.
	var face_dir := Vector3.ZERO
	if aiming or _aim_hold > 0.0:
		face_dir = forward
	elif dir.length() > 0.1:
		face_dir = dir
	if face_dir != Vector3.ZERO:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(face_dir.x, face_dir.z), 1.0 - exp(-14.0 * delta))

	_fire_cooldown -= delta
	_aim_hold -= delta
	var wants_fire := force_fire or (input_enabled and Input.is_action_pressed("atirar"))
	if wants_fire and _fire_cooldown <= 0.0:
		fire()

	_update_animation(delta)


## Analógico direito gira a câmera, com curva suave perto do centro.
## Com controle e mirando, o auxílio de mira freia o giro perto de um alvo e puxa de leve.
func _look_with_stick(delta: float) -> void:
	var look := Vector2.ZERO
	if input_enabled:
		look = Input.get_vector("olhar_esquerda", "olhar_direita", "olhar_cima", "olhar_baixo")
	look *= look.length()
	var factor := stick_aim_factor if aiming else 1.0
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
	var air := "chao" if is_on_floor() else "ar"
	if air != _air_state:
		_air_state = air
		anim_tree.set("parameters/chao_ar/transition_request", air)
	var want := 1.0 if (aiming or _aim_hold > 0.0) else 0.0
	_aim_amount = move_toward(_aim_amount, want, delta * 8.0)
	anim_tree.set("parameters/mira/blend_amount", _aim_amount)


func fire() -> void:
	_fire_cooldown = fire_interval
	_aim_hold = 0.6
	if is_instance_valid(anim_tree):
		anim_tree.set("parameters/tiro/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	# O tiro sai do centro da tela (a mira), não do cano: assim a mira nunca mente.
	var from := camera.global_position
	var to := from - camera.global_basis.z * 120.0
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
			hb.receive_hit(damage, end)
			hit_confirmed.emit(hb.region, damage * hb.multiplier)
			Fx.confetti(world, end, 30 if hb.multiplier > 1.0 else 16, 5.0)
			hit_target = true
		else:
			Fx.dust(world, end)
	if is_instance_valid(muzzle):
		Fx.tracer(world, muzzle.global_position, end, Color("#fff3a0"))
		Fx.muzzle_flash(muzzle)
	if vibration and using_gamepad:
		if hit_target:
			Input.start_joy_vibration(_joy_device, 0.45, 0.25, 0.12)
		else:
			Input.start_joy_vibration(_joy_device, 0.2, 0.0, 0.07)


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
