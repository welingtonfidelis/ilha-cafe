class_name DadoQueTomba
extends AnimatableBody3D
## Dado grande de brinquedo, a novidade da 2-3 Quarto de Brinquedos (2026-10-30): um soco (ou o giro) tomba o dado
## para o lado do golpe, um lado inteiro de cada vez, girando em volta da aresta de baixo. Ele vira degrau (1,8 m: dá
## para subir nele com um pulo, e dele subir mais 1,6 m). Fica no grupo dos alvos dos golpes, como o baú; o pisão e o
## laser não tombam (nem a pancada do martelinho, da 3-2).
## - Com alguma coisa no caminho (parede, móvel, Bolota), ele só balança.
## - Tombando para fora de uma beirada, ele cai; se cair mais de 1 m abaixo de onde começou (da mesa para o chão,
##   por exemplo), some num puf e volta para a `casa`, para a tarefa nunca ficar impossível.
## - `travado` (a fase trava quando ele chega no lugar certo) não tomba mais.
## O nó fica no meio do dado.

signal tombou(dado: DadoQueTomba)

const TEMPO := 0.35

var lado := 1.8
## Modelo do dado ("D6_A", "D6_A_red"...), na pasta do quarto.
var modelo := "D6_A"
## Pasta e lado do modelo: os dados do quarto têm 0,76 m; os blocos da 3-2 (Block Bits, na pasta da fábrica), 2 m.
var pasta := Fase.QUARTO
var lado_modelo := 0.76
var casa := Vector3.ZERO
var travado := false
var tombando := false
## Para os golpes: o dado nunca é "derrotado".
var derrotado := false
var raio_golpe := 1.0
var _visual: Node3D
var _base := Basis.IDENTITY
var _de := Vector3.ZERO
var _dir := Vector3.ZERO
var _t := 0.0
var _caindo := false
var _vel_queda := 0.0


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	sync_to_physics = false
	collision_layer = 1
	collision_mask = 0
	casa = position
	_visual = Node3D.new()
	add_child(_visual)
	var m: Node3D = load(pasta + modelo + ".gltf").instantiate()
	m.scale = Vector3.ONE * lado / lado_modelo
	_visual.add_child(m)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3.ONE * lado
	cs.shape = caixa
	add_child(cs)


func receber_golpe(_dano: int, de: Vector3, _forca := 6.0, tipo := "") -> bool:
	if tombando or _caindo or travado or tipo in ["laser", "pisao", "pancada"]:
		return false
	var d := global_position - de
	d.y = 0.0
	var dir := Vector3(signf(d.x), 0, 0) if absf(d.x) > absf(d.z) else Vector3(0, 0, signf(d.z))
	if dir == Vector3.ZERO:
		return false
	if _bloqueado(dir):
		var tw := _visual.create_tween()
		tw.tween_property(_visual, "position", dir * 0.15, 0.08)
		tw.tween_property(_visual, "position", Vector3.ZERO, 0.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		Sfx.play_at(get_parent(), "bonk", global_position, -4.0)
		return true
	tombar(dir)
	return true


## Tomba um lado na direção `dir` (um dos quatro eixos), sem conferir o caminho (os testes usam).
func tombar(dir: Vector3) -> void:
	_dir = dir
	_de = global_position
	_t = 0.0
	tombando = true
	Sfx.play_at(get_parent(), "faisca_pisao", global_position, -3.0)


## Tem alguma coisa onde o dado vai parar.
func _bloqueado(dir: Vector3) -> bool:
	var q := PhysicsShapeQueryParameters3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3.ONE * lado * 0.9
	q.shape = caixa
	q.transform = Transform3D(Basis.IDENTITY, global_position + dir * lado)
	q.collision_mask = 1 | Alvo.CAMADA
	q.exclude = [get_rid()]
	return not get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()


func _physics_process(delta: float) -> void:
	if tombando:
		_t = minf(_t + delta / TEMPO, 1.0)
		var eixo := _dir.cross(Vector3.UP).normalized()
		var h := lado * 0.5
		var pivo := _de + _dir * h - Vector3.UP * h
		global_position = pivo + (-_dir * h + Vector3.UP * h).rotated(eixo, -_t * PI * 0.5)
		_visual.basis = Basis(eixo, -_t * PI * 0.5) * _base
		if _t >= 1.0:
			tombando = false
			_base = _visual.basis.orthonormalized()
			global_position = _de + _dir * lado
			# Sem chão rente (a beira da mesa, ou um degrau mais baixo, como o tampo fora do tabuleiro), ele cai até assentar.
			if not _tem_chao():
				_caindo = true
				_vel_queda = 0.0
			else:
				tombou.emit(self)
	elif _caindo:
		_vel_queda = minf(_vel_queda + 26.0 * delta, 30.0)
		var r := get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
				global_position, global_position + Vector3.DOWN * (lado * 0.5 + _vel_queda * delta + 0.05), 1, [get_rid()]))
		if r.is_empty():
			global_position += Vector3.DOWN * _vel_queda * delta
			if global_position.y < casa.y - 30.0:
				voltar_para_casa()
		else:
			global_position = r.position + Vector3.UP * lado * 0.5
			_caindo = false
			Sfx.play_at(get_parent(), "bonk", global_position, -2.0)
			if global_position.y < casa.y - 1.0:
				voltar_para_casa()
			else:
				tombou.emit(self)


func _tem_chao() -> bool:
	return not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
			global_position, global_position + Vector3.DOWN * (lado * 0.5 + 0.06), 1, [get_rid()])).is_empty()


## Some num puf e reaparece na casa (caiu da mesa, por exemplo).
func voltar_para_casa() -> void:
	tombando = false
	_caindo = false
	Fx.dust(get_parent(), global_position)
	global_position = casa
	_base = Basis.IDENTITY
	_visual.basis = Basis.IDENTITY
	_visual.scale = Vector3.ONE * 0.05
	var tw := _visual.create_tween()
	tw.tween_property(_visual, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play_at(get_parent(), "reaparecer", global_position, -4.0)
