class_name Hud
extends CanvasLayer
## Interface do Faísca, quase sem texto: corações, estrelinhas pegas, os vaga-lumes achados, o
## balão de dica do vovô (o rosto dele e o desenho do botão) e a tela de fim da fase.
## O A na tela de fim emite `jogar_de_novo` (na Ilha, volta para o farol).

signal jogar_de_novo

const DURACAO_DICA := 5.0

var fim_aberto := false
var dica_atual := ""
var _coracoes: Array[IconeCoracao] = []
var _contador: Label
var _luzes: Array[IconeVagaLume] = []
var _balao: Control
var _desenho_dica: DesenhoDica
var _fim: Control
var _fim_nome: Label
var _fim_estrelas: Label
var _fim_luzes: Array[IconeVagaLume] = []
var _tempo_dica := 0.0


func _ready() -> void:
	layer = 5
	var linha := HBoxContainer.new()
	linha.position = Vector2(28, 22)
	linha.add_theme_constant_override("separation", 10)
	add_child(linha)
	for i in Jogador.VIDA_MAX:
		var c := IconeCoracao.new()
		c.custom_minimum_size = Vector2(48, 48)
		linha.add_child(c)
		_coracoes.append(c)
	var vao := Control.new()
	vao.custom_minimum_size = Vector2(18, 0)
	linha.add_child(vao)
	var estrela := IconeEstrela.new()
	estrela.custom_minimum_size = Vector2(48, 48)
	linha.add_child(estrela)
	_contador = _rotulo(38)
	linha.add_child(_contador)

	var luzes := HBoxContainer.new()
	luzes.add_theme_constant_override("separation", 6)
	luzes.position = Vector2(28, 82)
	add_child(luzes)
	for i in 3:
		var v := IconeVagaLume.new()
		v.custom_minimum_size = Vector2(34, 34)
		luzes.add_child(v)
		_luzes.append(v)
	_montar_balao()
	_montar_fim()
	mostrar_estrelas(0)


func _process(delta: float) -> void:
	if _tempo_dica > 0.0:
		_tempo_dica -= delta
		_desenho_dica.queue_redraw()
		if _tempo_dica <= 0.0:
			var tw := create_tween()
			tw.tween_property(_balao, "modulate:a", 0.0, 0.3)
			tw.tween_callback(func(): _balao.hide(); dica_atual = "")
	if fim_aberto and Input.is_action_just_pressed("pular"):
		jogar_de_novo.emit()


func mostrar_vida(vida: int) -> void:
	for i in _coracoes.size():
		var cheio := i < vida
		if _coracoes[i].cheio and not cheio:
			var tw := create_tween()
			tw.tween_property(_coracoes[i], "scale", Vector2.ONE * 1.3, 0.08)
			tw.tween_property(_coracoes[i], "scale", Vector2.ONE, 0.15)
		_coracoes[i].cheio = cheio
		_coracoes[i].pivot_offset = _coracoes[i].custom_minimum_size / 2.0
		_coracoes[i].queue_redraw()


func mostrar_estrelas(pegas: int) -> void:
	_contador.text = str(pegas)


## Quantos vaga-lumes há na fase (os outros espaços somem) e quantos já voltaram.
func mostrar_vaga_lumes(achados: int, total: int) -> void:
	for i in _luzes.size():
		_luzes[i].visible = i < total
		_luzes[i].aceso = i < achados
		_luzes[i].queue_redraw()


## Balão do Vovô Farol: "pulo_alto", "flutuar" ou "laser".
func mostrar_dica(qual: String) -> void:
	dica_atual = qual
	_desenho_dica.qual = qual
	_desenho_dica.queue_redraw()
	_tempo_dica = DURACAO_DICA
	_balao.show()
	_balao.modulate.a = 0.0
	create_tween().tween_property(_balao, "modulate:a", 1.0, 0.25)


func mostrar_fim(nome: String, pegas: int, total: int, achados: int, total_vaga_lumes: int) -> void:
	_fim_nome.text = nome
	_fim_estrelas.text = "%d / %d" % [pegas, total]
	for i in _fim_luzes.size():
		_fim_luzes[i].visible = i < total_vaga_lumes
		_fim_luzes[i].aceso = i < achados
		_fim_luzes[i].queue_redraw()
	_fim.show()
	_fim.modulate.a = 0.0
	create_tween().tween_property(_fim, "modulate:a", 1.0, 0.5)
	# Meio segundo antes de aceitar o A, para quem ainda está apertando não pular a tela.
	await get_tree().create_timer(0.6).timeout
	fim_aberto = true


## Fecha a tela de fim (na Ilha, o A volta para o farol).
func esconder_fim() -> void:
	fim_aberto = false
	_fim.hide()


func _montar_balao() -> void:
	_balao = PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = Color(1, 1, 1, 0.92)
	estilo.set_corner_radius_all(28)
	estilo.border_color = Color("2b2140")
	estilo.set_border_width_all(5)
	estilo.content_margin_left = 16
	estilo.content_margin_right = 16
	estilo.content_margin_top = 12
	estilo.content_margin_bottom = 12
	_balao.add_theme_stylebox_override("panel", estilo)
	_balao.anchor_left = 1.0
	_balao.anchor_right = 1.0
	_balao.anchor_top = 1.0
	_balao.anchor_bottom = 1.0
	_balao.offset_left = -420
	_balao.offset_right = -28
	_balao.offset_top = -190
	_balao.offset_bottom = -28
	add_child(_balao)
	var linha := HBoxContainer.new()
	linha.add_theme_constant_override("separation", 14)
	_balao.add_child(linha)
	var rosto := RostoVovo.new()
	rosto.custom_minimum_size = Vector2(120, 130)
	linha.add_child(rosto)
	_desenho_dica = DesenhoDica.new()
	_desenho_dica.custom_minimum_size = Vector2(230, 130)
	linha.add_child(_desenho_dica)
	_balao.hide()


func _montar_fim() -> void:
	_fim = ColorRect.new()
	_fim.color = Color(0.12, 0.09, 0.25, 0.72)
	_fim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fim)
	var coluna := VBoxContainer.new()
	coluna.set_anchors_preset(Control.PRESET_CENTER)
	coluna.grow_horizontal = Control.GROW_DIRECTION_BOTH
	coluna.grow_vertical = Control.GROW_DIRECTION_BOTH
	coluna.alignment = BoxContainer.ALIGNMENT_CENTER
	coluna.add_theme_constant_override("separation", 18)
	_fim.add_child(coluna)
	var grande := IconeEstrela.new()
	grande.custom_minimum_size = Vector2(170, 170)
	grande.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coluna.add_child(grande)
	_fim_nome = _rotulo(40)
	_fim_nome.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coluna.add_child(_fim_nome)
	var linha := HBoxContainer.new()
	linha.alignment = BoxContainer.ALIGNMENT_CENTER
	linha.add_theme_constant_override("separation", 12)
	coluna.add_child(linha)
	var estrela := IconeEstrela.new()
	estrela.custom_minimum_size = Vector2(56, 56)
	linha.add_child(estrela)
	_fim_estrelas = _rotulo(44)
	linha.add_child(_fim_estrelas)
	var vao := Control.new()
	vao.custom_minimum_size = Vector2(30, 0)
	linha.add_child(vao)
	for i in 3:
		var v := IconeVagaLume.new()
		v.custom_minimum_size = Vector2(52, 52)
		linha.add_child(v)
		_fim_luzes.append(v)
	var botao := BotaoA.new()
	botao.custom_minimum_size = Vector2(90, 90)
	botao.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	coluna.add_child(botao)
	_fim.hide()


func _rotulo(tamanho: int) -> Label:
	var r := Label.new()
	r.add_theme_font_size_override("font_size", tamanho)
	r.add_theme_color_override("font_color", Color.WHITE)
	r.add_theme_color_override("font_outline_color", Color("2b2140"))
	r.add_theme_constant_override("outline_size", 10)
	return r


## Estrela desenhada na tela (a fonte padrão da Godot não tem o ★).
class IconeEstrela extends Control:
	func _draw() -> void:
		var pts := PackedVector2Array()
		var c := size / 2.0
		for i in 10:
			var a := -PI / 2.0 + i * PI / 5.0
			pts.append(c + Vector2(cos(a), sin(a)) * (size.x * 0.5 if i % 2 == 0 else size.x * 0.22))
		draw_colored_polygon(pts, Color("ffd23f"))
		pts.append(pts[0])
		draw_polyline(pts, Color("2b2140"), maxf(size.x * 0.07, 3.0), true)


## Coração cheio (vermelho) ou vazio (só o contorno, clarinho).
class IconeCoracao extends Control:
	var cheio := true

	func _draw() -> void:
		var pts := PackedVector2Array()
		var c := size / 2.0 + Vector2(0, size.y * 0.04)
		for i in 40:
			var t := TAU * i / 40.0
			var x := 16.0 * pow(sin(t), 3)
			var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
			pts.append(c + Vector2(x, -y) * size.x / 36.0)
		draw_colored_polygon(pts, Color("ff4d6d") if cheio else Color(1, 1, 1, 0.35))
		pts.append(pts[0])
		draw_polyline(pts, Color("2b2140"), 4.0, true)
		if cheio:
			draw_circle(c + Vector2(-size.x * 0.17, -size.y * 0.12), size.x * 0.07, Color(1, 1, 1, 0.7))


## Bolinha do vaga-lume: acesa (verde-limão brilhando) ou apagada (cinza).
class IconeVagaLume extends Control:
	var aceso := false

	func _draw() -> void:
		var c := size / 2.0
		var r := size.x * 0.36
		if aceso:
			draw_circle(c, r * 1.35, Color(0.78, 1.0, 0.3, 0.35))
		draw_circle(c, r, Color("c6ff4a") if aceso else Color(1, 1, 1, 0.3))
		draw_arc(c, r, 0, TAU, 32, Color("2b2140"), 3.0, true)


## Rosto do Vovô Farol no rádio: cabeça redonda azul-acinzentada, visor com olhos bondosos,
## bigodão branco e a luzinha amarela no alto.
class RostoVovo extends Control:
	func _draw() -> void:
		var c := Vector2(size.x / 2.0, size.y * 0.58)
		var r := size.x * 0.42
		draw_line(c + Vector2(0, -r), c + Vector2(0, -r - 14), Color("2b2140"), 5.0)
		draw_circle(c + Vector2(0, -r - 18), 9, Color("ffd23f"))
		draw_circle(c, r, Color("8fa3c7"))
		draw_arc(c, r, 0, TAU, 48, Color("2b2140"), 4.0, true)
		var visor := Rect2(c + Vector2(-r * 0.72, -r * 0.55), Vector2(r * 1.44, r * 0.8))
		draw_rect(visor, Color("1b1d2a"))
		for lado in [-1.0, 1.0]:
			draw_arc(c + Vector2(r * 0.3 * lado, -r * 0.12), r * 0.15, PI, TAU, 12, Color("8ff3ff"), 5.0, true)
		for lado in [-1.0, 1.0]:
			draw_circle(c + Vector2(r * 0.22 * lado, r * 0.42), r * 0.24, Color.WHITE)
		draw_circle(c + Vector2(0, r * 0.3), r * 0.1, Color("ff8fa3"))


## Botão A do controle (verde, com a letra), que pode estar "segurado".
class BotaoA extends Control:
	func _draw() -> void:
		var c := size / 2.0
		var r := size.x * 0.45
		draw_circle(c + Vector2(0, 4), r, Color("1f7a3a"))
		draw_circle(c, r, Color("3ccf6a"))
		draw_arc(c, r, 0, TAU, 40, Color("2b2140"), 4.0, true)
		var fonte := ThemeDB.fallback_font
		var t := int(r * 1.2)
		var largura := fonte.get_string_size("A", HORIZONTAL_ALIGNMENT_LEFT, -1, t).x
		draw_string(fonte, c + Vector2(-largura / 2.0, t * 0.36), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, t, Color.WHITE)


## Desenho da dica: o botão A sendo segurado (a barrinha enche) e o que acontece.
##   pulo_alto: o Faísca pulando bem alto; flutuar: os jatos na descida; laser: o feixe na flor.
class DesenhoDica extends Control:
	var qual := ""

	func _draw() -> void:
		var tempo := Time.get_ticks_msec() / 1000.0
		var enche := fmod(tempo, 1.6) / 1.2
		var b := Vector2(52, size.y * 0.42)
		draw_circle(b + Vector2(0, 4), 36, Color("1f7a3a"))
		draw_circle(b, 36, Color("3ccf6a"))
		draw_arc(b, 36, 0, TAU, 40, Color("2b2140"), 4.0, true)
		var fonte := ThemeDB.fallback_font
		draw_string(fonte, b + Vector2(-13, 15), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color.WHITE)
		var barra := Rect2(b + Vector2(-40, 50), Vector2(80, 14))
		draw_rect(barra, Color(0, 0, 0, 0.15))
		draw_rect(Rect2(barra.position, Vector2(80 * clampf(enche, 0, 1), 14)), Color("ffd23f"))
		draw_rect(barra, Color("2b2140"), false, 3.0)
		var f := Vector2(170, size.y * 0.5)
		match qual:
			"pulo_alto":
				var alto := 40.0 * sin(clampf(enche, 0, 1) * PI)
				draw_line(f + Vector2(-30, 44), f + Vector2(30, 44), Color("2b2140"), 4.0)
				_faisca(f + Vector2(0, 20 - alto))
				draw_line(f + Vector2(42, 30), f + Vector2(42, -40), Color("ff8c42"), 5.0)
				draw_colored_polygon(PackedVector2Array([f + Vector2(32, -36), f + Vector2(52, -36), f + Vector2(42, -52)]), Color("ff8c42"))
			"flutuar":
				var p := f + Vector2(0, -12 + sin(tempo * 3.0) * 4.0)
				_faisca(p)
				for lado in [-8.0, 8.0]:
					draw_line(p + Vector2(lado, 22), p + Vector2(lado, 52), Color("8ff3ff"), 6.0)
				draw_arc(f + Vector2(0, 30), 50, PI * 1.1, PI * 1.9, 16, Color("ff8c42"), 4.0)
			"laser":
				var p := f + Vector2(0, -30)
				_faisca(p)
				for lado in [-8.0, 8.0]:
					draw_line(p + Vector2(lado, 22), f + Vector2(lado, 36), Color("8ff3ff"), 5.0)
				for i in 6:
					var a := TAU * i / 6.0
					draw_circle(f + Vector2(cos(a), sin(a) * 0.5) * 14 + Vector2(0, 42), 8, Color("ff8fc8"))
				draw_circle(f + Vector2(0, 42), 7, Color("ffe066"))

	## O Faísca em miniatura: cabeça branca com o visor e o corpinho laranja.
	func _faisca(p: Vector2) -> void:
		draw_circle(p + Vector2(0, 10), 10, Color("ff7a22"))
		draw_rect(Rect2(p + Vector2(-16, -22), Vector2(32, 26)), Color("f4f5f9"))
		draw_rect(Rect2(p + Vector2(-16, -22), Vector2(32, 26)), Color("2b2140"), false, 3.0)
		draw_rect(Rect2(p + Vector2(-11, -17), Vector2(22, 14)), Color("1b1d2a"))
		for lado in [-5.0, 5.0]:
			draw_line(p + Vector2(lado, -14), p + Vector2(lado, -8), Color("8ff3ff"), 3.0)
