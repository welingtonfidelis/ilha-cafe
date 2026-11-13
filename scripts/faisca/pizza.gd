class_name PizzaGiratoria
extends AnimatableBody3D
## Pizza gigante girando devagar em cima da mesa redonda, como o prato do micro-ondas (2-1 Cozinha Gigante).
## Quem está em cima vai junto; as Bolotas também. O nó fica no meio de baixo da pizza.

var velocidade := 0.35
var escala := 8.0


func _ready() -> void:
	sync_to_physics = true
	collision_layer = 1
	collision_mask = 0
	var pizza: Node3D = load(Fase.COZINHA + "food_pizza_pepperoni_plated.gltf").instantiate()
	pizza.scale = Vector3.ONE * escala
	add_child(pizza)
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 1.0 * escala
	cil.height = 0.3 * escala
	cs.shape = cil
	cs.position.y = 0.15 * escala
	add_child(cs)


func topo() -> float:
	return global_position.y + 0.3 * escala


func _physics_process(delta: float) -> void:
	rotation.y += velocidade * delta
