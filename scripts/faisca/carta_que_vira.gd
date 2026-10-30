class_name CartaQueVira
extends AnimatableBody3D
## Carta de baralho gigante deitada em cima do chão que é lava (2-3 Quarto de Brinquedos): fica parada um tempo,
## treme e vira de ponta-cabeça em volta do lado comprido. Quem estiver em cima quando ela vira cai na lava. Depois
## de virada ela fica firme de novo (com a outra face para cima). O nó fica no meio da carta.

const PARADA := 2.8
const TREME := 0.7
const VIRA := 0.5

var modelo := "card_hearts_ace"
var atraso := 0.0
var escala := 0.9
var _visual: Node3D
var _tempo := 0.0
var _giro := 0.0


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	_visual = Node3D.new()
	add_child(_visual)
	var m: Node3D = load(Fase.QUARTO + modelo + ".gltf").instantiate()
	m.scale = Vector3.ONE * escala
	# A carta do pacote fica em pé (no plano XY): deita no chão.
	m.rotation.x = -PI / 2.0
	_visual.add_child(m)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(4.32 * escala, 0.2, 6.0 * escala)
	cs.shape = caixa
	add_child(cs)
	_tempo = atraso


## Em que parte do ciclo ela está: "parada", "treme" ou "vira".
func fase_do_ciclo() -> String:
	var t := fmod(_tempo, PARADA + TREME + VIRA)
	return "parada" if t < PARADA else ("treme" if t < PARADA + TREME else "vira")


func _physics_process(delta: float) -> void:
	var antes := fase_do_ciclo()
	_tempo += delta
	var t := fmod(_tempo, PARADA + TREME + VIRA)
	match fase_do_ciclo():
		"treme":
			_visual.position = Vector3(randf_range(-0.05, 0.05), 0, randf_range(-0.05, 0.05))
		"vira":
			_visual.position = Vector3.ZERO
			rotation.z = _giro + PI * clampf((t - PARADA - TREME) / VIRA, 0.0, 1.0)
		_:
			if antes == "vira":
				_giro = fmod(_giro + PI, TAU)
				rotation.z = _giro
				Sfx.play_at(get_parent(), "pancada", global_position, -8.0)
