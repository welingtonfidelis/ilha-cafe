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
