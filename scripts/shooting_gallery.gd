class_name ShootingGallery
extends Node3D
## Barraca de tiro ao alvo da festa: quatro alvos de pé do Prototype Bits, que caem para trás quando
## acertados e voltam sozinhos, o boneco de treino do Avian Swordsman no meio (balança e mostra o dano,
## cabeça vale o dobro, igual nos esqueletos) e o placar de acertos flutuando em cima.
## Os alvos ficam à frente do nó (+Z local), virados para quem atira.

const TARGETS := "res://assets/props/tiro/%s.gltf"
const DUMMY := "res://assets/props/tiro/boneco/Trainingdummy_Base.gltf"
const BACK_UP := 2.5

var hits := 0
var targets: Array[GalleryTarget] = []
var dummy: TrainingDummy
var _board: Label3D


func _ready() -> void:
	for spec in [[-5.0, "target_stand_A"], [-2.8, "target_stand_B"], [2.8, "target_stand_A_Decorated"], [5.0, "target_stand_B"]]:
		var t := GalleryTarget.new()
		t.model_path = TARGETS % spec[1]
		t.gallery = self
		t.position = Vector3(spec[0], 0, 3.0)
		add_child(t)
		targets.append(t)
	dummy = TrainingDummy.new()
	dummy.position = Vector3(0, 0, 3.3)
	add_child(dummy)
	_board = Label3D.new()
	_board.font_size = 64
	_board.outline_size = 14
	_board.outline_modulate = Color(0.15, 0.08, 0.25)
	_board.modulate = Color("#ffd23f")
	_board.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_board.pixel_size = 0.008
	_board.position = Vector3(0, 3.9, 3.3)
	add_child(_board)
	_refresh()


## Os acertos ficam salvos na campanha (recorde da barraca).
func set_hits(n: int) -> void:
	hits = n
	_refresh()


func scored() -> void:
	hits += 1
	_refresh()


func _refresh() -> void:
	_board.text = "TIRO AO ALVO\nAcertos: %d" % hits


## Alvo de pé: cai para trás quando acertado e volta depois de um tempinho.
class GalleryTarget:
	extends StaticBody3D
	var model_path := ""
	var gallery: ShootingGallery
	var up := true
	var _pivot: Node3D
	var _hb: Hurtbox

	func _ready() -> void:
		collision_layer = 1
		_pivot = Node3D.new()
		add_child(_pivot)
		var m: Node3D = load(model_path).instantiate()
		m.rotation_degrees.y = 180.0
		_pivot.add_child(m)
		# Só a base bloqueia o caminho: o tiro (que também bate no mundo) tem que chegar na região do alvo.
		var cs := CollisionShape3D.new()
		var base := BoxShape3D.new()
		base.size = Vector3(0.8, 0.4, 0.8)
		cs.shape = base
		cs.position.y = 0.2
		add_child(cs)
		_hb = Hurtbox.new()
		_hb.region = "alvo"
		_hb.owner_target = self
		var hcs := CollisionShape3D.new()
		var face := BoxShape3D.new()
		face.size = Vector3(1.0, 1.1, 0.6)
		hcs.shape = face
		hcs.position = Vector3(0, 1.45, 0.3)
		_hb.add_child(hcs)
		_pivot.add_child(_hb)

	func take_hit(_amount: float, point: Vector3, _from: Hurtbox) -> void:
		if not up:
			return
		up = false
		_hb.set_active(false)
		gallery.scored()
		Fx.popup_text(get_parent(), point + Vector3.UP * 0.3, "+1", Color("#ffd23f"))
		Fx.confetti(get_parent(), point, 18, 2.0)
		Sfx.play_at(get_parent(), "acerto_cabeca", point)
		var tw := create_tween()
		tw.tween_property(_pivot, "rotation_degrees:x", 80.0, 0.18).set_ease(Tween.EASE_IN)
		tw.tween_interval(ShootingGallery.BACK_UP)
		tw.tween_property(_pivot, "rotation_degrees:x", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			up = true
			_hb.set_active(true))


## Boneco de treino: aguenta tudo, balança e mostra o dano (cabeça vale o dobro).
class TrainingDummy:
	extends StaticBody3D
	var hits := 0
	var _model: Node3D

	func _ready() -> void:
		collision_layer = 1
		_model = load(ShootingGallery.DUMMY).instantiate()
		_model.rotation_degrees.y = 180.0
		add_child(_model)
		var cs := CollisionShape3D.new()
		var base := CylinderShape3D.new()
		base.radius = 0.35
		base.height = 0.6
		cs.shape = base
		cs.position.y = 0.3
		add_child(cs)
		var head := SphereShape3D.new()
		head.radius = 0.4
		_region("cabeça", 2.0, head, Vector3(0, 2.1, 0))
		var body := CapsuleShape3D.new()
		body.radius = 0.5
		body.height = 1.2
		_region("corpo", 1.0, body, Vector3(0, 1.25, 0))

	func _region(region: String, mult: float, shape: Shape3D, offset: Vector3) -> void:
		var hb := Hurtbox.new()
		hb.region = region
		hb.multiplier = mult
		hb.owner_target = self
		var hcs := CollisionShape3D.new()
		hcs.shape = shape
		hcs.position = offset
		hb.add_child(hcs)
		_model.add_child(hb)

	func take_hit(amount: float, point: Vector3, hb: Hurtbox) -> void:
		hits += 1
		var crit := hb != null and hb.multiplier > 1.0
		var shown := "%.1f" % amount if fmod(amount, 1.0) > 0.01 else "%d" % int(amount)
		Fx.popup_text(get_parent(), point + Vector3.UP * 0.3, "x2!" if crit else "-" + shown, Color("#ffd23f") if crit else Color.WHITE)
		Sfx.play_at(get_parent(), "acerto_cabeca" if crit else "acerto", point)
		var tw := create_tween()
		tw.tween_property(_model, "rotation_degrees:x", 14.0, 0.08)
		tw.tween_property(_model, "rotation_degrees:x", 0.0, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
