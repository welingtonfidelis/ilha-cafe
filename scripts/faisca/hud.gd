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
	# Corações, estrelinhas e vaga-lumes no canto de cima à direita, no mesmo lugar e tamanho dos corações e
	# das moedas das crianças (pedido do usuário em 2026-10-29: "padronizar o hud entre os personagens").
	var canto := VBoxContainer.new()
	canto.anchor_left = 1.0
	canto.anchor_right = 1.0
	# O coração da direita fica com o meio a 36 px da borda e a 34 px do topo, como o das crianças.
	canto.offset_right = -17
	canto.offset_top = 14
	canto.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	canto.add_theme_constant_override("separation", 4)
	canto.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canto)
	var linha := HBoxContainer.new()
	linha.size_flags_horizontal = Control.SIZE_SHRINK_END
	linha.add_theme_constant_override("separation", 8)
	# Na ilha os corações dele somem (ficam os das crianças, no mesmo lugar): a linha guarda a altura para as
	# estrelinhas não subirem por cima deles.
	linha.custom_minimum_size = Vector2(0, 38)
	canto.add_child(linha)
	for i in Jogador.VIDA_MAX:
		var c := IconeCoracao.new()
		c.custom_minimum_size = Vector2(38, 38)
		linha.add_child(c)
		_coracoes.append(c)
	# O número fica à esquerda da estrela, como o das moedas.
	var estrelas := HBoxContainer.new()
	estrelas.size_flags_horizontal = Control.SIZE_SHRINK_END
	estrelas.add_theme_constant_override("separation", 8)
	canto.add_child(estrelas)
	_contador = _rotulo(32)
	estrelas.add_child(_contador)
	var estrela := IconeEstrela.new()
	estrela.custom_minimum_size = Vector2(38, 38)
	estrela.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	estrelas.add_child(estrela)

	var luzes := HBoxContainer.new()
	luzes.size_flags_horizontal = Control.SIZE_SHRINK_END
	luzes.add_theme_constant_override("separation", 6)
	canto.add_child(luzes)
	for i in 3:
		var v := IconeVagaLume.new()
		v.custom_minimum_size = Vector2(32, 32)
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


## Na ilha o Faísca usa os corações das crianças (os do canto direito, do main.gd): os três dele somem.
func mostrar_coracoes(on: bool) -> void:
	for c in _coracoes:
		c.visible = on


func mostrar_estrelas(pegas: int) -> void:
	_contador.text = str(pegas)


## Quantos vaga-lumes há na fase (os outros espaços somem) e quantos já voltaram.
func mostrar_vaga_lumes(achados: int, total: int) -> void:
	for i in _luzes.size():
		_luzes[i].visible = i < total
		_luzes[i].aceso = i < achados
		_luzes[i].queue_redraw()


## Balão do Vovô Farol: "pulo_alto", "flutuar", "laser", "tocha" ou "golpe".
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
##   pulo_alto: o Faísca pulando bem alto; flutuar: o laser na descida; laser: o feixe na flor;
##   tocha: o feixe na tocha, que pega fogo. No golpe é o X apertado três vezes, na parede rachada.
##   quicar: a nuvem rosa amassa e joga para cima; balao: o balão de chiclete enche, sobe e estoura (2-2).
##   dado: o soco tomba o dado; ioio: X no ar perto da argola laranja puxa o Faísca até ela (2-3).
class DesenhoDica extends Control:
	var qual := ""

	func _draw() -> void:
		var tempo := Time.get_ticks_msec() / 1000.0
		var enche := fmod(tempo, 1.6) / 1.2
		var b := Vector2(52, size.y * 0.42)
		var golpe := qual in ["golpe", "alavanca", "dado", "ioio"]
		# O botão de cada dica: X (azul) nos golpes, Y (amarelo) no agarrar, A (verde) no resto.
		var letra := "X" if golpe or qual == "giro_forte" else ("Y" if qual == "agarrar" else "A")
		var cores := {"X": [Color("1d4f9a"), Color("4a90e2")], "Y": [Color("a8800c"), Color("f5c518")], "A": [Color("1f7a3a"), Color("3ccf6a")]}
		# No golpe o botão pulsa a cada toque; nos outros fica apertado enquanto a barrinha enche.
		var toque := fmod(tempo, 1.6) < 1.2 and fmod(tempo * 2.5, 1.0) < 0.35 if golpe else false
		var raio := 32.0 if toque else 36.0
		draw_circle(b + Vector2(0, 4), raio, cores[letra][0])
		draw_circle(b, raio, cores[letra][1])
		draw_arc(b, raio, 0, TAU, 40, Color("2b2140"), 4.0, true)
		var fonte := ThemeDB.fallback_font
		draw_string(fonte, b + Vector2(-13, 15), letra, HORIZONTAL_ALIGNMENT_LEFT, -1, 42, Color.WHITE)
		if golpe:
			var vezes := mini(int(fmod(tempo, 1.6) * 2.5) + 1, 3)
			for i in 3:
				draw_circle(b + Vector2(-24 + i * 24, 58), 8, Color("ffd23f") if i < vezes else Color(0, 0, 0, 0.15))
				draw_arc(b + Vector2(-24 + i * 24, 58), 8, 0, TAU, 16, Color("2b2140"), 2.5, true)
		else:
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
			"tocha":
				var p := f + Vector2(0, -34)
				_faisca(p)
				for lado in [-8.0, 8.0]:
					draw_line(p + Vector2(lado, 22), f + Vector2(lado, 26), Color("8ff3ff"), 5.0)
				draw_rect(Rect2(f + Vector2(-5, 30), Vector2(10, 26)), Color("8a5a36"))
				draw_rect(Rect2(f + Vector2(-9, 26), Vector2(18, 8)), Color("6a6478"))
				if enche > 0.5:
					var chama := 1.0 + sin(tempo * 14.0) * 0.12
					draw_colored_polygon(PackedVector2Array([f + Vector2(-9, 26), f + Vector2(9, 26), f + Vector2(0, 26 - 22 * chama)]), Color("ff9a2e"))
					draw_colored_polygon(PackedVector2Array([f + Vector2(-5, 26), f + Vector2(5, 26), f + Vector2(0, 26 - 13 * chama)]), Color("ffe066"))
			"tampa":
				# Em cima da tampa da panela, que treme e pula levando o Faísca lá para o alto.
				var ciclo := fmod(tempo, 2.0)
				var sobe := 0.0 if ciclo < 1.2 else sin((ciclo - 1.2) / 0.8 * PI) * 50.0
				var treme := sin(tempo * 40.0) * 2.0 if ciclo > 0.8 and ciclo < 1.2 else 0.0
				draw_rect(Rect2(f + Vector2(-30, 36), Vector2(60, 20)), Color("8a8fa8"))
				draw_rect(Rect2(f + Vector2(-34 + treme, 30 - sobe * 0.15), Vector2(68, 7)), Color("c9cede"))
				draw_circle(f + Vector2(treme, 28 - sobe * 0.15), 5, Color("6a6478"))
				_faisca(f + Vector2(0, 4 - sobe))
				if ciclo > 0.8:
					for i in 3:
						draw_circle(f + Vector2(-26 + i * 26, 22 - fmod(tempo * 30.0 + i * 7.0, 24.0)), 5, Color(1, 1, 1, 0.7))
			"botao":
				# Pula e cai em cima do botão vermelho, que afunda.
				var pulo := absf(sin(tempo * 3.0))
				var em_cima := pulo < 0.15
				draw_line(f + Vector2(-44, 52), f + Vector2(44, 52), Color("2b2140"), 4.0)
				draw_rect(Rect2(f + Vector2(-26, 42), Vector2(52, 10)), Color("6a6478"))
				draw_rect(Rect2(f + Vector2(-18, 36 if em_cima else 30), Vector2(36, 12 if em_cima else 14)), Color("ff5d5d"))
				_faisca(f + Vector2(0, 2 - pulo * 46))
				if em_cima:
					for i in 3:
						var a := -PI * 0.15 - i * PI * 0.35
						draw_line(f + Vector2(0, 34) + Vector2(cos(a), sin(a)) * 30, f + Vector2(0, 34) + Vector2(cos(a), sin(a)) * 42, Color("ffd23f"), 3.0)
			"alavanca":
				# Soca a alavanca: o cabo vira e a grade sobe.
				var bate := fmod(tempo * 1.2, 1.0) < 0.3
				var p := f + Vector2(-28 + (8.0 if bate else 0.0), 10)
				_faisca(p)
				draw_line(p + Vector2(14, 6), p + Vector2(28 if bate else 20, 6), Color("ff7a22"), 7.0)
				draw_rect(Rect2(f + Vector2(14, 40), Vector2(26, 10)), Color("6a6478"))
				var vira := 0.6 if fmod(tempo * 1.2, 1.0) > 0.3 else -0.6
				var cabo := f + Vector2(27, 40)
				draw_line(cabo, cabo + Vector2(sin(vira), -cos(vira)) * 30, Color("ffd23f"), 6.0)
				draw_circle(cabo + Vector2(sin(vira), -cos(vira)) * 30, 6, Color("ff5d5d"))
			"agarrar":
				# A Bolota tonta (estrelinhas girando); segura Y: o Faísca gira com ela pendurada pela antena;
				# solta: ela voa longe.
				var ciclo := fmod(tempo, 2.0)
				_faisca(f + Vector2(0, 8))
				if ciclo < 0.5:
					var bola := f + Vector2(46, 10 + sin(tempo * 9.0) * 2.0)
					_bolota(bola)
					for i in 3:
						var a := tempo * 6.0 + i * TAU / 3.0
						var e := bola + Vector2(cos(a) * 14, -26 + sin(a) * 4)
						draw_circle(e, 4, Color("ffd23f"))
						draw_arc(e, 4, 0, TAU, 12, Color("2b2140"), 1.5, true)
				elif ciclo < 1.6:
					var a := (ciclo - 0.5) * TAU * 1.4
					var bola := f + Vector2(cos(a) * 46, 10 + sin(a) * 14)
					draw_line(f + Vector2(0, 12), bola + (f + Vector2(0, 12) - bola).normalized() * 12, Color("2b2140"), 3.0)
					_bolota(bola)
				else:
					var voo := (ciclo - 1.6) / 0.4
					_bolota(f + Vector2(46 + voo * 50, 10 - sin(voo * PI) * 26))
			"giro_forte":
				# Segura X: carrega (anel dourado crescendo) e gira de braços abertos, jogando as Bolotas longe.
				var ciclo := fmod(tempo, 1.6)
				if ciclo < 1.2:
					var treme := sin(tempo * 50.0) * 2.0 * ciclo
					draw_arc(f + Vector2(0, 40), 14 + 30 * ciclo / 1.2, 0, TAU, 32, Color("ffd23f"), 4.0)
					_faisca(f + Vector2(treme, 8))
					for lado in [-1.0, 1.0]:
						_bolota(f + Vector2(52 * lado, 24))
				else:
					var giro := (ciclo - 1.2) / 0.4
					for i in 3:
						var a := tempo * 18.0 + i * TAU / 3.0
						draw_arc(f + Vector2(0, 14), 34, a, a + 1.2, 12, Color("8ff3ff"), 4.0)
					_faisca(f + Vector2(0, 8))
					draw_line(f + Vector2(-26, 8), f + Vector2(26, 8), Color("f4f5f9"), 6.0)
					for lado in [-1.0, 1.0]:
						_bolota(f + Vector2((52 + giro * 30) * lado, 24 - sin(giro * PI) * 20))
			"quicar":
				# Cai na nuvem rosa, ela amassa e joga o Faísca lá para cima.
				var pulo := absf(sin(tempo * 2.6))
				var amassa := 1.0 - maxf(0.0, 0.25 - pulo) * 1.6
				for bola in [[Vector2(0, 46), 34.0], [Vector2(-24, 42), 20.0], [Vector2(24, 42), 20.0]]:
					draw_set_transform(f + bola[0], 0.0, Vector2(1.0, 0.45 * amassa))
					draw_circle(Vector2.ZERO, bola[1], Color("ffb3d9"))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
				_faisca(f + Vector2(0, 14 - pulo * 50))
				if pulo < 0.2:
					for lado in [-1.0, 1.0]:
						draw_line(f + Vector2(30 * lado, 30), f + Vector2(42 * lado, 18), Color("ff7a22"), 3.0)
			"balao":
				# Segurando A no ar, o balão de chiclete enche e o Faísca sobe devagar; soltando, estoura.
				var ciclo := fmod(tempo, 1.6)
				var sobe := clampf(ciclo / 1.2, 0.0, 1.0)
				var p := f + Vector2(0, 34 - sobe * 46 + (maxf(ciclo - 1.2, 0.0) / 0.4) * 30.0)
				_faisca(p)
				if ciclo < 1.2:
					var r := 8.0 + 12.0 * minf(sobe * 3.0, 1.0)
					draw_line(p + Vector2(0, -22), p + Vector2(0, -30), Color("c2407e"), 2.0)
					draw_circle(p + Vector2(0, -30 - r), r, Color("ff79bd"))
					draw_circle(p + Vector2(-r * 0.4, -30 - r * 1.4), r * 0.2, Color(1, 1, 1, 0.7))
				else:
					for i in 6:
						var a := TAU * i / 6.0
						draw_line(p + Vector2(0, -46) + Vector2(cos(a), sin(a)) * 8, p + Vector2(0, -46) + Vector2(cos(a), sin(a)) * 18, Color("ff79bd"), 3.0)
			"dado":
				# Soca o dado, e ele tomba para o lado (vira em volta da aresta de baixo).
				var ciclo := fmod(tempo, 1.6)
				var bate := ciclo > 0.2 and ciclo < 0.45
				var p := f + Vector2(-34 + (8.0 if bate else 0.0), 10)
				_faisca(p)
				draw_line(p + Vector2(14, 6), p + Vector2(28 if bate else 20, 6), Color("ff7a22"), 7.0)
				draw_line(f + Vector2(-50, 52), f + Vector2(60, 52), Color("2b2140"), 4.0)
				var gira := clampf((ciclo - 0.45) / 0.4, 0.0, 1.0) * PI * 0.5
				var pivo := f + Vector2(36, 52)
				var cantos := PackedVector2Array()
				for c in [Vector2(-28, 0), Vector2(0, 0), Vector2(0, -28), Vector2(-28, -28)]:
					cantos.append(pivo + c.rotated(gira))
				draw_colored_polygon(cantos, Color("f4f5f9"))
				cantos.append(cantos[0])
				draw_polyline(cantos, Color("2b2140"), 3.0)
				draw_circle(pivo + Vector2(-14, -14).rotated(gira), 4, Color("2b2140"))
			"ioio":
				# No ar, X perto da argola laranja: o fio estica e puxa o Faísca até ela.
				var ciclo := fmod(tempo, 1.6)
				var argola := f + Vector2(40, -34)
				draw_arc(argola, 12, 0, TAU, 24, Color("ff7a22"), 5.0)
				var puxa := clampf((ciclo - 0.4) / 0.8, 0.0, 1.0)
				var p := (f + Vector2(-30, 24)).lerp(argola + Vector2(0, 22), puxa)
				_faisca(p)
				if ciclo > 0.3:
					draw_line(p + Vector2(10, -10), argola, Color("ff7a22"), 2.5)
			"golpe":
				var bate := fmod(tempo * 2.5, 1.0) < 0.35
				var p := f + Vector2(-26 + (8.0 if bate else 0.0), 10)
				_faisca(p)
				draw_line(p + Vector2(14, 6), p + Vector2(28 if bate else 20, 6), Color("ff7a22"), 7.0)
				var parede := Rect2(f + Vector2(16, -38), Vector2(30, 84))
				draw_rect(parede, Color("8a90a8"))
				draw_rect(parede, Color("2b2140"), false, 3.0)
				draw_polyline(PackedVector2Array([f + Vector2(31, -38), f + Vector2(24, -12), f + Vector2(36, 4), f + Vector2(26, 28), f + Vector2(32, 46)]), Color("2b2140"), 3.0)
				if bate:
					for i in 4:
						var a := -0.8 + i * 0.5
						draw_line(f + Vector2(14, 16), f + Vector2(14, 16) + Vector2(cos(a + PI), sin(a + PI)) * 14, Color("ffd23f"), 3.0)

	## Bolota em miniatura: bolinha roxa de um olho, com a antena de bolinha vermelha.
	func _bolota(p: Vector2) -> void:
		draw_line(p + Vector2(0, -10), p + Vector2(0, -18), Color("3d2e5c"), 3.0)
		draw_circle(p + Vector2(0, -19), 3.5, Color("ff5a6e"))
		draw_circle(p, 11, Color("9b5de5"))
		draw_arc(p, 11, 0, TAU, 24, Color("2b2140"), 2.5, true)
		draw_circle(p + Vector2(0, -2), 4, Color.WHITE)
		draw_circle(p + Vector2(0, -2), 2, Color("1b1530"))

	## O Faísca em miniatura: cabeça branca com o visor e o corpinho laranja.
	func _faisca(p: Vector2) -> void:
		draw_circle(p + Vector2(0, 10), 10, Color("ff7a22"))
		draw_rect(Rect2(p + Vector2(-16, -22), Vector2(32, 26)), Color("f4f5f9"))
		draw_rect(Rect2(p + Vector2(-16, -22), Vector2(32, 26)), Color("2b2140"), false, 3.0)
		draw_rect(Rect2(p + Vector2(-11, -17), Vector2(22, 14)), Color("1b1d2a"))
		for lado in [-5.0, 5.0]:
			draw_line(p + Vector2(lado, -14), p + Vector2(lado, -8), Color("8ff3ff"), 3.0)
