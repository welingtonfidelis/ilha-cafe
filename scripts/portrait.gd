class_name Portrait
extends SubViewportContainer
## Retrato vivo de um personagem para os menus (escolha de personagem e pausa): o boneco 3D de verdade num
## mundinho próprio, com fundo colorido, parado respirando ou dando tchau. Menino e menina são os .glb do
## Player; o Faísca é o Robo montado por código. Os modelos ficam guardados: trocar de um para outro (a pausa
## mostra quem está jogando) não carrega de novo. Escondido, o boneco para de animar.

const BACKGROUNDS := {
	"menino": Color("#8fd0ff"),
	"menina": Color("#ffb3d9"),
	"faisca": Color("#ffbf80"),
}
## Câmera de cada um: altura de onde olha, distância e altura do ponto que ela mira.
const FRAMING := {
	"menino": [1.4, 5.2, 1.15],
	"menina": [1.4, 5.2, 1.15],
	"faisca": [1.35, 5.4, 1.1],
}

var key := ""
var _viewport: SubViewport
var _env: Environment
var _camera: Camera3D
var _stage: Node3D
var _models := {}
var _players := {}
var _cheering := false


func _init(side := Vector2(220, 240)) -> void:
	custom_minimum_size = side
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	add_child(_viewport)
	var world := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color(0.9, 0.9, 1.0)
	_env.ambient_light_energy = 0.75
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = _env
	_viewport.add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 30, 0)
	sun.light_energy = 1.1
	_viewport.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -140, 0)
	fill.light_energy = 0.35
	_viewport.add_child(fill)
	_camera = Camera3D.new()
	_camera.fov = 30.0
	_viewport.add_child(_camera)
	_stage = Node3D.new()
	# Um pouco de lado, de três quartos, como numa figurinha.
	_stage.rotation.y = 0.35
	_viewport.add_child(_stage)
	# Sombrinha redonda debaixo dos pés.
	var shadow := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.75
	disc.bottom_radius = 0.75
	disc.height = 0.01
	shadow.mesh = disc
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0, 0, 0, 0.18)
	shadow.material_override = m
	_viewport.add_child(shadow)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and _stage:
		_stage.process_mode = Node.PROCESS_MODE_INHERIT if is_visible_in_tree() else Node.PROCESS_MODE_DISABLED


## Mostra o personagem ("menino", "menina" ou "faisca"). Só com o retrato já na árvore (o Robo se monta no _ready).
func show_character(char_key: String) -> void:
	if char_key == key:
		return
	key = char_key
	for k in _models:
		_models[k].visible = k == key
	if not _models.has(key):
		_models[key] = _build_model(key)
		_stage.add_child(_models[key])
	_env.background_color = BACKGROUNDS.get(key, Color("#8fd0ff"))
	var f: Array = FRAMING.get(key, FRAMING.menino)
	_camera.position = Vector3(0, f[0], f[1])
	_camera.look_at(Vector3(0, f[2], 0))
	_animate()


## Dando tchau (cartão marcado) ou parado respirando.
func cheer(on: bool) -> void:
	if on != _cheering:
		_cheering = on
		_animate()


func _animate() -> void:
	var anim := "festa/Waving" if _cheering else "geral/Idle_A"
	if _models.get(key) is Robo:
		(_models[key] as Robo).animar(anim, 0.25)
	elif _players.has(key):
		var ap: AnimationPlayer = _players[key]
		ap.play(anim, 0.25)


func _build_model(char_key: String) -> Node3D:
	if char_key == "faisca":
		return Robo.new()
	var model: Node3D = load(Player.CHARACTERS.get(char_key, Player.CHARACTERS.menino)).instantiate()
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		for hint in Player.HIDDEN_MESH_HINTS:
			if hint in mi.name:
				mi.visible = false
	_players[char_key] = AnimUtil.make_player(model, ["geral", "festa"])
	return model
