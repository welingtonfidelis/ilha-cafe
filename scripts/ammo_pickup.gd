class_name AmmoPickup
extends Area3D
## Caixa de munição (caixote do Blaster Kit com um pente em cima). Devolve um pente de cada
## blaster de estoque limitado e uma granada (Weapons.CRATE_AMMO). Se não couber nada, fica no chão.
## Caixas da ilha (respawn > 0) voltam depois de um tempo; as que caem de esqueleto somem.

const CRATE := "res://assets/weapons/crate-small.glb"
const CLIP := "res://assets/weapons/clip-small.glb"

## Segundos para a caixa voltar depois de pega (0 = não volta, some de vez).
var respawn := 0.0
## Caixa que caiu de esqueleto: some sozinha depois de LIFETIME.
var dropped := false

const LIFETIME := 30.0

var _visual: Node3D
var _time := 0.0
var _hidden_time := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1  # jogador
	monitoring = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.1
	shape.shape = sphere
	shape.position.y = 0.6
	add_child(shape)
	_visual = Node3D.new()
	add_child(_visual)
	var crate: Node3D = load(CRATE).instantiate()
	crate.scale = Vector3.ONE * 1.6
	_visual.add_child(crate)
	var clip: Node3D = load(CLIP).instantiate()
	clip.scale = Vector3.ONE * 3.0
	clip.position = Vector3(0, 0.62, 0)
	clip.rotation_degrees.z = 90.0
	_visual.add_child(clip)
	if dropped:
		_visual.position.y = 1.2
		var tw := create_tween()
		tw.tween_property(_visual, "position:y", 0.0, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _physics_process(delta: float) -> void:
	if not _visual.visible and respawn > 0.0:
		_hidden_time -= delta
		if _hidden_time <= 0.0:
			_visual.visible = true
			Fx.confetti(get_parent(), global_position + Vector3.UP * 0.6, 12, 2.5)
		return
	_time += delta
	_visual.rotation.y += delta * 1.2
	if dropped:
		if _time > LIFETIME - 4.0:
			_visual.visible = fmod(_time, 0.3) < 0.18
		if _time > LIFETIME:
			queue_free()
			return
	for body in get_overlapping_bodies():
		if body is Player and (body as Player).add_ammo_crate():
			Sfx.play(get_parent(), "municao")
			Fx.popup_text(get_parent(), global_position + Vector3.UP * 1.6, "+munição", Color("#9fdcff"))
			if respawn > 0.0:
				_visual.visible = false
				_hidden_time = respawn
			else:
				queue_free()
			return


func is_available() -> bool:
	return _visual.visible
