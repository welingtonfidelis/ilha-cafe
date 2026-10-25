class_name SkeletonEnemy
extends CharacterBody3D
## Esqueleto do KayKit. Persegue o jogador e ataca do seu jeito (ver TYPES); ao levar tiros
## suficientes, desmonta numa pilha de ossos e se remonta depois. Ninguém morre (regras de tom).
## Todo ataque tem um aviso ("!" em cima da cabeça) antes do golpe, para dar tempo de desviar.
## Duas regiões de impacto presas aos ossos: cabeça (dano em dobro) e corpo.

signal defeated(enemy: SkeletonEnemy)

enum State { PERSEGUINDO, PREPARANDO, ATACANDO, ESPERANDO, ATINGIDO, DESMONTADO, REMONTANDO, COMEMORANDO }

const SKELETONS := "res://assets/characters/skeletons/%s.glb"
const WEAPONS := "res://assets/weapons/skeleton/%s.gltf"

## kind: "melee" (golpe de perto), "flecha" ou "bolha" (à distância).
## range: distância em que começa o ataque. windup: tempo do aviso até o golpe sair.
const TYPES := {
	"Skeleton_Minion": {
		"kind": "melee", "health": 3.0, "speed": 2.4, "range": 1.8, "windup": 0.5, "cooldown": 1.6,
		"attack": "luta/Melee_Unarmed_Attack_Punch_A", "right": "", "left": "",
	},
	"Skeleton_Warrior": {
		"kind": "melee", "health": 5.0, "speed": 1.7, "range": 2.1, "windup": 0.55, "cooldown": 2.2,
		"attack": "luta/Melee_1H_Attack_Chop", "right": "Skeleton_Axe", "left": "Skeleton_Shield_Small_A",
		"shield": true,
	},
	"Skeleton_Rogue": {
		"kind": "flecha", "health": 3.0, "speed": 2.2, "range": 12.0, "windup": 0.8, "cooldown": 2.8,
		"aim": "tiro/Ranged_2H_Aiming", "attack": "tiro/Ranged_2H_Shoot", "right": "Skeleton_Crossbow", "left": "",
	},
	"Skeleton_Mage": {
		"kind": "bolha", "health": 3.0, "speed": 1.9, "range": 13.0, "windup": 0.7, "cooldown": 3.8,
		"aim": "tiro/Ranged_Magic_Spellcasting", "attack": "tiro/Ranged_Magic_Shoot", "right": "Skeleton_Staff", "left": "",
	},
}

@export var type_name := "Skeleton_Minion"
@export var down_time := 3.5

var target: Player
var health := 3.0
var state := State.REMONTANDO
var hurtboxes: Array[Hurtbox] = []
var config: Dictionary

var visual: Node3D
var model: Node3D
var ap: AnimationPlayer
var _warning: Label3D
var _hand_r: BoneAttachment3D
var _state_time := 0.0
var _rise_length := 1.0
var _cooldown := 0.0
var _struck := false
var _spawn_point := Vector3.ZERO
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0


func _ready() -> void:
	config = TYPES[type_name]
	health = config.health
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 1) | (1 << 2)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 2.0
	shape.shape = capsule
	shape.position.y = 1.0
	add_child(shape)
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	model = load(SKELETONS % type_name).instantiate()
	visual.add_child(model)
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
	_warning.position.y = 3.0
	_warning.visible = false
	add_child(_warning)
	_spawn_point = global_position
	_enter(State.REMONTANDO, "especial/Skeletons_Awaken_Floor")


## Volta para o lugar de origem e acorda de novo (usado quando o aventureiro reaparece).
func reset_to_spawn() -> void:
	global_position = _spawn_point
	velocity = Vector3.ZERO
	health = config.health
	_cooldown = 1.5
	_enter(State.REMONTANDO, "especial/Skeletons_Awaken_Floor")


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
	head.radius = 0.5
	_add_hurtbox(sk, "head", "cabeça", 2.0, head, Vector3(0, 0.45, 0), Color(1, 0.85, 0.2, 0.35))
	var body := CapsuleShape3D.new()
	body.radius = 0.4
	body.height = 1.1
	_add_hurtbox(sk, "chest", "corpo", 1.0, body, Vector3(0, -0.2, 0), Color(1, 0.3, 0.3, 0.35))


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

	match state:
		State.PERSEGUINDO:
			if dist <= config.range and _cooldown <= 0.0 and _can_see_target():
				_start_attack()
			elif config.kind != "melee" and dist <= config.range:
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
				_enter(State.ATACANDO, config.attack if config.kind != "melee" else "")
		State.ATACANDO:
			_move(Vector3.ZERO)
			if _state_time > 0.5:
				_cooldown = config.cooldown
				_enter(State.ESPERANDO, "especial/Skeletons_Idle")
		State.ATINGIDO:
			_move(Vector3.ZERO)
			if _state_time > 0.45:
				_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
		State.DESMONTADO:
			_move(Vector3.ZERO)
			if _state_time > down_time:
				_enter(State.REMONTANDO, "especial/Skeletons_Death_Resurrect")
		State.REMONTANDO:
			_move(Vector3.ZERO)
			if _state_time > _rise_length:
				health = config.health
				_set_hittable(true)
				_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
		State.COMEMORANDO:
			_move(Vector3.ZERO)
			if not target_down:
				_cooldown = 1.0
				_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
	move_and_slide()


func _start_attack() -> void:
	_struck = false
	_warning.visible = true
	# Golpe de perto: a animação já começa no aviso e o dano sai no meio dela.
	_enter(State.PREPARANDO, config.attack if config.kind == "melee" else config.aim)


func _strike(dist: float, to_target: Vector3) -> void:
	if not is_instance_valid(target):
		return
	match config.kind:
		"melee":
			var forward := visual.global_basis.z
			if dist <= config.range + 0.8 and forward.dot(to_target.normalized()) > 0.3:
				target.take_damage(1, global_position, name)
		"flecha", "bolha":
			var from := _hand_r.global_position + Vector3.UP * 0.2 + visual.global_basis.z * 0.5
			var kind := Projectile.Kind.FLECHA if config.kind == "flecha" else Projectile.Kind.BOLHA
			get_parent().add_child(Projectile.create(kind, from, target))


func _can_see_target() -> bool:
	if not is_instance_valid(target):
		return false
	if config.kind == "melee":
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
func _enter(new_state: State, anim_name: String) -> void:
	state = new_state
	_state_time = 0.0
	if new_state != State.PREPARANDO:
		_warning.visible = false
	if anim_name != "":
		ap.play(StringName(anim_name), 0.15)
	if new_state == State.REMONTANDO:
		_rise_length = ap.current_animation_length
		_set_hittable(false)
	elif new_state == State.DESMONTADO:
		_set_hittable(false)


func _set_hittable(on: bool) -> void:
	for hb in hurtboxes:
		hb.set_active(on)
	# Desmontado, o jogador passa por cima da pilha; a máscara continua batendo no chão.
	collision_layer = (1 << 2) if on else 0


func take_hit(amount: float, point: Vector3, hb: Hurtbox) -> void:
	if state == State.DESMONTADO or state == State.REMONTANDO:
		return
	# O guerreiro segura o escudo na frente: tiro no corpo de frente não passa,
	# a não ser quando ele está erguendo o machado.
	if config.get("shield", false) and hb.region == "corpo" and state != State.PREPARANDO and state != State.ATACANDO:
		var from_front := visual.global_basis.z.dot((point - global_position).normalized()) > 0.2
		if from_front:
			Fx.dust(get_parent(), point)
			Fx.popup_text(get_parent(), point + Vector3.UP * 0.3, "bloqueou!", Color("#c9d1dc"))
			return
	health -= amount
	var crit := hb.multiplier > 1.0
	Fx.popup_text(get_parent(), point + Vector3.UP * 0.3, "x2!" if crit else "-%d" % int(amount),
			Color("#ffd23f") if crit else Color.WHITE)
	if health <= 0.0:
		Fx.confetti(get_parent(), global_position + Vector3.UP * 1.2, 70, 6.5)
		_enter(State.DESMONTADO, "especial/Skeletons_Death")
		defeated.emit(self)
	else:
		# Levar tiro interrompe o ataque: dá chance para quem está aprendendo.
		_cooldown = maxf(_cooldown, 0.8)
		_enter(State.ATINGIDO, "geral/Hit_A")
