class_name HeartPickup
extends Area3D
## Coração que às vezes cai de um esqueleto desmontado. Devolve um coração de vida;
## com a vida cheia ele fica esperando no chão. Some depois de um tempo, piscando no fim.

const LIFETIME := 25.0

var _time := 0.0
var _visual: MeshInstance3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1  # jogador
	monitoring = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	shape.shape = sphere
	shape.position.y = 0.9
	add_child(shape)
	_visual = MeshInstance3D.new()
	_visual.mesh = Fx.heart_mesh()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#ff4d6d")
	mat.emission_enabled = true
	mat.emission = Color("#ff4d6d")
	mat.emission_energy_multiplier = 0.35
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_visual.material_override = mat
	_visual.position.y = 0.9
	add_child(_visual)
	# Pulinho ao cair.
	var tw := create_tween()
	tw.tween_property(_visual, "position:y", 1.8, 0.25).set_ease(Tween.EASE_OUT)
	tw.tween_property(_visual, "position:y", 0.9, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	_time += delta
	_visual.rotation.y += delta * 2.5
	if _time > LIFETIME - 4.0:
		_visual.visible = fmod(_time, 0.3) < 0.18
	if _time > LIFETIME:
		queue_free()
		return
	for body in get_overlapping_bodies():
		if body is Player and (body as Player).heal(1):
			Fx.confetti(get_parent(), global_position + Vector3.UP, 20, 3.5)
			Fx.popup_text(get_parent(), global_position + Vector3.UP * 1.8, "+1", Color("#ff4d6d"))
			queue_free()
			return
