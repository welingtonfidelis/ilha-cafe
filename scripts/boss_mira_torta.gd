class_name BossMiraTorta
extends Boss
## Mira-Torta, guardiã da Lanterna Leste: esqueleta ladina gigante de besta. Não para quieta:
## - Pulo: salta para outro ponto da arena, longe do aventureiro.
## - Leque: 5 flechas de ventosa abertas em leque (andar de lado escapa).
## - Chuva: círculos vermelhos aparecem no chão e enchem; quando enchem, caem flechas.
##   Sair do círculo a tempo escapa. Abaixo da metade da vida, a chuva tem mais círculos.

enum Move { PULANDO, POUSO, LEQUE, CHUVA }

const JUMP_TIME := 0.9
const FAN_FIRE := 0.9
const FAN_END := 1.6
const FAN_ARROWS := 5
const FAN_SPREAD_DEG := 12.0
const RAIN_SPAWN := 0.4
const RAIN_END := 2.3
const RAIN_DELAY := 1.4
const RAIN_RADIUS := 2.4

var _move := Move.POUSO
var _move_time := 0.0
var _fired := false
var _next_attack := Move.LEQUE


func _setup() -> void:
	display_name = "Mira-Torta"
	subtitle = "a esqueleta da besta"
	max_health = 44.0
	body_scale = 2.3
	speed = 0.0


func _build() -> void:
	_skeleton("Skeleton_Rogue", "Skeleton_Crossbow", "")


func _fight(delta: float, to_target: Vector3, dist: float) -> void:
	_move_time += delta
	var dir := to_target.normalized() if dist > 0.01 else forward()
	match _move:
		Move.POUSO:
			move(Vector3.ZERO)
			face(dir, delta, 6.0)
			play(&"tiro/Pose_2H" if ap.get_animation_library(&"tiro").has_animation(&"Pose_2H") else &"especial/Skeletons_Idle")
			if _move_time > 0.4:
				_start_attack(_next_attack)
		Move.LEQUE:
			move(Vector3.ZERO)
			if not _fired:
				face(dir, delta, 6.0)
			if not _fired and _move_time >= FAN_FIRE:
				_fired = true
				hide_alert()
				_fire_fan(dir)
				restart(&"tiro/Ranged_2H_Shoot")
			if _move_time >= FAN_END:
				_next_attack = Move.CHUVA
				_jump()
		Move.CHUVA:
			move(Vector3.ZERO)
			face(dir, delta, 4.0)
			if not _fired and _move_time >= RAIN_SPAWN:
				_fired = true
				hide_alert()
				_rain()
			if _move_time >= RAIN_END:
				_next_attack = Move.LEQUE
				_jump()
		Move.PULANDO:
			if _move_time > 0.2 and is_on_floor():
				move(Vector3.ZERO)
				Fx.dust(get_parent(), global_position + Vector3.UP * 0.2)
				_move = Move.POUSO
				_move_time = 0.0


func _start_attack(m: Move) -> void:
	_move = m
	_move_time = 0.0
	_fired = false
	alert()
	restart(&"tiro/Ranged_2H_Aiming")


## Pula para um ponto da arena longe do aventureiro.
func _jump() -> void:
	var best := global_position
	var best_score := -INF
	for k in 8:
		var a := randf() * TAU
		var p := arena_center + Vector3(cos(a), 0, sin(a)) * randf_range(arena_radius * 0.4, arena_radius)
		var score := p.distance_to(target.global_position) if is_instance_valid(target) else 0.0
		score -= absf(p.distance_to(global_position) - 9.0) * 0.5  # nem colado, nem longe demais
		if score > best_score:
			best_score = score
			best = p
	var flat := best - global_position
	flat.y = 0.0
	velocity = flat / JUMP_TIME
	velocity.y = _gravity * JUMP_TIME * 0.5
	_move = Move.PULANDO
	_move_time = 0.0
	restart(&"mov/Jump_Idle")


func _fire_fan(dir: Vector3) -> void:
	if not is_instance_valid(target):
		return
	var from := hand_r.global_position + Vector3.UP * 0.3 + forward() * 1.0
	var aim := (target.global_position + Vector3.UP * 1.2 - from).normalized()
	for k in FAN_ARROWS:
		var angle := deg_to_rad((k - (FAN_ARROWS - 1) / 2.0) * FAN_SPREAD_DEG)
		var p := Projectile.create(Projectile.Kind.FLECHA, from, target)
		p.direction = aim.rotated(Vector3.UP, angle).normalized()
		p.speed = 13.0
		p.scale = Vector3.ONE * 1.6
		get_parent().add_child(p)
	Sfx.play_at(get_parent(), "flecha", from, 4.0)


func _rain() -> void:
	if not is_instance_valid(target):
		return
	var count := 5 if health > max_health * 0.5 else 7
	var center := target.global_position
	danger_zone(center, RAIN_RADIUS, RAIN_DELAY)
	for k in count - 1:
		var a := randf() * TAU
		danger_zone(center + Vector3(cos(a), 0, sin(a)) * randf_range(3.0, 7.0), RAIN_RADIUS, RAIN_DELAY + randf() * 0.4)


func _cancel_attack() -> void:
	_move = Move.POUSO
	_move_time = 0.0
