class_name TampaQuePula
extends AnimatableBody3D
## Tampa de panela que pula, a novidade da 2-1 Cozinha Gigante (pedido do usuário em 2026-10-29: "pode fazer a
## próxima fase"). A panela ferve e, de tempos em tempos, a tampa treme soltando vapor e pula. Quem estiver em
## cima na hora vai lá para o alto, como na mola, mas no tempo dela. Entre um pulo e outro dá para ficar em pé
## nela (é plataforma). O nó fica no meio de baixo da tampa, em cima da panela.

signal pulou

const ESPERA := 2.0
const TREME := 0.8
const PULO := 0.55
const SUBIDA := 1.2

var forca := 21.0
## Segundos de diferença no ciclo (para tampas vizinhas não pularem juntas).
var atraso := 0.0
var escala := 6.0
var modelo := "lid_A"
var _t := 0.0
var _base := Vector3.ZERO
var _area: Area3D
var _visual: Node3D
var _lancou := false


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_base = position
	_t = -atraso
	_visual = Node3D.new()
	add_child(_visual)
	var tampa: Node3D = load(Fase.COZINHA + modelo + ".gltf").instantiate()
	tampa.scale = Vector3.ONE * escala
	_visual.add_child(tampa)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 0.5 * escala
	cil.height = 0.2 * escala
	cs.shape = cil
	cs.position.y = 0.1 * escala
	add_child(cs)
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Fase.CAMADA_JOGADOR
	var forma := CollisionShape3D.new()
	var topo := CylinderShape3D.new()
	topo.radius = 0.45 * escala
	topo.height = 1.2
	forma.shape = topo
	forma.position.y = 0.2 * escala + 0.6
	_area.add_child(forma)
	add_child(_area)


## Fase do ciclo: "quieta", "treme" ou "pula".
func fase_do_ciclo() -> String:
	var f := fposmod(_t, ESPERA + TREME + PULO)
	if f < ESPERA:
		return "quieta"
	return "treme" if f < ESPERA + TREME else "pula"


func _physics_process(delta: float) -> void:
	_t += delta
	var f := fposmod(_t, ESPERA + TREME + PULO)
	if f < ESPERA:
		position = _base
		_visual.rotation = Vector3.ZERO
		_lancou = false
	elif f < ESPERA + TREME:
		# Tremendo e soltando um fiozinho de vapor: vai pular.
		_visual.rotation.z = sin(_t * 45.0) * 0.05
		_visual.rotation.x = cos(_t * 38.0) * 0.04
		if randf() < delta * 6.0:
			_vapor(1, 0.5)
	else:
		_visual.rotation = Vector3.ZERO
		var p := (f - ESPERA - TREME) / PULO
		position = _base + Vector3.UP * SUBIDA * sin(PI * p)
		if not _lancou:
			_lancou = true
			_vapor(6, 1.2)
			Sfx.play_at(get_parent(), "bonk", global_position, -6.0)
			for corpo in _area.get_overlapping_bodies():
				if corpo is Jogador:
					(corpo as Jogador).lancar(forca)
			pulou.emit()


## Bolinhas brancas de vapor subindo e sumindo em volta da tampa.
func _vapor(n: int, tamanho: float) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1, 1, 1, 0.7)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in n:
		var e := MeshInstance3D.new()
		var bola := SphereMesh.new()
		bola.radius = tamanho * randf_range(0.6, 1.0)
		bola.height = bola.radius * 2.0
		e.mesh = bola
		e.material_override = m
		e.top_level = true
		add_child(e)
		var a := randf() * TAU
		var de := global_position + Vector3(cos(a), 0, sin(a)) * 0.5 * escala + Vector3.UP * 0.3 * escala
		e.global_position = de
		var tw := e.create_tween().set_parallel()
		tw.tween_property(e, "global_position", de + Vector3(cos(a) * 0.8, 3.0 + randf() * 2.0, sin(a) * 0.8), 1.1)
		tw.tween_property(e, "scale", Vector3.ONE * 2.0, 1.1)
		tw.tween_property(m, "albedo_color:a", 0.0, 1.1)
		tw.chain().tween_callback(e.queue_free)
