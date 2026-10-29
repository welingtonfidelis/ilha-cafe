class_name KartCircuit
extends RefCounted
## Traçado da pista de kart, refeita em 2026-10-29 (pedido do usuário: "mais emocionante com subidas e descidas,
## curvas e retas", e larga para caber dois carros com folga). É um 8 na campina a leste do Morro, com 13 m de
## asfalto e uns 420 m por volta, o dobro do oval antigo. A volta norte é plana. Saindo dela, a pista sobe por
## uma rampa até a ponte do cruzamento, a 6,5 m, e desce para a volta sul, que tem uma lombada perto da praia.
## A reta comprida passa por baixo da ponte e chega na largada.
## Os pontos de controle passam numa curva Catmull-Rom fechada. O gerador da ilha (tools/gerar_ilha.gd) monta o
## asfalto, as zebras, as muretas, as paredes e a ponte a partir deles. A corrida (scripts/kart_race.gd) usa as
## mesmas contas para as marcas da volta, a entrada e para saber se o kart está na pista.

## (x, z, altura do asfalto). O kart corre nesta ordem. O 0 é o cruzamento por baixo e o 9 é a ponte.
const POINTS := [
	Vector3(118, -4, 0.3), Vector3(104, -25, 0.3), Vector3(90, -45, 0.3), Vector3(86, -64, 0.3),
	Vector3(97, -80, 0.3), Vector3(116, -82, 0.3), Vector3(131, -68, 0.6), Vector3(138, -46, 2.4),
	Vector3(133, -24, 4.8), Vector3(118, -4, 6.5), Vector3(103, 16, 4.8), Vector3(93, 38, 2.4),
	Vector3(94, 60, 0.6), Vector3(108, 78, 0.3), Vector3(130, 82, 0.3), Vector3(146, 68, 0.3),
	Vector3(150, 45, 1.6), Vector3(138, 20, 0.3),
]
const WIDTH := 13.0
## Largada e chegada: na reta do ponto 1, 14 m depois dele (uns 40 m depois da passagem por baixo da ponte),
## indo para o noroeste.
const START := 1
const START_AHEAD := 14.0
## Marcas que a volta precisa passar, na ordem: o alto da volta norte, a ponte e o fundo da volta sul (a
## chegada é a última).
const GATES := [5, 9, 14]
const BRIDGE := 9
## A abertura da mureta de fora (o lado oeste da reta), por onde o kart entra vindo do box: metros antes da
## largada, medidos na pista.
const ENTRY_FROM := 22.0
const ENTRY_TO := 12.0

static var _cache: Array = []
static var _length := 0.0


## Pontos da linha do meio a cada metro (mais ou menos), em ordem: {pos (com a altura de projeto), dir (para a
## frente, no plano), s (metros desde o ponto 0), k (ponto de controle de antes)}.
static func samples() -> Array:
	if not _cache.is_empty():
		return _cache
	var dense: Array[Vector3] = []
	var owner_k: Array[int] = []
	var n := POINTS.size()
	for k in n:
		for j in 40:
			dense.append(_catmull(POINTS[(k - 1 + n) % n], POINTS[k], POINTS[(k + 1) % n], POINTS[(k + 2) % n], j / 40.0))
			owner_k.append(k)
	var total := 0.0
	var acc: Array[float] = [0.0]
	for i in dense.size():
		total += _flat(dense[i]).distance_to(_flat(dense[(i + 1) % dense.size()]))
		acc.append(total)
	_length = total
	var count := int(round(total))
	var step := total / count
	var j := 0
	for i in count:
		var s := i * step
		while acc[j + 1] < s:
			j += 1
		var t := (s - acc[j]) / maxf(acc[j + 1] - acc[j], 0.0001)
		var a := dense[j]
		var b := dense[(j + 1) % dense.size()]
		var p := a.lerp(b, t)
		var dir := _flat(b) - _flat(a)
		_cache.append({"pos": Vector3(p.x, p.z, p.y), "dir": Vector3(dir.x, 0, dir.y).normalized(), "s": s, "k": owner_k[j]})
	return _cache


static func length() -> float:
	samples()
	return _length


## Amostra mais perto do ponto de controle `k`, só entre as do trecho dele (no cruzamento, o 0 e o 9 ficam no
## mesmo lugar do mapa: um embaixo e o outro na ponte).
static func at_point(k: int) -> Dictionary:
	var best: Dictionary = {}
	var best_d := INF
	var target := _flat(POINTS[k])
	var n := POINTS.size()
	for sm in samples():
		if sm.k != k and sm.k != (k - 1 + n) % n:
			continue
		var d := Vector2(sm.pos.x, sm.pos.z).distance_to(target)
		if d < best_d:
			best_d = d
			best = sm
	return best


## Amostra a `meters` da linha de chegada (negativo: antes dela).
static func from_start(meters: float) -> Dictionary:
	var all := samples()
	var s0: float = at_point(START).s + START_AHEAD
	var s := fposmod(s0 + meters, length())
	return all[int(round(s / length() * all.size())) % all.size()]


## Distância no plano até a linha do meio (e a amostra mais perto). Perto do cruzamento valem as duas pistas:
## fica a mais perto.
static func nearest(p: Vector3) -> Dictionary:
	var best: Dictionary = {}
	var best_d := INF
	var q := Vector2(p.x, p.z)
	for sm in samples():
		var d := Vector2(sm.pos.x, sm.pos.z).distance_squared_to(q)
		if d < best_d:
			best_d = d
			best = sm
	return {"dist": sqrt(best_d), "sample": best}


## Em cima da pista (no plano, com `extra` de folga para os lados).
static func on_track(p: Vector3, extra := 1.0) -> bool:
	return nearest(p).dist < WIDTH * 0.5 + extra


## Ponto de controle no plano (eles são x, z, altura).
static func _flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.y)


static func _catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)
