class_name Boss
extends CharacterBody3D
## Base dos guardiões das lanternas: esqueletos gigantes que chegam na última onda de uma defesa.
## Sobem da rachadura do centro, lutam com ataques avisados ("!", onda no chão, círculos de perigo) e,
## derrotados, vão embora num cacho de balões, acenando, como os esqueletos comuns. Ninguém morre.
## Cada guardião é um script filho que preenche _setup, _build e _fight (e, se quiser, _blocks).

signal defeated(boss: Boss)
signal gone(boss: Boss)
signal health_changed(boss: Boss)
signal summon_requested(type_name: String, pos: Vector3)

enum Phase { CHEGANDO, LUTANDO, COMEMORANDO, INDO_EMBORA, AFUNDANDO }

const SKELETONS := "res://assets/characters/skeletons/%s.glb"
const WEAPONS := "res://assets/weapons/skeleton/%s.gltf"
const PLAT := "res://assets/props/platformer/%s.gltf"
const BALLOONS := ["red/ball_red", "blue/ball_blue", "yellow/ball_yellow", "green/ball_green"]

var display_name := "Guardião"
var subtitle := ""
var max_health := 30.0
## Vida ao chegar (-1 = cheia). A defesa guarda a vida se a onda for cancelada no meio da luta.
var start_health := -1.0
var health := 30.0
var body_scale := 2.5
var speed := 1.8
var target: Player
## Centro e raio da arena (para quem pula de um lado para o outro).
var arena_center := Vector3.ZERO
var arena_radius := 15.0
var phase := Phase.CHEGANDO

var visual: Node3D
var model: Node3D
var ap: AnimationPlayer
var skeleton: Skeleton3D
var hand_r: BoneAttachment3D
var hurtboxes: Array[Hurtbox] = []

var _warning: Label3D
var _body_shape: CollisionShape3D
var _phase_time := 0.0
var _arrive_time := 2.3
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0
var _balloons: Node3D
var _drift := Vector3.ZERO
var _start_y := 0.0
## Contorna o pilar da lanterna, troncos e pedras em vez de empacar empurrando de frente.
var _detour := Detour.new()
var _want := Vector3.ZERO
## Golpes do Faísca na Festa sem fim (soco, giro, pisão e laser chamam receber_golpe). Fora da luta não é alvo.
var raio_golpe := 1.2
var derrotado: bool:
	get:
		return phase != Phase.LUTANDO and phase != Phase.COMEMORANDO
var _last_punch := -10.0


# --- a preencher nos guardiões ----------------------------------------------

## Nome, vida, tamanho, velocidade.
func _setup() -> void:
	pass


## Monta o modelo dentro de `visual` (já ampliado por body_scale).
func _build() -> void:
	pass


## Um passo da luta (só roda na fase LUTANDO).
func _fight(_delta: float, _to_target: Vector3, _dist: float) -> void:
	pass


## O golpe recebido é bloqueado (escudo)? Por padrão, nunca.
func _blocks(_point: Vector3, _hb: Hurtbox) -> bool:
	return false


## Multiplicador de dano (o Minionzão tonto leva em dobro).
func _damage_factor() -> float:
	return 1.0


## Chamado depois de cada dano (para mudar de fase na metade da vida, por exemplo).
func _on_damaged() -> void:
	pass


## Cancela o que estiver fazendo (o aventureiro ficou tonto).
func _cancel_attack() -> void:
	pass


## Altura do "!" de aviso (a Torre é bem mais alta que os outros).
func _warning_height() -> float:
	return 2.75 * body_scale


# --- montagem ----------------------------------------------------------------

func _ready() -> void:
	_setup()
	add_to_group(Alvo.GRUPO)
	raio_golpe = 0.5 * body_scale
	health = max_health if start_health < 0.0 else minf(start_health, max_health)
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 1)
	_body_shape = CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5 * body_scale
	capsule.height = 2.0 * body_scale
	_body_shape.shape = capsule
	_body_shape.position.y = body_scale
	add_child(_body_shape)
	visual = Node3D.new()
	visual.name = "Visual"
	visual.scale = Vector3.ONE * body_scale
	add_child(visual)
	_build()
	_warning = Label3D.new()
	_warning.text = "!"
	_warning.font_size = 220
	_warning.outline_size = 32
	_warning.modulate = Color("#ffd23f")
	_warning.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_warning.no_depth_test = true
	_warning.pixel_size = 0.008
	_warning.position.y = _warning_height()
	_warning.visible = false
	add_child(_warning)
	_arrive()


## Monta um esqueleto do KayKit dentro de `visual`, com armas e regiões de impacto
## (cabeça vale o dobro). As regiões crescem junto com o modelo ampliado. Outros personagens no mesmo
## Rig_Medium (o Guerreiro Planta) passam os próprios caminhos de modelo e de arma.
func _skeleton(type_name: String, right: String, left: String, model_fmt := SKELETONS, weapon_fmt := WEAPONS) -> void:
	model = load(model_fmt % type_name).instantiate()
	visual.add_child(model)
	ap = AnimUtil.make_player(model, ["geral", "mov", "luta", "tiro", "especial", "festa"])
	skeleton = model.find_child("Skeleton3D", true, false)
	hand_r = _attach(skeleton, "handslot.r", right, weapon_fmt)
	_attach(skeleton, "handslot.l", left, weapon_fmt)
	var head := SphereShape3D.new()
	head.radius = 0.5
	add_hurtbox(skeleton, "head", "cabeça", 2.0, head, Vector3(0, 0.45, 0))
	var body := CapsuleShape3D.new()
	body.radius = 0.4
	body.height = 1.1
	add_hurtbox(skeleton, "chest", "corpo", 1.0, body, Vector3(0, -0.2, 0))


func _attach(sk: Skeleton3D, bone: String, weapon: String, weapon_fmt := WEAPONS) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	sk.add_child(attachment)
	if weapon != "":
		attachment.add_child(SkeletonEnemy.held_item(weapon, weapon_fmt))
	return attachment


func add_hurtbox(sk: Skeleton3D, bone: String, region: String, mult: float, shape: Shape3D, offset: Vector3) -> Hurtbox:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	sk.add_child(attachment)
	var hb := Hurtbox.new()
	hb.region = region
	hb.multiplier = mult
	hb.owner_target = self
	hb.aim_assist = region == "corpo"
	attachment.add_child(hb)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = offset
	hb.add_child(cs)
	hb.set_active(false)
	hurtboxes.append(hb)
	return hb


func _set_hittable(on: bool) -> void:
	for hb in hurtboxes:
		if is_instance_valid(hb):
			hb.set_active(on)


## Sobe da rachadura do centro da arena.
func _arrive() -> void:
	phase = Phase.CHEGANDO
	_phase_time = 0.0
	if ap:
		ap.play(&"especial/Skeletons_Spawn_Ground", 0.1, 1.6)
		_arrive_time = ap.current_animation_length / 1.6
	visual.position.y = -1.3 * body_scale
	var tw := create_tween()
	tw.tween_property(visual, "position:y", 0.0, 0.9).set_ease(Tween.EASE_OUT)
	Fx.confetti(get_parent(), global_position + Vector3.UP, 40, 5.0)


# --- laço --------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_phase_time += delta
	if phase == Phase.INDO_EMBORA:
		_fly_away(delta)
		return
	if phase == Phase.AFUNDANDO:
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
	match phase:
		Phase.CHEGANDO:
			move(Vector3.ZERO)
			if _phase_time > _arrive_time:
				_set_hittable(true)
				phase = Phase.LUTANDO
				_phase_time = 0.0
		Phase.LUTANDO:
			if target_down:
				_cancel_attack()
				hide_alert()
				phase = Phase.COMEMORANDO
				play(&"festa/Cheering")
			else:
				_fight(delta, to_target, dist)
		Phase.COMEMORANDO:
			move(Vector3.ZERO)
			if not target_down:
				phase = Phase.LUTANDO
				_phase_time = 0.0
	move_and_slide()
	_detour.update(self, _want, delta)


## Anda nesta velocidade. steer = false para investidas e saltos, que devem bater no obstáculo (o
## Minionzão fica tonto ao bater numa parede) em vez de contornar.
func move(v: Vector3, steer := true) -> void:
	_want = v if steer else Vector3.ZERO
	if steer:
		v = _detour.steer(v)
	velocity.x = v.x
	velocity.z = v.z


func face(dir: Vector3, delta: float, rate := 5.0) -> void:
	if dir.length() < 0.01:
		return
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-rate * delta))


func forward() -> Vector3:
	return visual.global_basis.z.normalized()


func play(anim: StringName, speed_scale := 1.0) -> void:
	if ap and ap.current_animation != anim:
		ap.play(anim, 0.2, speed_scale)


func restart(anim: StringName, speed_scale := 1.0) -> void:
	if ap:
		ap.play(anim, 0.15, speed_scale)
		ap.seek(0.0, true)


func alert() -> void:
	_warning.visible = true
	Sfx.play_at(get_parent(), "alerta", global_position + Vector3.UP * 3.0 * body_scale, 4.0)


func hide_alert() -> void:
	_warning.visible = false


## Altura do chão sob um ponto (raio para baixo no mundo).
func ground_at(pos: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 30.0, pos + Vector3.DOWN * 30.0, 1)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position.y if hit else pos.y


func hit_player(from: Vector3) -> void:
	if is_instance_valid(target):
		target.take_damage(1, from, display_name)


# --- dano e derrota ----------------------------------------------------------

## Golpe do Faísca: 1,5 de dano por ponto do golpe (como nos esqueletos), sem o bloqueio do escudo.
func receber_golpe(dano: int, _de: Vector3, _forca := 6.0, _tipo := "") -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if derrotado or now - _last_punch < 0.3:
		return false
	_last_punch = now
	_apply_damage(dano * 1.5 * _damage_factor(), global_position + Vector3.UP * body_scale * 1.4, false)
	return true


func take_hit(amount: float, point: Vector3, hb: Hurtbox) -> void:
	if phase != Phase.LUTANDO and phase != Phase.COMEMORANDO:
		return
	if _blocks(point, hb):
		Fx.dust(get_parent(), point)
		Fx.popup_text(get_parent(), point + Vector3.UP * 0.4, "bloqueou!", Color("#c9d1dc"))
		Sfx.play_at(get_parent(), "escudo", point)
		return
	_apply_damage(amount * _damage_factor(), point, hb.multiplier > 1.0)


func take_explosion(amount: float, center: Vector3) -> void:
	if phase != Phase.LUTANDO and phase != Phase.COMEMORANDO:
		return
	_apply_damage(amount * _damage_factor(), center + Vector3.UP * 2.0, false)


func _apply_damage(amount: float, point: Vector3, crit: bool) -> void:
	health = maxf(health - amount, 0.0)
	var shown := "%.1f" % amount if fmod(amount, 1.0) > 0.01 else "%d" % int(amount)
	Fx.popup_text(get_parent(), point + Vector3.UP * 0.4, "x2!" if crit else "-" + shown,
			Color("#ffd23f") if crit else Color.WHITE)
	health_changed.emit(self)
	if health <= 0.0:
		_defeat()
	else:
		_on_damaged()


func _defeat() -> void:
	_cancel_attack()
	hide_alert()
	phase = Phase.INDO_EMBORA
	_phase_time = 0.0
	_set_hittable(false)
	velocity = Vector3.ZERO
	collision_mask = 0
	collision_layer = 0
	_start_y = global_position.y
	var home := -global_position
	home.y = 0.0
	_drift = home.normalized() * 1.5 if home.length() > 1.0 else Vector3.ZERO
	restart(&"geral/Hit_B")
	Fx.confetti(get_parent(), global_position + Vector3.UP * body_scale * 1.5, 140, 8.0)
	defeated.emit(self)
	_build_balloons()


## Cacho de cinco balões grandes (gira e acena enquanto sobe).
func _build_balloons() -> void:
	_balloons = Node3D.new()
	_balloons.name = "Baloes"
	_balloons.position.y = 2.6
	_balloons.scale = Vector3.ONE * 0.01
	visual.add_child(_balloons)
	var spots := [Vector3(0, 2.4, 0), Vector3(-0.8, 1.9, 0.3), Vector3(0.8, 1.95, -0.25), Vector3(-0.35, 1.7, -0.7), Vector3(0.4, 1.65, 0.7)]
	var string_mat := Fx.flat_material(Color.WHITE, false)
	for k in spots.size():
		var ball: Node3D = load(PLAT % BALLOONS[k % BALLOONS.size()]).instantiate()
		ball.scale = Vector3(0.45, 0.54, 0.45)
		ball.position = spots[k]
		_balloons.add_child(ball)
		var bottom: Vector3 = spots[k] - Vector3(0, 0.54, 0)
		var cord := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.012
		cyl.bottom_radius = 0.012
		cyl.height = bottom.length()
		cyl.material = string_mat
		cord.mesh = cyl
		cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cord.transform = Transform3D(Basis(Quaternion(Vector3.UP, bottom.normalized())), bottom * 0.5)
		_balloons.add_child(cord)
	var tw := _balloons.create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func() -> void: Sfx.play_at(get_parent(), "balao", global_position + Vector3.UP * 6.0, 4.0))
	tw.tween_property(_balloons, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _fly_away(delta: float) -> void:
	if _phase_time < 1.3:
		return
	if ap and ap.current_animation != "festa/Waving":
		ap.play(&"festa/Waving", 0.3)
		Fx.popup_text(get_parent(), global_position + Vector3.UP * 3.0 * body_scale, "Tchau!", Color("#ffd6f3"))
	var t := _phase_time - 1.3
	global_position += (Vector3.UP * minf(0.5 + t * 1.2, 4.0) + _drift) * delta
	visual.rotation.z = sin(_phase_time * 1.8) * 0.06
	if _phase_time > 9.0 or global_position.y - _start_y > 40.0:
		Fx.confetti(get_parent(), global_position + Vector3.UP * 6.0 * body_scale, 50, 4.0)
		gone.emit(self)
		queue_free()


## Onda cancelada: afunda de volta na rachadura e some (a defesa guarda a vida dele).
func sink_away() -> void:
	if phase == Phase.INDO_EMBORA or phase == Phase.AFUNDANDO:
		return
	_cancel_attack()
	hide_alert()
	phase = Phase.AFUNDANDO
	_set_hittable(false)
	collision_mask = 0
	collision_layer = 0
	Fx.dust(get_parent(), global_position + Vector3.UP * 0.5)
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(visual, "position:y", -2.8 * body_scale, 1.0).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


func is_fighting() -> bool:
	return phase == Phase.LUTANDO or phase == Phase.COMEMORANDO or phase == Phase.CHEGANDO


# --- ataques de área ---------------------------------------------------------

## Onda que corre pelo chão a partir de um ponto: quem estiver no chão quando ela passar leva
## um golpe; pulando, escapa.
func shockwave(center: Vector3, max_radius: float, wave_speed: float) -> void:
	var wave := Shockwave.new()
	wave.target = target
	wave.max_radius = max_radius
	wave.speed = wave_speed
	wave.source = display_name
	get_parent().add_child(wave)
	wave.global_position = Vector3(center.x, ground_at(center) + 0.05, center.z)


## Círculo de perigo no chão: enche durante `delay` segundos e então cai a chuva de flechas.
func danger_zone(pos: Vector3, radius: float, delay: float) -> DangerZone:
	var zone := DangerZone.new()
	zone.target = target
	zone.radius = radius
	zone.delay = delay
	zone.source = display_name
	get_parent().add_child(zone)
	zone.global_position = Vector3(pos.x, ground_at(pos) + 0.04, pos.z)
	return zone


class Shockwave:
	extends Node3D
	var target: Player
	var max_radius := 14.0
	var speed := 8.0
	var source := ""
	var radius := 0.6
	var _hit := false
	var _mesh: MeshInstance3D
	var _torus: TorusMesh
	var _mat: StandardMaterial3D

	func _ready() -> void:
		_torus = TorusMesh.new()
		_torus.rings = 48
		_torus.ring_segments = 6
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.albedo_color = Color(1.0, 0.75, 0.3, 0.85)
		_torus.material = _mat
		_mesh = MeshInstance3D.new()
		_mesh.mesh = _torus
		_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mesh.scale = Vector3(1, 0.6, 1)
		add_child(_mesh)
		_update_mesh()

	func _update_mesh() -> void:
		_torus.inner_radius = maxf(radius - 0.35, 0.05)
		_torus.outer_radius = radius + 0.35

	func _physics_process(delta: float) -> void:
		radius += speed * delta
		_update_mesh()
		_mat.albedo_color.a = 0.85 * (1.0 - radius / max_radius) + 0.15
		if is_instance_valid(target) and not _hit:
			var d := Vector2(target.global_position.x - global_position.x, target.global_position.z - global_position.z).length()
			var low := target.is_on_floor() or target.global_position.y - global_position.y < 0.4
			if absf(d - radius) < 0.8 and low:
				target.take_damage(1, global_position, source)
				_hit = true
		if radius >= max_radius:
			queue_free()


class DangerZone:
	extends Node3D
	var target: Player
	var radius := 2.4
	var delay := 1.4
	var source := ""
	var _t := 0.0
	var _done := false
	var _fill: MeshInstance3D

	func _ready() -> void:
		var base := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = radius
		disc.bottom_radius = radius
		disc.height = 0.04
		disc.material = _mat(Color(1.0, 0.3, 0.35, 0.22))
		base.mesh = disc
		base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(base)
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius - 0.12
		torus.outer_radius = radius
		torus.rings = 40
		torus.ring_segments = 4
		torus.material = _mat(Color(1.0, 0.35, 0.4, 0.9))
		ring.mesh = torus
		ring.scale = Vector3(1, 0.3, 1)
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(ring)
		_fill = MeshInstance3D.new()
		var fill_disc := CylinderMesh.new()
		fill_disc.top_radius = radius
		fill_disc.bottom_radius = radius
		fill_disc.height = 0.05
		fill_disc.material = _mat(Color(1.0, 0.35, 0.4, 0.45))
		_fill.mesh = fill_disc
		_fill.scale = Vector3(0.01, 1, 0.01)
		_fill.position.y = 0.01
		_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_fill)

	func _mat(color: Color) -> StandardMaterial3D:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color = color
		return m

	func _physics_process(delta: float) -> void:
		_t += delta
		if _done:
			if _t > delay + 0.5:
				queue_free()
			return
		var k := minf(_t / delay, 1.0)
		_fill.scale = Vector3(k, 1, k)
		if _t >= delay:
			_done = true
			_rain()
			if is_instance_valid(target):
				var d := Vector2(target.global_position.x - global_position.x, target.global_position.z - global_position.z).length()
				if d < radius and absf(target.global_position.y - global_position.y) < 3.0:
					target.take_damage(1, global_position + Vector3.UP, source)

	## Flechas de ventosa caindo do céu dentro do círculo.
	func _rain() -> void:
		Sfx.play_at(get_parent(), "ventosa", global_position + Vector3.UP)
		for k in 5:
			var arrow := Node3D.new()
			var shaft := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 0.04
			cyl.bottom_radius = 0.04
			cyl.height = 1.1
			cyl.material = Fx.flat_material(Color("#c98b4a"), false)
			shaft.mesh = cyl
			arrow.add_child(shaft)
			var cup := MeshInstance3D.new()
			var cup_mesh := SphereMesh.new()
			cup_mesh.radius = 0.13
			cup_mesh.height = 0.15
			cup_mesh.material = Fx.flat_material(Color("#ff5d8f"), false)
			cup.mesh = cup_mesh
			cup.position.y = -0.6
			arrow.add_child(cup)
			add_child(arrow)
			var a := randf() * TAU
			var r := sqrt(randf()) * radius * 0.8
			arrow.position = Vector3(cos(a) * r, 9.0, sin(a) * r)
			var tw := arrow.create_tween()
			tw.tween_property(arrow, "position:y", 0.6, 0.18 + randf() * 0.08).set_ease(Tween.EASE_IN)
		Fx.dust(get_parent(), global_position + Vector3.UP * 0.3)
