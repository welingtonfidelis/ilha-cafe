class_name RewardPickup
extends Area3D
## Recompensa de uma região vencida, flutuando e girando sobre um anel dourado:
## um blaster novo (kind = id do blaster) ou um coração a mais no máximo (kind = "coracao").
## Quem aplica o efeito é a história (sinal `collected`).

signal collected(pickup: RewardPickup)

const HEART := "res://assets/props/platformer/red/heart_red.gltf"

var kind := "coracao"
var _visual: Node3D
var _time := 0.0
var _taken := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1  # jogador
	monitoring = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.6
	shape.shape = sphere
	shape.position.y = 1.2
	add_child(shape)
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 1.1
	torus.outer_radius = 1.4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#ffd23f")
	mat.emission_enabled = true
	mat.emission = Color("#ffd23f")
	mat.emission_energy_multiplier = 1.2
	torus.material = mat
	ring.mesh = torus
	ring.scale = Vector3(1, 0.4, 1)
	ring.position.y = 0.1
	add_child(ring)
	var light := OmniLight3D.new()
	light.light_color = Color("#ffe39a")
	light.light_energy = 2.0
	light.omni_range = 5.0
	light.position.y = 1.5
	add_child(light)
	_visual = Node3D.new()
	_visual.position.y = 1.5
	add_child(_visual)
	if kind == "coracao":
		var heart: Node3D = load(HEART).instantiate()
		heart.scale = Vector3.ONE * 1.1
		_visual.add_child(heart)
	else:
		var def := Weapons.get_def(Weapons.index_of(kind))
		var gun: Node3D = load(Weapons.MODEL_DIR % def.modelo).instantiate()
		gun.scale = Vector3.ONE * 2.4
		_visual.add_child(gun)
	var label := Label3D.new()
	label.text = "+1 coração" if kind == "coracao" else Weapons.get_def(Weapons.index_of(kind)).nome
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 64
	label.outline_size = 14
	label.pixel_size = 0.006
	label.modulate = Color("#ffd23f")
	label.position.y = 3.2
	add_child(label)


func _physics_process(delta: float) -> void:
	_time += delta
	_visual.rotation.y += delta * 1.6
	_visual.position.y = 1.5 + sin(_time * 2.4) * 0.15
	if _taken or _time < 0.6:
		return
	for body in get_overlapping_bodies():
		if body is Player and not (body as Player).dizzy:
			_taken = true
			Fx.confetti(get_parent(), global_position + Vector3.UP * 1.5, 60, 5.0)
			Sfx.play(get_parent(), "bandeira")
			collected.emit(self)
			queue_free()
			return
