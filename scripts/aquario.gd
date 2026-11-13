class_name Aquario
extends Node3D
## Aquário da praia do cais (item 5 da lista de melhorias, 2026-11-10): um tanque de vidro numa mesa de madeira,
## na areia ao lado da entrada do cais, de frente para a praça. Cada peixe novo da Pescaria vem nadar aqui (um de
## cada), e o placar em cima conta quantos dos 17 já estão. Montado em tempo de jogo, sem mexer na ilha gerada.

## Na areia, à direita de quem desce da praça para o cais (fora do círculo da defesa da praia).
const CENTRO := Vector3(10.0, 0.0, 200.0)
const LARGURA := 3.4
const FUNDO := 1.4
const ALTURA := 1.6
const MESA := 0.7
const BORDA := 0.12
const ESCALA_PEIXE := 0.15

## Os peixes que já estão nadando, pelo modelo.
var peixes := {}
var placar: Label3D
var _corpo: StaticBody3D
var _pegos := {}
var _assentado := false


func _ready() -> void:
	position = CENTRO
	_montar()
	_assentar.call_deferred()


## Põe a mesa no chão de verdade (a areia da praia não é plana).
func _assentar() -> void:
	await get_tree().physics_frame
	var de := Vector3(CENTRO.x, 60.0, CENTRO.z)
	var query := PhysicsRayQueryParameters3D.create(de, de + Vector3.DOWN * 120.0, 1)
	query.exclude = [_corpo.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		position.y = hit.position.y - 0.05
	_assentado = true
	for id in peixes:
		_acertar(peixes[id])


## Põe no tanque os peixes que ainda não estão (um de cada).
func atualizar(pegos: Dictionary) -> void:
	_pegos = pegos
	for spec: Dictionary in Pescaria.PEIXES:
		if pegos.has(spec.id) and not peixes.has(spec.id):
			var f := Fish.new()
			f.model_name = spec.id
			f.cardume = false
			f.model_scale = ESCALA_PEIXE
			f.radius = randf_range(0.7, 1.3)
			f.squash = (FUNDO * 0.5 - 0.28) / f.radius
			f.depth = randf_range(0.3, 1.0)
			f.speed = randf_range(0.35, 0.65)
			add_child(f)
			peixes[spec.id] = f
			_acertar(f)
	var n := pegos.size()
	var total := Pescaria.PEIXES.size()
	placar.text = "AQUÁRIO COMPLETO!\n%d de %d" % [n, total] if n >= total else "AQUÁRIO\n%d de %d peixes" % [n, total]


## Água e centro do nado em coordenadas do mundo (o peixe nada no mundo).
func _acertar(f: Fish) -> void:
	f.center = global_position + Vector3.UP * (MESA + BORDA + ALTURA * 0.5)
	f.water_y = agua_y()
	f.global_position = f.center


## Altura do topo da água.
func agua_y() -> float:
	return global_position.y + MESA + BORDA + ALTURA - 0.2


func _montar() -> void:
	var madeira := Color("#9c6b3f")
	var friso := Color("#2b4f7a")
	_caixa(Vector3(LARGURA + 0.3, MESA, FUNDO + 0.3), Vector3(0, MESA * 0.5, 0), _material(madeira))
	_caixa(Vector3(LARGURA + 0.1, BORDA, FUNDO + 0.1), Vector3(0, MESA + BORDA * 0.5, 0), _material(friso))
	var fundo := MESA + BORDA
	_caixa(Vector3(LARGURA - 0.1, 0.16, FUNDO - 0.1), Vector3(0, fundo + 0.08, 0), _material(Color("#f2dca0")))
	# Água azulzinha e o vidro por fora, com os cantos e a borda de cima no friso.
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.35, 0.78, 1.0, 0.3)
	agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	agua.roughness = 0.15
	_caixa(Vector3(LARGURA - 0.08, ALTURA - 0.2, FUNDO - 0.08), Vector3(0, fundo + (ALTURA - 0.2) * 0.5, 0), agua)
	var vidro := StandardMaterial3D.new()
	vidro.albedo_color = Color(0.85, 0.95, 1.0, 0.12)
	vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidro.roughness = 0.05
	vidro.metallic_specular = 1.0
	_caixa(Vector3(LARGURA, ALTURA, FUNDO), Vector3(0, fundo + ALTURA * 0.5, 0), vidro)
	var friso_mat := _material(friso)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_caixa(Vector3(0.08, ALTURA, 0.08), Vector3(sx * LARGURA * 0.5, fundo + ALTURA * 0.5, sz * FUNDO * 0.5), friso_mat)
	for sz in [-1.0, 1.0]:
		_caixa(Vector3(LARGURA + 0.08, 0.08, 0.08), Vector3(0, fundo + ALTURA, sz * FUNDO * 0.5), friso_mat)
	for sx in [-1.0, 1.0]:
		_caixa(Vector3(0.08, 0.08, FUNDO + 0.08), Vector3(sx * LARGURA * 0.5, fundo + ALTURA, 0), friso_mat)
	# Pedrinhas e plantinhas na areia do fundo.
	var pedra := _material(Color("#8a8f9c"))
	for spec in [[Vector3(-1.1, 0, -0.25), 0.22], [Vector3(-0.85, 0, 0.2), 0.15], [Vector3(1.2, 0, 0.1), 0.2]]:
		var m := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = spec[1]
		esfera.height = spec[1] * 1.2
		m.mesh = esfera
		m.material_override = pedra
		m.position = spec[0] + Vector3.UP * (fundo + 0.16)
		add_child(m)
	var alga := _material(Color("#3fbf63"))
	for spec in [[Vector3(-1.35, 0, 0.35), 0.9], [Vector3(-1.2, 0, 0.45), 0.6], [Vector3(0.9, 0, -0.4), 0.8], [Vector3(1.4, 0, -0.35), 0.55],
			[Vector3(0.2, 0, -0.45), 0.5]]:
		var m := MeshInstance3D.new()
		var cano := CapsuleMesh.new()
		cano.radius = 0.05
		cano.height = spec[1]
		m.mesh = cano
		m.material_override = alga
		m.position = spec[0] + Vector3.UP * (fundo + 0.12 + spec[1] * 0.5)
		m.rotation.z = randf_range(-0.2, 0.2)
		add_child(m)
	_corpo = StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(LARGURA + 0.3, fundo + ALTURA, FUNDO + 0.3)
	forma.shape = caixa
	forma.position.y = (fundo + ALTURA) * 0.5
	_corpo.add_child(forma)
	add_child(_corpo)
	placar = Label3D.new()
	placar.font_size = 60
	placar.outline_size = 14
	placar.outline_modulate = Color(0.15, 0.08, 0.25)
	placar.modulate = Color("#ffd23f")
	placar.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	placar.pixel_size = 0.007
	placar.position = Vector3(0, fundo + ALTURA + 0.85, 0)
	add_child(placar)
	atualizar({})


func _caixa(tamanho: Vector3, pos: Vector3, mat: Material) -> void:
	var m := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tamanho
	m.mesh = b
	m.material_override = mat
	m.position = pos
	add_child(m)


func _material(cor: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cor
	mat.roughness = 0.8
	return mat
