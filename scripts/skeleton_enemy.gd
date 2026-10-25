class_name SkeletonEnemy
extends CharacterBody3D
## Esqueleto do KayKit. Persegue o jogador, provoca de perto e, ao levar tiros suficientes,
## desmonta numa pilha de ossos e se remonta depois. Ninguém morre (regras de tom do doc).
## Duas regiões de impacto presas aos ossos: cabeça (dano em dobro) e corpo.

enum State { PERSEGUINDO, PROVOCANDO, ATINGIDO, DESMONTADO, REMONTANDO }

@export var model_path := "res://assets/characters/skeletons/Skeleton_Minion.glb"
@export var max_health := 3.0
@export var speed := 2.2
@export var down_time := 3.5

var target: Node3D
var health := 3.0
var state := State.REMONTANDO
var hurtboxes: Array[Hurtbox] = []

var visual: Node3D
var model: Node3D
var ap: AnimationPlayer
var _body_shape: CollisionShape3D
var _state_time := 0.0
var _rise_length := 1.0
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0


func _ready() -> void:
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 1) | (1 << 2)
	_body_shape = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5
	capsule.height = 2.0
	_body_shape.shape = capsule
	_body_shape.position.y = 1.0
	add_child(_body_shape)
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	model = load(model_path).instantiate()
	visual.add_child(model)
	ap = AnimUtil.make_player(model, ["geral", "mov", "especial"])
	_build_hurtboxes()
	health = max_health
	_enter(State.REMONTANDO, "especial/Skeletons_Awaken_Floor")


func _build_hurtboxes() -> void:
	var sk: Skeleton3D = model.find_child("Skeleton3D", true, false)
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
	if not is_on_floor():
		velocity.y -= _gravity * delta
	var to_target := Vector3.ZERO
	var dist := INF
	if is_instance_valid(target):
		to_target = target.global_position - global_position
		to_target.y = 0.0
		dist = to_target.length()

	match state:
		State.PERSEGUINDO:
			if dist < 1.9:
				_enter(State.PROVOCANDO, "especial/Skeletons_Taunt")
			elif dist < INF:
				var dir := to_target / dist
				_move(dir * speed)
				_face(dir, delta)
		State.PROVOCANDO:
			_move(Vector3.ZERO)
			if dist < INF:
				_face(to_target.normalized(), delta)
			if _state_time > ap.current_animation_length:
				if dist > 2.5:
					_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
				else:
					_enter(State.PROVOCANDO, "especial/Skeletons_Taunt")
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
				health = max_health
				_set_hittable(true)
				_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
	move_and_slide()


func _move(v: Vector3) -> void:
	velocity.x = v.x
	velocity.z = v.z


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-8.0 * delta))


func _enter(new_state: State, anim_name: String) -> void:
	state = new_state
	_state_time = 0.0
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
	health -= amount
	var crit := hb.multiplier > 1.0
	Fx.popup_text(get_parent(), point + Vector3.UP * 0.3, "x2!" if crit else "-%d" % int(amount),
			Color("#ffd23f") if crit else Color.WHITE)
	if health <= 0.0:
		Fx.confetti(get_parent(), global_position + Vector3.UP * 1.2, 70, 6.5)
		_enter(State.DESMONTADO, "especial/Skeletons_Death")
	else:
		_enter(State.ATINGIDO, "geral/Hit_A")
