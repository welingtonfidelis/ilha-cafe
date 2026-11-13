class_name BlocoPisca
extends StaticBody3D
## Bloco-pisca lilás, a novidade da 3-2 Fábrica de Blocos (2026-10-31): blocos de 3 x 3 m que aparecem e somem no
## tique-taque da fábrica, em dois grupos que se revezam. Cada grupo fica 3 s e some 1,8 s; os dois ficam juntos por
## 0,6 s em cada troca, dando tempo de passar de um para o outro. Antes de sumir, o bloco pisca (os últimos 0,7 s).
## O contorno lilás fica sempre, mostrando onde ele aparece. Lilás quer dizer "cuidado, some", como as nuvens que somem.
## Quem manda no relógio é a fase (`definir`, a cada quadro de física), para todos andarem juntos. O nó fica no meio da
## face de cima, onde se pisa.

const LADO := 3.0
const ALTURA := 1.0
const CICLO := 4.8
const LIGADO := 3.0
const PISCA := 0.7

var grupo := 0
var aceso := true
var _visual: MeshInstance3D
var _forma: CollisionShape3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	_visual = MeshInstance3D.new()
	_visual.mesh = Forma.caixa_redonda(Vector3(LADO, ALTURA, LADO), 0.18)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("c9a7ff")
	m.emission_enabled = true
	m.emission = Color("b58cff")
	m.emission_energy_multiplier = 0.35
	m.roughness = 0.4
	_visual.material_override = m
	_visual.position.y = -ALTURA * 0.5
	add_child(_visual)
	_forma = CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(LADO, ALTURA, LADO)
	_forma.shape = caixa
	_forma.position.y = -ALTURA * 0.5
	add_child(_forma)
	# O contorno: as doze arestas em lilás escuro (enfeite: atravessa-se).
	var contorno := Fase.so_enfeite(Node3D.new())
	var linha := StandardMaterial3D.new()
	linha.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	linha.albedo_color = Color("7d55d0")
	var h := LADO * 0.5
	var a := ALTURA * 0.5
	for x in [-h, h]:
		for z in [-h, h]:
			_aresta(contorno, Vector3(x, -a, z), Vector3(0.06, ALTURA, 0.06), linha)
		for y in [-a, a]:
			_aresta(contorno, Vector3(x, -a + y, 0), Vector3(0.06, 0.06, LADO), linha)
	for z in [-h, h]:
		for y in [-a, a]:
			_aresta(contorno, Vector3(0, -a + y, z), Vector3(LADO, 0.06, 0.06), linha)
	add_child(contorno)


func _aresta(pai: Node3D, pos: Vector3, tamanho: Vector3, m: Material) -> void:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = tamanho
	mi.mesh = b
	mi.material_override = m
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(mi)


## Aceso (pisável) no tempo `t` da fase, para o grupo `g`.
static func aceso_em(t: float, g: int) -> bool:
	return fposmod(t + g * CICLO * 0.5, CICLO) < LIGADO


## Põe o bloco no tempo `t` da fase: aceso ou sumido, e piscando no fim.
func definir(t: float) -> void:
	var f := fposmod(t + grupo * CICLO * 0.5, CICLO)
	var agora := f < LIGADO
	if agora != aceso:
		aceso = agora
		_forma.set_deferred("disabled", not aceso)
	_visual.visible = aceso and not (f > LIGADO - PISCA and int(f * 10.0) % 2 == 1)
