class_name BossMestre
extends Boss
## Mestre Ossinho, chefe final no cemitério do Morro: o Necromancer do Skeletons completo (mago de coroa),
## com o cajado do Mage. Três fases pela vida:
## 1. Fica a uma certa distância, joga bolhas mágicas e chama dois minions de vez em quando.
## 2. Escudo de seis bolhas girando em volta: enquanto houver bolha, nada passa. Estouradas todas,
##    fica tonto uns segundos (estrelinhas, dano em dobro) e o escudo volta.
## 3. Bolhas gigantes e lentas que, estouradas com tiro, se dividem em três pequenas.
## Derrotado, não vai de balão: senta no chão, tira a coroa e confessa que só queria ir à festa.

const BUBBLE_EVERY := 3.2
const GIANT_EVERY := 3.4
const CAST_WINDUP := 0.7
const SUMMON_EVERY := 10.0
const SHIELD_COUNT := 6
const SHIELD_RADIUS := 1.7
const DIZZY_TIME := 5.0
const KEEP_MIN := 7.0
const KEEP_MAX := 12.0

## Fase da luta (1, 2 ou 3), pela vida que sobra.
var stage_n := 1
var shield: Array[ShieldBubble] = []
var crown_on_floor: MeshInstance3D
var _cast_timer := 2.0
var _casting := 0.0
var _summon_timer := 3.0
var _dizzy := 0.0
var _spin := 0.0
var _stars: Node3D
var _crown: MeshInstance3D
var _sat := false
var _confessed := false


func _setup() -> void:
	display_name = "Mestre Ossinho"
	subtitle = "o líder dos esqueletos"
	max_health = 48.0
	body_scale = 2.0
	speed = 1.3


func _build() -> void:
	_skeleton("Necromancer", "Skeleton_Staff", "")
	_crown = model.find_child("Necromancer_Crown", true, false)
	_stars = Node3D.new()
	_stars.visible = false
	add_child(_stars)
	var mesh := Fx.star_mesh(0.3, 0.12, 0.08)
	var mat := Fx.flat_material(Color("#ffd23f"))
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	for i in 4:
		var star := MeshInstance3D.new()
		star.mesh = mesh
		star.material_override = mat
		var a := TAU * i / 4.0
		star.position = Vector3(cos(a), 0, sin(a)) * 1.1
		_stars.add_child(star)
	# Se a defesa foi interrompida no meio da luta, ele volta na fase certa (e com o escudo, na 2).
	stage_n = _stage_for(health)


func _ready() -> void:
	super()
	if stage_n == 2:
		_raise_shield.call_deferred()


func _stage_for(h: float) -> int:
	var f := h / max_health
	if f > 0.66:
		return 1
	if f > 0.33:
		return 2
	return 3


func _fight(delta: float, to_target: Vector3, dist: float) -> void:
	var dir := to_target.normalized() if dist > 0.01 else forward()
	_spin_shield(delta)
	if _dizzy > 0.0:
		_dizzy -= delta
		move(Vector3.ZERO)
		_stars.global_position = global_position + Vector3.UP * 2.9 * body_scale
		_stars.rotate_y(delta * 3.0)
		if _dizzy <= 0.0:
			_stars.visible = false
			if stage_n == 2:
				_raise_shield()
		return
	face(dir, delta, 3.0)
	if dist > KEEP_MAX:
		move(dir * speed)
	elif dist < KEEP_MIN:
		move(-dir * speed * 0.8)
	else:
		move(Vector3.ZERO)
	if _casting > 0.0:
		_casting -= delta
		if _casting <= 0.0:
			_release()
	else:
		var walking := Vector2(velocity.x, velocity.z).length() > 0.3
		play(&"especial/Skeletons_Walking" if walking else &"especial/Skeletons_Idle")
		_cast_timer -= delta
		if _cast_timer <= 0.0:
			_cast_timer = GIANT_EVERY if stage_n == 3 else BUBBLE_EVERY * (1.3 if stage_n == 2 else 1.0)
			_casting = CAST_WINDUP
			alert()
			restart(&"tiro/Ranged_Magic_Spellcasting")
	if stage_n != 2:
		_summon_timer -= delta
		if _summon_timer <= 0.0:
			_summon_timer = SUMMON_EVERY * (1.5 if stage_n == 3 else 1.0)
			summon()


## Chama dois minions pelas bordas da arena.
func summon() -> void:
	Fx.popup_text(get_parent(), global_position + Vector3.UP * 3.0 * body_scale, "Venham, meus ossinhos!", Color("#d9a8ff"))
	for k in 2:
		var a := randf() * TAU
		var p := arena_center + Vector3(cos(a), 0, sin(a)) * arena_radius * 0.8
		p.y = ground_at(p)
		summon_requested.emit("Skeleton_Minion", p)


func _release() -> void:
	hide_alert()
	restart(&"tiro/Ranged_Magic_Shoot")
	if not is_instance_valid(target):
		return
	var from := hand_r.global_position + Vector3.UP * 0.6 + forward() * 1.2
	if stage_n == 3:
		get_parent().add_child(GiantBubble.make(from, target))
	else:
		get_parent().add_child(Projectile.create(Projectile.Kind.BOLHA, from, target))
	Sfx.play_at(get_parent(), "bolha", from, 4.0)


func _on_damaged() -> void:
	var s := _stage_for(health)
	if s == stage_n:
		return
	stage_n = s
	_cancel_attack()
	if s == 2:
		_raise_shield()
		Fx.popup_text(get_parent(), global_position + Vector3.UP * 3.0 * body_scale, "Escudo de bolhas!", Color("#ffd6f3"))
	elif s == 3:
		_clear_shield()
		_dizzy = 0.0
		_stars.visible = false
		Fx.popup_text(get_parent(), global_position + Vector3.UP * 3.0 * body_scale, "Bolhas gigantes!", Color("#ffd6f3"))


func _blocks(_point: Vector3, _hb: Hurtbox) -> bool:
	return not shield.is_empty()


func _damage_factor() -> float:
	return 2.0 if _dizzy > 0.0 else 1.0


func _cancel_attack() -> void:
	_casting = 0.0
	hide_alert()


func is_dizzy() -> bool:
	return _dizzy > 0.0


# --- escudo de bolhas ----------------------------------------------------------

func _raise_shield() -> void:
	_clear_shield()
	for k in SHIELD_COUNT:
		var b := ShieldBubble.new()
		b.popped.connect(_on_shield_popped)
		get_parent().add_child(b)
		shield.append(b)
	_spin_shield(0.0)


func _clear_shield() -> void:
	for b in shield:
		if is_instance_valid(b):
			b.queue_free()
	shield.clear()


func _spin_shield(delta: float) -> void:
	_spin += delta * 1.3
	for i in shield.size():
		var a := _spin + TAU * i / shield.size()
		var h := 1.3 * body_scale + sin(_spin * 2.0 + i) * 0.3
		shield[i].global_position = global_position + Vector3(cos(a) * SHIELD_RADIUS * body_scale, h, sin(a) * SHIELD_RADIUS * body_scale)


func _on_shield_popped(b: ShieldBubble) -> void:
	shield.erase(b)
	if shield.is_empty() and stage_n == 2 and phase == Phase.LUTANDO:
		_get_dizzy()


func _get_dizzy() -> void:
	_cancel_attack()
	_dizzy = DIZZY_TIME
	_stars.visible = true
	restart(&"geral/Hit_B")
	Fx.popup_text(get_parent(), global_position + Vector3.UP * 3.0 * body_scale, "tonto! dano em dobro", Color("#ffd23f"))
	Sfx.play_at(get_parent(), "tonto", global_position + Vector3.UP * 4.0)


# --- derrota: sem balão ----------------------------------------------------------

func _defeat() -> void:
	_cancel_attack()
	_clear_shield()
	_dizzy = 0.0
	_stars.visible = false
	phase = Phase.INDO_EMBORA
	_phase_time = 0.0
	_set_hittable(false)
	velocity = Vector3.ZERO
	collision_layer = 0
	restart(&"geral/Hit_B")
	Fx.confetti(get_parent(), global_position + Vector3.UP * body_scale * 1.5, 140, 8.0)
	defeated.emit(self)


## Senta no chão, tira a coroa e confessa. Fica ali sentado (não some).
func _fly_away(_delta: float) -> void:
	if _phase_time > 1.0 and not _sat:
		_sat = true
		# A animação de sentar no chão vira o corpo 90° para a direita: o modelo compensa.
		model.rotation.y = PI / 2.0
		restart(&"festa/Sit_Floor_Down")
		ap.queue(&"festa/Sit_Floor_Idle")
	if _phase_time > 3.0 and _crown and _crown.visible:
		_take_off_crown()
	if _phase_time > 4.0 and not _confessed:
		_confessed = true
		Fx.popup_text(get_parent(), global_position + Vector3.UP * 2.2 * body_scale, "Eu só queria ir à festa...", Color("#ffd6f3"))
		gone.emit(self)


func _take_off_crown() -> void:
	var at := global_position + forward() * 1.6 * body_scale
	at.y = ground_at(at) + 0.02
	_crown.visible = false
	crown_on_floor = MeshInstance3D.new()
	crown_on_floor.name = "CoroaDoMestre"
	crown_on_floor.mesh = _crown.mesh
	get_parent().add_child(crown_on_floor)
	var s := body_scale
	var center := _crown.mesh.get_aabb().get_center()
	var bottom := _crown.mesh.get_aabb().position.y
	crown_on_floor.scale = Vector3.ONE * s
	crown_on_floor.global_position = at + Vector3.UP * 1.2 - Vector3(center.x, bottom, center.z) * s
	var tw := crown_on_floor.create_tween()
	tw.tween_property(crown_on_floor, "global_position:y", at.y - bottom * s, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	Fx.confetti(get_parent(), at + Vector3.UP, 30, 3.0)


func is_sitting() -> bool:
	return _sat


# --- bolhas especiais --------------------------------------------------------------

## Bolha do escudo: gira em volta do Mestre; um tiro (ou granada) estoura.
class ShieldBubble:
	extends Node3D
	signal popped(b: ShieldBubble)
	var _done := false

	func _ready() -> void:
		var ball := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.55
		mesh.height = 1.1
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.75, 0.6, 1.0, 0.5)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.rim_enabled = true
		mat.rim = 1.0
		mat.emission_enabled = true
		mat.emission = Color("#c9a0ff")
		mat.emission_energy_multiplier = 0.7
		mesh.material = mat
		ball.mesh = mesh
		ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ball)
		var hb := Hurtbox.new()
		hb.region = "bolha"
		hb.owner_target = self
		var cs := CollisionShape3D.new()
		var sphere := SphereShape3D.new()
		sphere.radius = 0.7
		cs.shape = sphere
		hb.add_child(cs)
		add_child(hb)

	func take_hit(_amount: float, _point: Vector3, _hb: Hurtbox) -> void:
		pop()

	func pop() -> void:
		if _done:
			return
		_done = true
		Fx.bubble_pop(get_parent(), global_position)
		Fx.popup_text(get_parent(), global_position + Vector3.UP * 0.5, "plof!", Color("#ffd6f3"))
		Sfx.play_at(get_parent(), "estouro", global_position)
		popped.emit(self)
		queue_free()


## Bolha gigante e lenta: estourada com tiro, vira três bolhas pequenas que seguem o aventureiro.
class GiantBubble:
	extends Projectile
	const SIZE := 2.4
	var _split := false

	static func make(from: Vector3, p_target: Node3D) -> GiantBubble:
		var g := GiantBubble.new()
		g.kind = Projectile.Kind.BOLHA
		g.target = p_target
		g.position = from
		g.direction = (p_target.global_position + Vector3.UP * 1.2 - from).normalized()
		g.speed = 2.6
		g.turn_rate = 0.6
		g.life = 9.0
		return g

	func _physics_process(delta: float) -> void:
		super(delta)
		scale *= SIZE

	func take_hit(amount: float, point: Vector3, hb: Hurtbox) -> void:
		_split = true
		super(amount, point, hb)

	func pop() -> void:
		if _popped:
			return
		if _split and is_instance_valid(target):
			for k in 3:
				var b := Projectile.create(Projectile.Kind.BOLHA, global_position, target)
				b.direction = direction.rotated(Vector3.UP, (k - 1) * 0.9)
				b.speed = 4.0
				get_parent().add_child(b)
		super()
