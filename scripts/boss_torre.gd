class_name BossTorre
extends Boss
## Torre de Ossinhos, guardiã da Clareira: cinco Minions empilhados, um nos ombros do outro.
## - A torre anda devagar, balançando; o de cima joga bolhas mágicas (estouram com um tiro).
## - Cada Minion tem a própria vida: vencido, ele vai embora de balão e os de cima descem um andar.
## - Com 2 ou menos, a torre pula e solta uma onda no chão ao cair (pular escapa).
## A vida na barra é a soma dos que sobraram.

const SEGMENTS := 5
const SEG_HEALTH := 6.0
const SEG_SCALE := 1.15
const SPACING := 1.75
const THROW_EVERY := 2.2
const THROW_EVERY_SHORT := 1.6
const THROW_WINDUP := 0.7
const HOP_EVERY := 4.0
const HOP_SPEED := 8.0
const KEEP_MIN := 7.0
const KEEP_MAX := 14.0

## Cada andar: {holder, model, ap, hp, hurtboxes}.
var segments: Array[Dictionary] = []
var _throw_timer := 2.0
var _throwing := 0.0
var _hop_timer := HOP_EVERY
var _hopping := false
var _time := 0.0


func _setup() -> void:
	display_name = "Torre de Ossinhos"
	subtitle = "cinco Minions numa pilha só"
	max_health = SEGMENTS * SEG_HEALTH
	body_scale = 1.0
	speed = 1.5


func _build() -> void:
	# Se a defesa foi interrompida no meio da luta, a Torre volta só com os andares que sobraram.
	var count := clampi(ceili(health / SEG_HEALTH), 1, SEGMENTS)
	for i in count:
		var holder := Node3D.new()
		holder.position.y = i * SPACING
		visual.add_child(holder)
		var m: Node3D = load(SKELETONS % "Skeleton_Minion").instantiate()
		m.scale = Vector3.ONE * SEG_SCALE
		holder.add_child(m)
		var seg_ap := AnimUtil.make_player(m, ["geral", "especial", "festa"])
		seg_ap.play(&"especial/Skeletons_Idle")
		seg_ap.seek(randf() * 1.0, true)
		var sk: Skeleton3D = m.find_child("Skeleton3D", true, false)
		var hp := minf(SEG_HEALTH, health - i * SEG_HEALTH) if i == count - 1 else SEG_HEALTH
		var seg := {"holder": holder, "model": m, "ap": seg_ap, "hp": hp, "hurtboxes": []}
		var head := SphereShape3D.new()
		head.radius = 0.5
		var body := CapsuleShape3D.new()
		body.radius = 0.4
		body.height = 1.1
		for spec in [["head", "cabeça", 2.0, head, Vector3(0, 0.45, 0)], ["chest", "corpo", 1.0, body, Vector3(0, -0.2, 0)]]:
			var hb := add_hurtbox(sk, spec[0], spec[1], spec[2], spec[3], spec[4])
			hb.set_meta("andar", holder)
			seg.hurtboxes.append(hb)
		segments.append(seg)
	_fit_body()


func _warning_height() -> float:
	return segments.size() * SPACING + 1.8


## A cápsula de colisão acompanha a altura da pilha.
func _fit_body() -> void:
	var h := maxf(segments.size() * SPACING + 0.6, 2.0)
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.7
	capsule.height = h
	if _body_shape:
		_body_shape.shape = capsule
		_body_shape.position.y = h * 0.5
	if _warning:
		_warning.position.y = _warning_height()


func _fight(delta: float, to_target: Vector3, dist: float) -> void:
	_time += delta
	visual.rotation.z = sin(_time * 1.8) * 0.05
	var dir := to_target.normalized() if dist > 0.01 else forward()
	face(dir, delta, 3.0)
	# Anda até ficar a uma distância boa de arremesso.
	if _hopping:
		if is_on_floor() and velocity.y <= 0.0:
			_hopping = false
			shockwave(global_position, 10.0, 7.0)
			Sfx.play_at(get_parent(), "pancada", global_position)
			if is_instance_valid(target):
				target.shake(0.25)
	elif dist > KEEP_MAX:
		move(dir * speed)
	elif dist < KEEP_MIN:
		move(-dir * speed * 0.7)
	else:
		move(Vector3.ZERO)
	var bottom := _bottom()
	if not bottom.is_empty():
		(bottom.ap as AnimationPlayer).play(&"especial/Skeletons_Walking" if Vector2(velocity.x, velocity.z).length() > 0.3 else &"especial/Skeletons_Idle", 0.2)
	# Bolha do de cima.
	if _throwing > 0.0:
		_throwing -= delta
		if _throwing <= 0.0:
			_throw()
	else:
		_throw_timer -= delta
		if _throw_timer <= 0.0:
			_throw_timer = THROW_EVERY_SHORT if segments.size() <= 2 else THROW_EVERY
			_throwing = THROW_WINDUP
			alert()
			var top := _top()
			if not top.is_empty():
				(top.ap as AnimationPlayer).play(&"geral/Throw", 0.1)
	# Pulo quando já está baixinha.
	if segments.size() <= 2 and not _hopping:
		_hop_timer -= delta
		if _hop_timer <= 0.0 and is_on_floor():
			_hop_timer = HOP_EVERY
			_hopping = true
			velocity.y = HOP_SPEED
			Fx.dust(get_parent(), global_position + Vector3.UP * 0.2)


func _top() -> Dictionary:
	return segments[-1] if not segments.is_empty() else {}


func _bottom() -> Dictionary:
	return segments[0] if not segments.is_empty() else {}


func _throw() -> void:
	hide_alert()
	var top := _top()
	if top.is_empty() or not is_instance_valid(target):
		return
	var from: Vector3 = (top.holder as Node3D).global_position + Vector3.UP * 2.6 + forward() * 0.6
	get_parent().add_child(Projectile.create(Projectile.Kind.BOLHA, from, target))
	Sfx.play_at(get_parent(), "bolha", from, 4.0)


func take_hit(amount: float, point: Vector3, hb: Hurtbox) -> void:
	if phase != Phase.LUTANDO and phase != Phase.COMEMORANDO:
		return
	var holder: Node3D = hb.get_meta("andar", null)
	for seg in segments:
		if seg.holder == holder:
			_damage_segment(seg, amount, point, hb.multiplier > 1.0)
			return


## A granada acerta o andar de baixo.
func take_explosion(amount: float, center: Vector3) -> void:
	if (phase != Phase.LUTANDO and phase != Phase.COMEMORANDO) or segments.is_empty():
		return
	_damage_segment(segments[0], amount, center + Vector3.UP * 2.0, false)


func _damage_segment(seg: Dictionary, amount: float, point: Vector3, crit: bool) -> void:
	seg.hp -= amount
	var shown := "%.1f" % amount if fmod(amount, 1.0) > 0.01 else "%d" % int(amount)
	Fx.popup_text(get_parent(), point + Vector3.UP * 0.4, "x2!" if crit else "-" + shown,
			Color("#ffd23f") if crit else Color.WHITE)
	if seg.hp <= 0.0:
		_pop(seg)
	_update_health()
	if segments.is_empty():
		_defeat()


func _update_health() -> void:
	var total := 0.0
	for seg in segments:
		total += maxf(seg.hp, 0.0)
	health = total
	health_changed.emit(self)


## Um andar vencido sai da pilha de balão; os de cima descem.
func _pop(seg: Dictionary) -> void:
	segments.erase(seg)
	for hb in seg.hurtboxes:
		(hb as Hurtbox).set_active(false)
		hurtboxes.erase(hb)
	var holder: Node3D = seg.holder
	var xf := holder.global_transform
	visual.remove_child(holder)
	get_parent().add_child(holder)
	holder.global_transform = xf
	holder.rotation = Vector3(0, holder.rotation.y, 0)
	Fx.confetti(get_parent(), holder.global_position + Vector3.UP * 1.5, 40, 5.0)
	Fx.balloon_away(holder, seg.ap, 2.6 * SEG_SCALE)
	for i in segments.size():
		var h: Node3D = segments[i].holder
		var tw := h.create_tween()
		tw.tween_property(h, "position:y", i * SPACING, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_fit_body()


## Sem andares: o último já foi de balão; a Torre só avisa e some.
func _defeat() -> void:
	hide_alert()
	phase = Phase.INDO_EMBORA
	_phase_time = 0.0
	velocity = Vector3.ZERO
	collision_mask = 0
	collision_layer = 0
	defeated.emit(self)


func _fly_away(_delta: float) -> void:
	if _phase_time > 6.5:
		gone.emit(self)
		queue_free()


func _cancel_attack() -> void:
	_throwing = 0.0
	_throw_timer = THROW_EVERY
