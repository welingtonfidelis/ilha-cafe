class_name BossOssao
extends Boss
## Ossão, guardião da Lanterna Oeste: guerreiro esqueleto gigante de machado e escudo grande.
## - Salto: pula e bate no chão, soltando uma onda que corre pelo chão; pular por cima escapa.
## - Machadada: de perto, golpe na frente dele.
## - O escudo bloqueia tiro no corpo pela frente, menos quando ele está atacando; cabeça e costas valem.
## - Na metade da vida, chama dois Minions.

enum Move { ANDANDO, SALTO, GOLPE, DESCANSO }

## Animações tocadas a 0,8x: o salto (1,33 s) bate no chão perto de 0,85 s do original.
const ANIM_SPEED := 0.8
const SLAM_IMPACT := 0.85 / ANIM_SPEED
const SLAM_END := 1.33 / ANIM_SPEED + 0.2
const CHOP_HIT := 0.55 / ANIM_SPEED
const CHOP_END := 1.07 / ANIM_SPEED
const CHOP_RANGE := 6.5
const SLAM_RANGE := 18.0
const WAVE_RADIUS := 16.0
const WAVE_SPEED := 8.0

var _move := Move.ANDANDO
var _move_time := 0.0
var _slam_cooldown := 2.0
var _struck := false
var _summoned := false
var _summoned_again := false


func _setup() -> void:
	display_name = "Ossão"
	subtitle = "o guerreiro do escudo"
	max_health = 56.0
	body_scale = 2.6
	speed = 2.0


func _build() -> void:
	_skeleton("Skeleton_Warrior", "Skeleton_Axe", "Skeleton_Shield_Large_A")


func _fight(delta: float, to_target: Vector3, dist: float) -> void:
	_move_time += delta
	_slam_cooldown -= delta
	var dir := to_target.normalized() if dist > 0.01 else forward()
	match _move:
		Move.ANDANDO:
			if dist < CHOP_RANGE - 1.0:
				_start(Move.GOLPE, &"luta/Melee_1H_Attack_Chop")
			elif dist < SLAM_RANGE and _slam_cooldown <= 0.0:
				_start(Move.SALTO, &"luta/Melee_1H_Attack_Jump_Chop")
			else:
				move(dir * speed)
				face(dir, delta)
				play(&"especial/Skeletons_Walking", 0.7)
		Move.SALTO:
			move(Vector3.ZERO)
			if _move_time < SLAM_IMPACT * 0.6:
				face(dir, delta, 3.0)
			if not _struck and _move_time >= SLAM_IMPACT:
				_struck = true
				hide_alert()
				shockwave(global_position + forward() * 2.0, WAVE_RADIUS, WAVE_SPEED)
				Sfx.play_at(get_parent(), "pancada", global_position)
				Fx.dust(get_parent(), global_position + forward() * 2.0)
				if is_instance_valid(target):
					target.shake(0.35)
			if _move_time >= SLAM_END:
				_slam_cooldown = 3.4
				_rest()
		Move.GOLPE:
			move(Vector3.ZERO)
			if _move_time < CHOP_HIT * 0.7:
				face(dir, delta, 4.0)
			if not _struck and _move_time >= CHOP_HIT:
				_struck = true
				hide_alert()
				Sfx.play_at(get_parent(), "golpe_ar", global_position + Vector3.UP * 3.0)
				if dist <= CHOP_RANGE and forward().dot(dir) > 0.3:
					hit_player(global_position)
			if _move_time >= CHOP_END:
				_rest()
		Move.DESCANSO:
			move(Vector3.ZERO)
			face(dir, delta, 3.0)
			play(&"especial/Skeletons_Idle")
			if _move_time > 0.9:
				_move = Move.ANDANDO
				_move_time = 0.0


func _start(m: Move, anim: StringName) -> void:
	_move = m
	_move_time = 0.0
	_struck = false
	alert()
	restart(anim, ANIM_SPEED)


func _rest() -> void:
	_move = Move.DESCANSO
	_move_time = 0.0


func _cancel_attack() -> void:
	_rest()


## O escudo segura tiro no corpo vindo da frente, a não ser quando ele está atacando.
func _blocks(point: Vector3, hb: Hurtbox) -> bool:
	if hb.region != "corpo" or _move == Move.SALTO or _move == Move.GOLPE:
		return false
	var to_point := point - global_position
	to_point.y = 0.0
	return forward().dot(to_point.normalized()) > 0.2


func _on_damaged() -> void:
	if _summoned and not _summoned_again and health <= max_health * 0.25:
		_summoned_again = true
		Fx.popup_text(get_parent(), global_position + Vector3.UP * 7.5, "Mais ossinhos!", Color("#ffd6f3"))
		for side in [-1.0, 1.0]:
			summon_requested.emit("Skeleton_Minion", global_position + visual.global_basis.x * side * 4.0)
	if not _summoned and health <= max_health * 0.5:
		_summoned = true
		Fx.popup_text(get_parent(), global_position + Vector3.UP * 7.5, "Ossinhos, venham!", Color("#ffd6f3"))
		for side in [-1.0, 1.0]:
			summon_requested.emit("Skeleton_Minion", global_position + visual.global_basis.x * side * 4.0)
