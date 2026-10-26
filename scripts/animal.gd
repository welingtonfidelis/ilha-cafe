class_name Animal
extends CharacterBody3D
## Bicho solto da ilha (Quaternius, CC0): passeia perto de casa, para, pasta e volta a andar. Os tímidos
## (veado, raposa) saem galopando quando o aventureiro chega perto. Os da fazenda (porco, ovelha, lhama,
## pug) só têm a animação parada: ficam no lugar e viram devagar de vez em quando.
## Fica na camada dos moradores: o aventureiro esbarra, mas tiros e esqueletos passam direto.

const MODELS := "res://assets/animais/%s"
const WALK_SPEED := 1.3
const FLEE_SPEED := 5.5
const FLEE_RADIUS := 7.0

@export var model_file := "Horse.gltf"
@export var model_scale := 0.42
## Raio do passeio em volta do lugar onde nasceu (0 = fica parado).
@export var wander_radius := 6.0
@export var shy := false

var player: Player
var visual: Node3D
var ap: AnimationPlayer
var _anims := {}
var _home := Vector3.ZERO
var _target := Vector3.ZERO
var _state := "parado"
var _timer := 0.0
var _stuck := 0.0
var _last_pos := Vector3.ZERO
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0


func _ready() -> void:
	add_to_group(&"animais")
	collision_layer = Townsperson.LAYER
	collision_mask = 1
	visual = Node3D.new()
	add_child(visual)
	var model: Node3D = load(MODELS % model_file).instantiate()
	model.scale = Vector3.ONE * model_scale
	visual.add_child(model)
	var aabb := _model_aabb(model)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(maxf(aabb.size.x, 0.3), maxf(aabb.size.y * 0.8, 0.3), maxf(aabb.size.z * 0.8, 0.3))
	shape.shape = box
	shape.position = Vector3(0, box.size.y * 0.5, aabb.get_center().z)
	add_child(shape)
	ap = model.find_child("AnimationPlayer", true, false)
	if ap:
		for full in ap.get_animation_list():
			var short := String(full).get_slice("|", String(full).get_slice_count("|") - 1)
			_anims[short] = full
			if short in ["Idle", "Walk", "Gallop", "Eating", "Idle_2", "Idle_Headlow", "Idle_2_HeadLow"]:
				ap.get_animation(full).loop_mode = Animation.LOOP_LINEAR
	if not _anims.has("Walk"):
		wander_radius = 0.0
	_home = global_position
	_target = _home
	_timer = randf_range(0.5, 4.0)
	_play("Idle")
	if ap and ap.current_animation != "":
		ap.seek(randf() * 1.5, true)


func _model_aabb(model: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.mesh == null:
			continue
		var xf := Transform3D.IDENTITY
		var n: Node = m
		while n != self and n is Node3D:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var a: AABB = xf * m.get_aabb()
		result = a if first else result.merge(a)
		first = false
	return result


func _play(short: String, blend := 0.3) -> void:
	if not ap:
		return
	var full: StringName = _anims.get(short, _anims.get("Idle", &""))
	if full != &"" and ap.current_animation != full:
		ap.play(full, blend)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = 0.0
	_timer -= delta
	var near_player := shy and is_instance_valid(player) and player.global_position.distance_to(global_position) < FLEE_RADIUS
	if near_player and _state != "fugindo" and _anims.has("Gallop"):
		var away := global_position - player.global_position
		away.y = 0.0
		_target = global_position + away.normalized() * 12.0
		_state = "fugindo"
		_timer = 3.0
		_stuck = 0.0
		_last_pos = global_position
	match _state:
		"parado", "pastando":
			_move(Vector3.ZERO, delta)
			if wander_radius <= 0.0:
				if _timer <= 0.0:
					_timer = randf_range(6.0, 12.0)
					var tw := create_tween()
					tw.tween_property(visual, "rotation:y", visual.rotation.y + randf_range(-0.9, 0.9), 2.0).set_trans(Tween.TRANS_SINE)
			elif _timer <= 0.0:
				var a := randf() * TAU
				_target = _home + Vector3(cos(a), 0, sin(a)) * randf_range(1.5, wander_radius)
				_state = "andando"
				_timer = 12.0
				_stuck = 0.0
				_last_pos = global_position
		"andando", "fugindo":
			var to := _target - global_position
			to.y = 0.0
			var fleeing := _state == "fugindo"
			# Travado: quase não saiu do lugar desde o quadro anterior (esbarrou numa árvore, numa cerca).
			var moved := Vector2(global_position.x - _last_pos.x, global_position.z - _last_pos.z).length()
			_stuck = _stuck + delta if moved < WALK_SPEED * 0.25 * delta else 0.0
			_last_pos = global_position
			if to.length() < 0.6 or _timer <= 0.0 or _stuck > 1.5:
				_rest()
			else:
				_move(to.normalized() * (FLEE_SPEED if fleeing else WALK_SPEED), delta)
				_play("Gallop" if fleeing else "Walk")
	move_and_slide()


func _rest() -> void:
	# Depois de andar, pasta (os que sabem) ou fica parado olhando em volta.
	var eats := _anims.has("Eating") and randf() < 0.6
	_state = "pastando" if eats else "parado"
	_play("Eating" if eats else "Idle")
	_timer = randf_range(3.0, 8.0)
	# Quem fugiu mora onde parou.
	if wander_radius > 0.0 and global_position.distance_to(_home) > wander_radius * 2.0:
		_home = global_position


func _move(v: Vector3, delta: float) -> void:
	velocity.x = v.x
	velocity.z = v.z
	if v.length() > 0.05:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(v.x, v.z), 1.0 - exp(-5.0 * delta))
