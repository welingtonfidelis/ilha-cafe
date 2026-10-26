class_name Kart
extends CharacterBody3D
## Veículo de corrida (Car Kit do Kenney, CC0; pedidos do usuário em 2026-10-26): kart ou carro de corrida.
## Estacionado, fica vazio (o piloto do modelo do kart é escondido) e é um obstáculo como qualquer outro.
## Quem entra aparece no lugar do piloto da cintura para cima (o próprio modelo do aventureiro, com pernas e
## mochila escondidas), na pose de segurar o volante (Holding_A, com o respirar dela). A primeira versão
## mostrava só a cabeça, num esqueleto parado na pose de T: tinha falhas e parecia flutuar; um capacete
## montado por código também não agradou. Controle de fliperama: frente / RT acelera, trás / LT freia e dá ré, esquerda e direita viram
## (mais devagar parado). As rodas giram e as da frente esterçam. Bater de frente em parede segura o carro e
## faz "bonk". A câmera vai atrás. O modelo olha para +Z.

const MODELS := "res://assets/carros/%s.glb"
const REVERSE := 5.0
const ACCEL := 9.0
const BRAKE := 18.0
const DRAG := 3.0
const TURN := 2.3

@export var model_name := "kart-oopi"
@export var model_scale := 1.6
## Cor da carroceria (multiplica a textura; branco é a cor original).
@export var tint := Color.WHITE
## Onde o piloto senta (x e z do assento, y é a altura do banco, onde fica a cintura) e o tamanho dele.
@export var driver_spot := Vector3(0, 0.42, -0.15)
@export var driver_scale := 0.75
@export var max_speed := 17.0
@export var display_name := "Kart"

var speed := 0.0
var camera: Camera3D
var driving := false
## Lugar no box; volta para cá quando o aventureiro desce longe ou sai da pista.
var home := Transform3D.IDENTITY
var input_enabled := true
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0
var _visual: Node3D
var _bump := 0.0
var _steer := 0.0
var _head: Node3D
var _wheels: Array[MeshInstance3D] = []
var _wheel_base: Array[Basis] = []
var _wheel_radius := 0.3
var _spin := 0.0
## Giro e altura da câmera em volta do veículo (analógico direito ou mouse); voltam ao normal depois de soltar.
var _cam_yaw := 0.0
var _cam_pitch := 0.0
var _cam_idle := 10.0
const CAM_STICK := Vector2(2.6, 1.6)
const CAM_MOUSE := 0.004


func _ready() -> void:
	collision_mask = 1 | Townsperson.LAYER
	floor_snap_length = 0.4
	_visual = Node3D.new()
	add_child(_visual)
	var model: Node3D = load(MODELS % model_name).instantiate()
	model.scale = Vector3.ONE * model_scale
	_visual.add_child(model)
	var box := AABB()
	var first := true
	for m in model.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.name == "character":
			mi.visible = false
			continue
		if String(mi.name).begins_with("wheel"):
			_wheels.append(mi)
			_wheel_base.append(mi.basis)
			_wheel_radius = mi.get_aabb().size.y * 0.5 * model_scale
			continue
		if tint != Color.WHITE and mi.mesh.get_surface_count() > 0:
			var mat := mi.mesh.surface_get_material(0)
			if mat is StandardMaterial3D:
				var copy: StandardMaterial3D = mat.duplicate()
				copy.albedo_color = tint
				mi.material_override = copy
		var a: AABB = mi.transform * mi.get_aabb()
		box = a if first else box.merge(a)
		first = false
	# Cápsula deitada: passa liso pelas emendas das peças da pista (uma caixa engancha nelas).
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = clampf(box.size.x * model_scale * 0.5, 0.45, 0.65)
	capsule.height = maxf(box.size.z * model_scale, capsule.radius * 2.0 + 0.1)
	shape.shape = capsule
	shape.rotation_degrees.x = 90.0
	shape.position = Vector3(0, capsule.radius, box.get_center().z * model_scale)
	add_child(shape)
	camera = Camera3D.new()
	camera.fov = 72.0
	camera.top_level = true
	add_child(camera)
	park()


func forward() -> Vector3:
	return global_basis.z


## Estaciona: sem piloto, parado e na camada do mundo (o aventureiro esbarra).
func park() -> void:
	driving = false
	speed = 0.0
	velocity = Vector3.ZERO
	collision_layer = 1
	set_physics_process(false)
	if is_instance_valid(_head):
		_head.queue_free()
	_head = null
	_steer = 0.0
	_pose_wheels()


## Começa a dirigir, com o aventureiro (char_path: o .glb do personagem) no lugar do piloto.
func drive(char_path: String) -> void:
	driving = true
	speed = 0.0
	collision_layer = 1 << 1
	set_physics_process(true)
	_head = load(char_path).instantiate()
	_head.name = "PilotoNoBanco"
	for m in _head.find_children("*", "MeshInstance3D", true, false):
		var n := String(m.name)
		(m as Node3D).visible = not (n.contains("Leg") or n.contains("Backpack"))
	_head.scale = Vector3.ONE * driver_scale
	# A cintura do KayKit fica a 0,45 do chão do modelo: ela vai na altura do banco.
	_head.position = driver_spot - Vector3(0, 0.45 * driver_scale, 0)
	_visual.add_child(_head)
	var ap := AnimUtil.make_player(_head, ["ferramentas"])
	ap.play(&"ferramentas/Holding_A")
	_cam_yaw = 0.0
	_cam_pitch = 0.0
	_place_camera(1.0)


func go_home() -> void:
	global_transform = home
	park()


func is_home() -> bool:
	return global_position.distance_to(home.origin) < 0.5


func _physics_process(delta: float) -> void:
	var throttle := 0.0
	var brake := 0.0
	var steer := 0.0
	if input_enabled:
		throttle = maxf(Input.get_action_strength("frente"), Input.get_action_strength("atirar"))
		brake = maxf(Input.get_action_strength("tras"), Input.get_action_strength("mirar"))
		steer = Input.get_action_strength("esquerda") - Input.get_action_strength("direita")
	if throttle > 0.0:
		speed = minf(speed + ACCEL * throttle * delta, max_speed)
	elif brake > 0.0:
		speed = maxf(speed - (BRAKE if speed > 0.0 else ACCEL * 0.6) * brake * delta, -REVERSE)
	else:
		speed = move_toward(speed, 0.0, (DRAG + absf(speed) * 0.1) * delta)
	# Virar depende da velocidade (parado não gira); de ré, o volante inverte.
	var grip := clampf(absf(speed) / 6.0, 0.0, 1.0)
	rotation.y += steer * TURN * grip * signf(speed if speed != 0.0 else 1.0) * delta
	var fwd := forward()
	fwd.y = 0.0
	fwd = fwd.normalized()
	velocity.x = fwd.x * speed
	velocity.z = fwd.z * speed
	if is_on_floor():
		velocity.y = -0.5
	else:
		velocity.y -= _gravity * delta
	move_and_slide()
	# Bateu de frente em parede (contato acima do asfalto, não nas emendas do chão): perde velocidade e dá
	# um tranco.
	_bump = maxf(_bump - delta, 0.0)
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var high := c.get_position().y > global_position.y + 0.2
		if high and absf(c.get_normal().y) < 0.5 and c.get_normal().dot(fwd * signf(speed)) < -0.5 and absf(speed) > 3.0 and _bump <= 0.0:
			speed *= 0.35
			_bump = 0.4
			Sfx.play_at(get_parent(), "bonk", global_position + Vector3.UP, -2.0)
	# Balanço do corpo: inclina para fora na curva e empina um pouco ao acelerar.
	_visual.rotation.z = lerpf(_visual.rotation.z, -steer * grip * 0.08, 1.0 - exp(-8.0 * delta))
	_visual.rotation.x = lerpf(_visual.rotation.x, -throttle * 0.03 + brake * 0.04, 1.0 - exp(-6.0 * delta))
	_steer = lerpf(_steer, steer, 1.0 - exp(-10.0 * delta))
	if input_enabled:
		var look := Input.get_vector("olhar_esquerda", "olhar_direita", "olhar_cima", "olhar_baixo")
		if look.length() > 0.1:
			_cam_idle = 0.0
			_cam_yaw -= look.x * CAM_STICK.x * delta
			_cam_pitch = clampf(_cam_pitch - look.y * CAM_STICK.y * delta, -0.35, 0.9)
	_cam_idle += delta
	if _cam_idle > 1.5:
		_cam_yaw = lerp_angle(_cam_yaw, 0.0, 1.0 - exp(-2.0 * delta))
		_cam_pitch = lerpf(_cam_pitch, 0.0, 1.0 - exp(-2.0 * delta))
	_spin += speed / maxf(_wheel_radius, 0.1) * delta
	_pose_wheels()
	_place_camera(delta)


## Rodas: giram com a velocidade; as da frente (z > 0) esterçam.
func _pose_wheels() -> void:
	for k in _wheels.size():
		var w := _wheels[k]
		var turn := Basis(Vector3.UP, _steer * 0.45) if w.position.z > 0.0 else Basis.IDENTITY
		w.basis = turn * _wheel_base[k] * Basis(Vector3.RIGHT, _spin)


func _unhandled_input(event: InputEvent) -> void:
	if driving and input_enabled and event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_cam_idle = 0.0
		_cam_yaw -= event.relative.x * CAM_MOUSE
		_cam_pitch = clampf(_cam_pitch + event.relative.y * CAM_MOUSE, -0.35, 0.9)


func _place_camera(delta: float) -> void:
	if not is_instance_valid(camera):
		return
	var fwd := forward()
	fwd.y = 0.0
	fwd = fwd.normalized().rotated(Vector3.UP, _cam_yaw)
	var back := -fwd * 6.5 * cos(_cam_pitch * 0.8) + Vector3.UP * (3.0 + 6.0 * sin(_cam_pitch))
	var want := global_position + back
	var k := 1.0 - exp(-6.0 * delta)
	camera.global_position = camera.global_position.lerp(want, k) if delta < 1.0 else want
	camera.look_at(global_position + fwd * (3.0 if _cam_idle > 1.5 else 1.0) + Vector3.UP * 1.0)
