class_name Bau
extends StaticBody3D
## Baú das Bolotas (o baú grande do pacote Platformer, amarelo). Três golpes abrem: a cada um
## ele balança; no terceiro a tampa abre e a Estrela Grande sobe de dentro. Encostar nela
## termina a fase (sinal `estrela_pega`). Fica no grupo dos alvos para os golpes e a mira.

signal aberto
signal estrela_pega

const GOLPES_PARA_ABRIR := 3
const ESCALA := 1.7

## Para os golpes: aberto conta como derrotado (não vira mais alvo).
var derrotado := false
## O baú é grande: os golpes alcançam a partir da beirada, não do meio.
var raio_golpe := 1.9
var golpes := 0
var estrela: Area3D
var _modelo: Node3D
var _tampa: Node3D
var _imune := 0.0
var _tempo := 0.0
var _estrela_visual: Node3D
## A estrela só pode ser pega depois de terminar de subir.
var _estrela_pronta := false


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	collision_layer = 1
	collision_mask = 0
	_modelo = load(Fase.PLATAFORMA + "chest_large_yellow.gltf").instantiate()
	_modelo.scale = Vector3.ONE * ESCALA
	add_child(_modelo)
	_tampa = _modelo.find_child("chest_large_lid_yellow", true, false)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(1.85, 0.8, 1.6) * ESCALA
	cs.shape = caixa
	cs.position = Vector3(0, 0.4 * ESCALA - 0.16 * ESCALA, 0.1 * ESCALA)
	add_child(cs)


func _process(delta: float) -> void:
	_tempo += delta
	_imune -= delta
	if _estrela_visual:
		_estrela_visual.rotation.y += delta * 1.8
		_estrela_visual.position.y = sin(_tempo * 2.5) * 0.15
	# Pela sobreposição, e não por "entrou": quem abriu o baú costuma já estar embaixo dela.
	if _estrela_pronta and estrela.monitoring:
		for corpo in estrela.get_overlapping_bodies():
			if corpo is Jogador:
				_estrela_pronta = false
				estrela.set_deferred("monitoring", false)
				estrela_pega.emit()


func receber_golpe(_dano: int, de: Vector3, _forca := 6.0) -> bool:
	if derrotado or _imune > 0.0:
		return false
	_imune = 0.3
	golpes += 1
	var lado := (global_position - de).normalized()
	var tw := create_tween()
	tw.tween_property(_modelo, "rotation:z", -0.12 * signf(lado.x + 0.01), 0.06)
	tw.tween_property(_modelo, "rotation:z", 0.08 * signf(lado.x + 0.01), 0.08)
	tw.tween_property(_modelo, "rotation:z", 0.0, 0.1)
	tw.parallel().tween_property(_modelo, "scale", Vector3.ONE * ESCALA, 0.12).from(Vector3(1.12, 0.88, 1.12) * ESCALA)
	if golpes >= GOLPES_PARA_ABRIR:
		_abrir()
	return true


func _abrir() -> void:
	derrotado = true
	if _tampa:
		create_tween().tween_property(_tampa, "rotation:x", -1.9, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_criar_estrela()
	aberto.emit()


## A Estrela Grande sai de dentro do baú, sobe um pouco e fica girando esperando o Faísca.
func _criar_estrela() -> void:
	estrela = Area3D.new()
	estrela.collision_layer = 0
	estrela.collision_mask = Fase.CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 1.3
	cs.shape = esfera
	estrela.add_child(cs)
	_estrela_visual = Node3D.new()
	estrela.add_child(_estrela_visual)
	var mi := MeshInstance3D.new()
	mi.mesh = Forma.estrela(0.9, 0.42, 0.45)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color("ffe066")
	m.roughness = 0.25
	m.emission_enabled = true
	m.emission = Color("ffc400")
	m.emission_energy_multiplier = 0.7
	mi.material_override = m
	_estrela_visual.add_child(mi)
	var luz := OmniLight3D.new()
	luz.light_color = Color("ffe680")
	luz.light_energy = 1.2
	luz.omni_range = 7.0
	estrela.add_child(luz)
	add_child(estrela)
	estrela.position = Vector3(0, 0.6, 0)
	estrela.scale = Vector3.ONE * 0.2
	var tw := estrela.create_tween().set_parallel()
	# Sobe para a frente do baú, onde o Faísca alcança com um pulinho.
	tw.tween_property(estrela, "position", Vector3(0, 2.9, 1.4), 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(estrela, "scale", Vector3.ONE, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func(): _estrela_pronta = true)


## Depois que o Faísca pega: a estrela sobe para o céu e some lá no alto.
func estrela_sobe() -> void:
	var tw := estrela.create_tween().set_parallel()
	tw.tween_property(estrela, "global_position", estrela.global_position + Vector3(0, 40, 0), 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(estrela, "scale", Vector3.ONE * 0.3, 2.5)
