class_name Avalanche
extends Node3D
## A avalanche, o momento especial da 3-1 (item 9 da lista do Faísca, 2026-11-11): na saída da Encosta das Avalanches,
## o trecho do anel do pico entre a chegada da ponte de gelo e a neve fofa. Chegando, a avalanche grande despenca pela
## parede do pico (o controle treme forte); depois, duas calhas soltam neve no ritmo: avisam (pedrinhas de neve
## escorregando, o ronco e o controle tremendo de leve) e a onda desce a parede e atravessa o anel até cair da beira.
## Quem a onda pega vira uma bola de neve e volta ao abrigo de antes (o boneco de neve), sem perder coração.
## As alturas e os raios são os do pico da 3-1 (a fase passa).

signal comecou
signal pegou

## Os ângulos (graus, como no `Fase31.no_pico`) do meio de cada calha, e os abrigos: um antes de cada calha e o do fim.
var calhas: Array[float] = []
var abrigos: Array[Vector3] = []
## Onde a avalanche grande despenca (de, até, em graus) e o gatilho dela (a chegada no anel).
var setor := Vector2(-30.0, -60.0)
var gatilho := Vector3.ZERO
var tamanho_gatilho := Vector3(7, 4, 7)
## O pico: o anel (de raio_dentro a raio_fora, na altura topo_anel) e a parede de cima (raio no pé e no cume).
var raio_dentro := 18.0
var raio_fora := 26.0
var topo_anel := 30.0
var raio_cume := 11.0
var topo_cume := 46.0
## O ritmo: cada calha repete a cada `periodo` segundos; a segunda começa na metade.
var periodo := 5.0
const AVISO := 1.2
const DESCIDA := 2.0
const LARGURA := 5.0

var comecada := false
var vezes_que_pegou := 0
var _tempo := 0.0
var _ondas: Array = []
var _avisando: Array[bool] = []
var _jogador: Jogador
var _mat_neve: StandardMaterial3D
var _malhas: Array[Mesh] = []
var _som_ronco: AudioStreamPlayer3D
var _preso := false


func _ready() -> void:
	_mat_neve = StandardMaterial3D.new()
	_mat_neve.albedo_color = Color("f6f9ff")
	_mat_neve.roughness = 0.95
	for r in [1.0, 1.4, 1.9]:
		_malhas.append(Forma.superelipsoide(Vector3(r, r * 0.75, r), 1.0, 1.0, -PI / 2.0, 10, 16))
	for i in calhas.size():
		_avisando.append(false)
		_montar_calha(calhas[i])
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = Fase.CAMADA_JOGADOR
	area.monitorable = false
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = tamanho_gatilho
	cs.shape = caixa
	area.add_child(cs)
	add_child(area)
	area.top_level = true
	area.global_position = gatilho
	area.body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador and not comecada:
			comecar(corpo))


## Em que ponto do caminho (0 a 1) está a onda que pega da calha `i`, ou -1 se não tem nenhuma descendo (os testes).
func onda_da_calha(i: int) -> float:
	for o in _ondas:
		if o.pega and is_equal_approx(o.graus, calhas[i]):
			return o.t / DESCIDA
	return -1.0


## O ponto da parede ou do anel no ângulo `graus`, a `raio` do meio, na altura `y`.
func no_pico(graus: float, raio: float, y: float) -> Vector3:
	var a := deg_to_rad(graus)
	return Vector3(raio * cos(a), y, -raio * sin(a))


func raio_da_parede(y: float) -> float:
	return lerpf(raio_dentro, raio_cume, clampf((y - topo_anel) / (topo_cume - topo_anel), 0.0, 1.0))


## A calha na parede: uma faixa lisa de neve mais clara descendo pela parede (sem degrau nenhum, para não parecer
## escada) e, no alto, a cornija (o monte de neve que despenca).
func _montar_calha(graus: float) -> void:
	var a := deg_to_rad(graus)
	var fora := Vector3(cos(a), 0, -sin(a))
	var lado := Vector3.UP.cross(fora).normalized()
	var de := no_pico(graus, raio_dentro + 0.2, topo_anel + 0.3)
	var ate := no_pico(graus, raio_da_parede(topo_anel + 13.0) + 0.2, topo_anel + 13.0)
	var subida := (ate - de).normalized()
	var frente := lado.cross(subida).normalized()
	var faixa := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(LARGURA - 0.6, de.distance_to(ate), 0.3)
	faixa.mesh = caixa
	var mat_faixa := StandardMaterial3D.new()
	mat_faixa.albedo_color = Color("e4eeff")
	mat_faixa.roughness = 0.9
	faixa.material_override = mat_faixa
	faixa.transform = Transform3D(Basis(lado, subida, frente), (de + ate) * 0.5 + frente * 0.15)
	add_child(Fase.so_enfeite(faixa))
	var cornija := MeshInstance3D.new()
	cornija.mesh = _malhas[2]
	cornija.material_override = _mat_neve
	var y_alto := topo_anel + 13.5
	cornija.position = no_pico(graus, raio_da_parede(y_alto) + 1.2, y_alto)
	cornija.scale = Vector3(2.4, 1.2, 1.4)
	cornija.rotation.y = deg_to_rad(graus) + PI * 0.5
	add_child(Fase.so_enfeite(cornija))
	cornija.set_meta("calha", graus)


## A avalanche grande (uma vez só): despenca pela parede no setor todo, e o ritmo das calhas começa.
func comecar(j: Jogador) -> void:
	if comecada:
		return
	comecada = true
	_jogador = j
	_tempo = 0.0
	comecou.emit()
	Sfx.play_at(get_parent(), "rolar", no_pico((setor.x + setor.y) * 0.5, raio_dentro, topo_anel + 6.0), 6.0, 0.0)
	j.tremidinha(1.0)
	var g := RandomNumberGenerator.new()
	g.seed = 31
	for i in 26:
		var graus := lerpf(setor.x, setor.y, g.randf())
		get_tree().create_timer(g.randf_range(0.0, 1.8)).timeout.connect(func() -> void:
			_soltar_onda(graus, false, g.randf_range(0.8, 1.3)))


## Pula para o ritmo já andando (os testes e as fotos).
func comecar_ja(j: Jogador) -> void:
	comecada = true
	_jogador = j


func _physics_process(delta: float) -> void:
	if comecada:
		_tempo += delta
		for i in calhas.size():
			# A primeira onda de cada calha vem depois da avalanche grande (3 s), e a segunda calha vai meio ciclo atrás.
			var t := _tempo - 3.0 - periodo * 0.5 * i
			if t < 0.0:
				continue
			var no_ciclo := fmod(t, periodo)
			var antes := no_ciclo - delta
			var inicio_aviso := periodo - AVISO - DESCIDA
			if antes < inicio_aviso and no_ciclo >= inicio_aviso:
				_avisar(i)
			if antes < periodo - DESCIDA and no_ciclo >= periodo - DESCIDA:
				_avisando[i] = false
				_soltar_onda(calhas[i], true, 1.0)
	for k in range(_ondas.size() - 1, -1, -1):
		var o: Dictionary = _ondas[k]
		o.t += delta
		var f: float = o.t / DESCIDA
		if f >= 1.0:
			(o.no as Node3D).queue_free()
			_ondas.remove_at(k)
			continue
		var p := _na_descida(o.graus, f)
		(o.no as Node3D).global_position = p
		(o.no as Node3D).rotation.x += delta * 4.0
		if o.pega and is_instance_valid(_jogador) and not _preso and _jogador.controle_ligado:
			var no_anel := absf(p.y - topo_anel - 1.0) < 1.8
			if no_anel and _encosta(_jogador.global_position, o.graus, p):
				_soterrar(o.graus)


## Onde está a onda que desce a calha `graus` na fração `f` do caminho: a parede (de 13 m acima do anel até o pé),
## o anel inteiro, e cai da beira.
func _na_descida(graus: float, f: float) -> Vector3:
	var y_alto := topo_anel + 13.5
	var a := no_pico(graus, raio_da_parede(y_alto) + 1.6, y_alto)
	var b := no_pico(graus, raio_dentro + 1.0, topo_anel + 1.2)
	var c := no_pico(graus, raio_fora + 0.5, topo_anel + 1.2)
	var d := no_pico(graus, raio_fora + 4.0, topo_anel - 9.0)
	if f < 0.35:
		return a.lerp(b, ease(f / 0.35, 1.6))
	if f < 0.85:
		return b.lerp(c, (f - 0.35) / 0.5)
	return c.lerp(d, ease((f - 0.85) / 0.15, 2.0))


## O Faísca dentro da faixa da onda: perto dela no raio e dentro da largura da calha (ao longo do anel).
func _encosta(pos: Vector3, graus: float, onda: Vector3) -> bool:
	var a := deg_to_rad(graus)
	var fora := Vector3(cos(a), 0, -sin(a))
	var lado := Vector3.UP.cross(fora)
	var d := pos - onda
	return absf(d.dot(fora)) < 2.2 and absf(d.dot(lado)) < LARGURA * 0.5 and d.y > -1.5 and d.y < 2.5


## O aviso: umas bolinhas de neve escorregando pela calha, o ronco e o controle tremendo de leve.
func _avisar(i: int) -> void:
	_avisando[i] = true
	var graus: float = calhas[i]
	Sfx.play_at(get_parent(), "rolar", no_pico(graus, raio_da_parede(topo_anel + 8.0), topo_anel + 8.0), -4.0, 0.1)
	for k in 5:
		get_tree().create_timer(k * 0.22).timeout.connect(func() -> void: _soltar_onda(graus + randf_range(-6.0, 6.0), false, 0.3))
	if is_instance_valid(_jogador) and _jogador.global_position.distance_to(no_pico(graus, 22.0, topo_anel)) < 14.0:
		_jogador.tremidinha(0.25)


## Uma onda (ou uma bolinha de aviso) descendo a calha `graus`; `pega` diz se ela soterra quem estiver no caminho.
func _soltar_onda(graus: float, pega: bool, tamanho: float) -> void:
	var no := Node3D.new()
	get_parent().add_child(Fase.so_enfeite(no))
	var g := RandomNumberGenerator.new()
	g.randomize()
	var n := 7 if tamanho >= 1.0 else 1
	var a := deg_to_rad(graus)
	var lado := Vector3.UP.cross(Vector3(cos(a), 0, -sin(a)))
	for k in n:
		var mi := MeshInstance3D.new()
		mi.mesh = _malhas[g.randi() % _malhas.size()]
		mi.material_override = _mat_neve
		mi.scale = Vector3.ONE * tamanho * g.randf_range(0.7, 1.15)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if n == 1 else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if n > 1:
			mi.position = lado * lerpf(-LARGURA * 0.45, LARGURA * 0.45, k / float(n - 1)) + Vector3(0, g.randf_range(0.0, 1.2), g.randf_range(-0.6, 0.6))
		no.add_child(mi)
	no.global_position = _na_descida(graus, 0.0)
	_ondas.append({"no": no, "graus": graus, "t": 0.0, "pega": pega})
	if pega:
		Sfx.play_at(get_parent(), "rolar", no.global_position, 0.0, 0.05)


## A onda pegou: o Faísca vira uma bola de neve um instante e volta ao abrigo de antes da calha, sem perder coração.
func _soterrar(graus: float) -> void:
	_preso = true
	vezes_que_pegou += 1
	pegou.emit()
	var j := _jogador
	j.controle_ligado = false
	j.velocity = Vector3.ZERO
	j.tremidinha(0.7)
	Sfx.play_at(get_parent(), "bonk", j.global_position, 2.0, 0.0)
	var bola := MeshInstance3D.new()
	bola.mesh = _malhas[2]
	bola.material_override = _mat_neve
	bola.scale = Vector3.ONE * 0.9
	j.add_child(Fase.so_enfeite(bola))
	bola.position = Vector3(0, 0.9, 0)
	var volta := _abrigo_antes(graus)
	var tw := j.create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(func() -> void:
		Fx.dust(get_parent(), j.global_position)
		bola.queue_free()
		j.teleportar(volta)
		j.controle_ligado = true
		_preso = false)


## O abrigo do lado de onde o Faísca veio: o último antes da calha `graus` (andando do começo do setor para o fim).
func _abrigo_antes(graus: float) -> Vector3:
	var melhor: Vector3 = abrigos[0]
	for k in calhas.size():
		if is_equal_approx(calhas[k], graus):
			melhor = abrigos[k]
	return melhor + Vector3.UP * 0.1
