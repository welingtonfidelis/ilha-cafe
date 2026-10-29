class_name Tocha
extends StaticBody3D
## Tocha num pedestal de pedra (peças do Dungeon Pack), a novidade dos Túneis do Morro (1-2). Começa
## apagada, cinzinha; o laser dos pés acende (flutuar em cima dela): a chama aparece balançando e a luz
## laranja clareia em volta. Como a flor de luz, o corpo que o laser enxerga fica na camada da luz, e o
## pedestal é sólido à parte. Algumas fazem coisas quando acendem (abrir porta, subir ponte): quem cuida
## é a fase, pelo sinal `acesa`.

signal acesa(tocha: Tocha)

## Altura da chama acima do pé da tocha (o pedestal tem 1,54 m).
const CHAMA := 1.4
const COR_LUZ := Color("ffb35c")
const ENERGIA := 2.6

## Para a fase: já começa acesa (enfeite que os Ossinhos deixaram queimando).
var acesa_no_comeco := false
## Sem o pedestal (em cima de caixotes ou de um pilar, a tocha fica direto no chão de lá).
var com_pedestal := true
var esta_acesa := false
var _tocha: Node3D
var _chama: MeshInstance3D
var _mat_chama: StandardMaterial3D
var _luz: OmniLight3D
var _tempo := 0.0
var _base := 0.0
## De 0 a 1 enquanto a chama pega (a luz cresce junto).
var _forca := 0.0


func _ready() -> void:
	collision_layer = Fase.CAMADA_LUZ
	collision_mask = 0
	_tempo = randf() * 5.0
	_base = 1.54 if com_pedestal else 0.0
	if com_pedestal:
		var pedestal: Node3D = load(Fase.MASMORRA + "column.gltf").instantiate()
		pedestal.scale = Vector3.ONE * 1.1
		add_child(pedestal)
		var solido := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var cil := CylinderShape3D.new()
		cil.radius = 0.42
		cil.height = _base
		cs.shape = cil
		cs.position.y = _base * 0.5
		solido.add_child(cs)
		add_child(solido)
	_trocar_modelo("torch")
	# O que o laser acende: uma bola larga em volta da chama, para não precisar acertar em cheio.
	var cs := CollisionShape3D.new()
	var esfera := SphereShape3D.new()
	esfera.radius = 0.8
	cs.shape = esfera
	cs.position.y = _base + CHAMA - 0.2
	add_child(cs)
	_mat_chama = StandardMaterial3D.new()
	_mat_chama.albedo_color = Color("ffcf5a")
	_mat_chama.emission_enabled = true
	_mat_chama.emission = Color("ff9a2e")
	_mat_chama.emission_energy_multiplier = 4.0
	_chama = MeshInstance3D.new()
	_chama.mesh = Forma.superelipsoide(Vector3(0.24, 0.38, 0.24), 1.0, 0.7)
	_chama.material_override = _mat_chama
	_chama.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_chama.position.y = _base + CHAMA
	_chama.visible = false
	add_child(_chama)
	_luz = OmniLight3D.new()
	_luz.light_color = COR_LUZ
	_luz.light_energy = 0.0
	_luz.omni_range = 11.0
	_luz.position.y = _base + CHAMA + 0.4
	_luz.visible = false
	add_child(_luz)
	if acesa_no_comeco:
		acender(true)


func _process(delta: float) -> void:
	if not esta_acesa:
		return
	_tempo += delta
	var tremor := sin(_tempo * 11.0) * 0.06 + sin(_tempo * 17.0) * 0.04
	if _forca >= 1.0:
		_chama.scale = Vector3(1.0 - tremor * 0.5, 1.0 + tremor, 1.0 - tremor * 0.5)
	else:
		_chama.scale = Vector3.ONE * maxf(_forca, 0.1)
	_luz.light_energy = ENERGIA * _forca * (1.0 + tremor * 0.8)


## Acende (pelo laser, ou já no começo com `sem_festa`). Acender de novo não faz nada.
func acender(sem_festa := false) -> void:
	if esta_acesa:
		return
	esta_acesa = true
	_trocar_modelo("torch_lit")
	_chama.visible = true
	_luz.visible = true
	if sem_festa:
		_forca = 1.0
		return
	_chama.scale = Vector3.ONE * 0.1
	create_tween().tween_property(self, "_forca", 1.0, 0.5)
	Fx.confetti(self, global_position + Vector3.UP * (_base + CHAMA), 12, 2.0)
	acesa.emit(self)


## Onde fica a chama (para os testes e as fotos).
func ponto_da_chama() -> Vector3:
	return global_position + Vector3.UP * (_base + CHAMA)


func _trocar_modelo(nome: String) -> void:
	if _tocha:
		_tocha.queue_free()
	_tocha = load(Fase.MASMORRA + nome + ".gltf").instantiate()
	_tocha.scale = Vector3.ONE * 1.3
	_tocha.position.y = _base + 0.52
	add_child(_tocha)
	if nome == "torch":
		var cinza := StandardMaterial3D.new()
		cinza.albedo_color = Color("6a6478")
		cinza.roughness = 0.9
		for mi in _tocha.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_override = cinza
