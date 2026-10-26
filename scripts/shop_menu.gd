class_name ShopMenu
extends CenterContainer
## Menu da Lojinha de Blasters, feito para criança (pedido do usuário: "muito textual"): uma coluna por tipo
## (Pistola, Metralhadora, Escopeta, Rifle e Extras), cada blaster num cartão com a miniatura colorida
## (assets/ui/loja/, de tools/gerar_miniaturas.gd), o nome e o preço com moeda, ou "em uso" / "é seu".
## Escolher um cartão abre a prévia: o blaster girando, o tipo, o dano em número grande e barras de força,
## rapidez, alcance e balas; ali se compra ou equipa. Abre com o jogo pausado (estado "loja" do main.gd).

const THUMBS := "res://assets/ui/loja/%s.png"
const TYPE_COLORS := [Color("#ffb3d9"), Color("#9fffd6"), Color("#ffe08a"), Color("#c9a6ff"), Color("#ff9d9d")]
const SLOT_WORDS := ["seta de cima · tecla 1", "seta da direita · tecla 2", "seta de baixo · tecla 3", "seta da esquerda · tecla 4"]
const GOLD := Color("#ffd23f")
const OWNED := Color("#c9f7a0")
const DIM := Color(1, 1, 1, 0.5)
## Barras de 5 pedaços: quantos limites o valor passa (mínimo 1).
const BAR_STEPS := {
	"Força": [0.0, 1.2, 2.5, 4.0, 5.5],
	"Rapidez": [0.0, 2.0, 4.0, 8.0, 12.0],
	"Alcance": [0.0, 40.0, 90.0, 150.0, 210.0],
	"Balas": [0.0, 6.0, 12.0, 20.0, 35.0],
}

var game: Node
var focus_style: StyleBox
var _coins: Label
var _cards := {}
var _grid: Control
var _preview: Control
var _viewport: SubViewport
var _turntable: Node3D
var _p_name: Label
var _p_type: Label
var _p_type_box: PanelContainer
var _p_damage_title: Label
var _p_damage: Label
var _p_damage_note: Label
var _p_bars := {}
var _p_slot: Label
var _p_msg: Label
var _p_action: Button
var _p_back: Button
var _close: Button
var _current := ""


func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Fundo opaco: as faixas do jogo (como "Você ganhou moedas!") não aparecem por trás das letras.
	var panel := PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.11, 0.11, 0.16, 1.0)
	bg.set_corner_radius_all(10)
	bg.set_content_margin_all(18)
	bg.border_color = Color(GOLD, 0.6)
	bg.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", bg)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := Label.new()
	title.text = "Lojinha de Blasters"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	header.add_child(CoinIcon.new(30.0))
	_coins = Label.new()
	_coins.add_theme_font_size_override("font_size", 32)
	_coins.add_theme_color_override("font_color", Color("#ffe9a8"))
	header.add_child(_coins)
	_grid = _build_grid()
	box.add_child(_grid)
	_preview = _build_preview()
	box.add_child(_preview)
	_preview.visible = false
	_close = _button("Sair da lojinha", Vector2(300, 48))
	_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close.pressed.connect(func() -> void:
		Sfx.play(game.ui_layer, "ui_ok", 0.0, 0.0)
		game.close_menus())
	box.add_child(_close)


func _build_grid() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	for slot in 5:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		row.add_child(col)
		col.add_child(_type_tag("Extras" if slot == 4 else Weapons.TYPES[slot], TYPE_COLORS[slot]))
		var ids := []
		if slot == 4:
			ids = Weapons.UPGRADES.map(func(up: Dictionary) -> String: return up.id)
		else:
			ids.append(Weapons.get_def(slot).id)
			for def in Weapons.SHOP:
				if def.slot == slot:
					ids.append(def.id)
		for id in ids:
			col.add_child(_card(id))
	return row


func _type_tag(text: String, color: Color) -> PanelContainer:
	var tag := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(14)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	tag.add_theme_stylebox_override("panel", style)
	var l := Label.new()
	l.text = text.to_upper()
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", Color(0.12, 0.1, 0.18))
	tag.add_child(l)
	return tag


## Cartão: miniatura, nome e preço (ou "em uso" / "é seu"). Os filhos não pegam o mouse: o clique é do botão.
func _card(id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(176, 152)
	b.add_theme_stylebox_override("focus", focus_style)
	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_theme_constant_override("separation", 2)
	b.add_child(inner)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.offset_left = 6
	inner.offset_right = -6
	inner.offset_top = 4
	inner.offset_bottom = -4
	var pic := TextureRect.new()
	pic.texture = load(THUMBS % id)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(160, 88)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(pic)
	var name_label := Label.new()
	name_label.text = _name_of(id)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(name_label)
	var price_row := HBoxContainer.new()
	price_row.alignment = BoxContainer.ALIGNMENT_CENTER
	price_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.add_child(price_row)
	var coin := CoinIcon.new(18.0)
	price_row.add_child(coin)
	var price := Label.new()
	price.add_theme_font_size_override("font_size", 19)
	price.mouse_filter = Control.MOUSE_FILTER_IGNORE
	price_row.add_child(price)
	b.focus_entered.connect(func() -> void: Sfx.play(game.ui_layer, "ui_mover", 0.0, 0.0))
	b.pressed.connect(func() -> void:
		Sfx.play(game.ui_layer, "ui_ok", 0.0, 0.0)
		open_preview(id))
	_cards[id] = {"botao": b, "moeda": coin, "preco": price, "foto": pic}
	return b


func _build_preview() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	var holder := SubViewportContainer.new()
	holder.custom_minimum_size = Vector2(420, 300)
	holder.stretch = true
	row.add_child(holder)
	_viewport = SubViewport.new()
	_viewport.own_world_3d = true
	_viewport.transparent_bg = true
	_viewport.msaa_3d = Viewport.MSAA_4X
	holder.add_child(_viewport)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.85, 0.85, 0.95)
	env.environment.ambient_light_energy = 0.9
	_viewport.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, -30, 0)
	_viewport.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 32.0
	cam.position = Vector3(0, 0.35, 2.6)
	cam.rotation_degrees.x = -7.0
	_viewport.add_child(cam)
	_turntable = Node3D.new()
	_viewport.add_child(_turntable)
	var info := VBoxContainer.new()
	info.custom_minimum_size = Vector2(420, 0)
	info.add_theme_constant_override("separation", 8)
	row.add_child(info)
	_p_name = Label.new()
	_p_name.add_theme_font_size_override("font_size", 38)
	info.add_child(_p_name)
	_p_type_box = _type_tag("", Color.WHITE)
	_p_type_box.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_p_type = _p_type_box.get_child(0)
	info.add_child(_p_type_box)
	var dmg := HBoxContainer.new()
	dmg.add_theme_constant_override("separation", 10)
	info.add_child(dmg)
	_p_damage_title = Label.new()
	_p_damage_title.text = "DANO"
	_p_damage_title.add_theme_font_size_override("font_size", 22)
	_p_damage_title.add_theme_color_override("font_color", Color("#ff9d7a"))
	dmg.add_child(_p_damage_title)
	_p_damage = Label.new()
	_p_damage.add_theme_font_size_override("font_size", 46)
	_p_damage.add_theme_color_override("font_color", Color("#ffe9a8"))
	dmg.add_child(_p_damage)
	_p_damage_note = Label.new()
	_p_damage_note.add_theme_font_size_override("font_size", 18)
	dmg.add_child(_p_damage_note)
	for bar in BAR_STEPS:
		var line := HBoxContainer.new()
		var l := Label.new()
		l.text = bar
		l.custom_minimum_size = Vector2(100, 0)
		l.add_theme_font_size_override("font_size", 19)
		line.add_child(l)
		var meter := BarMeter.new()
		line.add_child(meter)
		info.add_child(line)
		_p_bars[bar] = meter
	_p_slot = Label.new()
	_p_slot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_p_slot.custom_minimum_size = Vector2(400, 0)
	_p_slot.add_theme_font_size_override("font_size", 17)
	_p_slot.add_theme_color_override("font_color", Color("#d9a8ff"))
	info.add_child(_p_slot)
	_p_msg = Label.new()
	_p_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_p_msg.custom_minimum_size = Vector2(400, 26)
	_p_msg.add_theme_font_size_override("font_size", 18)
	info.add_child(_p_msg)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	info.add_child(buttons)
	_p_action = _button("Comprar", Vector2(220, 56))
	_p_action.pressed.connect(func() -> void: buy(_current))
	buttons.add_child(_p_action)
	_p_back = _button("Voltar", Vector2(150, 56))
	_p_back.pressed.connect(func() -> void:
		Sfx.play(game.ui_layer, "ui_ok", 0.0, 0.0)
		back())
	buttons.add_child(_p_back)
	return row


func _button(text: String, size_min: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = size_min
	b.add_theme_font_size_override("font_size", 22)
	b.add_theme_stylebox_override("focus", focus_style)
	b.focus_entered.connect(func() -> void: Sfx.play(game.ui_layer, "ui_mover", 0.0, 0.0))
	return b


func _process(delta: float) -> void:
	if visible and _preview.visible and is_instance_valid(_turntable):
		_turntable.rotate_y(delta * 1.1)


# --- dados de cada item ---------------------------------------------------------------

func _upgrade(id: String) -> Dictionary:
	for up in Weapons.UPGRADES:
		if up.id == id:
			return up
	return {}


func _name_of(id: String) -> String:
	var up := _upgrade(id)
	return up.nome if not up.is_empty() else Weapons.find(id).nome


func _price_of(id: String) -> int:
	var up := _upgrade(id)
	return int(up.preco) if not up.is_empty() else Weapons.price(id)


func _owned(id: String) -> bool:
	if not _upgrade(id).is_empty():
		return id in game.story.upgrades
	return game.player.has_weapon(id)


func _in_use(id: String) -> bool:
	if not _upgrade(id).is_empty():
		return _owned(id)
	return _owned(id) and game.player.equipped[Weapons.index_of(id)] == id


func _steps(bar: String, value: float) -> int:
	var n := 0
	for limit in BAR_STEPS[bar]:
		if value >= limit:
			n += 1
	return clampi(n, 1, 5)


# --- telas -----------------------------------------------------------------------------

## Abre na grade de cartões, com o foco no item mais barato que ainda não é seu.
func open() -> void:
	back()
	var best := ""
	for id in _cards:
		if not _owned(id) and _price_of(id) > 0 and (best == "" or _price_of(id) < _price_of(best)):
			best = id
	if best != "":
		_cards[best].botao.grab_focus.call_deferred()
	else:
		_close.grab_focus.call_deferred()


func in_preview() -> bool:
	return _preview.visible


func back() -> void:
	var was := _current
	_preview.visible = false
	_grid.visible = true
	_close.visible = true
	_current = ""
	refresh()
	if was != "" and _cards.has(was):
		_cards[was].botao.grab_focus.call_deferred()


func refresh() -> void:
	var story: Story = game.story
	_coins.text = str(story.coins)
	for id in _cards:
		var c: Dictionary = _cards[id]
		var price_label: Label = c.preco
		var coin: Control = c.moeda
		var b: Button = c.botao
		b.modulate = Color.WHITE
		if _in_use(id):
			price_label.text = "em uso" if _upgrade(id).is_empty() else "comprado"
			price_label.add_theme_color_override("font_color", OWNED)
			coin.visible = false
		elif _owned(id):
			price_label.text = "é seu"
			price_label.add_theme_color_override("font_color", Color.WHITE)
			coin.visible = false
		else:
			var price := _price_of(id)
			price_label.text = str(price)
			coin.visible = true
			var can := story.coins >= price
			price_label.add_theme_color_override("font_color", GOLD if can else DIM)
			if not can:
				b.modulate = Color(1, 1, 1, 0.65)


func open_preview(id: String) -> void:
	_current = id
	_grid.visible = false
	_close.visible = false
	_preview.visible = true
	for child in _turntable.get_children():
		child.queue_free()
	_turntable.rotation = Vector3.ZERO
	var model := _model_for(id)
	_turntable.add_child(model)
	_fit(model)
	_p_name.text = _name_of(id)
	_p_msg.text = ""
	var up := _upgrade(id)
	for bar in _p_bars:
		(_p_bars[bar] as Control).get_parent().visible = up.is_empty()
	_p_damage_title.text = "DANO" if up.is_empty() else ""
	if up.is_empty():
		var def := Weapons.find(id)
		var slot := Weapons.index_of(id)
		_p_type.text = Weapons.TYPES[slot].to_upper()
		(_p_type_box.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = TYPE_COLORS[slot]
		var per_shot: float = def.dano * def.tiros
		_p_damage.text = _number(per_shot)
		_p_damage_note.text = "por tiro" if def.tiros == 1 else "por tiro (%d grãos)" % def.tiros
		_p_bars["Força"].value = _steps("Força", per_shot)
		_p_bars["Rapidez"].value = _steps("Rapidez", 1.0 / def.intervalo)
		_p_bars["Alcance"].value = _steps("Alcance", def.alcance)
		_p_bars["Balas"].value = _steps("Balas", def.pente)
		_p_slot.text = "Fica na %s%s" % [SLOT_WORDS[slot], " · munição infinita" if Weapons.infinite(def) else ""]
	else:
		_p_type.text = "EXTRA"
		(_p_type_box.get_theme_stylebox("panel") as StyleBoxFlat).bg_color = TYPE_COLORS[4]
		if id == "granada_extra":
			_p_damage.text = "%d → %d" % [Weapons.GRENADE.max, Weapons.GRENADE.max + 1]
			_p_damage_note.text = "granadas no bolso"
		else:
			_p_damage.text = "+1"
			_p_damage_note.text = "coração (você tem %d)" % game.player.max_hearts
		_p_slot.text = up.descricao
	_refresh_action()
	_p_action.grab_focus.call_deferred()


func _refresh_action() -> void:
	var id := _current
	_p_action.disabled = false
	if _in_use(id):
		_p_action.text = "Em uso" if _upgrade(id).is_empty() else "Comprado"
		_p_action.disabled = true
	elif _owned(id):
		_p_action.text = "Usar este"
	else:
		_p_action.text = "Comprar  %d" % _price_of(id)
		var missing := _price_of(id) - int(game.story.coins)
		if missing > 0 and _p_msg.text == "":
			_p_msg.text = "Faltam %d moedas" % missing


func _number(v: float) -> String:
	var s := ("%.1f" % v) if fmod(v, 1.0) > 0.01 else ("%d" % int(v))
	return s.replace(".", ",")


func _model_for(id: String) -> Node3D:
	if id == "coracao_extra":
		var mi := MeshInstance3D.new()
		mi.mesh = Fx.heart_mesh(0.6, 0.3)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("#ff5d7a")
		mi.material_override = mat
		return mi
	var path: String = Weapons.MODEL_DIR % (Weapons.GRENADE.modelo if id == "granada_extra" else Weapons.find(id).modelo)
	return load(path).instantiate()


## Centraliza o modelo no prato que gira e ajusta o tamanho para caber.
func _fit(model: Node3D) -> void:
	var box := AABB()
	var first := true
	var meshes := model.find_children("*", "MeshInstance3D", true, false)
	if model is MeshInstance3D:
		meshes.append(model)
	for m in meshes:
		var mi := m as MeshInstance3D
		var xf := Transform3D.IDENTITY
		var n: Node = mi
		while n != model and n is Node3D:
			xf = (n as Node3D).transform * xf
			n = n.get_parent()
		var a: AABB = xf * mi.get_aabb()
		box = a if first else box.merge(a)
		first = false
	var biggest := maxf(box.size.x, maxf(box.size.y, box.size.z))
	var s := 1.3 / maxf(biggest, 0.01)
	model.scale = Vector3.ONE * s
	model.position = -box.get_center() * s


# --- comprar e equipar -------------------------------------------------------------------

## Compra, equipa ou avisa. Devolve "comprou", "equipou", "sem_moedas" ou "nada".
func buy(id: String) -> String:
	var story: Story = game.story
	var player: Player = game.player
	var result := "nada"
	var up := _upgrade(id)
	if _owned(id):
		if up.is_empty() and not _in_use(id):
			player.equip(id)
			player.switch_weapon(Weapons.index_of(id))
			result = "equipou"
	elif _price_of(id) > 0 and story.spend_coins(_price_of(id)):
		if not up.is_empty():
			story.upgrades.append(id)
			if id == "granada_extra":
				player.grenade_max = Weapons.GRENADE.max + 1
				player.grenades = player.grenade_max
				player.ammo_changed.emit()
			else:
				player.add_max_heart()
		else:
			player.unlock_weapon(id)
		result = "comprou"
	else:
		result = "sem_moedas"
	match result:
		"comprou":
			Sfx.play(game.ui_layer, "bandeira", 0.0, 0.0)
			_p_msg.text = "É seu! Já está na mão." if up.is_empty() else "Comprado!"
			story.save()
		"equipou":
			Sfx.play(game.ui_layer, "troca_arma", 0.0, 0.0)
			_p_msg.text = "Pronto, está na mão."
			story.save()
		"sem_moedas":
			Sfx.play(game.ui_layer, "sem_municao", 0.0, 0.0)
			_p_msg.text = "Faltam %d moedas. Vença guardiões ou jogue a Festa sem fim!" % (_price_of(id) - story.coins)
	if _preview.visible:
		_refresh_action()
	refresh()
	return result


## Moedinha desenhada (a fonte não tem o símbolo).
class CoinIcon:
	extends Control
	var diameter := 20.0

	func _init(d := 20.0) -> void:
		diameter = d
		custom_minimum_size = Vector2(d + 4.0, d)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := Vector2(diameter * 0.5 + 2.0, size.y * 0.5)
		var r := diameter * 0.5
		draw_circle(c, r, Color("#ffd23f"))
		draw_arc(c, r, 0.0, TAU, 28, Color("#c98a10"), maxf(r * 0.18, 1.5), true)
		draw_arc(c, r * 0.55, 0.0, TAU, 20, Color("#c98a10"), maxf(r * 0.12, 1.0), true)


## Barra de 5 pedaços (força, rapidez, alcance, balas).
class BarMeter:
	extends Control
	var value := 3:
		set(v):
			value = v
			queue_redraw()

	func _init() -> void:
		custom_minimum_size = Vector2(230, 22)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := 40.0
		for k in 5:
			var rect := Rect2(k * (w + 6.0), 3.0, w, size.y - 6.0)
			draw_rect(rect, Color("#ffd23f") if k < value else Color(1, 1, 1, 0.15), true)
