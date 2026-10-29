class_name VagaLume
extends Area3D
## Vaga-lume escondido: robozinho de cabeça branca com dois olhinhos, asinhas que batem e a
## barriga verde-limão que brilha. Fica flutuando no cantinho dele; encostar e ele volta para
## o farol (sobe girando e some). Já achado em outra vez (`ja_visto`), fica transparente.

signal achado(vaga_lume: VagaLume)

var encontrado := false
var ja_visto := false
var _corpo: Node3D
var _asas: Array[Node3D] = []
var _tempo := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.9
	cs.shape = esfera
	add_child(cs)
	_tempo = randf() * 6.0
	_corpo = Node3D.new()
	add_child(_corpo)
	var branco := _material(Color("f4f5f9"))
	var brilho := _material(Color("c6ff4a"))
	brilho.emission_enabled = true
	brilho.emission = Color("b6ff2e")
	brilho.emission_energy_multiplier = 0.8 if ja_visto else 2.5
	var cabeca := MeshInstance3D.new()
	cabeca.mesh = Forma.superelipsoide(Vector3(0.2, 0.18, 0.19), 0.8, 0.8)
	cabeca.material_override = branco
	cabeca.position = Vector3(0, 0.08, 0.14)
	_corpo.add_child(cabeca)
	for lado in [-1.0, 1.0]:
		var olho := MeshInstance3D.new()
		var capsula := CapsuleMesh.new()
		capsula.radius = 0.03
		capsula.height = 0.1
		olho.mesh = capsula
		olho.material_override = _material(Color("1b1530"))
		olho.position = Vector3(0.07 * lado, 0.1, 0.32)
		_corpo.add_child(olho)
		var asa := Node3D.new()
		asa.position = Vector3(0.1 * lado, 0.2, -0.02)
		_corpo.add_child(asa)
		var malha := MeshInstance3D.new()
		malha.mesh = Forma.superelipsoide(Vector3(0.2, 0.02, 0.11), 1.0, 1.0)
		var vidro := _material(Color(0.9, 0.97, 1.0, 0.6))
		vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		malha.material_override = vidro
		malha.position.x = 0.18 * lado
		asa.add_child(malha)
		_asas.append(asa)
	var barriga := MeshInstance3D.new()
	barriga.mesh = Forma.superelipsoide(Vector3(0.16, 0.15, 0.2), 1.0, 1.0)
	barriga.material_override = brilho
	barriga.position = Vector3(0, -0.02, -0.18)
	_corpo.add_child(barriga)
	var luz := OmniLight3D.new()
	luz.light_color = Color("c6ff4a")
	luz.light_energy = 1.2
	luz.omni_range = 3.0
	_corpo.add_child(luz)
	body_entered.connect(_encostou)


func _process(delta: float) -> void:
	_tempo += delta
	if encontrado:
		return
	_corpo.position.y = sin(_tempo * 2.2) * 0.15
	_corpo.rotation.y = sin(_tempo * 0.7) * 0.6
	for i in _asas.size():
		_asas[i].rotation.z = (1.0 if i == 0 else -1.0) * sin(_tempo * 30.0) * 0.5


func _encostou(corpo: Node3D) -> void:
	if not corpo is Jogador or encontrado:
		return
	encontrado = true
	set_deferred("monitoring", false)
	(corpo as Jogador).robo.expressao("coracao", 1.2)
	achado.emit(self)
	var tw := create_tween().set_parallel()
	tw.tween_property(_corpo, "position", Vector3(0, 6.0, 0), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_corpo, "rotation:y", TAU * 3.0, 1.2)
	tw.tween_property(_corpo, "scale", Vector3.ONE * 0.01, 0.4).set_delay(0.8)
	tw.chain().tween_callback(hide)


func _material(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.4
	if ja_visto:
		m.albedo_color.a *= 0.4
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m
