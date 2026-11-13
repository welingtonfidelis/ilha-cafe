class_name PainelTintas
extends CenterContainer
## A lojinha das tintas do Faísca (2026-11-12, pedido do usuário: trocar a cor por uma lojinha com prévia, como o
## guarda-roupa das crianças na ilha, aberta pelo soco no cabide do farol). À esquerda, o Faísca de verdade num
## retrato, girando devagar, que já prova a tinta do cartão marcado; à direita, os cartões: a de fábrica (laranja) e
## as seis tintas da Máquina de Brindes. As que ainda não saíram ficam com cadeado: dá para provar, não para
## escolher (o A mostra que ela sai na máquina). Feita para quem não lê: a lata na cor, o cadeado, o visto verde da
## que está em uso; o nome embaixo é só apoio. O A escolhe (e a lojinha fica aberta para provar outras); B fecha.

signal escolheu(id: String)
signal fechou

const LADO := Vector2(132, 156)
const VERDE := Color("#7be36a")

var retrato: Portrait
var cartoes := {}
## A tinta em uso ("" é a de fábrica), as que já saíram e a do cartão marcado.
var atual := ""
var tem: Array = []
var marcado := ""
var _sfx: Node
var _nome: Label
var _contagem: Label
var _aviso: HBoxContainer
var _aviso_tempo := 0.0
var _voltar: Button


func montar(sfx_parent: Node) -> void:
	_sfx = sfx_parent
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var painel := PanelContainer.new()
	painel.add_theme_stylebox_override("panel", MenuKit.panel_style())
	add_child(painel)
	var caixa := VBoxContainer.new()
	caixa.add_theme_constant_override("separation", 12)
	painel.add_child(caixa)
	# O topo: a lata, "Tintas" e quantas já saíram (a latinha e o número).
	var topo := HBoxContainer.new()
	topo.add_theme_constant_override("separation", 12)
	caixa.add_child(topo)
	var icone := LataIcone.new()
	icone.cor = Brindes.COR_ORIGINAL
	icone.custom_minimum_size = Vector2(48, 48)
	topo.add_child(icone)
	var titulo := Label.new()
	titulo.text = "Tintas"
	titulo.add_theme_font_size_override("font_size", 34)
	titulo.add_theme_color_override("font_color", MenuKit.GOLD)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topo.add_child(titulo)
	var mini := LataIcone.new()
	mini.cor = Color("#8ff3ff")
	mini.custom_minimum_size = Vector2(34, 34)
	topo.add_child(mini)
	_contagem = Label.new()
	_contagem.add_theme_font_size_override("font_size", 28)
	_contagem.add_theme_color_override("font_color", Color("#ffe9a8"))
	topo.add_child(_contagem)
	var meio := HBoxContainer.new()
	meio.add_theme_constant_override("separation", 20)
	caixa.add_child(meio)
	# A prévia: o Faísca girando devagar, já com a tinta do cartão marcado.
	var esquerda := VBoxContainer.new()
	esquerda.add_theme_constant_override("separation", 6)
	meio.add_child(esquerda)
	var moldura := Panel.new()
	moldura.custom_minimum_size = Vector2(270, 330)
	moldura.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	moldura.add_theme_stylebox_override("panel", MenuKit.box(Color.WHITE, 14))
	esquerda.add_child(moldura)
	retrato = Portrait.new(moldura.custom_minimum_size)
	moldura.add_child(retrato)
	retrato.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	retrato.girando = 0.6
	_nome = Label.new()
	_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_nome.custom_minimum_size = Vector2(270, 0)
	_nome.add_theme_font_size_override("font_size", 24)
	esquerda.add_child(_nome)
	# Os cartões: a de fábrica e as seis tintas, quatro por linha.
	var grade := GridContainer.new()
	grade.columns = 4
	grade.add_theme_constant_override("h_separation", 10)
	grade.add_theme_constant_override("v_separation", 10)
	grade.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meio.add_child(grade)
	grade.add_child(_cartao(""))
	for id in Brindes.ids("tinta"):
		grade.add_child(_cartao(id))
	# O aviso das trancadas: a cápsula da Máquina de Brindes e a frase de apoio.
	_aviso = HBoxContainer.new()
	_aviso.alignment = BoxContainer.ALIGNMENT_CENTER
	_aviso.add_theme_constant_override("separation", 10)
	_aviso.custom_minimum_size = Vector2(0, 44)
	caixa.add_child(_aviso)
	var capsula := CapsulaIcone.new()
	capsula.custom_minimum_size = Vector2(40, 40)
	_aviso.add_child(capsula)
	var frase := Label.new()
	frase.text = "Essa sai na Máquina de Brindes!"
	frase.add_theme_font_size_override("font_size", 22)
	frase.add_theme_color_override("font_color", Color("#8ff3ff"))
	_aviso.add_child(frase)
	_aviso.modulate.a = 0.0
	_voltar = MenuKit.icon_button("Voltar", "voltar", sfx_parent, 260)
	_voltar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_voltar.pressed.connect(fechar)
	caixa.add_child(_voltar)


## Abre com a tinta em uso marcada (e já provada).
func abrir(em_uso: String, ja_tem: Array) -> void:
	atual = em_uso
	tem = ja_tem.duplicate()
	retrato.show_character("faisca")
	_aviso.modulate.a = 0.0
	_aviso_tempo = 0.0
	show()
	_provar(atual)
	atualizar()
	(cartoes[atual].botao as Button).grab_focus.call_deferred()


func fechar() -> void:
	if not visible:
		return
	Sfx.play(_sfx, "ui_ok", 0.0, 0.0)
	retrato.cheer(false)
	hide()
	fechou.emit()


func _tem(id: String) -> bool:
	return id == "" or id in tem


func atualizar() -> void:
	_contagem.text = "%d/%d" % [tem.filter(func(t: String) -> bool: return Brindes.dados(t).get("tipo", "") == "tinta").size(),
			Brindes.ids("tinta").size()]
	for id in cartoes:
		var c: Dictionary = cartoes[id]
		var lata: LataIcone = c.lata
		lata.trancada = not _tem(id)
		lata.usando = id == atual
		lata.queue_redraw()
		var borda: StyleBoxFlat = (c.botao as Button).get_theme_stylebox("normal")
		borda.border_color = VERDE if id == atual else Color.TRANSPARENT


func _cartao(id: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = LADO
	var normal := MenuKit.box(MenuKit.BUTTON, 14, Color.TRANSPARENT, 4)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", normal)
	b.add_theme_stylebox_override("pressed", normal)
	b.add_theme_stylebox_override("focus", MenuKit.focus_style(14, 5))
	MenuKit.focus_on_mouse_move(b)
	var dentro := VBoxContainer.new()
	dentro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dentro.offset_top = 6
	dentro.offset_bottom = -6
	dentro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_theme_constant_override("separation", 2)
	b.add_child(dentro)
	var lata := LataIcone.new()
	lata.cor = Brindes.cor_de(id)
	lata.metal = Brindes.metal(id)
	lata.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lata.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_child(lata)
	var nome := Label.new()
	nome.text = _nome_de(id)
	nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nome.add_theme_font_size_override("font_size", 16)
	nome.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dentro.add_child(nome)
	b.focus_entered.connect(func() -> void:
		Sfx.play(_sfx, "ui_mover", 0.0, 0.0)
		_provar(id))
	b.pressed.connect(escolher.bind(id))
	cartoes[id] = {"botao": b, "lata": lata}
	return b


func _nome_de(id: String) -> String:
	return "Laranja" if id == "" else String(Brindes.dados(id).get("nome", ""))


## Marcar um cartão já prova a tinta no Faísca do retrato (até as trancadas).
func _provar(id: String) -> void:
	marcado = id
	retrato.pintar_faisca(Brindes.cor_de(id), Brindes.metal(id))
	_nome.text = _nome_de(id)
	_nome.add_theme_color_override("font_color", Brindes.cor_de(id).lightened(0.35))


## A: pinta o Faísca com ela (se já saiu) e ele dá tchau; trancada, nega e mostra a Máquina de Brindes.
func escolher(id: String) -> void:
	if not _tem(id):
		Sfx.play(_sfx, "sem_municao", 0.0, 0.0)
		_aviso.modulate.a = 1.0
		_aviso_tempo = 2.2
		var c: Button = cartoes[id].botao
		var tw := c.create_tween()
		tw.tween_property(c, "rotation", 0.06, 0.06)
		tw.tween_property(c, "rotation", -0.06, 0.08)
		tw.tween_property(c, "rotation", 0.0, 0.06)
		return
	Sfx.play(_sfx, "ui_ok", 0.0, 0.0)
	Sfx.play(_sfx, "faisquinha_salvo", -6.0, 0.0)
	atual = id
	escolheu.emit(id)
	atualizar()
	retrato.cheer(true)
	get_tree().create_timer(1.4, true, false, true).timeout.connect(func() -> void:
		if is_instance_valid(retrato):
			retrato.cheer(false))


func _process(delta: float) -> void:
	if _aviso_tempo > 0.0:
		_aviso_tempo -= delta
		if _aviso_tempo <= 0.6:
			_aviso.modulate.a = maxf(_aviso_tempo / 0.6, 0.0)
	# O cartão girado pelo "não" gira em volta do meio.
	for id in cartoes:
		var b: Button = cartoes[id].botao
		b.pivot_offset = b.size * 0.5


## A lata de tinta desenhada: o balde de metal com a alça, a tinta em cima e o escorrido na frente. Trancada, fica
## apagada com um cadeado; em uso, ganha o visto verde.
class LataIcone extends Control:
	var cor := Color.WHITE
	var metal := false
	var trancada := false
	var usando := false

	func _draw() -> void:
		var lado := minf(size.x, size.y)
		var c := Vector2(size.x * 0.5, size.y * 0.54)
		var lw := lado * 0.62
		var lh := lado * 0.56
		var ry := lw * 0.16
		var apaga := 0.45 if trancada else 1.0
		var lata_cor := Color("c9cfdb").darkened(0.0 if not trancada else 0.35)
		var tinta := cor if not trancada else cor.darkened(0.35)
		tinta.a = 1.0
		var topo := c.y - lh * 0.5
		var base := c.y + lh * 0.5
		# A alça, atrás.
		draw_arc(Vector2(c.x, topo), lw * 0.5, PI, TAU, 24, Color("8a93a6") * Color(1, 1, 1, apaga), maxf(2.0, lado * 0.035), true)
		# O corpo e o fundo redondo.
		draw_rect(Rect2(c.x - lw * 0.5, topo, lw, lh), lata_cor)
		_elipse(Vector2(c.x, base), lw * 0.5, ry, lata_cor)
		draw_rect(Rect2(c.x - lw * 0.5, topo + lh * 0.22, lw, lh * 0.08), lata_cor.darkened(0.15))
		draw_rect(Rect2(c.x - lw * 0.5, topo + lh * 0.7, lw, lh * 0.08), lata_cor.darkened(0.15))
		# A boca: o aro e a tinta dentro.
		_elipse(Vector2(c.x, topo), lw * 0.5, ry, lata_cor.darkened(0.25))
		_elipse(Vector2(c.x, topo + 1.0), lw * 0.44, ry * 0.8, tinta)
		if metal and not trancada:
			_elipse(Vector2(c.x - lw * 0.14, topo), lw * 0.12, ry * 0.3, Color(1, 1, 0.85, 0.8))
		# O escorrido pela frente.
		var pingo := Rect2(c.x + lw * 0.05, topo + ry * 0.4, lw * 0.14, lh * 0.42)
		draw_rect(pingo, tinta)
		draw_circle(Vector2(pingo.get_center().x, pingo.end.y), lw * 0.07, tinta)
		draw_rect(Rect2(c.x - lw * 0.32, topo + ry * 0.4, lw * 0.1, lh * 0.22), tinta)
		draw_circle(Vector2(c.x - lw * 0.27, topo + ry * 0.4 + lh * 0.22), lw * 0.05, tinta)
		if trancada:
			_cadeado(Vector2(c.x + lw * 0.42, base - lh * 0.05), lado * 0.2)
		if usando:
			_visto(Vector2(size.x - lado * 0.17, lado * 0.17), lado * 0.15)

	func _elipse(m: Vector2, rx: float, ry: float, cor_dela: Color) -> void:
		var pts := PackedVector2Array()
		for i in 28:
			var a := TAU * i / 28.0
			pts.append(m + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, cor_dela)

	func _cadeado(m: Vector2, t: float) -> void:
		draw_arc(m + Vector2(0, -t * 0.35), t * 0.32, PI, TAU, 16, Color("#ffd23f"), t * 0.14, true)
		draw_rect(Rect2(m.x - t * 0.5, m.y - t * 0.38, t, t * 0.8), Color("#ffd23f"))
		draw_circle(m + Vector2(0, t * 0.0), t * 0.11, Color("#5a4300"))

	func _visto(m: Vector2, r: float) -> void:
		draw_circle(m, r, Color("#7be36a"))
		draw_polyline(PackedVector2Array([m + Vector2(-r * 0.5, 0), m + Vector2(-r * 0.12, r * 0.4), m + Vector2(r * 0.5, -r * 0.4)]),
				Color("#173d10"), maxf(2.0, r * 0.28), true)


## A cápsula da Máquina de Brindes (a metade de cima colorida, a de baixo branca), para o aviso das trancadas.
class CapsulaIcone extends Control:
	func _draw() -> void:
		var r := minf(size.x, size.y) * 0.45
		var m := size * 0.5
		draw_circle(m, r, Color("#fff6fb"))
		var cima := PackedVector2Array()
		for i in 17:
			var a := PI + PI * i / 16.0
			cima.append(m + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(cima, Color("#ff5fae"))
		draw_line(m - Vector2(r, 0), m + Vector2(r, 0), Color("#c08aa8"), 2.0)
