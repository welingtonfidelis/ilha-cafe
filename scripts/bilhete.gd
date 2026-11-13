class_name Bilhete
extends Node3D
## Bilhete pela ilha (item 7 da lista de melhorias, 2026-11-10): um envelope branco com selo de coração, flutuando e
## girando devagar sobre um anel dourado no chão. Encostar pega: some com confete, dá moedas, vai para o álbum e
## aparece o cartão de papel com o texto (para um adulto ler junto) e quem escreveu. São oito, um em cada canto da
## ilha (Album.BILHETES); cada um procura chão livre perto do ponto marcado.

const PEGAR := 1.8

var id := ""
var game: Node
var _t := 0.0
var _corpo: Node3D
var _pronto := false


func _ready() -> void:
	_corpo = Node3D.new()
	_corpo.scale = Vector3.ONE * 1.7
	add_child(_corpo)
	var papel := StandardMaterial3D.new()
	papel.albedo_color = Color("#fffaf0")
	papel.emission_enabled = true
	papel.emission = Color("#fff4dc")
	papel.emission_energy_multiplier = 0.35
	var envelope := MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(0.62, 0.42, 0.05)
	envelope.mesh = caixa
	envelope.material_override = papel
	_corpo.add_child(envelope)
	var aba := MeshInstance3D.new()
	var prisma := PrismMesh.new()
	prisma.size = Vector3(0.62, 0.24, 0.055)
	aba.mesh = prisma
	aba.material_override = Fx.flat_material(Color("#f2e6c8"), false)
	aba.rotation.z = PI
	aba.position = Vector3(0, 0.09, 0.004)
	_corpo.add_child(aba)
	for lado in [1.0, -1.0]:
		var selo := MeshInstance3D.new()
		selo.mesh = Fx.heart_mesh(0.16, 0.05)
		selo.material_override = Fx.flat_material(Color("#ff5d7a"), false)
		selo.position = Vector3(0, -0.02, 0.04 * lado)
		_corpo.add_child(selo)
	var anel := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 0.55
	toro.outer_radius = 0.7
	toro.rings = 28
	toro.ring_segments = 6
	anel.mesh = toro
	anel.material_override = Fx.glow_material(Color("#ffd23f"), 1.4)
	anel.scale = Vector3(1, 0.12, 1)
	anel.position.y = 0.04
	add_child(anel)
	var luz := OmniLight3D.new()
	luz.light_color = Color("#ffe9a8")
	luz.light_energy = 0.8
	luz.omni_range = 3.0
	luz.position.y = 1.3
	add_child(luz)
	_assentar.call_deferred()


## Procura chão livre perto do ponto (em volta, até 9 m), fora d'água e sem nada em cima.
func _assentar() -> void:
	await get_tree().physics_frame
	var base := global_position
	var espaco := get_world_3d().direct_space_state
	for raio in [0.0, 2.0, 4.0, 6.0, 9.0]:
		for k in (1 if raio == 0.0 else 8):
			var p: Vector3 = base + Vector3(cos(k * TAU / 8.0), 0, sin(k * TAU / 8.0)) * raio
			var ray := PhysicsRayQueryParameters3D.create(Vector3(p.x, 80, p.z), Vector3(p.x, -40, p.z), 1)
			var hit := espaco.intersect_ray(ray)
			if hit.is_empty() or (hit.normal as Vector3).y < 0.8 or (hit.position as Vector3).y < -0.2:
				continue
			var forma := CapsuleShape3D.new()
			forma.radius = 0.5
			forma.height = 1.6
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = forma
			q.transform = Transform3D(Basis(), (hit.position as Vector3) + Vector3.UP * 1.1)
			q.collision_mask = 1
			if espaco.intersect_shape(q, 1).is_empty():
				global_position = hit.position
				_pronto = true
				return
	global_position.y = 0.0
	_pronto = true


func pronto() -> bool:
	return _pronto


func _process(delta: float) -> void:
	if not visible or not _pronto:
		return
	_t += delta
	_corpo.position.y = 1.4 + sin(_t * 2.0) * 0.12
	_corpo.rotation.y += delta * 1.2
	if game == null or game.menu_state != "" or not is_instance_valid(game.player):
		return
	var p: Vector3 = game.player.global_position
	if Vector2(p.x - global_position.x, p.z - global_position.z).length() < PEGAR and absf(p.y - global_position.y) < 2.5:
		pegar()


func pegar() -> void:
	hide()
	Sfx.play(game, "estrelinha", -2.0, 0.0)
	Fx.confetti(game, global_position + Vector3.UP * 1.4, 24, 3.0)
	game.story.pegar_bilhete(id, global_position + Vector3.UP * 2.2)
	Vozes.falar(game, "bilhete")
	game.bilhete_cartao.mostrar(id)


## O cartão de papel do bilhete, no meio da tela: a figura do lugar, "Bilhete 3 de 8", o texto e quem escreveu.
## Some com A (depois de um segundo) ou sozinho em 10 s.
class Cartao:
	extends PanelContainer
	var _icone: MenuIcon
	var _titulo: Label
	var _texto: Label
	var _de: Label
	var _t := 0.0

	func _init() -> void:
		var estilo := MenuKit.box(Color("#fff4dc"), 18, MenuKit.GOLD, 5)
		estilo.set_content_margin_all(22)
		add_theme_stylebox_override("panel", estilo)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		anchor_left = 0.5
		anchor_right = 0.5
		anchor_top = 0.5
		anchor_bottom = 0.5
		grow_horizontal = Control.GROW_DIRECTION_BOTH
		grow_vertical = Control.GROW_DIRECTION_BOTH
		visible = false
		var caixa := VBoxContainer.new()
		caixa.add_theme_constant_override("separation", 12)
		add_child(caixa)
		var topo := HBoxContainer.new()
		topo.add_theme_constant_override("separation", 14)
		caixa.add_child(topo)
		_icone = MenuIcon.new("bilhete", MenuKit.ICON_COLORS.bilhete, 54)
		topo.add_child(_icone)
		_titulo = Label.new()
		_titulo.add_theme_font_size_override("font_size", 30)
		_titulo.add_theme_color_override("font_color", Color("#9a5a10"))
		_titulo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		topo.add_child(_titulo)
		_texto = Label.new()
		_texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_texto.custom_minimum_size = Vector2(560, 0)
		_texto.add_theme_font_size_override("font_size", 26)
		_texto.add_theme_color_override("font_color", Color("#4a3520"))
		caixa.add_child(_texto)
		_de = Label.new()
		_de.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_de.add_theme_font_size_override("font_size", 24)
		_de.add_theme_color_override("font_color", Color("#9a5a10"))
		caixa.add_child(_de)

	func mostrar(bid: String) -> void:
		var spec := Album.bilhete(bid)
		var n := 0
		for i in Album.BILHETES.size():
			if Album.BILHETES[i].id == bid:
				n = i + 1
		_icone.kind = spec.get("icone", "bilhete")
		_icone.color = MenuKit.ICON_COLORS.get(_icone.kind, MenuKit.ICON_COLORS.bilhete)
		_icone.queue_redraw()
		_titulo.text = "Bilhete %d de %d" % [n, Album.BILHETES.size()]
		_texto.text = spec.get("texto", "")
		_de.text = "— " + String(spec.get("de", ""))
		reset_size()
		var tam := get_combined_minimum_size()
		offset_left = -tam.x * 0.5
		offset_right = tam.x * 0.5
		offset_top = -tam.y * 0.5 - 40
		offset_bottom = tam.y * 0.5 - 40
		_t = 0.0
		show()

	func _process(delta: float) -> void:
		if not visible:
			return
		_t += delta
		if _t > 10.0 or (_t > 1.0 and (Input.is_action_just_pressed("pular") or Input.is_action_just_pressed("interagir"))):
			hide()

	func texto() -> String:
		return _texto.text
