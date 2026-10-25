class_name Hurtbox
extends Area3D
## Região de impacto presa a um osso. O tiro (raio) acerta a área e repassa o dano ao dono,
## já multiplicado (cabeça vale mais que o corpo).

const LAYER := 1 << 3  # camada 4, "pontos_de_impacto"
## Regiões que o auxílio de mira do controle pode "segurar".
const AIM_GROUP := &"alvo_mira"

@export var region := "corpo"
@export var multiplier := 1.0
## Se o auxílio de mira considera esta região (no jogo, só o corpo, que é o alvo fácil).
@export var aim_assist := false

var owner_target: Node


func _init() -> void:
	collision_layer = LAYER
	collision_mask = 0
	monitoring = false


func _ready() -> void:
	if aim_assist:
		add_to_group(AIM_GROUP)


func set_active(on: bool) -> void:
	collision_layer = LAYER if on else 0


func is_active() -> bool:
	return collision_layer != 0


## Centro da forma de colisão, que pode estar deslocada do osso.
func aim_point() -> Vector3:
	for c in get_children():
		if c is CollisionShape3D:
			return c.global_position
	return global_position


func receive_hit(damage: float, point: Vector3) -> void:
	if owner_target and owner_target.has_method("take_hit"):
		owner_target.take_hit(damage * multiplier, point, self)
