class_name Detour
extends RefCounted
## Desvio de obstáculo para quem anda em linha reta até o aventureiro (guardiões e esqueletos). Empurrando de
## frente o pilar de uma lanterna, um tronco ou uma pedra, o move_and_slide não tem para onde escorregar e o
## corpo fica parado andando no lugar (o Minionzão empacava no pilar da lanterna do Morro dos Ventos quando o
## aventureiro ficava atrás dele). Detour percebe que não saiu do lugar e anda de lado, pela beira do obstáculo,
## até passar; se travar de novo no desvio, tenta o outro lado.

## Segundos sem sair do lugar até começar o desvio.
const BLOCKED_AFTER := 0.3
## Segundos andando de lado.
const DETOUR_TIME := 1.3

var _blocked := 0.0
var _left := 0.0
var _dir := Vector3.ZERO
var _side := 1.0


## A velocidade a usar neste quadro: a desejada ou, desviando, a mesma rapidez pela beira do obstáculo.
func steer(want: Vector3) -> Vector3:
	var flat := Vector3(want.x, 0.0, want.z)
	if _left > 0.0 and flat.length() > 0.1:
		var v := _dir * flat.length()
		return Vector3(v.x, want.y, v.z)
	return want


func detouring() -> bool:
	return _left > 0.0


## Depois do move_and_slide: confere se o corpo andou o que queria.
func update(body: CharacterBody3D, want: Vector3, delta: float) -> void:
	_left = maxf(_left - delta, 0.0)
	want.y = 0.0
	if want.length() < 0.5:
		_blocked = 0.0
		return
	var wall := Vector3.ZERO
	for i in body.get_slide_collision_count():
		var c := body.get_slide_collision(i)
		# Encostado no aventureiro não é obstáculo: é ele que quer pegar.
		if c.get_collider() is Player:
			_blocked = 0.0
			return
		var n := c.get_normal()
		if absf(n.y) < 0.7:
			wall = Vector3(n.x, 0.0, n.z).normalized()
	var real := body.get_real_velocity()
	real.y = 0.0
	if real.length() > want.length() * 0.35:
		_blocked = 0.0
		return
	# Raspando a quina do pilar, o move_and_slide às vezes só informa o chão: o obstáculo está na frente.
	if wall == Vector3.ZERO:
		wall = -want.normalized()
	_blocked += delta
	if _blocked < BLOCKED_AFTER:
		return
	_blocked = 0.0
	var tangent := wall.cross(Vector3.UP)
	if _left > 0.0:
		_side = -_side
	else:
		# O lado da beira que fica mais perto do caminho; de frente (empate), o mesmo lado da última vez.
		var d := tangent.dot(want.normalized())
		if absf(d) > 0.05:
			_side = signf(d)
	_dir = (tangent * _side + wall * 0.3).normalized()
	_left = DETOUR_TIME
