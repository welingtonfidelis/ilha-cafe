class_name Snowball
extends Node3D
## Bola de neve do Golem de Gelo: voa em arco até o ponto marcado, onde um círculo branco no chão enche
## enquanto ela vem (dá tempo de sair). Quem estiver no círculo quando ela cai leva um golpe; ela estoura em
## neve.

const FLIGHT := 1.25
const RADIUS := 2.2
const PEAK := 6.0

var target: Node3D
var source := ""
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _t := 0.0
var _ball: MeshInstance3D
var _fill: MeshInstance3D
var _zone: Node3D


static func create(from: Vector3, land: Vector3, p_target: Node3D, p_source: String) -> Snowball:
	var s := Snowball.new()
	s._from = from
	s._to = land
	s.target = p_target
	s.source = p_source
	return s


func _ready() -> void:
	var space := get_world_3d().direct_space_state
	var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(_to + Vector3.UP * 6.0, _to + Vector3.DOWN * 8.0, 1))
	if hit:
		_to = hit.position
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.45
	sphere.height = 0.9
	sphere.material = Fx.flat_material(Color("#f4fbff"), false)
	_ball.mesh = sphere
	add_child(_ball)
	_ball.global_position = _from
	_zone = Node3D.new()
	add_child(_zone)
	_zone.global_position = _to + Vector3.UP * 0.05
	var base := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = RADIUS
	disc.bottom_radius = RADIUS
	disc.height = 0.04
	disc.material = _mat(Color(0.85, 0.95, 1.0, 0.25))
	base.mesh = disc
	base.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_zone.add_child(base)
	_fill = MeshInstance3D.new()
	var fill_disc := CylinderMesh.new()
	fill_disc.top_radius = RADIUS
	fill_disc.bottom_radius = RADIUS
	fill_disc.height = 0.05
	fill_disc.material = _mat(Color(0.75, 0.9, 1.0, 0.5))
	_fill.mesh = fill_disc
	_fill.scale = Vector3(0.01, 1, 0.01)
	_fill.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_zone.add_child(_fill)


func _mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	return m


func _physics_process(delta: float) -> void:
	_t += delta
	var k := minf(_t / FLIGHT, 1.0)
	var p := _from.lerp(_to, k)
	p.y += 4.0 * PEAK * k * (1.0 - k)
	_ball.global_position = p
	_ball.rotate_x(delta * 6.0)
	_fill.scale = Vector3(k, 1, k)
	if k < 1.0:
		return
	Fx.dust(get_parent(), _to + Vector3.UP * 0.3)
	Fx.confetti(get_parent(), _to + Vector3.UP * 0.4, 30, 4.0)
	Sfx.play_at(get_parent(), "pancada", _to, -2.0)
	if is_instance_valid(target):
		var d := Vector2(target.global_position.x - _to.x, target.global_position.z - _to.z).length()
		if d < RADIUS and absf(target.global_position.y - _to.y) < 2.5:
			(target as Player).take_damage(1, _to, source)
	queue_free()
