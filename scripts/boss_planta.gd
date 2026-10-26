class_name BossPlanta
extends Boss
## Guerreiro Planta: o guardião (opcional) da Vila das Copas, do Mystery Monthly Series 6. Não é esqueleto:
## protege a mata e desafia quem quer subir na Vila. Brota do chão e segura o escudo de folha na frente
## (tiro no corpo pela frente não passa; cabeça e costas valem). Alterna:
## - três flechas em leque, com o arco (aviso "!" antes);
## - investida com a lança: uma faixa no chão mostra o caminho; depois da investida fica uns segundos
##   sem escudo, ofegante.
## Vencido, não vai de balão: aplaude, diz que a Vila é sua e fica ali.

const CHAR := "res://assets/characters/guardioes/%s.glb"
const ARMS := "res://assets/weapons/planta/%s.gltf"
const ARROW_EVERY := 2.8
const DRAW_TIME := 0.8
const DASH_EVERY := 7.0
const DASH_WINDUP := 1.0
const DASH_LOCK := 0.35
const DASH_SPEED := 11.0
const DASH_TIME := 0.9
const DASH_HIT_RADIUS := 1.8
const OPEN_TIME := 1.8
const KEEP_MIN := 6.0
const KEEP_MAX := 11.0

enum Move { ANDANDO, ATIRANDO, PREPARANDO, INVESTIDA, ABERTO }

var move_state := Move.ANDANDO
var _move_time := 0.0
var _arrow_timer := 2.0
var _dash_timer := 5.0
var _dash_dir := Vector3.FORWARD
var _struck := false
var _spear: Node3D
var _bow: Node3D
var _stripe: MeshInstance3D
var _bowed := false


func _setup() -> void:
	display_name = "Guerreiro Planta"
	subtitle = "o guardião da Vila das Copas"
	max_health = 30.0
	body_scale = 1.7
	speed = 2.4


func _build() -> void:
	_skeleton("PlantWarrior", "PlantWarrior_Spear", "PlantWarrior_Shield", CHAR, ARMS)
	_spear = hand_r.get_child(0)
	_bow = load(ARMS % "PlantWarrior_Bow_withString").instantiate()
	_bow.visible = false
	hand_r.add_child(_bow)


func _fight(delta: float, to_target: Vector3, dist: float) -> void:
	_move_time += delta
	var dir := to_target.normalized() if dist > 0.01 else forward()
	match move_state:
		Move.ANDANDO:
			face(dir, delta, 4.0)
			if dist > KEEP_MAX:
				move(dir * speed)
			elif dist < KEEP_MIN:
				move(-dir * speed * 0.8)
			else:
				move(Vector3.ZERO)
			play(&"luta/Melee_Blocking" if Vector2(velocity.x, velocity.z).length() < 0.3 else &"especial/Skeletons_Walking")
			_arrow_timer -= delta
			_dash_timer -= delta
			if _dash_timer <= 0.0 and dist < 16.0:
				_start(Move.PREPARANDO)
				restart(&"especial/Skeletons_Taunt")
				_show_stripe(dir)
			elif _arrow_timer <= 0.0:
				_start(Move.ATIRANDO)
				_hold_bow(true)
				restart(&"tiro/Ranged_Bow_Draw")
		Move.ATIRANDO:
			move(Vector3.ZERO)
			face(dir, delta, 6.0)
			if not _struck and _move_time >= DRAW_TIME:
				_struck = true
				hide_alert()
				restart(&"tiro/Ranged_Bow_Release")
				_volley()
			if _move_time >= DRAW_TIME + 0.6:
				_arrow_timer = ARROW_EVERY
				_hold_bow(false)
				_rest()
		Move.PREPARANDO:
			move(Vector3.ZERO)
			if _move_time < DASH_WINDUP - DASH_LOCK:
				face(dir, delta, 6.0)
				_dash_dir = dir
				_place_stripe(_dash_dir)
			if _move_time >= DASH_WINDUP:
				hide_alert()
				_hide_stripe()
				move_state = Move.INVESTIDA
				_move_time = 0.0
				_struck = false
				restart(&"luta/Melee_1H_Attack_Stab", 1.2)
				Sfx.play_at(get_parent(), "golpe_ar", global_position + Vector3.UP * 2.0, 3.0)
		Move.INVESTIDA:
			move(_dash_dir * DASH_SPEED)
			face(_dash_dir, delta, 10.0)
			if not _struck and is_instance_valid(target):
				var rel := target.global_position - global_position
				rel.y = 0.0
				if rel.length() < DASH_HIT_RADIUS:
					_struck = true
					hit_player(global_position)
			var hit_wall := false
			for i in get_slide_collision_count():
				var c := get_slide_collision(i)
				if not (c.get_collider() is Player) and absf(c.get_normal().y) < 0.5:
					hit_wall = true
			if _move_time >= DASH_TIME or (hit_wall and _move_time > 0.2):
				move_state = Move.ABERTO
				_move_time = 0.0
				_dash_timer = DASH_EVERY
				restart(&"geral/Hit_B")
				Fx.popup_text(get_parent(), global_position + Vector3.UP * 3.0 * body_scale * 0.6, "ufa!", Color("#c9f7a0"))
		Move.ABERTO:
			move(Vector3.ZERO)
			if _move_time > 0.6:
				play(&"especial/Skeletons_Idle")
			if _move_time >= OPEN_TIME:
				_rest()


func _start(m: Move) -> void:
	move_state = m
	_move_time = 0.0
	_struck = false
	alert()


func _rest() -> void:
	move_state = Move.ANDANDO
	_move_time = 0.0


func _hold_bow(on: bool) -> void:
	_bow.visible = on
	_spear.visible = not on


## Três flechas em leque na direção do aventureiro.
func _volley() -> void:
	if not is_instance_valid(target):
		return
	var from := hand_r.global_position + Vector3.UP * 0.3 + forward() * 0.8
	for k in 3:
		var p := Projectile.create(Projectile.Kind.FLECHA, from, target)
		p.direction = p.direction.rotated(Vector3.UP, (k - 1) * 0.22)
		get_parent().add_child(p)
	Sfx.play_at(get_parent(), "flecha", from)


## O escudo segura tiro no corpo pela frente, menos quando está atacando ou ofegante.
func _blocks(point: Vector3, hb: Hurtbox) -> bool:
	if move_state != Move.ANDANDO or hb.region != "corpo":
		return false
	return forward().dot((point - global_position).normalized()) > 0.2


func _cancel_attack() -> void:
	_hide_stripe()
	_hold_bow(false)
	hide_alert()
	_rest()


func is_open() -> bool:
	return move_state == Move.ABERTO


# --- derrota: aplaude e fica -----------------------------------------------------

func _defeat() -> void:
	_cancel_attack()
	phase = Phase.INDO_EMBORA
	_phase_time = 0.0
	_set_hittable(false)
	velocity = Vector3.ZERO
	collision_layer = 0
	restart(&"festa/Cheering")
	Fx.confetti(get_parent(), global_position + Vector3.UP * body_scale * 1.5, 100, 6.0)
	defeated.emit(self)


func _fly_away(_delta: float) -> void:
	if _phase_time > 1.2 and not _bowed:
		_bowed = true
		Fx.popup_text(get_parent(), global_position + Vector3.UP * 2.6 * body_scale, "Você é digno! A Vila das Copas é sua!", Color("#c9f7a0"))
		gone.emit(self)
	if _phase_time > 3.0 and ap.current_animation != "festa/Waving":
		ap.play(&"festa/Waving", 0.4)


# --- faixa da investida -------------------------------------------------------------

func _show_stripe(dir: Vector3) -> void:
	if not is_instance_valid(_stripe):
		_stripe = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(DASH_HIT_RADIUS * 2.0, 0.05, DASH_SPEED * DASH_TIME)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.55, 1.0, 0.45, 0.4)
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
	var mid := global_position + dir * (DASH_SPEED * DASH_TIME * 0.5)
	mid.y = ground_at(mid) + 0.06
	_stripe.global_transform = Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z)), mid)


func _hide_stripe() -> void:
	if is_instance_valid(_stripe):
		_stripe.visible = false
