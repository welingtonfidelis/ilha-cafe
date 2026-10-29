class_name Bolotona
extends Bolota
## Bolotona, o mini-chefe da 1-2 (pedido do usuário em 2026-10-29, "as fases estão muito curtas"): uma Bolota
## duas vezes maior, mais devagar e com 8 de vida. Começa dormindo no meio da arena. Derrotada, ela se desfaz
## em três Bolotas pequenas acordadas (as `filhas`, criadas pela fase junto com ela e guardadas escondidas lá
## embaixo até a hora, para as estrelinhas delas já contarem no total da fase).

const TAMANHO := 2.1

var filhas: Array[Bolota] = []


func _ready() -> void:
	vida_max = 8
	velocidade = 1.5
	ve_de = 9.0
	desiste_de = 14.0
	alcance_toque = 1.05 * TAMANHO
	super()
	raio_golpe = 0.6 * TAMANHO
	visual.scale = Vector3.ONE * TAMANHO
	for c in get_children():
		if c is CollisionShape3D and (c as CollisionShape3D).shape is SphereShape3D:
			((c as CollisionShape3D).shape as SphereShape3D).radius = 0.62 * TAMANHO
			(c as CollisionShape3D).position.y = 0.62 * TAMANHO
	derrotada.connect(func(_a: Alvo) -> void: _soltar_filhas())


## Esconde uma filha lá embaixo, parada, sem colisão (a fase chama logo depois de criar).
static func guardar(b: Bolota) -> void:
	b.visible = false
	b.process_mode = Node.PROCESS_MODE_DISABLED
	b.collision_layer = 0
	b.position += Vector3.DOWN * 60.0


func _soltar_filhas() -> void:
	var centro := global_position
	for i in filhas.size():
		var b := filhas[i]
		var a := TAU * i / filhas.size()
		b.global_position = centro + Vector3(cos(a) * 1.8, 0.4, sin(a) * 1.8)
		b.set("_origem", b.global_position)
		b.visible = true
		b.collision_layer = Alvo.CAMADA
		b.process_mode = Node.PROCESS_MODE_INHERIT
		b.dormindo = false
		b.velocity = Vector3(cos(a) * 3.0, 6.0, sin(a) * 3.0)
	Fx.confetti(get_parent(), centro + Vector3.UP * 1.5, 50, 5.0)
