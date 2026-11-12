class_name Vendaval
extends Node3D
## O vendaval, o momento especial da 3-3 Moinhos do Vento (item 9 da lista do Faísca, 2026-11-12): a terceira janela
## da escada acorda o Moinho Gigante. As pás gigantes disparam, um redemoinho branco envolve a torre (riscos girando,
## fardos de feno e folhas voando em volta, o uivo do vento e o controle tremendo) e leva o Faísca voando em espiral
## em volta do moinho, subindo e passando pelas estrelinhas do caminho, até pousar na arena do topo. Depois disso, o
## último degrau da escada continua chamando o vendaval (para quem cair e subir de novo). O nó fica no meio do moinho.

signal levou

var fase: Fase
## O último degrau da escada (de onde ele sai) e onde ele pousa, na arena.
var de_onde := Vector3.ZERO
var pouso := Vector3.ZERO
var soprando := false
var levando := false
var vezes := 0

## Por fora dos pilares da arena (15 m) e por dentro das velas gigantes (que passam a 17,8 m, ao sul).
const RAIO_VOO := 16.6
const TOPO_VOO := 45.0
const VOLTAS := 1.25
const DURACAO := 6.5
## Até onde do último degrau ele precisa estar para o vendaval levar.
const ALCANCE := 8.0

var _t := 0.0
var _jogador: Jogador
var _angulo0 := 0.0
var _r0 := 0.0
var _y0 := 0.0
var _redemoinho: Node3D
var _riscos: MultiMeshInstance3D
var _voando: Array[Node3D] = []
var _forca := 0.0
var _tempo := 0.0
var _som: AudioStreamPlayer3D
var _gatilho: Area3D


func _ready() -> void:
	_redemoinho = Node3D.new()
	add_child(Fase.so_enfeite(_redemoinho))
	var risco := BoxMesh.new()
	risco.size = Vector3(0.12, 0.12, 3.2)
	var branco := StandardMaterial3D.new()
	branco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	branco.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	branco.albedo_color = Color(1, 1, 1, 0.8)
	risco.material = branco
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = risco
	mm.instance_count = 90
	_riscos = MultiMeshInstance3D.new()
	_riscos.multimesh = mm
	_riscos.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_redemoinho.add_child(_riscos)
	# O que voa no redemoinho: fardos de feno e folhas verdes.
	var feno := StandardMaterial3D.new()
	feno.albedo_color = Color("f2c94c")
	var folha := StandardMaterial3D.new()
	folha.albedo_color = Color("6cc35a")
	folha.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in 16:
		var mi := MeshInstance3D.new()
		if i % 3 == 0:
			var cil := CylinderMesh.new()
			cil.top_radius = 0.7
			cil.bottom_radius = 0.7
			cil.height = 0.9
			mi.mesh = cil
			mi.material_override = feno
		else:
			var q := QuadMesh.new()
			q.size = Vector2(0.5, 0.3)
			mi.mesh = q
			mi.material_override = folha
		_redemoinho.add_child(mi)
		_voando.append(mi)
	_redemoinho.visible = false
	_desenhar(0.0)


## A ponta do caminho do voo, `t` de 0 a 1 (as estrelinhas do vendaval ficam nele): a espiral subindo em volta da torre
## e, no fim, a descida até o pouso.
func ponto_do_voo(t: float, de: Vector3 = de_onde) -> Vector3:
	var a0 := atan2(-de.z, de.x)
	var r0 := Vector2(de.x, de.z).length()
	if t < 0.1:
		# Primeiro para fora, reto (sem cruzar os pilares da arena).
		var k0 := t / 0.1
		var r := lerpf(r0, RAIO_VOO, smoothstep(0.0, 1.0, k0))
		return Vector3(r * cos(a0), de.y + 0.2 + k0 * 0.6, -r * sin(a0))
	if t < 0.8:
		var k := (t - 0.1) / 0.7
		var a := a0 - TAU * VOLTAS * k
		var y := lerpf(de.y + 0.8, TOPO_VOO, smoothstep(0.0, 1.0, k))
		return Vector3(RAIO_VOO * cos(a), y, -RAIO_VOO * sin(a))
	var fim := ponto_do_voo(0.7999, de)
	var k2 := (t - 0.8) / 0.2
	return fim.lerp(pouso + Vector3.UP * 0.3, smoothstep(0.0, 1.0, k2)) + Vector3.UP * sin(k2 * PI) * 1.5


## A terceira janela abriu: o vendaval acorda (e leva o Faísca, se ele estiver no último degrau). Daí em diante, o
## último degrau chama o vendaval de novo.
func chamar() -> void:
	if _gatilho == null:
		_gatilho = Area3D.new()
		_gatilho.collision_layer = 0
		_gatilho.collision_mask = Fase.CAMADA_JOGADOR
		var cs := CollisionShape3D.new()
		var esfera := SphereShape3D.new()
		esfera.radius = 2.2
		cs.shape = esfera
		_gatilho.add_child(cs)
		add_child(_gatilho)
		_gatilho.global_position = de_onde + Vector3.UP * 1.0
		_gatilho.body_entered.connect(func(corpo: Node3D) -> void:
			if corpo is Jogador and not levando:
				levar(corpo as Jogador))
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j and j.global_position.distance_to(de_onde) < ALCANCE:
		levar(j)
	else:
		_acordar()


## O redemoinho aparece e as pás disparam (sem levar ninguém).
func _acordar() -> void:
	soprando = true
	_redemoinho.visible = true
	if _som == null:
		_som = Sfx.play_at(self, "vendaval", Vector3(0, 38, 0), 4.0, 0.0)
		if _som:
			_som.max_distance = 120.0
			_som.unit_size = 30.0


## Leva o Faísca voando em volta do moinho até a arena.
func levar(j: Jogador) -> void:
	if levando:
		return
	_acordar()
	levando = true
	vezes += 1
	_jogador = j
	_t = 0.0
	_y0 = j.global_position.y
	j.controle_ligado = false
	j.velocity = Vector3.ZERO
	j.set_physics_process(false)
	j.robo.animar("mov/Jump_Idle", 0.15)
	j.robo.expressao("surpreso", 1.0)
	j.tremidinha(0.8)
	Sfx.play_at(get_parent(), "vento", j.global_position, 2.0, 0.0)


func _physics_process(delta: float) -> void:
	_tempo += delta
	_forca = move_toward(_forca, 1.0 if soprando else 0.0, delta * (0.8 if soprando else 0.4))
	_redemoinho.visible = _forca > 0.02
	if _redemoinho.visible:
		_desenhar(delta)
	if not levando or not is_instance_valid(_jogador):
		return
	var j := _jogador
	_t = minf(_t + delta / DURACAO, 1.0)
	var antes := j.global_position
	j.global_position = ponto_do_voo(_t)
	var anda := j.global_position - antes
	var h := Vector3(anda.x, 0, anda.z)
	if h.length() > 0.01:
		j.visual.rotation.y = lerp_angle(j.visual.rotation.y, atan2(h.x, h.z), 1.0 - exp(-8.0 * delta))
		j.yaw = lerp_angle(j.yaw, atan2(-h.x, -h.z), 1.0 - exp(-3.0 * delta))
	j.acompanhar_camera(delta)
	if fmod(_t * DURACAO, 1.2) < delta:
		j.tremidinha(0.35)
	if _t >= 1.0:
		_pousar(j)


func _pousar(j: Jogador) -> void:
	levando = false
	_jogador = null
	j.global_position = pouso + Vector3.UP * 0.2
	j.velocity = Vector3.ZERO
	j.set_physics_process(true)
	j.controle_ligado = true
	j.robo.expressao("feliz", 1.4)
	Fx.confetti(get_parent(), pouso + Vector3.UP * 1.5, 40, 4.0)
	Sfx.play_at(get_parent(), "bandeira", pouso, 0.0)
	levou.emit()
	# O vento vai acalmando (as pás e o redemoinho) um pouco depois do pouso.
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		if not levando:
			soprando = false
			if _som:
				var tw := _som.create_tween()
				tw.tween_property(_som, "volume_db", -40.0, 2.0)
				tw.tween_callback(_som.queue_free)
				_som = null)


## O redemoinho: os riscos brancos girando em volta da torre, subindo, e o que voa nele.
func _desenhar(_delta: float) -> void:
	var mm := _riscos.multimesh
	for i in mm.instance_count:
		var k := fmod(i * 0.6180339 + _tempo * 0.08, 1.0)
		var a := TAU * fmod(i * 0.1372, 1.0) - _tempo * (2.2 + k)
		var r := 15.5 + 4.0 * k
		var y := 30.0 + 22.0 * k
		var tang := Vector3(-sin(a), 0, -cos(a))
		var b := Basis.looking_at(tang, Vector3.UP).scaled(Vector3.ONE * _forca * clampf(minf(k, 1.0 - k) * 6.0, 0.0, 1.0))
		mm.set_instance_transform(i, Transform3D(b, Vector3(r * cos(a), y, -r * sin(a))))
	for i in _voando.size():
		var no := _voando[i]
		var a := TAU * i / _voando.size() - _tempo * (1.4 + 0.1 * (i % 4))
		var r := 16.0 + 3.0 * sin(i * 1.7 + _tempo * 0.6)
		no.position = Vector3(r * cos(a), 31.0 + fmod(i * 1.3 + _tempo * 1.5, 18.0), -r * sin(a))
		no.rotation = Vector3(_tempo * 2.0 + i, _tempo * 1.4, i)
		no.scale = Vector3.ONE * _forca
