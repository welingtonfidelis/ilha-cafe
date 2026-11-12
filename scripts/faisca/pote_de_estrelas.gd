class_name PoteDeEstrelas
extends StaticBody3D
## Pote gigante de estrelas do Depósito de Estrelas, na Nave Aspiratrão (a fase final do Faísca, 2026-11-12, da
## maquete aprovada pelo usuário): um cilindro de vidro cheio das estrelas roubadas, com a tampa roxa por cima. É
## sólido, e a tampa dá para pisar. Com `com_trava`, a tampa é laranja, uma fita laranja desce pela frente e embaixo
## fica o Ferrolho (`ferrolho`): o soco nele solta a tampa, que pula longe, e as estrelas saem num jorro e voam até o
## Tanque de Estrelas no meio da nave (`destino`). Avisa a fase (`abriu`). O nó fica no chão, no meio do pote; a
## frente é o +Z.

signal abriu(p: PoteDeEstrelas)

var raio := 2.4
var altura := 4.4
var com_trava := false
## Para onde voam as estrelas quando abre (o tanque).
var destino := Vector3.ZERO
var aberto := false
var ferrolho: Ferrolho

var _tampa: MeshInstance3D
var _estrelas: Array[MeshInstance3D] = []
var _tempo := 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = raio + 0.08
	cil.height = altura + 0.5
	cs.shape = cil
	cs.position.y = cil.height * 0.5
	add_child(cs)
	var vidro := MeshInstance3D.new()
	var tubo := CylinderMesh.new()
	tubo.top_radius = raio
	tubo.bottom_radius = raio
	tubo.height = altura
	tubo.cap_top = false
	vidro.mesh = tubo
	var mv := StandardMaterial3D.new()
	mv.albedo_color = Color(0.8, 0.9, 1.0, 0.3)
	mv.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mv.cull_mode = BaseMaterial3D.CULL_DISABLED
	mv.roughness = 0.05
	mv.rim_enabled = true
	vidro.material_override = mv
	vidro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	vidro.position.y = altura * 0.5
	add_child(vidro)
	var fundo := MeshInstance3D.new()
	var f := CylinderMesh.new()
	f.top_radius = raio + 0.1
	f.bottom_radius = raio + 0.2
	f.height = 0.3
	fundo.mesh = f
	fundo.material_override = _cor(Color("5b3fa0"))
	fundo.position.y = 0.15
	add_child(fundo)
	_tampa = MeshInstance3D.new()
	var t := CylinderMesh.new()
	t.top_radius = raio + 0.12
	t.bottom_radius = raio + 0.12
	t.height = 0.5
	_tampa.mesh = t
	_tampa.material_override = _cor(Color("ff7a22") if com_trava else Color("8a6fd0"))
	_tampa.position.y = altura + 0.25
	add_child(_tampa)
	# As estrelas lá dentro, amontoadas e girando devagar.
	var brilho := StandardMaterial3D.new()
	brilho.albedo_color = Color("fff1a8")
	brilho.emission_enabled = true
	brilho.emission = Color("ffd23f")
	brilho.emission_energy_multiplier = 1.6
	var forma := Forma.estrela(0.45, 0.2, 0.18)
	for k in 14:
		var e := MeshInstance3D.new()
		e.mesh = forma
		e.material_override = brilho
		var a := k * 2.4
		var r := raio * (0.25 + 0.5 * fmod(k * 0.37, 1.0))
		e.position = Vector3(cos(a) * r, 0.6 + fmod(k * 0.83, altura - 1.0), sin(a) * r)
		e.rotation = Vector3(k * 0.7, k * 1.1, k * 0.3)
		add_child(e)
		_estrelas.append(e)
	if com_trava:
		# A fita laranja da tampa até a trava, embaixo, na frente.
		var fita := MeshInstance3D.new()
		var b := BoxMesh.new()
		b.size = Vector3(0.5, altura - 1.6, 0.08)
		fita.mesh = b
		fita.material_override = _cor(Color("ff7a22"))
		fita.position = Vector3(0, 1.6 + (altura - 1.6) * 0.5, raio + 0.06)
		add_child(fita)
		ferrolho = Ferrolho.new()
		ferrolho.position = Vector3(0, 0, raio + 0.1)
		add_child(ferrolho)
		ferrolho.aberto.connect(func(_f: Ferrolho) -> void: abrir())


## A trava soltou: a tampa pula longe girando e as estrelas saem num jorro, voando até o tanque.
func abrir() -> void:
	if aberto:
		return
	aberto = true
	var de := _tampa.position
	var tw := _tampa.create_tween()
	tw.tween_method(func(k: float) -> void:
		_tampa.position = de + Vector3(0, sin(k * PI) * 3.0 + k * 1.5, k * 3.0)
		_tampa.rotation.x = k * TAU * 1.5, 0.0, 1.0, 0.9)
	tw.tween_callback(_tampa.hide)
	Sfx.play_at(get_parent(), "estouro", global_position + Vector3.UP * altura, 0.0, 0.05)
	Fx.confetti(get_parent(), global_position + Vector3.UP * (altura + 0.6), 30, 3.5)
	for i in _estrelas.size():
		var e := _estrelas[i]
		var saida := e.create_tween()
		saida.tween_interval(i * 0.08)
		var inicio := e.global_position
		var topo := global_position + Vector3.UP * (altura + 4.0 + randf() * 2.0) + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5))
		saida.tween_method(func(k: float) -> void:
			if not is_instance_valid(e):
				return
			var p := inicio.lerp(topo, minf(k * 3.0, 1.0))
			if k > 0.33:
				var k2 := (k - 0.33) / 0.67
				p = topo.lerp(destino, k2) + Vector3.UP * sin(k2 * PI) * 10.0
			e.global_position = p
			e.scale = Vector3.ONE * (1.0 if k < 0.85 else (1.0 - k) / 0.15 + 0.05), 0.0, 1.0, 2.4)
		saida.tween_callback(e.hide)
	abriu.emit(self)


func _process(delta: float) -> void:
	_tempo += delta
	if aberto:
		return
	for i in _estrelas.size():
		_estrelas[i].rotation.y += delta * (0.4 + 0.1 * (i % 3))


func _cor(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.6
	return m
