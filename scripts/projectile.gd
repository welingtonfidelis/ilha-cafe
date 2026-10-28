class_name Projectile
extends Area3D
## Ataques à distância dos esqueletos.
## - Flecha de ventosa (Skeleton_Rogue): reta e rápida; dá para desviar andando de lado.
## - Bolha mágica (Skeleton_Mage): lenta, persegue de leve e estoura com um tiro.
## - Dardo de espuma (Esqueleto Pistoleiro): o projétil do Blaster Kit, reto e mais rápido que a flecha, em
##   rajadas de três.

enum Kind { FLECHA, BOLHA, DARDO }

const DART := "res://assets/weapons/bullet-foam-tip.glb"

var kind := Kind.FLECHA
var direction := Vector3.FORWARD
var speed := 15.0
var target: Node3D
var turn_rate := 0.0
var life := 4.0
var damage := 1

var _popped := false


static func create(p_kind: Kind, from: Vector3, p_target: Node3D) -> Projectile:
	var p := Projectile.new()
	p.kind = p_kind
	p.target = p_target
	p.position = from
	p.direction = (aim_at(p_target) - from).normalized()
	if p_kind == Kind.BOLHA:
		p.speed = 4.5
		p.turn_rate = 1.1
		p.life = 6.0
	elif p_kind == Kind.DARDO:
		p.speed = 17.0
		p.life = 2.5
	return p


## Ponto onde mirar: o peito do aventureiro (ou o piloto, se ele está dirigindo).
static func aim_at(t: Node3D) -> Vector3:
	return (t as Player).aim_point() if t is Player else t.global_position + Vector3.UP * 1.2


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | (1 << 1)  # mundo e jogador
	monitoring = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.4 if kind == Kind.BOLHA else 0.22
	shape.shape = sphere
	add_child(shape)
	match kind:
		Kind.FLECHA:
			_build_arrow()
		Kind.BOLHA:
			_build_bubble()
		Kind.DARDO:
			# O dardo do Blaster Kit é pequenino e em pé (+Y): deitado para a frente (-Z) e bem maior.
			var dart: Node3D = load(DART).instantiate()
			dart.scale = Vector3.ONE * 6.0
			dart.rotation_degrees.x = -90.0
			add_child(dart)
	body_entered.connect(_on_body_entered)


func _build_arrow() -> void:
	var visual := Node3D.new()
	add_child(visual)
	# A flecha aponta para -Z (frente da Godot), porque o nó vira com look_at.
	var shaft := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.025
	cyl.bottom_radius = 0.025
	cyl.height = 0.75
	cyl.material = Fx.flat_material(Color("#c98b4a"), false)
	shaft.mesh = cyl
	shaft.rotation_degrees.x = 90.0
	visual.add_child(shaft)
	var cup := MeshInstance3D.new()
	var cup_mesh := SphereMesh.new()
	cup_mesh.radius = 0.09
	cup_mesh.height = 0.1
	cup_mesh.material = Fx.flat_material(Color("#ff5d8f"), false)
	cup.mesh = cup_mesh
	cup.position.z = -0.4
	visual.add_child(cup)
	for side in [-1.0, 1.0]:
		var fin := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.14, 0.02, 0.14)
		box.material = Fx.flat_material(Color.WHITE, false)
		fin.mesh = box
		fin.position = Vector3(0, 0, 0.33)
		fin.rotation_degrees.z = 45.0 * side
		visual.add_child(fin)


func _build_bubble() -> void:
	var ball := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.38
	mesh.height = 0.76
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.6, 0.9, 0.45)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.rim_enabled = true
	mat.rim = 1.0
	mat.emission_enabled = true
	mat.emission = Color("#ff9be6")
	mat.emission_energy_multiplier = 0.6
	mesh.material = mat
	ball.mesh = mesh
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ball)
	# A bolha também é alvo: um tiro estoura.
	var hb := Hurtbox.new()
	hb.region = "bolha"
	hb.owner_target = self
	var cs := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	cs.shape = sphere
	hb.add_child(cs)
	add_child(hb)


func _physics_process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		pop()
		return
	if turn_rate > 0.0 and is_instance_valid(target):
		var desired := (aim_at(target) - global_position).normalized()
		direction = direction.slerp(desired, minf(1.0, turn_rate * delta)).normalized()
	global_position += direction * speed * delta
	if kind != Kind.BOLHA:
		var up := Vector3.UP if absf(direction.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		look_at(global_position + direction, up)
	else:
		scale = Vector3.ONE * (1.0 + 0.06 * sin(life * 9.0))


func _on_body_entered(body: Node) -> void:
	if _popped:
		return
	var hit: Player = body as Player
	# Dirigindo, o aventureiro fica escondido sem colisão: quem leva a flecha é o veículo, e o golpe vai para
	# quem está nele.
	if body is Kart:
		hit = (body as Kart).driver
	if is_instance_valid(hit):
		hit.take_damage(damage, global_position - direction, ["flecha", "bolha", "dardo"][kind])
	pop()


## Chamado pela Hurtbox da bolha quando o jogador acerta um tiro nela.
func take_hit(_amount: float, _point: Vector3, _hb: Hurtbox) -> void:
	Fx.popup_text(get_parent(), global_position + Vector3.UP * 0.4, "plof!", Color("#ffd6f3"))
	pop()


func pop() -> void:
	if _popped:
		return
	_popped = true
	if kind == Kind.BOLHA:
		Fx.bubble_pop(get_parent(), global_position)
		Sfx.play_at(get_parent(), "estouro", global_position)
	else:
		Fx.dust(get_parent(), global_position)
		Sfx.play_at(get_parent(), "ventosa", global_position)
	queue_free()
