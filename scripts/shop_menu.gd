class_name ShopMenu
extends CenterContainer
## Lojinha de Blasters no celular (pedido do usuário em 2026-10-27; antes era uma barraca na praia): o
## aventureiro puxa o celular do bolso (Select ou C, fora de luta) e o menu abre numa tela de celular deitado.
## Feito para criança (pedido do usuário: "muito textual"): uma coluna por tipo (Pistola, Metralhadora,
## Escopeta, Rifle e Extras), cada blaster num cartão com a miniatura colorida (assets/ui/loja/, de
## tools/gerar_miniaturas.gd), o nome e o preço com moeda, ou "em uso" / "é seu" / "a caminho". Escolher um
## cartão abre a prévia: o blaster girando, o tipo, o dano em número grande e barras de força, rapidez, alcance
## e balas; ali se compra ou equipa. Comprar faz um pedido: quando o celular fecha, tudo desce de balão na
## frente do aventureiro (Delivery). Abre com o jogo pausado (estado "loja" do main.gd).

const THUMBS := "res://assets/ui/loja/%s.png"
const TYPE_COLORS := [Color("#ffb3d9"), Color("#9fffd6"), Color("#ffe08a"), Color("#c9a6ff"), Color("#ff9d9d")]
const SLOT_WORDS := ["seta de cima · tecla 1", "seta da direita · tecla 2", "seta de baixo · tecla 3", "seta da esquerda · tecla 4"]
const GOLD := Color("#ffd23f")
const OWNED := Color("#c9f7a0")
const ON_THE_WAY := Color("#9fdcff")
## Moldura do celular.
const BEZEL := Color("#2b2836")
const SCREEN := Color(0.11, 0.11, 0.16, 1.0)
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
var _grid: ScrollContainer
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
## Duas pistolas: põe a pistola na mão esquerda.
var _p_second: Button
var _close: Button
var _current := ""
var _phone: PanelContainer
var _more: Control


func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Celular deitado: moldura escura com cantos redondos, câmera no lado esquerdo e botões em cima. A tela é
	# opaca: as faixas do jogo (como "Você ganhou moedas!") não aparecem por trás das letras.
	_phone = PanelContainer.new()
	var bezel := StyleBoxFlat.new()
	bezel.bg_color = BEZEL
	bezel.set_corner_radius_all(44)
	bezel.set_content_margin_all(16)
	bezel.content_margin_left = 34
	bezel.content_margin_right = 34
	bezel.shadow_color = Color(0, 0, 0, 0.45)
	bezel.shadow_size = 16
	bezel.border_color = Color("#4a4658")
	bezel.set_border_width_all(3)
	_phone.add_theme_stylebox_override("panel", bezel)
	_phone.draw.connect(_draw_phone_details)
	add_child(_phone)
	var panel := PanelContainer.new()
	var bg := StyleBoxFlat.new()
	bg.bg_color = SCREEN
	bg.set_corner_radius_all(24)
	bg.set_content_margin_all(18)
	bg.content_margin_top = 10
	panel.add_theme_stylebox_override("panel", bg)
	_phone.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	box.add_child(StatusBar.new())
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	box.add_child(header)
	header.add_child(BalloonIcon.new())
	var title := Label.new()
	title.text = "Lojinha Delivery"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", GOLD)
	header.add_child(title)
	var tag := Label.new()
	tag.text = "chega de balão!"
	tag.add_theme_font_size_override("font_size", 18)
	tag.add_theme_color_override("font_color", ON_THE_WAY)
	tag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(tag)
	header.add_child(CoinIcon.new(30.0))
	_coins = Label.new()
	_coins.add_theme_font_size_override("font_size", 32)
	_coins.add_theme_color_override("font_color", Color("#ffe9a8"))
	header.add_child(_coins)
	# Com 18 blasters as colunas passam da tela: a tela do celular rola, e o foco do controle leva junto.
	_grid = ScrollContainer.new()
	_grid.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid.follow_focus = true
	_grid.custom_minimum_size = Vector2(0, 480)
	_grid.add_child(_build_grid())
	box.add_child(_grid)
	_more = MoreHint.new()
	_more.scroll = _grid
	box.add_child(_more)
	_preview = _build_preview()
	box.add_child(_preview)
	_preview.visible = false
	_close = _button("Guardar o celular", Vector2(300, 48))
	_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close.pressed.connect(func() -> void:
		Sfx.play(game.ui_layer, "ui_ok", 0.0, 0.0)
		game.close_menus())
	box.add_child(_close)


## Câmera na lateral esquerda e os botões de volume e de ligar na borda de cima da moldura.
func _draw_phone_details() -> void:
	var h := _phone.size.y
	_phone.draw_circle(Vector2(17, h * 0.5), 6.0, Color("#15131c"))
	_phone.draw_circle(Vector2(17, h * 0.5), 2.5, Color("#3d5a80"))
	for spec in [[0.18, 70.0], [0.3, 40.0], [0.78, 56.0]]:
		_phone.draw_rect(Rect2(_phone.size.x * spec[0], -4.0, spec[1], 5.0), Color("#4a4658"))


## Abre crescendo de leve, como quem acaba de tirar o celular do bolso.
func slide_in() -> void:
	_phone.pivot_offset = _phone.size * 0.5
	_phone.scale = Vector2.ONE * 0.85
	_phone.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(_phone, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_phone, "modulate:a", 1.0, 0.15)


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
			var extra := Weapons.SHOP.filter(func(def: Dictionary) -> bool: return def.slot == slot)
			extra.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.preco < b.preco)
			for def in extra:
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
	_p_second = _button("Na outra mão", Vector2(200, 56))
	_p_second.pressed.connect(func() -> void:
		game.player.set_second_pistol(_current)
		Sfx.play(game.ui_layer, "troca_arma", 0.0, 0.0)
		_p_msg.text = "Pronto! Com a pistola na mão, aperte a seta de cima (ou 1) de novo para usar as duas."
		_refresh_action()
		refresh()
		game.story.save())
	buttons.add_child(_p_second)
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


## Munição: compra quantas vezes quiser.
func _repeats(id: String) -> bool:
	return _upgrade(id).get("repete", false)


func _on_the_way(id: String) -> bool:
	return game.story.on_the_way(id)


## Munição com tudo cheio (nada para encher).
func _full(id: String) -> bool:
	return id == "municao" and game.player.ammo_full()


## Pistola escolhida para a mão esquerda (duas pistolas).
func _second(id: String) -> bool:
	return Weapons.index_of(id) == 0 and _upgrade(id).is_empty() and _owned(id) and game.player.left_pistol_id() == id


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
		if not _owned(id) and not _on_the_way(id) and not _full(id) and _price_of(id) > 0 and (best == "" or _price_of(id) < _price_of(best)):
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
	_more.visible = true
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
		if _on_the_way(id):
			price_label.text = "a caminho"
			price_label.add_theme_color_override("font_color", ON_THE_WAY)
			coin.visible = false
		elif _full(id):
			price_label.text = "tudo cheio"
			price_label.add_theme_color_override("font_color", DIM)
			coin.visible = false
		elif _in_use(id):
			price_label.text = "em uso" if _upgrade(id).is_empty() else "comprado"
			price_label.add_theme_color_override("font_color", OWNED)
			coin.visible = false
		elif _second(id):
			price_label.text = "outra mão"
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
	_more.visible = false
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
		if id == "municao":
			_p_damage.text = "Enche"
			_p_damage_note.text = "todos os blasters e as granadas"
		elif id == "granada_extra":
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
	# "Na outra mão": pistola sua que não está na mão direita nem já na esquerda.
	_p_second.visible = Weapons.index_of(id) == 0 and _upgrade(id).is_empty() and _owned(id) and not _in_use(id) and not _second(id)
	if _on_the_way(id):
		_p_action.text = "A caminho!"
		_p_action.disabled = true
	elif _full(id):
		_p_action.text = "Tudo cheio"
		_p_action.disabled = true
	elif _in_use(id):
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
	if id == "municao":
		return ammo_model()
	var path: String = Weapons.MODEL_DIR % (Weapons.GRENADE.modelo if id == "granada_extra" else Weapons.find(id).modelo)
	return load(path).instantiate()


## Munição: caixote pequeno do Blaster Kit com um pente em cima (como as caixas da ilha).
static func ammo_model() -> Node3D:
	var node := Node3D.new()
	node.add_child(load(Weapons.MODEL_DIR % "crate-small").instantiate())
	var clip: Node3D = load(Weapons.MODEL_DIR % "clip-small").instantiate()
	clip.position = Vector3(0, 0.32, 0)
	clip.rotation_degrees = Vector3(0, 30, 90)
	node.add_child(clip)
	return node


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

## Compra (vira pedido de entrega), equipa ou avisa. Devolve "comprou", "equipou", "a_caminho", "cheio",
## "sem_moedas" ou "nada".
func buy(id: String) -> String:
	var story: Story = game.story
	var player: Player = game.player
	var result := "nada"
	var up := _upgrade(id)
	if _on_the_way(id):
		result = "a_caminho"
	elif _full(id):
		result = "cheio"
	elif _owned(id) and not _repeats(id):
		if up.is_empty() and not _in_use(id):
			player.equip(id)
			player.switch_weapon(Weapons.index_of(id))
			result = "equipou"
	elif _price_of(id) > 0 and story.spend_coins(_price_of(id)):
		story.order.append(id)
		result = "comprou"
	else:
		result = "sem_moedas"
	match result:
		"comprou":
			Sfx.play(game.ui_layer, "bandeira", 0.0, 0.0)
			_p_msg.text = "Pedido feito! Guarde o celular e ele chega de balão."
			story.save()
		"a_caminho":
			_p_msg.text = "Já está a caminho! Guarde o celular para ele chegar."
		"cheio":
			_p_msg.text = "Tudo cheio! Volte quando gastar munição."
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


## Setinha embaixo da grade quando tem mais cartões para baixo (some no fim da rolagem).
class MoreHint:
	extends Control
	var scroll: ScrollContainer

	func _init() -> void:
		custom_minimum_size = Vector2(0, 14)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if not is_instance_valid(scroll):
			return
		var bar := scroll.get_v_scroll_bar()
		if bar.value + bar.page >= bar.max_value - 4.0:
			return
		var c := Vector2(size.x * 0.5, 4.0)
		var bob := sin(Time.get_ticks_msec() / 200.0) * 2.0
		draw_colored_polygon(PackedVector2Array([c + Vector2(-14, bob), c + Vector2(14, bob), c + Vector2(0, 10 + bob)]), Color(1, 0.82, 0.25, 0.85))


## Barra de cima da tela do celular: hora, sinal e bateria.
class StatusBar:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(0, 18)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(4, 15), "10:27", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1, 1, 1, 0.75))
		var x := size.x - 70.0
		for k in 4:
			var h := 4.0 + k * 3.0
			draw_rect(Rect2(x + k * 6.0, 16.0 - h, 4.0, h), Color(1, 1, 1, 0.75))
		var b := Rect2(size.x - 38.0, 4.0, 30.0, 13.0)
		draw_rect(b, Color(1, 1, 1, 0.75), false, 1.5)
		draw_rect(Rect2(b.end.x, 8.0, 3.0, 5.0), Color(1, 1, 1, 0.75))
		draw_rect(Rect2(b.position + Vector2(2.5, 2.5), Vector2(19.0, 8.0)), Color("#9fffa8"))


## Balãozinho ao lado do nome da loja.
class BalloonIcon:
	extends Control

	func _init() -> void:
		custom_minimum_size = Vector2(30, 40)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := Vector2(15, 15)
		draw_circle(c, 12.0, Color("#ff5d8f"))
		draw_circle(c + Vector2(-4, -4), 3.5, Color(1, 1, 1, 0.55))
		draw_colored_polygon(PackedVector2Array([c + Vector2(-3, 11), c + Vector2(3, 11), c + Vector2(0, 15)]), Color("#ff5d8f"))
		draw_polyline(PackedVector2Array([c + Vector2(0, 15), c + Vector2(3, 19), c + Vector2(-2, 22), c + Vector2(1, 25)]), Color.WHITE, 1.5, true)


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
