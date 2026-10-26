class_name SpringPad
extends StaticBody3D
## Mola do Platformer Pack (completo): pisou, sobe. Fica no chão da Vila das Copas, ao lado das
## plataformas, e joga o aventureiro até lá em cima (a gravidade dele é o dobro da padrão).

const MODEL := "res://assets/props/molas/vermelho/spring_pad_red.gltf"
const SPEED := 16.0

var _model: Node3D
var _cooldown := 0.0


func _ready() -> void:
	collision_layer = 1
	_model = load(MODEL).instantiate()
	add_child(_model)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, 0.5, 1.5)
	cs.shape = box
	cs.position.y = 0.25
	add_child(cs)
	var area := Area3D.new()
	area.collision_layer = 0
	area.collision_mask = 1 << 1
	var acs := CollisionShape3D.new()
	var abox := BoxShape3D.new()
	abox.size = Vector3(1.4, 0.6, 1.4)
	acs.shape = abox
	acs.position.y = 0.8
	area.add_child(acs)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_cooldown -= delta


func _on_body_entered(body: Node) -> void:
	if body is Player and _cooldown <= 0.0:
		_cooldown = 0.5
		(body as Player).bounce(SPEED)
		var tw := _model.create_tween()
		tw.tween_property(_model, "scale", Vector3(1.15, 0.55, 1.15), 0.06)
		tw.tween_property(_model, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
