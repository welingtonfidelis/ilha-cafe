class_name BossMinionzao
extends Boss
## Minionzão, guardião do Morro dos Ventos: um Minion três vezes maior.
## - Soco: de perto, na frente dele.
## - Investida: faz pose, uma faixa vermelha no chão mostra o caminho e ele dispara em linha reta.
##   Andar para o lado escapa. Depois da investida fica tonto uns segundos (estrelinhas) e leva dano
##   em dobro; se bater numa parede, fica tonto por mais tempo.

enum Move { ANDANDO, SOCO, PREPARANDO, INVESTIDA, TONTO, DESCANSO }

const PUNCH_RANGE := 6.5
const PUNCH_HIT := 0.55 / 0.8
const PUNCH_END := 1.17 / 0.8
const CHARGE_RANGE := 24.0
const CHARGE_WINDUP := 1.15
## A faixa para de seguir o aventureiro um pouco antes da largada, para dar tempo de sair.
const CHARGE_LOCK := 0.45
const CHARGE_SPEED := 15.0
const CHARGE_TIME := 1.5
const CHARGE_HIT_RADIUS := 2.6
const DIZZY_TIME := 2.2
const DIZZY_WALL_TIME := 3.6

var _move := Move.ANDANDO
var _move_time := 0.0
var _struck := false
var _charge_cooldown := 2.5
var _charge_dir := Vector3.FORWARD
var _dizzy_time := DIZZY_TIME
var _stripe: MeshInstance3D
var _stars: Node3D


func _setup() -> void:
	display_name = "Minionzão"
	subtitle = "o Minion gigante"
	max_health = 50.0
	body_scale = 3.0
	speed = 2.0


func _build() -> void:
	_skeleton("Skeleton_Minion", "", "")
	_stars = Node3D.new()
	_stars.visible = false
	add_child(_stars)
	var mesh := Fx.star_mesh(0.36, 0.15, 0.1)
	var mat := Fx.flat_material(Color("#ffd23f"))
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	for i in 4:
		var star := MeshInstance3D.new()
		star.mesh = mesh
		star.material_override = mat
		var a := TAU * i / 4.0
		star.position = Vector3(cos(a), 0, sin(a)) * 1.2
		_stars.add_child(star)


func _fight(delta: float, to_target: Vector3, dist: float) -> void:
	_move_time += delta
	_charge_cooldown -= delta
	var dir := to_target.normalized() if dist > 0.01 else forward()
	match _move:
		Move.ANDANDO:
			if dist < PUNCH_RANGE - 1.0:
				_start(Move.SOCO)
				restart(&"luta/Melee_Unarmed_Attack_Punch_A", 0.8)
			elif dist < CHARGE_RANGE and _charge_cooldown <= 0.0:
				_start(Move.PREPARANDO)
				restart(&"especial/Skeletons_Taunt", 1.0)
				_show_stripe(dir)
			else:
				move(dir * speed)
				face(velocity if _detour.detouring() else dir, delta)
				play(&"especial/Skeletons_Walking", 0.6)
		Move.SOCO:
			move(Vector3.ZERO)
			if _move_time < PUNCH_HIT * 0.7:
				face(dir, delta, 4.0)
			if not _struck and _move_time >= PUNCH_HIT:
				_struck = true
				hide_alert()
				Sfx.play_at(get_parent(), "golpe_ar", global_position + Vector3.UP * 3.0)
				if dist <= PUNCH_RANGE and forward().dot(dir) > 0.3:
					hit_player(global_position)
			if _move_time >= PUNCH_END:
				_rest()
		Move.PREPARANDO:
			move(Vector3.ZERO)
			if _move_time < CHARGE_WINDUP - CHARGE_LOCK:
				face(dir, delta, 6.0)
				_charge_dir = dir
				_place_stripe(_charge_dir)
			if _move_time >= CHARGE_WINDUP:
				hide_alert()
				_hide_stripe()
				_move = Move.INVESTIDA
				_move_time = 0.0
				_struck = false
				restart(&"mov/Running_A", 1.5)
				Sfx.play_at(get_parent(), "golpe_ar", global_position + Vector3.UP * 3.0, 4.0)
		Move.INVESTIDA:
			move(_charge_dir * CHARGE_SPEED, false)
			face(_charge_dir, delta, 10.0)
			if not _struck and is_instance_valid(target):
				var rel := target.global_position - global_position
				rel.y = 0.0
				if rel.length() < CHARGE_HIT_RADIUS:
					_struck = true
					hit_player(global_position)
			var hit_wall := false
			for i in get_slide_collision_count():
				var c := get_slide_collision(i)
				var n := c.get_normal()
				if not (c.get_collider() is Player) and absf(n.y) < 0.5 and n.dot(_charge_dir) < -0.5:
					hit_wall = true
			if hit_wall or _move_time >= CHARGE_TIME:
				_get_dizzy(hit_wall)
		Move.TONTO:
			move(Vector3.ZERO)
			_stars.global_position = global_position + Vector3.UP * 3.0 * body_scale
			_stars.rotate_y(delta * 3.0)
			if _move_time >= _dizzy_time:
				_stars.visible = false
				_charge_cooldown = 3.8
				_rest()
		Move.DESCANSO:
			move(Vector3.ZERO)
			face(dir, delta, 3.0)
			play(&"especial/Skeletons_Idle")
			if _move_time > 0.8:
				_move = Move.ANDANDO
				_move_time = 0.0


func _start(m: Move) -> void:
	_move = m
	_move_time = 0.0
	_struck = false
	alert()


func _rest() -> void:
	_move = Move.DESCANSO
	_move_time = 0.0


func _get_dizzy(hit_wall: bool) -> void:
	_move = Move.TONTO
	_move_time = 0.0
	_dizzy_time = DIZZY_WALL_TIME if hit_wall else DIZZY_TIME
	move(Vector3.ZERO)
	restart(&"geral/Hit_B", 0.6)
	_stars.visible = true
	Fx.popup_text(get_parent(), global_position + Vector3.UP * 3.4 * body_scale, "tonto! dano em dobro", Color("#ffd23f"))
	if hit_wall:
		Sfx.play_at(get_parent(), "pancada", global_position)
		Fx.dust(get_parent(), global_position + forward() * 1.5 + Vector3.UP)
	else:
		Sfx.play_at(get_parent(), "tonto", global_position + Vector3.UP * 4.0)


func is_dizzy() -> bool:
	return _move == Move.TONTO


func _damage_factor() -> float:
	return 2.0 if _move == Move.TONTO else 1.0


func _cancel_attack() -> void:
	_hide_stripe()
	_stars.visible = false
	_rest()


# --- faixa vermelha da investida -----------------------------------------------

func _show_stripe(dir: Vector3) -> void:
	if not is_instance_valid(_stripe):
		_stripe = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(CHARGE_HIT_RADIUS * 2.0, 0.05, CHARGE_SPEED * CHARGE_TIME)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1.0, 0.3, 0.35, 0.4)
		box.material = mat
		_stripe.mesh = box
		_stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_stripe.top_level = true
		add_child(_stripe)
	_stripe.visible = true
	_place_stripe(dir)


func _place_stripe(dir: Vector3) -> void:
	if not is_instance_valid(_stripe):
		return
	var length := CHARGE_SPEED * CHARGE_TIME
	var mid := global_position + dir * (length * 0.5)
	mid.y = ground_at(mid) + 0.06
	_stripe.global_transform = Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z)), mid)


func _hide_stripe() -> void:
	if is_instance_valid(_stripe):
		_stripe.visible = false
