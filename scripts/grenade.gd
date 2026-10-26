class_name Grenade
extends RigidBody3D
## Granada Brigadeiro: sai da mão em arco, quica e explode em confete depois do pavio.
## Desmonta esqueletos perto (mais dano no centro), tira um bom pedaço da vida dos chefes e estoura bolhas
## mágicas. O escudo não segura.

var thrower: Node3D
var _time := 0.0
var _exploded := false


static func create(from: Vector3, velocity: Vector3, p_thrower: Node3D) -> Grenade:
	var g := Grenade.new()
	g.position = from
	g.linear_velocity = velocity
	g.thrower = p_thrower
	return g


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1  # só o mundo: passa por esqueletos e pelo jogador
	gravity_scale = 2.0
	angular_velocity = Vector3(randf_range(-8, 8), randf_range(-8, 8), randf_range(-8, 8))
	var mat := PhysicsMaterial.new()
	mat.bounce = 0.35
	mat.friction = 0.8
	physics_material_override = mat
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.18
	shape.shape = sphere
	add_child(shape)
	var model: Node3D = load(Weapons.MODEL_DIR % Weapons.GRENADE.modelo).instantiate()
	model.scale = Vector3.ONE * 1.6
	model.position.y = -0.18
	add_child(model)


func _physics_process(delta: float) -> void:
	_time += delta
	if _time >= Weapons.GRENADE.pavio and not _exploded:
		explode()


func explode() -> void:
	_exploded = true
	var center := global_position
	var world := get_parent()
	var radius: float = Weapons.GRENADE.raio
	Fx.confetti(world, center + Vector3.UP * 0.3, 110, 9.0)
	Fx.shockwave(world, center, radius)
	Sfx.play_at(world, "granada", center)
	if thrower is Player:
		(thrower as Player).rumble(0.5, 0.5, 0.2)
	for node in world.get_children():
		if node is SkeletonEnemy:
			var e := node as SkeletonEnemy
			var dist := e.global_position.distance_to(center)
			if dist <= radius:
				e.take_explosion(lerpf(Weapons.GRENADE.dano, Weapons.GRENADE.dano_borda, dist / radius), center)
		elif node is Boss:
			# Chefe é grande: conta a distância até a borda do corpo, não até o centro.
			var b := node as Boss
			var flat := Vector2(b.global_position.x - center.x, b.global_position.z - center.z).length()
			var dist := maxf(flat - 0.5 * b.body_scale, 0.0)
			if dist <= radius and absf(b.global_position.y - center.y) < 3.0 * b.body_scale:
				b.take_explosion(lerpf(Weapons.GRENADE.dano_chefe, Weapons.GRENADE.dano_borda, dist / radius), center)
		elif node is Projectile and node.kind == Projectile.Kind.BOLHA:
			if node.global_position.distance_to(center) <= radius:
				node.pop()
		elif node is BossMestre.ShieldBubble:
			if node.global_position.distance_to(center) <= radius:
				node.pop()
	queue_free()
