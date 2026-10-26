class_name SkeletonEnemy
extends CharacterBody3D
## Esqueleto do KayKit. Persegue o jogador e ataca do seu jeito (ver TYPES); ao levar tiros
## suficientes, aparecem balões amarrados nele e ele vai embora voando, acenando, de volta para o
## Morro. Não volta mais. Ninguém morre (regras de tom do doc).
## Todo ataque tem um aviso ("!" em cima da cabeça) antes do golpe, para dar tempo de desviar.
## Duas regiões de impacto presas aos ossos: cabeça (dano em dobro) e corpo.

signal defeated(enemy: SkeletonEnemy)
## Saiu de vez (o balão subiu e sumiu). Logo depois o nó é liberado.
signal gone(enemy: SkeletonEnemy)

enum State { PERSEGUINDO, PREPARANDO, ATACANDO, ESPERANDO, ATINGIDO, INDO_EMBORA, ACORDANDO, COMEMORANDO, DORMINDO, VOLTANDO, AFUNDANDO }

const SKELETONS := "res://assets/characters/skeletons/%s.glb"
const WEAPONS := "res://assets/weapons/skeleton/%s.gltf"
const BALLOONS := ["red/ball_red", "blue/ball_blue", "yellow/ball_yellow", "green/ball_green"]
const PLAT := "res://assets/props/platformer/%s.gltf"
## Saída de balão: tempo até os balões aparecerem, até começar a subir, e até sumir.
const BALLOON_APPEAR := 0.35
const BALLOON_LIFT := 0.9
const BALLOON_GONE := 7.0

## kind: "melee" (golpe de perto), "pancada" (de perto, bate no chão e solta uma onda que se pula),
## "flecha" ou "bolha" (à distância). range: distância em que começa o ataque. windup: tempo do
## aviso até o golpe sair. rig "Large" usa o esqueleto grande do KayKit (ver LARGE_ANIMS).
const TYPES := {
	"Skeleton_Minion": {
		"kind": "melee", "health": 5.0, "speed": 2.4, "range": 1.8, "windup": 0.5, "cooldown": 1.6,
		"attack": "luta/Melee_Unarmed_Attack_Punch_A", "right": "", "left": "",
	},
	"Skeleton_Warrior": {
		"kind": "melee", "health": 8.0, "speed": 1.7, "range": 2.1, "windup": 0.55, "cooldown": 2.2,
		"attack": "luta/Melee_1H_Attack_Chop", "right": "Skeleton_Axe", "left": "Skeleton_Shield_Small_A",
		"shield": true,
	},
	"Skeleton_Rogue": {
		"kind": "flecha", "health": 4.0, "speed": 2.2, "range": 12.0, "windup": 0.8, "cooldown": 2.8,
		"aim": "tiro/Ranged_2H_Aiming", "attack": "tiro/Ranged_2H_Shoot", "right": "Skeleton_Crossbow", "left": "",
	},
	"Skeleton_Mage": {
		"kind": "bolha", "health": 4.0, "speed": 1.9, "range": 13.0, "windup": 0.7, "cooldown": 3.8,
		"aim": "tiro/Ranged_Magic_Spellcasting", "attack": "tiro/Ranged_Magic_Shoot", "right": "Skeleton_Staff", "left": "",
	},
	# Golem de Ossos: grandão e lento das ondas da mata. A pancada no chão solta uma onda (pular escapa);
	# empurrão de granada quase não mexe nele.
	"Skeleton_Golem": {
		"kind": "pancada", "health": 16.0, "speed": 1.5, "range": 3.6, "windup": 1.08, "cooldown": 3.0,
		"attack": "luta/Melee_Unarmed_Smash", "attack_speed": 0.85, "recover": 1.4, "right": "", "left": "",
		"rig": "Large", "scale": 0.85, "size": 1.7, "heavy": true,
	},
}

## O esqueleto grande só tem parado, andar, levar golpe e golpes de luta: o resto vira o mais parecido.
const LARGE_ANIMS := {
	"especial/Skeletons_Walking": "mov/Walking_A", "especial/Skeletons_Idle": "geral/Idle_A",
	"especial/Skeletons_Awaken_Floor": "geral/Idle_A", "especial/Skeletons_Inactive_Floor_Pose": "geral/Death_A_Pose",
	"especial/Skeletons_Death": "geral/Death_A", "festa/Cheering": "luta/Melee_Unarmed_Idle",
	"festa/Waving": "geral/Idle_B", "geral/Hit_B": "geral/Hit_A",
}

@export var type_name := "Skeleton_Minion"
## Na ilha, o esqueleto começa dormindo (pilha de ossos) e se monta quando o aventureiro chega
## a aggro_radius metros. Se ele se afastar mais que leash_radius da casa, volta e deita de novo.
## Na arena dos testes, start_awake liga e os raios ficam enormes (comportamento antigo).
@export var start_awake := false
@export var aggro_radius := -1.0  # -1: 16 m para golpe de perto, 22 m para quem atira
@export var leash_radius := 45.0
## Esqueleto de onda: sai de uma rachadura (sobe do chão) e persegue o aventureiro por toda a região.
@export var from_crack := false

var target: Player
var health := 3.0
var state := State.ACORDANDO
var hurtboxes: Array[Hurtbox] = []
var config: Dictionary

var visual: Node3D
var model: Node3D
var ap: AnimationPlayer
var _warning: Label3D
var _hand_r: BoneAttachment3D
var _state_time := 0.0
var _rise_length := 1.0
var _balloons: Node3D
var _drift := Vector3.ZERO
var _start_y := 0.0
var _cooldown := 0.0
var _struck := false
var _spawn_point := Vector3.ZERO
## Tamanho relativo ao esqueleto comum (cápsula, regiões de impacto, aviso e balões).
var _size := 1.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0


func _ready() -> void:
	config = TYPES[type_name]
	health = config.health
	_size = config.get("size", 1.0)
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 1) | (1 << 2)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5 * _size
	capsule.height = 2.0 * _size
	shape.shape = capsule
	shape.position.y = 1.0 * _size
	add_child(shape)
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	model = load(SKELETONS % type_name).instantiate()
	model.scale = Vector3.ONE * config.get("scale", 1.0)
	visual.add_child(model)
	if _large():
		ap = AnimUtil.make_player(model, ["geral", "mov", "luta"], "Large")
	else:
		ap = AnimUtil.make_player(model, ["geral", "mov", "luta", "tiro", "especial", "festa"])
	var sk: Skeleton3D = model.find_child("Skeleton3D", true, false)
	_hand_r = _attach_weapon(sk, "handslot.r", config.right)
	_attach_weapon(sk, "handslot.l", config.left)
	_build_hurtboxes(sk)
	_warning = Label3D.new()
	_warning.text = "!"
	_warning.font_size = 140
	_warning.outline_size = 24
	_warning.modulate = Color("#ffd23f")
	_warning.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_warning.no_depth_test = true
	_warning.pixel_size = 0.006
	_warning.position.y = 3.0 * _size
	_warning.visible = false
	add_child(_warning)
	_spawn_point = global_position
	if aggro_radius < 0.0:
		aggro_radius = 16.0 if _close_range() else 22.0
	if from_crack and _large():
		# O esqueleto grande não tem animação de sair do chão: sobe da rachadura parado.
		_enter(State.ACORDANDO, "especial/Skeletons_Idle")
		_rise_length = 1.3
		visual.position.y = -2.0 * _size
		var tw := create_tween()
		tw.tween_property(visual, "position:y", 0.0, 1.2).set_ease(Tween.EASE_OUT)
		Fx.dust(get_parent(), global_position + Vector3.UP * 0.2)
	elif from_crack:
		# A animação de sair do chão tem 3,6 s: tocada 1,6x mais rápida para a onda não demorar.
		_enter(State.ACORDANDO, "")
		ap.play(&"especial/Skeletons_Spawn_Ground", 0.1, 1.6)
		_rise_length = ap.current_animation_length / 1.6
		visual.position.y = -1.2
		var tw := create_tween()
		tw.tween_property(visual, "position:y", 0.0, 0.6).set_ease(Tween.EASE_OUT)
		Fx.dust(get_parent(), global_position + Vector3.UP * 0.2)
	elif start_awake:
		_enter(State.ACORDANDO, "especial/Skeletons_Awaken_Floor")
	else:
		_enter(State.DORMINDO, "especial/Skeletons_Inactive_Floor_Pose")


## Onda cancelada: afunda de volta na rachadura e some (não conta como derrotado).
func sink_away() -> void:
	if state in [State.INDO_EMBORA, State.AFUNDANDO]:
		return
	_enter(State.AFUNDANDO, "especial/Skeletons_Death")
	velocity = Vector3.ZERO
	collision_mask = 0
	Fx.dust(get_parent(), global_position + Vector3.UP * 0.3)
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(visual, "position:y", -2.6, 0.9).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


## Volta para o lugar de origem (usado quando o aventureiro reaparece na bandeira):
## na ilha deita de novo; na arena acorda na hora. Quem já está indo embora segue o balão.
func reset_to_spawn() -> void:
	if state in [State.INDO_EMBORA, State.AFUNDANDO] or from_crack:
		return
	global_position = _spawn_point
	velocity = Vector3.ZERO
	health = config.health
	_cooldown = 1.5
	if start_awake:
		_enter(State.ACORDANDO, "especial/Skeletons_Awaken_Floor")
	else:
		_enter(State.DORMINDO, "especial/Skeletons_Inactive_Floor_Pose")


func _too_far(dist: float) -> bool:
	var from_home := Vector2(global_position.x - _spawn_point.x, global_position.z - _spawn_point.z).length()
	return from_home > leash_radius or dist > leash_radius + 15.0


## As armas do KayKit foram feitas para o osso handslot: encaixam sem ajuste.
func _attach_weapon(sk: Skeleton3D, bone: String, weapon: String) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	sk.add_child(attachment)
	if weapon != "":
		attachment.add_child(load(WEAPONS % weapon).instantiate())
	return attachment


func _build_hurtboxes(sk: Skeleton3D) -> void:
	var head := SphereShape3D.new()
	head.radius = 0.5 * _size
	_add_hurtbox(sk, "head", "cabeça", 2.0, head, Vector3(0, 0.45, 0) * _size, Color(1, 0.85, 0.2, 0.35))
	var body := CapsuleShape3D.new()
	body.radius = 0.4 * _size
	body.height = 1.1 * _size
	_add_hurtbox(sk, "chest", "corpo", 1.0, body, Vector3(0, -0.2, 0) * _size, Color(1, 0.3, 0.3, 0.35))


func _large() -> bool:
	return config.get("rig", "Medium") == "Large"


## Quem ataca chegando perto (o golpe começa junto com o aviso).
func _close_range() -> bool:
	return config.kind == "melee" or config.kind == "pancada"


func _anim(anim_name: String) -> StringName:
	if _large():
		return StringName(LARGE_ANIMS.get(anim_name, anim_name))
	return StringName(anim_name)


func _add_hurtbox(sk: Skeleton3D, bone: String, region: String, mult: float, shape: Shape3D, offset: Vector3, debug_color: Color) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	sk.add_child(attachment)
	var hb := Hurtbox.new()
	hb.region = region
	hb.multiplier = mult
	hb.owner_target = self
	# O auxílio de mira do controle puxa para o corpo (alvo grande); a cabeça fica por conta de quem mira.
	hb.aim_assist = region == "corpo"
	attachment.add_child(hb)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = offset
	hb.add_child(cs)
	# Desenho da região, escondido; F3 mostra (grupo "regioes_de_impacto").
	var dbg := MeshInstance3D.new()
	if shape is SphereShape3D:
		var sm := SphereMesh.new()
		sm.radius = shape.radius
		sm.height = shape.radius * 2.0
		dbg.mesh = sm
	else:
		var cm := CapsuleMesh.new()
		cm.radius = shape.radius
		cm.height = shape.height
		dbg.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = debug_color
	mat.no_depth_test = true
	dbg.material_override = mat
	dbg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dbg.position = offset
	dbg.visible = false
	dbg.add_to_group(&"regioes_de_impacto")
	hb.add_child(dbg)
	hurtboxes.append(hb)


func _physics_process(delta: float) -> void:
	_state_time += delta
	_cooldown -= delta
	if state == State.INDO_EMBORA:
		_fly_away(delta)
		return
	if state == State.AFUNDANDO:
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	var to_target := Vector3.ZERO
	var dist := INF
	if is_instance_valid(target):
		to_target = target.global_position - global_position
		to_target.y = 0.0
		dist = to_target.length()
	var target_down := is_instance_valid(target) and target.is_dizzy()

	# Com o aventureiro tonto, os esqueletos comemoram em vez de atacar.
	if target_down and state in [State.PERSEGUINDO, State.PREPARANDO, State.ATACANDO, State.ESPERANDO]:
		_enter(State.COMEMORANDO, "festa/Cheering")

	if state in [State.PERSEGUINDO, State.ESPERANDO] and _too_far(dist):
		_enter(State.VOLTANDO, "especial/Skeletons_Walking")

	match state:
		State.DORMINDO:
			_move(Vector3.ZERO)
			if dist < aggro_radius and not target_down:
				_enter(State.ACORDANDO, "especial/Skeletons_Awaken_Floor")
		State.VOLTANDO:
			var home := _spawn_point - global_position
			home.y = 0.0
			if dist < aggro_radius * 0.6 and not target_down:
				_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
			elif home.length() < 1.2:
				_move(Vector3.ZERO)
				_enter(State.DORMINDO, "especial/Skeletons_Death")
			else:
				_move(home.normalized() * config.speed)
				_face(home.normalized(), delta)
		State.PERSEGUINDO:
			if dist <= config.range and _cooldown <= 0.0 and _can_see_target():
				_start_attack()
			elif not _close_range() and dist <= config.range:
				_enter(State.ESPERANDO, "especial/Skeletons_Idle")
			elif dist < INF:
				var dir := to_target / dist
				_move(dir * config.speed)
				_face(dir, delta)
		State.ESPERANDO:
			_move(Vector3.ZERO)
			if dist < INF:
				_face(to_target.normalized(), delta)
			if _cooldown <= 0.0:
				if dist <= config.range and _can_see_target():
					_start_attack()
				elif dist > config.range:
					_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
		State.PREPARANDO:
			_move(Vector3.ZERO)
			if dist < INF:
				_face(to_target.normalized(), delta * 0.6)
			if _state_time >= config.windup and not _struck:
				_struck = true
				_warning.visible = false
				_strike(dist, to_target)
				_enter(State.ATACANDO, config.attack if not _close_range() else "")
		State.ATACANDO:
			_move(Vector3.ZERO)
			if _state_time > config.get("recover", 0.5):
				_cooldown = config.cooldown
				_enter(State.ESPERANDO, "especial/Skeletons_Idle")
		State.ATINGIDO:
			_move(Vector3.ZERO)
			if _state_time > 0.45:
				_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
		State.ACORDANDO:
			_move(Vector3.ZERO)
			if _state_time > _rise_length:
				health = config.health
				_set_hittable(true)
				_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
		State.COMEMORANDO:
			_move(Vector3.ZERO)
			if not target_down:
				_cooldown = 1.0
				_enter(State.PERSEGUINDO if dist <= aggro_radius else State.VOLTANDO, "especial/Skeletons_Walking")
	move_and_slide()


func _start_attack() -> void:
	_struck = false
	_warning.visible = true
	Sfx.play_at(get_parent(), "alerta", global_position + Vector3.UP * 3.0)
	# Golpe de perto: a animação já começa no aviso e o dano sai no meio dela.
	_enter(State.PREPARANDO, config.attack if _close_range() else config.aim, config.get("attack_speed", 1.0))


func _strike(dist: float, to_target: Vector3) -> void:
	if not is_instance_valid(target):
		return
	match config.kind:
		"melee":
			Sfx.play_at(get_parent(), "golpe_ar", global_position + Vector3.UP * 1.2)
			var forward := visual.global_basis.z
			if dist <= config.range + 0.8 and forward.dot(to_target.normalized()) > 0.3:
				target.take_damage(1, global_position, name)
		"pancada":
			# Bate no chão na frente: quem está bem ali leva o golpe, e a onda corre pelo chão.
			var forward := visual.global_basis.z
			var center := global_position + forward * 1.8 * _size
			Sfx.play_at(get_parent(), "pancada", center)
			Fx.dust(get_parent(), center + Vector3.UP * 0.3)
			var wave := Boss.Shockwave.new()
			wave.target = target
			wave.max_radius = 9.0
			wave.speed = 7.0
			wave.source = name
			get_parent().add_child(wave)
			wave.global_position = Vector3(center.x, global_position.y + 0.05, center.z)
			if dist < 14.0:
				target.shake(0.15)
			if dist <= config.range and forward.dot(to_target.normalized()) > 0.3:
				target.take_damage(1, global_position, name)
		"flecha", "bolha":
			var from := _hand_r.global_position + Vector3.UP * 0.2 + visual.global_basis.z * 0.5
			var kind := Projectile.Kind.FLECHA if config.kind == "flecha" else Projectile.Kind.BOLHA
			get_parent().add_child(Projectile.create(kind, from, target))
			Sfx.play_at(get_parent(), config.kind, from)


func _can_see_target() -> bool:
	if not is_instance_valid(target):
		return false
	if _close_range():
		return true
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.5, target.global_position + Vector3.UP * 1.2, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _move(v: Vector3) -> void:
	velocity.x = v.x
	velocity.z = v.z


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-8.0 * delta))


## anim_name vazio mantém a animação atual (o golpe de perto continua tocando).
func _enter(new_state: State, anim_name: String, speed := 1.0) -> void:
	state = new_state
	_state_time = 0.0
	if new_state != State.PREPARANDO:
		_warning.visible = false
	if anim_name != "":
		ap.play(_anim(anim_name), 0.15, speed)
	if new_state == State.ACORDANDO:
		_rise_length = ap.current_animation_length if ap.current_animation != "" else 1.0
		_set_hittable(false)
		if is_inside_tree():
			Sfx.play_at(get_parent(), "remontar", global_position + Vector3.UP, -3.0)
	elif new_state in [State.INDO_EMBORA, State.DORMINDO, State.AFUNDANDO]:
		_set_hittable(false)


func _set_hittable(on: bool) -> void:
	for hb in hurtboxes:
		hb.set_active(on)
	# Desmontado, o jogador passa por cima da pilha; a máscara continua batendo no chão.
	collision_layer = (1 << 2) if on else 0


func take_hit(amount: float, point: Vector3, hb: Hurtbox) -> void:
	if state in [State.INDO_EMBORA, State.ACORDANDO, State.DORMINDO, State.AFUNDANDO]:
		return
	# O guerreiro segura o escudo na frente: tiro no corpo de frente não passa,
	# a não ser quando ele está erguendo o machado.
	if config.get("shield", false) and hb.region == "corpo" and state != State.PREPARANDO and state != State.ATACANDO:
		var from_front := visual.global_basis.z.dot((point - global_position).normalized()) > 0.2
		if from_front:
			Fx.dust(get_parent(), point)
			Fx.popup_text(get_parent(), point + Vector3.UP * 0.3, "bloqueou!", Color("#c9d1dc"))
			Sfx.play_at(get_parent(), "escudo", point)
			return
	_apply_damage(amount, point, hb.multiplier > 1.0)


## Explosão da granada: o escudo não segura, e o dano já vem com a distância descontada.
func take_explosion(amount: float, center: Vector3) -> void:
	if state in [State.INDO_EMBORA, State.ACORDANDO, State.DORMINDO, State.AFUNDANDO]:
		return
	var away := global_position - center
	away.y = 0.0
	if not config.get("heavy", false):
		velocity += away.normalized() * 4.0 + Vector3.UP * 3.0
	_apply_damage(amount, global_position + Vector3.UP * 1.8, false)


func _apply_damage(amount: float, point: Vector3, crit: bool) -> void:
	health -= amount
	var shown := "%.1f" % amount if fmod(amount, 1.0) > 0.01 else "%d" % int(amount)
	Fx.popup_text(get_parent(), point + Vector3.UP * 0.3, "x2!" if crit else "-" + shown,
			Color("#ffd23f") if crit else Color.WHITE)
	if health <= 0.0:
		Fx.confetti(get_parent(), global_position + Vector3.UP * 1.2, 50, 5.0)
		_start_leaving()
		defeated.emit(self)
	else:
		# Levar tiro interrompe o ataque: dá chance para quem está aprendendo.
		_cooldown = maxf(_cooldown, 0.8)
		_enter(State.ATINGIDO, "geral/Hit_A")


# --- indo embora de balão ----------------------------------------------------

func _start_leaving() -> void:
	_enter(State.INDO_EMBORA, "geral/Hit_B")
	velocity = Vector3.ZERO
	# Sem colisão: sobe atravessando telhados e copas sem enroscar.
	collision_mask = 0
	_start_y = global_position.y
	# Deriva de leve na direção do Morro (centro da ilha) enquanto sobe.
	var home := -global_position
	home.y = 0.0
	_drift = home.normalized() * 1.2 if home.length() > 1.0 else Vector3.ZERO
	_build_balloons()


## Três balões coloridos (bolas do Platformer Pack, um pouco esticadas) com cordinhas até
## um nó acima da cabeça. Nascem pequenos e enchem com um pulinho.
func _build_balloons() -> void:
	_balloons = Node3D.new()
	_balloons.name = "Baloes"
	_balloons.position.y = 2.6 * _size
	_balloons.scale = Vector3.ONE * 0.01
	add_child(_balloons)
	var colors := BALLOONS.duplicate()
	colors.shuffle()
	var spots := [Vector3(0, 2.2, 0), Vector3(-0.7, 1.7, 0.25), Vector3(0.7, 1.75, -0.2)]
	var string_mat := Fx.flat_material(Color(1, 1, 1, 1), false)
	for k in 3:
		var ball: Node3D = load(PLAT % colors[k]).instantiate()
		ball.scale = Vector3(0.42, 0.5, 0.42)
		ball.position = spots[k]
		_balloons.add_child(ball)
		var bottom: Vector3 = spots[k] - Vector3(0, 0.5, 0)
		var cord := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.015
		cyl.bottom_radius = 0.015
		cyl.height = bottom.length()
		cyl.material = string_mat
		cord.mesh = cyl
		cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cord.transform = Transform3D(Basis(Quaternion(Vector3.UP, bottom.normalized())), bottom * 0.5)
		_balloons.add_child(cord)
	var tw := _balloons.create_tween()
	tw.tween_interval(BALLOON_APPEAR)
	tw.tween_callback(func() -> void: Sfx.play_at(get_parent(), "balao", global_position + Vector3.UP * 3.0))
	tw.tween_property(_balloons, "scale", Vector3.ONE * sqrt(_size), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _fly_away(delta: float) -> void:
	if _state_time < BALLOON_LIFT:
		return
	if ap.current_animation != _anim("festa/Waving"):
		ap.play(_anim("festa/Waving"), 0.3)
		Fx.popup_text(get_parent(), global_position + Vector3.UP * 3.2 * _size, "Tchau!", Color("#ffd6f3"))
	var t := _state_time - BALLOON_LIFT
	var up := minf(0.6 + t * 1.4, 4.0)
	global_position += (Vector3.UP * up + _drift) * delta
	visual.rotation.z = sin(_state_time * 2.2) * 0.08
	_balloons.rotation.z = sin(_state_time * 2.2 + 0.6) * 0.12
	if _state_time > BALLOON_GONE or global_position.y - _start_y > 24.0:
		Fx.confetti(get_parent(), global_position + Vector3.UP * 4.0, 30, 3.0)
		gone.emit(self)
		queue_free()
