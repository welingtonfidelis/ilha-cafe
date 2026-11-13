class_name BolaDeNeve
extends AnimatableBody3D
## Bola de neve grande (a snowball do Holiday Bits, bem ampliada) que rola sozinha de um lado para o outro (3-1 Pico
## Gelado, 2026-10-30), girando como se rolasse de verdade. Encostar nela empurra o Faísca para longe, sem tirar
## coração: perto da beirada, é o risco. Como o DadoRolando, o nó fica no meio da bola, na posição `de`.

const EMPURRAO := 8.5
const ESPERA := 0.8

var de := Vector3.ZERO
var ate := Vector3.ZERO
var raio := 1.6
var periodo := 6.0
var atraso := 0.0
## Fração do vaivém parada em cada ponta.
var pausa := 0.06
var _visual: Node3D
var _tempo := 0.0
var _antes := 0.0
var _espera := 0.0


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_visual = Node3D.new()
	add_child(_visual)
	var m: Node3D = load("res://assets/faisca/neve/snowball.gltf").instantiate()
	m.scale = Vector3.ONE * raio / 0.15
	_visual.add_child(m)
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = raio
	cs.shape = esfera
	add_child(cs)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = Fase.CAMADA_JOGADOR
	var forma := CollisionShape3D.new()
	var maior := SphereShape3D.new()
	maior.radius = raio + 0.45
	forma.shape = maior
	area.add_child(forma)
	add_child(area)
	area.body_entered.connect(_esbarrou)


func _physics_process(delta: float) -> void:
	_tempo += delta
	_espera -= delta
	var s := 0.5 - 0.5 * cos(TAU * (_tempo + atraso) / periodo)
	s = clampf((s - pausa) / (1.0 - 2.0 * pausa), 0.0, 1.0)
	global_position = de.lerp(ate, s)
	var dir := (ate - de).normalized()
	var andado := (s - _antes) * de.distance_to(ate)
	_antes = s
	var eixo := dir.cross(Vector3.DOWN).normalized()
	_visual.basis = (Basis(eixo, andado / raio) * _visual.basis).orthonormalized()


## Esbarrou no Faísca: ele vai para longe da bola, para o lado em que ela está indo, e um pouco para cima.
func _esbarrou(corpo: Node3D) -> void:
	if not corpo is Jogador or _espera > 0.0:
		return
	_espera = ESPERA
	var fora := corpo.global_position - global_position
	fora.y = 0.0
	fora = fora.normalized() if fora.length() > 0.05 else (ate - de).normalized()
	(corpo as Jogador).empurrar(fora * EMPURRAO + Vector3.UP * 5.0)
	Sfx.play_at(get_parent(), "bonk", global_position, -3.0)
