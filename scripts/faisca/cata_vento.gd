class_name CataVento
extends StaticBody3D
## Cata-vento de brinquedo da 3-3 Moinhos do Vento (2026-11-12): o poste escuro e as quatro pás (laranja e brancas)
## com o miolo amarelo, paradas. Um soco (ou o giro) faz girar, com confete e o "fiu", e avisa a fase (`girou`): são as
## tarefas da campina e dos silos. Fica no grupo dos alvos dos golpes, como o registro da 2-1; girando, conta como
## derrotado (não vira mais alvo). O nó fica no pé do poste.

signal girou(c: CataVento)

var alto := 4.5
var girando := false
var derrotado: bool:
	get:
		return girando
var raio_golpe := 1.0

var _pas: Node3D
var _tempo := 0.0
var _velocidade := 0.0


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	collision_layer = 1
	collision_mask = 0
	_tempo = randf() * 4.0
	var escuro := StandardMaterial3D.new()
	escuro.albedo_color = Color("2b2140")
	var poste := MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.12
	cil.bottom_radius = 0.17
	cil.height = alto
	poste.mesh = cil
	poste.material_override = escuro
	poste.position.y = alto * 0.5
	add_child(poste)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = 0.2
	forma.height = alto
	cs.shape = forma
	cs.position.y = alto * 0.5
	add_child(cs)
	_pas = Node3D.new()
	_pas.position = Vector3(0, alto, 0.25)
	add_child(Fase.so_enfeite(_pas))
	for i in 4:
		var braco := Node3D.new()
		braco.rotation.z = i * PI / 2.0
		_pas.add_child(braco)
		var pa := MeshInstance3D.new()
		var forma_pa := PrismMesh.new()
		forma_pa.size = Vector3(0.9, 1.5, 0.06)
		forma_pa.left_to_right = 1.0
		pa.mesh = forma_pa
		var m := StandardMaterial3D.new()
		m.albedo_color = Color("ff7a22") if i % 2 == 0 else Color("fff8ee")
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		pa.material_override = m
		pa.position = Vector3(0.22, 0.8, 0)
		braco.add_child(pa)
	var miolo := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 0.22
	esfera.height = 0.44
	miolo.mesh = esfera
	var amarelo := StandardMaterial3D.new()
	amarelo.albedo_color = Color("ffd23f")
	miolo.material_override = amarelo
	_pas.add_child(miolo)


func receber_golpe(_dano: int, _de: Vector3, _forca := 6.0, _tipo := "") -> bool:
	if girando:
		return false
	girar()
	return true


## Começa a girar (cada vez mais rápido), com confete e o "fiu".
func girar() -> void:
	girando = true
	Fx.confetti(get_parent(), _pas.global_position, 16, 2.5)
	Sfx.play_at(get_parent(), "ui_ok", global_position, -2.0)
	Sfx.play_at(get_parent(), "vento", _pas.global_position, -4.0, 0.1)
	girou.emit(self)


func _process(delta: float) -> void:
	_tempo += delta
	_velocidade = move_toward(_velocidade, 9.0 if girando else 0.0, delta * 6.0)
	_pas.rotation.z -= _velocidade * delta
	if not girando:
		# Parado, balança um tiquinho, chamando o soco.
		_pas.rotation.z = sin(_tempo * 2.0) * 0.06
