class_name DadoRolando
extends AnimatableBody3D
## Dado grande que rola sozinho de um lado para o outro (2-3 Quarto de Brinquedos), girando como se rolasse de
## verdade. A caixa de colisão não gira: dá para subir nele e pegar carona (é assim que se atravessa o chão que é
## lava). Encostar do lado só empurra. O nó fica no meio do dado, na posição `de`.

var de := Vector3.ZERO
var ate := Vector3.ZERO
var lado := 2.6
var periodo := 8.0
var atraso := 0.0
## Fração do vaivém parado em cada ponta (para dar tempo de subir e descer).
var pausa := 0.15
var modelo := "D6_A_red"
var _visual: Node3D
var _tempo := 0.0
var _antes := 0.0


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_visual = Node3D.new()
	add_child(_visual)
	var m: Node3D = load(Fase.QUARTO + modelo + ".gltf").instantiate()
	m.scale = Vector3.ONE * lado / 0.76
	_visual.add_child(m)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3.ONE * lado
	cs.shape = caixa
	add_child(cs)


## Quanto do caminho ele já andou (0 em `de`, 1 em `ate`).
func progresso() -> float:
	var s := 0.5 - 0.5 * cos(TAU * (_tempo + atraso) / periodo)
	return clampf((s - pausa) / (1.0 - 2.0 * pausa), 0.0, 1.0)


func _physics_process(delta: float) -> void:
	_tempo += delta
	var s := progresso()
	global_position = de.lerp(ate, s)
	# Gira em volta do eixo de lado: ângulo = distância andada / raio.
	var dir := (ate - de).normalized()
	var andado := (s - _antes) * de.distance_to(ate)
	_antes = s
	var eixo := dir.cross(Vector3.DOWN).normalized()
	_visual.basis = Basis(eixo, andado / (lado * 0.5)) * _visual.basis
	_visual.basis = _visual.basis.orthonormalized()
