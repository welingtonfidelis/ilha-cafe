class_name HeartPickup
extends Area3D
## Coração (KayKit Platformer Pack) que às vezes cai de um esqueleto desmontado. Devolve um
## coração de vida; com a vida cheia ele fica esperando no chão. Some depois de um tempo, piscando no fim.

const LIFETIME := 25.0
const HEART_MODEL := "res://assets/props/platformer/red/heart_red.gltf"

var _time := 0.0
var _visual: Node3D


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
	_visual = load(HEART_MODEL).instantiate()
	_visual.scale = Vector3.ONE * 0.75
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
			Sfx.play(get_parent(), "coracao")
			Fx.confetti(get_parent(), global_position + Vector3.UP, 20, 3.5)
			Fx.popup_text(get_parent(), global_position + Vector3.UP * 1.8, "+1", Color("#ff4d6d"))
			queue_free()
			return
