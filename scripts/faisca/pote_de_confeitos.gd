class_name PoteDeConfeitos
extends StaticBody3D
## A chuva de confeitos, o momento especial da 2-2 (item 9 da lista do Faísca, 2026-11-11): o pote rosa de confeitos
## no último biscoito da Subida do Bolo. Um soco (ou o giro) e ele pula lá para o alto, vira de boca para baixo em cima
## do bolo e chacoalha: chove confeito colorido no bolo todo (os miudinhos ficam espalhados, de enfeite) e os três
## grandes, redondos, cravam na parede do andar de cima, um acima do outro: a escadinha até a arena. Fica no grupo dos
## alvos dos golpes, como o registro da 2-1.

signal virado(pote: PoteDeConfeitos)

## Onde cada confeito grande crava: o meio do topo dele (o lado de dentro fica enfiado na parede do bolo).
var degraus_em: Array[Vector3] = []
## Lá no alto, em cima do bolo, onde ele chacoalha.
var ponto_alto := Vector3.ZERO
## O bolo, para os miudinhos pousarem: o raio e a altura do andar de cima e do anel de baixo.
var raio_cima := 14.0
var topo_cima := 40.0
var raio_baixo := 24.0
var topo_baixo := 26.0
var virado_ja := false
## Para os golpes: virado conta como derrotado (não vira mais alvo).
var derrotado: bool:
	get:
		return virado_ja
var raio_golpe := 1.3
## Os degraus (prontos depois da chuva) e os miudinhos que caíram.
var degraus: Array[Degrau] = []
var miudos_no_bolo := 0

const CORES := [Color("e2304a"), Color("ffd23f"), Color("3f8fe0"), Color("4cc27a"), Color("ff8a2a"), Color("b07cf0")]
const RAIO_DEGRAU := 2.4
const GROSSURA := 1.1
const GRAVIDADE := 22.0

var _desenho: Node3D
var _chuva: Array = []
var _soltando := 0.0
var _tempo := 0.0
var _malhas_miudas: Array[Mesh] = []
## Um material por cor para os miudinhos (são centenas).
var _cores_miudas: Array[StandardMaterial3D] = []


## O confeito grande que vira degrau: escondido e sem colisão até cravar.
class Degrau extends StaticBody3D:
	var forma: CollisionShape3D
	var pronto := false


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	collision_layer = 1
	collision_mask = 0
	_desenho = Node3D.new()
	add_child(_desenho)
	# O pote: rosa, com a faixa branca de bolinhas coloridas e a tampa branca furadinha.
	var rosa := _mat(Color("ff8fc8"), 0.4)
	var branco := _mat(Color("fff6fb"), 0.5)
	_malha(_cilindro(1.05, 1.15, 2.2), Vector3(0, 1.1, 0), rosa)
	_malha(_cilindro(1.17, 1.17, 0.6), Vector3(0, 1.05, 0), branco)
	for i in 8:
		var a := TAU * i / 8.0
		var bolinha := SphereMesh.new()
		bolinha.radius = 0.16
		bolinha.height = 0.32
		_malha(bolinha, Vector3(cos(a) * 1.18, 1.05, sin(a) * 1.18), _mat(CORES[i % CORES.size()], 0.4))
	var tampa := MeshInstance3D.new()
	tampa.mesh = Forma.superelipsoide(Vector3(1.15, 0.55, 1.15), 1.0, 1.0, 0.0, 12, 32)
	tampa.material_override = branco
	tampa.position.y = 2.2
	_desenho.add_child(tampa)
	for i in 7:
		var a := TAU * i / 7.0
		var furo := SphereMesh.new()
		furo.radius = 0.11
		furo.height = 0.12
		_malha(furo, Vector3(cos(a) * 0.55, 2.68, sin(a) * 0.55), _mat(Color("4a3a52"), 0.6))
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 1.15
	cil.height = 2.7
	cs.shape = cil
	cs.position.y = 1.35
	add_child(cs)
	for cor in CORES:
		_cores_miudas.append(_mat(cor, 0.35))
	for raio in [0.35, 0.5, 0.7]:
		var m := Forma.superelipsoide(Vector3(raio, raio * 0.4, raio), 0.5, 1.0, -PI / 2.0, 8, 16)
		_malhas_miudas.append(m)
	_montar_degraus.call_deferred()


## Os confeitos grandes ficam prontos no lugar, escondidos e sem colisão, até a chuva.
func _montar_degraus() -> void:
	var malha := Forma.superelipsoide(Vector3(RAIO_DEGRAU, GROSSURA * 0.5, RAIO_DEGRAU), 0.45, 1.0, -PI / 2.0, 14, 40)
	for i in degraus_em.size():
		var d := Degrau.new()
		d.position = degraus_em[i] - Vector3(0, GROSSURA * 0.5, 0)
		var mi := MeshInstance3D.new()
		mi.mesh = malha
		mi.material_override = _mat(CORES[(i * 2) % CORES.size()], 0.3)
		d.add_child(mi)
		d.forma = CollisionShape3D.new()
		var cil := CylinderShape3D.new()
		cil.radius = RAIO_DEGRAU - 0.05
		cil.height = GROSSURA
		d.forma.shape = cil
		d.forma.disabled = true
		d.add_child(d.forma)
		d.visible = false
		get_parent().add_child(d)
		degraus.append(d)


func receber_golpe(_dano: int, _de: Vector3, _forca := 6.0, _tipo := "") -> bool:
	if virado_ja:
		return false
	virar()
	return true


## Pula lá para o alto, vira de boca para baixo e chacoalha: a chuva de confeitos.
func virar() -> void:
	virado_ja = true
	collision_layer = 0
	virado.emit(self)
	Fx.confetti(get_parent(), global_position + Vector3.UP * 2.0, 20, 3.0)
	Sfx.play_at(get_parent(), "ui_ok", global_position, -2.0)
	var tw := create_tween()
	tw.tween_property(self, "global_position", ponto_alto, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(_desenho, "rotation:z", PI, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		_soltando = 2.8
		Sfx.play_at(get_parent(), "confeitos", ponto_alto, 2.0, 0.0)
		for i in degraus.size():
			var d := degraus[i]
			get_tree().create_timer(0.5 + i * 0.7).timeout.connect(func() -> void: _cravar(d)))
	tw.tween_interval(3.0)
	tw.tween_property(self, "global_position", ponto_alto + Vector3.UP * 14.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "scale", Vector3.ONE * 0.05, 0.8)
	tw.tween_callback(func() -> void:
		Fx.confetti(get_parent(), global_position, 24, 3.0)
		hide())


## Pula para o fim da chuva (os testes e as fotos): os degraus cravados e uns miudinhos no bolo.
func chover_ja() -> void:
	virado_ja = true
	collision_layer = 0
	hide()
	for d in degraus:
		_no_lugar(d)
	var g := RandomNumberGenerator.new()
	g.seed = 22
	for i in 60:
		_soltar_miudo(g, true)


## Um confeito grande cai do pote até o lugar dele e crava (com poeira, o "tum" e o controle tremendo).
func _cravar(d: Degrau) -> void:
	var fim := d.global_position
	d.global_position = global_position
	d.scale = Vector3.ONE * 0.4
	d.visible = true
	var tw := d.create_tween()
	tw.tween_property(d, "global_position", fim, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(d, "scale", Vector3.ONE, 0.45)
	tw.tween_callback(func() -> void:
		_no_lugar(d)
		Fx.dust(get_parent(), fim + Vector3.UP * GROSSURA * 0.5)
		Sfx.play_at(get_parent(), "bonk", fim, 2.0)
		for c in get_tree().get_nodes_in_group("jogador"):
			if c is Jogador and (c as Jogador).global_position.distance_to(fim) < 14.0:
				(c as Jogador).tremidinha(0.35))


func _no_lugar(d: Degrau) -> void:
	d.visible = true
	d.scale = Vector3.ONE
	d.forma.disabled = false
	d.pronto = true


func _physics_process(delta: float) -> void:
	_tempo += delta
	if _soltando > 0.0:
		_soltando -= delta
		# Chacoalhando: balança de um lado para o outro e solta os miudinhos.
		_desenho.position.x = sin(_tempo * 30.0) * 0.25
		_desenho.rotation.x = sin(_tempo * 24.0) * 0.18
		var g := RandomNumberGenerator.new()
		g.seed = int(_tempo * 1000.0)
		_soltar_miudo(g, false)
	for i in range(_chuva.size() - 1, -1, -1):
		var c: Array = _chuva[i]
		var mi: MeshInstance3D = c[0]
		var v: Vector3 = c[1]
		v.y -= GRAVIDADE * delta
		var p := mi.global_position + v * delta
		var chao := _chao_do_bolo(p)
		if p.y <= chao + 0.08:
			mi.global_position = Vector3(p.x, chao + 0.08, p.z)
			mi.rotation = Vector3(0, mi.rotation.y, 0)
			miudos_no_bolo += 1
			_chuva.remove_at(i)
			continue
		if p.y < topo_baixo - 30.0:
			mi.queue_free()
			_chuva.remove_at(i)
			continue
		mi.global_position = p
		mi.rotation += Vector3(3.0, 2.0, 1.5) * delta
		c[1] = v


## Um miudinho saindo da boca do pote, espalhando para os lados; `ja_no_chao` põe direto no bolo (as fotos).
func _soltar_miudo(g: RandomNumberGenerator, ja_no_chao: bool) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = _malhas_miudas[g.randi() % _malhas_miudas.size()]
	mi.material_override = _cores_miudas[g.randi() % _cores_miudas.size()]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_parent().add_child(Fase.so_enfeite(mi))
	var a := g.randf() * TAU
	var r := g.randf_range(0.0, raio_baixo * 0.95)
	if ja_no_chao:
		var p := Vector3(cos(a) * r, 0, sin(a) * r)
		mi.global_position = Vector3(p.x, _chao_do_bolo(p) + 0.08, p.z)
		mi.rotation.y = g.randf() * TAU
		miudos_no_bolo += 1
		return
	mi.global_position = global_position + Vector3(g.randf_range(-0.5, 0.5), -1.2, g.randf_range(-0.5, 0.5))
	# Para onde ele vai cair: um ponto do bolo, mais perto do meio.
	var alvo := Vector3(cos(a) * r, 0, sin(a) * r)
	var tempo := 1.0
	var v := (alvo - mi.global_position) / tempo
	v.y = 2.0
	_chuva.append([mi, Vector3(v.x, v.y, v.z), 0])


## A altura do bolo em (x, z): o andar de cima, o anel ou nada (cai no céu).
func _chao_do_bolo(p: Vector3) -> float:
	var r := Vector2(p.x, p.z).length()
	if r < raio_cima:
		return topo_cima
	if r < raio_baixo:
		return topo_baixo
	return -INF


func _malha(malha: Mesh, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = mat
	mi.position = pos
	_desenho.add_child(mi)


func _cilindro(r_cima: float, r_baixo: float, altura: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r_cima
	c.bottom_radius = r_baixo
	c.height = altura
	c.radial_segments = 32
	return c


func _mat(cor: Color, aspereza: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = aspereza
	return m
