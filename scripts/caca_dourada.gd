class_name CacaDourada
extends Node
## Esqueleto dourado (item 8 da lista de melhorias, 2026-11-10). Depois do prólogo, andando pela ilha sem luta, sem
## menu, sem pescar e sem esconde-esconde, de tempos em tempos (o primeiro em 90 s, depois a cada 2,5 a 4 min) um
## esqueleto dourado sai do chão a uns 25 m, na frente da câmera. A faixa avisa, a seta de moeda "Dourado" aponta
## para ele e ele toca um sininho. Ele foge (tipo "Dourado" do SkeletonEnemy); derrotado, vai de balão soltando
## 25 moedas e confete dourado. Em 50 s (70 s no Modo Fácil) sem pegar, afunda de volta no chão e volta outra hora.

const PRIMEIRO := 90.0
const ENTRE := Vector2(150.0, 240.0)
const FUGA := 50.0
const FUGA_FACIL := 70.0
const MOEDAS := 25

var game: Node
var story: Story
## O esqueleto da vez (nulo sem nenhum na ilha).
var dourado: SkeletonEnemy
var pegos := 0
var _espera := PRIMEIRO
var _vida := 0.0
var _sino := 0.0


func _process(delta: float) -> void:
	if is_instance_valid(dourado):
		_correndo(delta)
		return
	dourado = null
	if pode_aparecer():
		_espera -= delta
		if _espera <= 0.0:
			aparecer()


func pode_aparecer() -> bool:
	if story == null or story.stage in ["antes", "prologo"] or game.menu_state != "":
		return false
	var p: Player = game.player
	if p.in_vehicle or p.parked or p.dizzy or p.pescando or p.using_phone or game.in_combat():
		return false
	if game.ending and game.ending.busy():
		return false
	if game.esconde and game.esconde.rodando():
		return false
	return not (game.farol and game.farol.no_mirante)


## Sai do chão na frente da câmera, a uns 25 m, num lugar com chão livre (fora d'água e de dentro das coisas).
func aparecer() -> bool:
	var p: Player = game.player
	var frente := -p.camera.global_basis.z
	frente.y = 0.0
	frente = frente.normalized() if frente.length() > 0.01 else Vector3.FORWARD
	for tentativa in 16:
		var dir := frente.rotated(Vector3.UP, randf_range(-0.9, 0.9))
		var ponto := p.global_position + dir * randf_range(20.0, 30.0)
		var chao := _chao_livre(ponto)
		if chao != Vector3.INF:
			_criar(chao)
			return true
	_espera = 20.0
	return false


func _criar(pos: Vector3) -> void:
	var e := SkeletonEnemy.new()
	e.type_name = "Dourado"
	e.from_crack = true
	e.start_awake = true
	e.aggro_radius = 999.0
	e.leash_radius = 999.0
	e.target = game.player
	e.set_meta("dourado", true)
	e.defeated.connect(game._on_enemy_defeated)
	e.defeated.connect(_pegou)
	game.add_child(e)
	e.global_position = pos
	dourado = e
	_vida = 0.0
	_sino = 0.0
	game.banner("Um esqueleto dourado!", "Pegue ele antes que fuja: ele solta um monte de moedas!", Color("#ffd23f"), 3.5)
	Sfx.play(game, "sino", 0.0, 0.0)


func _correndo(delta: float) -> void:
	if _indo(dourado):
		return
	_vida += delta
	_sino -= delta
	if _sino <= 0.0:
		_sino = 1.1
		Sfx.play_at(game, "sino", dourado.global_position + Vector3.UP * 1.5, -4.0)
	if _vida > (FUGA_FACIL if Ajustes.facil else FUGA) or story.stage == "festa":
		fugiu()


func fugiu() -> void:
	if not is_instance_valid(dourado):
		return
	dourado.sink_away()
	dourado = null
	_espera = randf_range(ENTRE.x, ENTRE.y)
	game.show_message("O esqueleto dourado fugiu! Ele volta outra hora.", Color("#ffe9a8"), 2.4)


func _pegou(e: SkeletonEnemy) -> void:
	pegos += 1
	var em := e.global_position + Vector3.UP * 1.6
	story.add_coins(MOEDAS, em + Vector3.UP * 1.4)
	for k in 3:
		Fx.confetti(game, em + Vector3(randf_range(-0.6, 0.6), k * 0.4, randf_range(-0.6, 0.6)), 30, 4.0)
	Sfx.play(game, "estrelinha", 0.0, 0.0)
	game.banner("Pegou o esqueleto dourado!", "+%d moedas!" % MOEDAS, Color("#ffd23f"), 3.0)
	dourado = null
	_espera = randf_range(ENTRE.x, ENTRE.y)
	story.save()


## Para onde a seta de moeda aponta (INF sem dourado na ilha).
func alvo() -> Vector3:
	if is_instance_valid(dourado) and not _indo(dourado):
		return dourado.global_position + Vector3.UP * 3.4
	return Vector3.INF


## Indo embora de balão (pego) ou afundando (fugiu); saindo do chão ainda conta como na ilha.
static func _indo(e: SkeletonEnemy) -> bool:
	return e.state in [SkeletonEnemy.State.INDO_EMBORA, SkeletonEnemy.State.AFUNDANDO]


func _chao_livre(p: Vector3) -> Vector3:
	var espaco: PhysicsDirectSpaceState3D = (game as Node3D).get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(Vector3(p.x, 80, p.z), Vector3(p.x, -40, p.z), 1)
	var hit: Dictionary = espaco.intersect_ray(ray)
	if hit.is_empty() or (hit.normal as Vector3).y < 0.8 or (hit.position as Vector3).y < 0.0:
		return Vector3.INF
	if absf((hit.position as Vector3).y - p.y) > 6.0:
		return Vector3.INF
	var forma := CapsuleShape3D.new()
	forma.radius = 0.6
	forma.height = 1.8
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = forma
	q.transform = Transform3D(Basis(), (hit.position as Vector3) + Vector3.UP * 1.3)
	q.collision_mask = 1
	if not espaco.intersect_shape(q, 1).is_empty():
		return Vector3.INF
	return hit.position
