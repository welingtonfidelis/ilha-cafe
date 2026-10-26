class_name Fx
extends RefCounted
## Efeitos rápidos criados por código: confete, rastro do tiro, clarão e texto flutuante.
## Seguem as regras de tom: impacto vira confete e faísca, nunca ferimento.

const CONFETTI_COLORS := [
	Color("#ff5d8f"), Color("#ffd23f"), Color("#3bceac"),
	Color("#5e9cff"), Color("#b18cff"), Color("#ff8c42"),
]


static func confetti(parent: Node, pos: Vector3, amount: int = 24, strength: float = 4.0) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.9
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = strength * 0.5
	p.initial_velocity_max = strength
	p.gravity = Vector3(0, -9.0, 0)
	p.particle_flag_rotate_y = true
	p.angular_velocity_min = -720.0
	p.angular_velocity_max = 720.0
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.09, 0.09, 0.02)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	p.mesh = mesh
	var ramp := Gradient.new()
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in CONFETTI_COLORS.size():
		offsets.append(float(i) / CONFETTI_COLORS.size())
		colors.append(CONFETTI_COLORS[i])
	ramp.offsets = offsets
	ramp.colors = colors
	p.color_initial_ramp = ramp
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


## Poeirinha cinza quando o tiro acerta cenário.
static func dust(parent: Node, pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 8
	p.lifetime = 0.4
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 0.8
	p.initial_velocity_max = 1.6
	p.gravity = Vector3.ZERO
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.9, 0.85)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	p.mesh = mesh
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


static func tracer(parent: Node, from: Vector3, to: Vector3, color: Color) -> void:
	var length := from.distance_to(to)
	if length < 0.05:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.05, 0.05, length)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = color
	mesh.material = mat
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = (from + to) * 0.5
	var dir := (to - from).normalized()
	var up := Vector3.UP if absf(dir.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	mi.look_at(to, up)
	var tw := mi.create_tween()
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.12)
	tw.tween_callback(mi.queue_free)


static func muzzle_flash(at: Node3D) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color("#ffd27a")
	light.light_energy = 4.0
	light.omni_range = 3.0
	var mesh := SphereMesh.new()
	mesh.radius = 0.09
	mesh.height = 0.18
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color("#fff3a0")
	mesh.material = mat
	var ball := MeshInstance3D.new()
	ball.mesh = mesh
	ball.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	at.add_child(light)
	at.add_child(ball)
	var tw := light.create_tween()
	tw.tween_interval(0.05)
	tw.tween_callback(light.queue_free)
	tw.tween_callback(ball.queue_free)


## Estrela de 5 pontas com volume (estrelinhas de tonto).
static func star_mesh(radius := 0.16, inner := 0.07, depth := 0.06) -> ArrayMesh:
	var outline: Array[Vector2] = []
	for i in 10:
		var a := PI / 2.0 + i * PI / 5.0
		outline.append(Vector2(cos(a), sin(a)) * (radius if i % 2 == 0 else inner))
	return _pillow_mesh(outline, depth)


## Coração com volume (vida e coração que cai dos esqueletos).
static func heart_mesh(size := 0.35, depth := 0.16) -> ArrayMesh:
	var outline: Array[Vector2] = []
	for i in 40:
		var t := TAU * i / 40.0
		var x := 16.0 * pow(sin(t), 3)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		outline.append(Vector2(x, y) * (size / 17.0))
	return _pillow_mesh(outline, depth)


## Contorno 2D vira um "travesseiro": leque de triângulos com o centro estufado na frente e atrás.
static func _pillow_mesh(outline: Array[Vector2], depth: float) -> ArrayMesh:
	var center := Vector2.ZERO
	for p in outline:
		center += p
	center /= outline.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [1.0, -1.0]:
		var tip := Vector3(center.x, center.y, side * depth * 0.5)
		for i in outline.size():
			var a := outline[i]
			var b := outline[(i + 1) % outline.size()]
			st.add_vertex(tip)
			if side > 0.0:
				st.add_vertex(Vector3(a.x, a.y, 0))
				st.add_vertex(Vector3(b.x, b.y, 0))
			else:
				st.add_vertex(Vector3(b.x, b.y, 0))
				st.add_vertex(Vector3(a.x, a.y, 0))
	st.generate_normals()
	return st.commit()


static func flat_material(color: Color, unshaded := true) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat


## Leva um esqueleto (ou parte da Torre) embora de balão: três balões enchem sobre a cabeça,
## ele acena e sobe em zigue-zague até sumir em confete. O nó deve estar solto no mundo.
static func balloon_away(node: Node3D, ap: AnimationPlayer, head_height := 2.6) -> void:
	var balloons := balloons(head_height)
	balloons.scale = Vector3.ONE * 0.01
	node.add_child(balloons)
	var world := node.get_parent()
	var tw := node.create_tween()
	tw.tween_property(balloons, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		Sfx.play_at(world, "balao", node.global_position + Vector3.UP * 3.0)
		if is_instance_valid(ap) and ap.has_animation(&"festa/Waving"):
			ap.play(&"festa/Waving", 0.3)
		popup_text(world, node.global_position + Vector3.UP * 3.2, "Tchau!", Color("#ffd6f3")))
	tw.tween_property(node, "position:y", node.position.y + 22.0, 6.0).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(node, "rotation:z", 0.12, 1.5).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		confetti(world, node.global_position + Vector3.UP * 4.0, 30, 3.0)
		node.queue_free())


## Três balões coloridos (bolas do Platformer Pack, um pouco esticadas) com cordinhas até um nó acima da
## cabeça (head_height). Devolve o nó, ainda solto.
static func balloons(head_height := 2.6) -> Node3D:
	var node := Node3D.new()
	node.name = "Baloes"
	node.position.y = head_height
	var colors := ["red/ball_red", "blue/ball_blue", "yellow/ball_yellow", "green/ball_green"]
	colors.shuffle()
	var spots := [Vector3(0, 2.2, 0), Vector3(-0.7, 1.7, 0.25), Vector3(0.7, 1.75, -0.2)]
	var string_mat := flat_material(Color.WHITE, false)
	for k in 3:
		var ball: Node3D = load("res://assets/props/platformer/%s.gltf" % colors[k]).instantiate()
		ball.scale = Vector3(0.42, 0.5, 0.42)
		ball.position = spots[k]
		node.add_child(ball)
		var bottom: Vector3 = spots[k] - Vector3(0, 0.5, 0)
		var cord := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.015
		cyl.bottom_radius = 0.015
		cyl.height = bottom.length()
		cyl.material = string_mat
		cord.mesh = cyl
		cord.transform = Transform3D(Basis(Quaternion(Vector3.UP, bottom.normalized())), bottom * 0.5)
		node.add_child(cord)
	return node


## Fogos de artifício (epílogo à noite): um rojão sobe com rastro e estoura numa esfera de faíscas
## coloridas que caem devagar, com um clarão que pinta a praça da cor do estouro.
static func firework(parent: Node, from: Vector3, height: float, color: Color) -> void:
	var rocket := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	sphere.material = glow_material(Color(1.0, 0.9, 0.7), 4.0)
	rocket.mesh = sphere
	rocket.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(rocket)
	rocket.global_position = from
	var trail := CPUParticles3D.new()
	trail.amount = 24
	trail.lifetime = 0.5
	trail.local_coords = false
	trail.direction = Vector3.DOWN
	trail.spread = 12.0
	trail.initial_velocity_min = 0.5
	trail.initial_velocity_max = 1.5
	trail.gravity = Vector3(0, -2.0, 0)
	trail.scale_amount_min = 0.5
	trail.scale_amount_max = 1.0
	var spark := SphereMesh.new()
	spark.radius = 0.05
	spark.height = 0.1
	spark.material = glow_material(Color(1.0, 0.8, 0.5), 3.0)
	trail.mesh = spark
	rocket.add_child(trail)
	var top := from + Vector3(randf_range(-2.0, 2.0), height, randf_range(-2.0, 2.0))
	var tw := rocket.create_tween()
	tw.tween_property(rocket, "global_position", top, 1.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func() -> void:
		_burst(parent, rocket.global_position, color)
		rocket.queue_free())


static func _burst(parent: Node, pos: Vector3, color: Color) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 120
	p.lifetime = 1.9
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 9.0
	p.initial_velocity_max = 12.0
	p.damping_min = 2.5
	p.damping_max = 3.5
	p.gravity = Vector3(0, -2.5, 0)
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(0.7, 0.8))
	curve.add_point(Vector2(1.0, 0.0))
	p.scale_amount_curve = curve
	var mesh := SphereMesh.new()
	mesh.radius = 0.2
	mesh.height = 0.4
	mesh.radial_segments = 6
	mesh.rings = 3
	mesh.material = glow_material(color, 2.6)
	p.mesh = mesh
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	var flash := OmniLight3D.new()
	flash.light_color = color
	flash.light_energy = 5.0
	flash.omni_range = 45.0
	flash.shadow_enabled = false
	parent.add_child(flash)
	flash.global_position = pos
	var tw := flash.create_tween()
	tw.tween_property(flash, "light_energy", 0.0, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_callback(flash.queue_free)
	Sfx.play_at(parent, "estouro", pos, 2.0, 0.2)


static func glow_material(color: Color, energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = energy
	return mat


## Onda da explosão da granada: uma bolha cor-de-rosa que cresce até o raio e some.
static func shockwave(parent: Node, pos: Vector3, radius: float) -> void:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.7, 0.85, 0.45)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = mat
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = pos
	mi.scale = Vector3.ONE * 0.2
	var tw := mi.create_tween()
	tw.set_parallel(true)
	tw.tween_property(mi, "scale", Vector3.ONE * radius, 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.45)
	tw.chain().tween_callback(mi.queue_free)


## Bolha estourando: gotinhas claras que somem rápido.
static func bubble_pop(parent: Node, pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.amount = 14
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = 2.0
	p.initial_velocity_max = 3.5
	p.gravity = Vector3(0, -4.0, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.0
	var mesh := SphereMesh.new()
	mesh.radius = 0.06
	mesh.height = 0.12
	mesh.material = flat_material(Color("#ffd6f3"))
	p.mesh = mesh
	parent.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)


static func popup_text(parent: Node, pos: Vector3, text: String, color: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = 72
	label.outline_size = 14
	label.pixel_size = 0.006
	label.modulate = color
	parent.add_child(label)
	label.global_position = pos
	var tw := label.create_tween()
	tw.set_parallel(true)
	tw.tween_property(label, "position:y", label.position.y + 0.9, 0.7)
	tw.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.25)
	tw.chain().tween_callback(label.queue_free)
