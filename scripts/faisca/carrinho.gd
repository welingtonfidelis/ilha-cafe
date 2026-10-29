class_name CarrinhoDeMina
extends AnimatableBody3D
## Carrinho de mina (pedido do usuário em 2026-10-29, "as fases estão muito curtas"), feito por código, porque
## os pacotes não têm um: caixa de madeira com cintas de ferro e quatro rodas, andando em linha reta nos trilhos
## de `de` até `ate`.
## - O Faísca pula para dentro e, um instante depois de pisar no fundo, o carrinho sai sozinho. Ele acelera,
##   corre e freia na estação do fim.
## - Pulando dentro do carrinho, o Faísca continua indo junto (leva a velocidade dele) e pega as estrelinhas
##   que ficam no ar em cima dos trilhos.
## - Quando ele desce no fim, o carrinho volta vazio para o começo, para quem cair e voltar no posto poder
##   andar de novo.
## O nó fica no meio do chão do carrinho, na altura dos trilhos.

signal saiu
signal chegou

const VELOCIDADE := 7.0
const ACELERA := 1.5
const LARGURA := 2.0
const COMPRIMENTO := 3.0
const FUNDO := 0.55
const BORDA := 1.25

var de := Vector3.ZERO
var ate := Vector3.ZERO
## parado, indo, chegou, voltando
var estado := "parado"
var _andado := 0.0
var _dentro := 0.0
var _vazio := 0.0
var _area: Area3D


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	look_at(de + (de - ate).normalized(), Vector3.UP)
	_montar()


func _montar() -> void:
	var madeira := StandardMaterial3D.new()
	madeira.albedo_color = Color("8a5a36")
	madeira.roughness = 0.9
	var ferro := StandardMaterial3D.new()
	ferro.albedo_color = Color("4a4658")
	ferro.metallic = 0.5
	ferro.roughness = 0.5
	var meia := Vector2(LARGURA, COMPRIMENTO) * 0.5
	var parede := 0.15
	# Fundo e as quatro paredes (com colisão: ele fica dentro, mas dá para pular para fora).
	_caixa(Vector3(LARGURA, 0.2, COMPRIMENTO), Vector3(0, FUNDO - 0.1, 0), madeira, true)
	var alto := BORDA - FUNDO
	for lado in [-1.0, 1.0]:
		_caixa(Vector3(parede, alto, COMPRIMENTO), Vector3(lado * (meia.x - parede * 0.5), FUNDO + alto * 0.5, 0), madeira, true)
		_caixa(Vector3(LARGURA, alto, parede), Vector3(0, FUNDO + alto * 0.5, lado * (meia.y - parede * 0.5)), madeira, true)
		# Cintas de ferro em volta da borda e nos cantos.
		_caixa(Vector3(parede + 0.06, 0.12, COMPRIMENTO + 0.06), Vector3(lado * (meia.x - parede * 0.5), BORDA, 0), ferro, false)
		_caixa(Vector3(LARGURA + 0.06, 0.12, parede + 0.06), Vector3(0, BORDA, lado * (meia.y - parede * 0.5)), ferro, false)
		for frente in [-1.0, 1.0]:
			_caixa(Vector3(0.18, alto + 0.1, 0.18), Vector3(lado * meia.x, FUNDO + alto * 0.5, frente * meia.y), ferro, false)
			var roda := MeshInstance3D.new()
			var cil := CylinderMesh.new()
			cil.top_radius = 0.3
			cil.bottom_radius = 0.3
			cil.height = 0.16
			roda.mesh = cil
			roda.material_override = ferro
			roda.rotation.z = PI / 2.0
			roda.position = Vector3(lado * (meia.x - 0.25), 0.3, frente * (meia.y - 0.6))
			add_child(roda)
	# Quem está em cima do fundo.
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Fase.CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(LARGURA - 0.4, 1.0, COMPRIMENTO - 0.4)
	cs.shape = caixa
	cs.position.y = FUNDO + 0.5
	_area.add_child(cs)
	add_child(_area)


func _caixa(tamanho: Vector3, pos: Vector3, material: Material, solida: bool) -> void:
	var mi := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = tamanho
	mi.mesh = malha
	mi.material_override = material
	mi.position = pos
	add_child(mi)
	if solida:
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = tamanho
		cs.shape = forma
		cs.position = pos
		add_child(cs)


## O Faísca está dentro, em pé no fundo.
func com_faisca() -> bool:
	for corpo in _area.get_overlapping_bodies():
		if corpo is Jogador and (corpo as Jogador).is_on_floor():
			return true
	return false


func _physics_process(delta: float) -> void:
	var total := de.distance_to(ate)
	match estado:
		"parado":
			_dentro = _dentro + delta if com_faisca() else 0.0
			if _dentro > 0.4:
				estado = "indo"
				_andado = 0.0
				saiu.emit()
				Sfx.play_at(get_parent(), "remontar", global_position, -4.0)
		"indo":
			# Acelera no começo e freia nos últimos metros.
			var falta := total - _andado
			var v := minf(VELOCIDADE, minf(VELOCIDADE * (_andado / (VELOCIDADE * ACELERA * 0.5) + 0.15), sqrt(maxf(falta, 0.0) * 6.0) + 0.3))
			_andado = minf(_andado + v * delta, total)
			global_position = de.lerp(ate, _andado / total)
			if _andado >= total:
				estado = "chegou"
				_vazio = 0.0
				chegou.emit()
				Sfx.play_at(get_parent(), "bonk", global_position, -4.0)
		"chegou":
			_vazio = 0.0 if com_faisca() else _vazio + delta
			if _vazio > 2.0:
				estado = "voltando"
		"voltando":
			_andado = maxf(_andado - VELOCIDADE * 1.4 * delta, 0.0)
			global_position = de.lerp(ate, _andado / total)
			if _andado <= 0.0:
				estado = "parado"
				_dentro = 0.0
