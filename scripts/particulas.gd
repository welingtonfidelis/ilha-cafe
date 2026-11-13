class_name Particulas
extends RefCounted
## Efeitos com as partículas do Kenney Particle Pack 1.1 (CC0, baixado em 2026-11-13 a pedido do usuário; o pacote
## inteiro fica em Projects/others/kenney-particle-pack, e as escolhidas em assets/fx/kenney/). São imagens brancas
## de 512 x 512 com transparência, coloridas aqui. Cada efeito é um ou mais jatos de CPUParticles3D com quadradinhos
## virados para a câmera. Fogo, chama e queimado de verdade ficam de fora (tema infantil); os "queimados" do pacote,
## estouros pontudos, viram o "pow!" do soco.
## A vitrine (tools/vitrine_particulas.gd) mostra cada efeito ao lado do de antes. No Faísca, desde 2026-11-13 (pedido
## do usuário: "Troca no Faísca"), eles entram onde não é festa (o confete ficou para as conquistas): a estrelinha pega,
## a Bolota estourando, o golpe acertando, o coração, a poeira do pulo e dos passos, o curto, o giro, o balão estourando,
## os poderes e o Faisquinha saindo da bolha, e o vento do vendaval e do aspirador do Rei.

const PASTA := "res://assets/fx/kenney/"

static var _texturas := {}
static var _materiais := {}
## Cada jato tem a semente dele (um contador), para não gastar o sorteio global do jogo: sem isso, o número de
## sorteios das partículas mudava com o tempo de cada quadro e mexia no espalhamento dos tiros da Ilha (o teste das
## duas pistolas passou a falhar de vez em quando).
static var _jatos := 0


static func textura(nome: String) -> Texture2D:
	if not _texturas.has(nome):
		_texturas[nome] = load(PASTA + nome + ".png")
	return _texturas[nome]


## Material da partícula: sem luz, transparente, virado para a câmera e colorido pela cor da partícula. `somar` clareia
## o que está atrás (brilhos, faíscas); sem ele, cobre (fumaça, poeira).
static func material(nome: String, somar := true) -> StandardMaterial3D:
	var chave := "%s:%s" % [nome, somar]
	if not _materiais.has(chave):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if somar else BaseMaterial3D.BLEND_MODE_MIX
		m.albedo_texture = textura(nome)
		m.vertex_color_use_as_albedo = true
		m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		m.billboard_keep_scale = true
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_materiais[chave] = m
	return _materiais[chave]


## Um jato de partículas com a imagem `nome` em `pos`. Opções (todas com padrão): quantos, vida, explosao (0 a 1),
## velocidade, abertura (graus), direcao, gravidade, tamanho (m), varia (quanto o tamanho varia), cresce (o tamanho no
## fim, relativo), gira (graus/s), cor, somar, caixa (meia-medida da caixa de onde saem), anel (Vector2 com os raios de
## dentro e de fora de um anel deitado de onde saem), radial (aceleração para fora; negativa puxa para o meio), roda
## (saem para os lados, rente ao chão, em vez de numa bola), angulo (graus: a imagem fica sempre nesse giro na tela, em
## vez de sortear) e sempre (não para sozinho: quem chama liga, desliga e solta).
static func jato(pai: Node, pos: Vector3, nome: String, op := {}) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var sempre := bool(op.get("sempre", false))
	p.one_shot = not sempre
	p.emitting = false
	_jatos += 1
	p.use_fixed_seed = true
	p.seed = hash(_jatos) & 0x7fffffff
	p.amount = int(op.get("quantos", 8))
	p.lifetime = float(op.get("vida", 0.6))
	p.explosiveness = float(op.get("explosao", 0.95))
	p.direction = op.get("direcao", Vector3.UP)
	p.spread = float(op.get("abertura", 180.0))
	var v := float(op.get("velocidade", 2.0))
	p.initial_velocity_min = v * 0.5
	p.initial_velocity_max = v
	p.gravity = op.get("gravidade", Vector3.ZERO)
	p.damping_min = float(op.get("freio", 0.0))
	p.damping_max = float(op.get("freio", 0.0))
	p.angle_min = float(op.get("angulo", -180.0))
	p.angle_max = float(op.get("angulo", 180.0))
	var gira := float(op.get("gira", 0.0))
	p.angular_velocity_min = -gira
	p.angular_velocity_max = gira
	var tamanho := float(op.get("tamanho", 1.0))
	var varia := float(op.get("varia", 0.3))
	p.scale_amount_min = 1.0 - varia
	p.scale_amount_max = 1.0 + varia
	var curva := Curve.new()
	curva.add_point(Vector2(0.0, float(op.get("comeca", 0.4))))
	curva.add_point(Vector2(0.18, 1.0))
	curva.add_point(Vector2(1.0, float(op.get("cresce", 1.0))))
	p.scale_amount_curve = curva
	var cor: Color = op.get("cor", Color.WHITE)
	var some := Gradient.new()
	some.set_color(0, cor)
	some.set_color(1, Color(cor.r, cor.g, cor.b, 0.0))
	some.add_point(0.6, cor)
	p.color_ramp = some
	# Com "local", as partículas andam junto com o pai (o giro em volta do Faísca).
	p.local_coords = bool(op.get("local", false))
	if op.has("caixa"):
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		p.emission_box_extents = op.caixa
	if op.has("anel"):
		var anel: Vector2 = op.anel
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
		p.emission_ring_axis = Vector3.UP
		p.emission_ring_inner_radius = anel.x
		p.emission_ring_radius = anel.y
		p.emission_ring_height = 0.05
	if op.has("radial"):
		p.radial_accel_min = float(op.radial)
		p.radial_accel_max = float(op.radial)
	if bool(op.get("roda", false)):
		p.direction = Vector3.RIGHT
		p.spread = 180.0
		p.flatness = 1.0
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * tamanho
	quad.material = material(nome, bool(op.get("somar", true)))
	p.mesh = quad
	pai.add_child(p)
	p.global_position = pos
	p.emitting = true
	if not sempre:
		p.finished.connect(p.queue_free)
	return p


## Material de uma figura deitada (sem virar para a câmera): o disco do giro forte, a onda no chão e o "zuim" do soco.
## Cada uma tem o seu (a cor e a transparência mudam enquanto ela some). `ordem` desempata as figuras na mesma altura.
static func material_plano(nome: String, cor: Color, ordem := 0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = textura(nome)
	m.albedo_color = cor
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.render_priority = ordem
	return m


## Uma figura deitada de `tamanho` m, sem sombra, com a parte de cima da imagem para -Z.
static func plano(nome: String, tamanho: float, cor: Color, ordem := 0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2.ONE * tamanho
	mi.mesh = pm
	mi.material_override = material_plano(nome, cor, ordem)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## Uma figura deitada que abre e some em `pos`. Opções: tamanho (m), de e ate (o tamanho no começo e no fim, relativos),
## vida (s), cor, gira (graus/s, em volta do próprio eixo) e base (o giro da figura; sem ela, deitada no chão).
static func onda(pai: Node, pos: Vector3, nome: String, op := {}) -> MeshInstance3D:
	var cor: Color = op.get("cor", Color.WHITE)
	var mi := plano(nome, float(op.get("tamanho", 1.0)), cor, 1)
	pai.add_child(mi)
	mi.global_position = pos
	if op.has("base"):
		mi.global_basis = op.base
	var vida := float(op.get("vida", 0.4))
	mi.scale = Vector3.ONE * float(op.get("de", 0.3))
	var tw := mi.create_tween().set_parallel()
	tw.tween_property(mi, "scale", Vector3.ONE * float(op.get("ate", 1.0)), vida).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(mi.material_override, "albedo_color", Color(cor.r, cor.g, cor.b, 0.0), vida).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if op.has("gira"):
		tw.tween_property(mi, "rotation:y", mi.rotation.y + deg_to_rad(float(op.gira)) * vida, vida)
	tw.chain().tween_callback(mi.queue_free)
	return mi


# --- os efeitos ------------------------------------------------------------------------
# As formas (estrelas, faíscas, corações, o "pow!") cobrem o fundo em vez de somar: somando, o branco sumia contra o céu
# claro das fases de dia. Só os clarões somam (de dia somem, no escuro brilham).

## Pegar estrelinha: um clarão dourado e estrelinhas que piscam e se espalham. `escala` aumenta ou diminui tudo.
static func estrelinha(pai: Node, pos: Vector3, escala := 1.0) -> void:
	var k := escala
	jato(pai, pos, "flare_01", {"quantos": 1, "vida": 0.35, "velocidade": 0.0, "tamanho": 2.6 * k, "varia": 0.0, "cor": Color("ffd23f"), "comeca": 0.2})
	jato(pai, pos, "star_07", {"quantos": 9, "vida": 0.75, "velocidade": 4.5 * k, "tamanho": 1.1 * k, "freio": 3.5, "gira": 200.0, "cor": Color("ffc21a"), "somar": false, "cresce": 0.3})
	jato(pai, pos, "symbol_02", {"quantos": 4, "vida": 0.6, "velocidade": 3.0 * k, "tamanho": 0.45 * k, "freio": 2.0, "gira": 300.0, "cor": Color("fff1a8"), "somar": false})


## A Bolota estourando: o puf de fumaça lilás com brilhinhos e estrelinhas pulando.
static func puf(pai: Node, pos: Vector3, cor := Color("b89bff"), escala := 1.0, com_estrelas := true) -> void:
	var k := escala
	jato(pai, pos, "smoke_05", {"quantos": 7, "vida": 0.8, "velocidade": 2.4 * k, "tamanho": 1.7 * k, "freio": 3.0, "somar": false, "cor": cor, "cresce": 1.6, "gira": 60.0})
	if not com_estrelas:
		return
	jato(pai, pos, "star_04", {"quantos": 4, "vida": 0.45, "velocidade": 2.5 * k, "tamanho": 1.1 * k, "cor": Color("fff8d0"), "somar": false})
	jato(pai, pos, "symbol_02", {"quantos": 6, "vida": 0.9, "velocidade": 5.0 * k, "tamanho": 0.5 * k, "gravidade": Vector3(0, -9, 0), "cor": Color("ffc21a"), "somar": false, "gira": 300.0})


## O curto do Faísca (perdeu todos os corações): os raios azuis estalando em volta e a fumacinha cinza subindo.
static func curto(pai: Node, pos: Vector3) -> void:
	jato(pai, pos, "spark_04", {"quantos": 7, "vida": 0.22, "explosao": 0.3, "velocidade": 0.5, "tamanho": 1.7, "cor": Color("1fa8e0"), "somar": false, "caixa": Vector3(0.5, 0.6, 0.5)})
	jato(pai, pos, "spark_03", {"quantos": 4, "vida": 0.18, "explosao": 0.2, "velocidade": 0.3, "tamanho": 1.4, "cor": Color("8ff3ff"), "caixa": Vector3(0.4, 0.5, 0.4)})
	jato(pai, pos + Vector3.UP * 0.4, "smoke_03", {"quantos": 6, "vida": 1.2, "explosao": 0.4, "velocidade": 1.2, "abertura": 25.0, "tamanho": 1.1, "somar": false, "cor": Color(0.55, 0.55, 0.62, 0.9), "cresce": 2.2})


## O soco acertando: o "pow!" amarelo, um clarão e estrelinhas.
static func soco(pai: Node, pos: Vector3, escala := 1.0) -> void:
	var k := escala
	jato(pai, pos, "scorch_01", {"quantos": 1, "vida": 0.22, "velocidade": 0.0, "tamanho": 2.5 * k, "varia": 0.0, "cor": Color("ffb800"), "somar": false, "comeca": 0.5, "cresce": 1.3})
	jato(pai, pos, "star_01", {"quantos": 1, "vida": 0.18, "velocidade": 0.0, "tamanho": 2.4 * k, "varia": 0.0, "cor": Color("fff6c2")})
	jato(pai, pos, "symbol_02", {"quantos": 4, "vida": 0.5, "velocidade": 3.5 * k, "tamanho": 0.45 * k, "freio": 4.0, "cor": Color("ffffff"), "somar": false, "gira": 400.0})


## Poeira de pousar e correr: uma nuvenzinha clara rente ao chão e, com `forca` de pulo ou pouso (0,8 ou mais), uns
## torrões de terra. `quantas` diz o tamanho da nuvem (os passinhos correndo usam 4).
static func poeira(pai: Node, pos: Vector3, cor := Color("b08a62"), forca := 1.0, quantas := 8) -> void:
	var f := clampf(forca, 0.4, 1.6)
	if forca >= 0.8:
		jato(pai, pos, "dirt_01", {"quantos": maxi(quantas / 3, 1), "vida": 0.5, "velocidade": 2.0 * f, "abertura": 80.0, "tamanho": 0.9 * f, "freio": 4.0, "somar": false, "cor": cor, "cresce": 1.3})
	jato(pai, pos, "smoke_01", {"quantos": maxi(quantas / 2, 2), "vida": 0.6, "velocidade": 1.6 * f, "abertura": 85.0, "tamanho": 0.9 * f, "freio": 3.5, "somar": false, "cor": Color(0.96, 0.93, 0.86, 0.8), "cresce": 1.8})


## Mágica (pegar a cápsula de poder, o Faisquinha salvo): o círculo mágico abrindo e brilhinhos subindo.
static func magia(pai: Node, pos: Vector3, cor := Color("ff5fae")) -> void:
	jato(pai, pos, "magic_03", {"quantos": 1, "vida": 0.7, "velocidade": 0.0, "tamanho": 3.0, "varia": 0.0, "cor": cor, "somar": false, "comeca": 0.2, "cresce": 1.4, "gira": 90.0})
	jato(pai, pos, "star_06", {"quantos": 10, "vida": 1.0, "explosao": 0.6, "velocidade": 2.0, "abertura": 40.0, "tamanho": 0.7, "cor": Color("ffd0ea"), "somar": false, "caixa": Vector3(0.6, 0.2, 0.6), "cresce": 0.3})


## Coração pego: coraçõezinhos rosa subindo.
static func coracoes(pai: Node, pos: Vector3) -> void:
	jato(pai, pos, "symbol_01", {"quantos": 6, "vida": 1.0, "explosao": 0.8, "velocidade": 2.6, "abertura": 40.0, "tamanho": 0.95, "somar": false, "cor": Color("ff4d7a"), "cresce": 0.7})
	jato(pai, pos, "star_08", {"quantos": 1, "vida": 0.3, "velocidade": 0.0, "tamanho": 2.0, "varia": 0.0, "cor": Color("ffb3c8")})


## Redemoinho de vento (o giro, o vendaval, o aspirador): espirais azuladas girando e riscos.
static func redemoinho(pai: Node, pos: Vector3) -> void:
	jato(pai, pos, "twirl_01", {"quantos": 3, "vida": 0.6, "explosao": 0.6, "velocidade": 0.2, "tamanho": 2.4, "gira": 720.0, "cor": Color(0.75, 0.9, 1.0, 0.9), "somar": false, "cresce": 1.4})
	jato(pai, pos, "trace_01", {"quantos": 6, "vida": 0.4, "velocidade": 4.0, "abertura": 180.0, "tamanho": 1.0, "cor": Color(0.85, 0.95, 1.0, 0.85), "somar": false})


## O giro do Faísca: uma espiral clarinha em volta dele, que vai junto enquanto ele gira.
static func giro(jogador: Node3D) -> void:
	jato(jogador, jogador.global_position + Vector3.UP * 1.0, "twirl_02", {"quantos": 2, "vida": 0.35, "explosao": 0.7, "velocidade": 0.0, "tamanho": 2.6, "gira": 900.0, "cor": Color(0.85, 0.95, 1.0, 0.75), "somar": false, "cresce": 1.2, "local": true})


## O "zuim" do soco (no jeito do Astro): um risco em meia-lua do lado do braço que soca, virado para a câmera (deitado na
## frente do punho, a câmera de trás não via: o corpo tapava). `na_tela` 1 é o braço do lado direito da tela e -1 o do
## esquerdo; `forte`, o terceiro soco, sai maior e dourado.
static func zuim(pai: Node, pos: Vector3, na_tela: float, forte := false) -> void:
	jato(pai, pos, "slash_03", {"quantos": 1, "vida": 0.2 if forte else 0.15, "velocidade": 0.0, "tamanho": 1.9 if forte else 1.4,
		"varia": 0.0, "angulo": 0.0 if na_tela > 0.0 else 180.0, "comeca": 0.6, "cresce": 1.15, "somar": false,
		"cor": Color("ffd23f") if forte else Color(0.92, 0.99, 1.0, 0.95)})


## A carga do giro forte: brilhinhos azuis que vêm de longe para o corpo, sem parar. Vai junto com o Faísca (`local`);
## quem chama gira o jato (o redemoinho) e desliga.
static func carga(jogador: Node3D) -> CPUParticles3D:
	return jato(jogador, jogador.global_position + Vector3.UP * 0.9, "star_06", {"quantos": 18, "vida": 0.45, "explosao": 0.0,
		"velocidade": 0.0, "tamanho": 0.5, "varia": 0.3, "cor": Color("bff8ff"), "somar": false, "anel": Vector2(1.5, 2.0),
		"radial": -15.0, "local": true, "sempre": true, "comeca": 0.7, "cresce": 0.35})


## A carga cheia: um clarão azul e uma estrelona branca piscando no corpo.
static func carga_cheia(pai: Node, pos: Vector3) -> void:
	jato(pai, pos, "flare_01", {"quantos": 1, "vida": 0.3, "velocidade": 0.0, "tamanho": 3.4, "varia": 0.0, "cor": Color("8ff3ff"), "comeca": 0.3})
	jato(pai, pos, "star_08", {"quantos": 1, "vida": 0.24, "velocidade": 0.0, "tamanho": 2.6, "varia": 0.0, "cor": Color.WHITE, "somar": false, "comeca": 0.3, "cresce": 0.2})


## A onda no chão: um anel claro que abre rente ao chão até `raio` e a poeira saindo em roda (o giro forte soltando, os
## pousos de muito alto).
static func onda_no_chao(pai: Node, pos: Vector3, raio: float, cor := Color(0.85, 0.97, 1.0, 0.9)) -> void:
	onda(pai, pos + Vector3.UP * 0.07, "circle_02", {"tamanho": raio * 2.2, "de": 0.15, "ate": 1.0, "vida": 0.38, "cor": cor})
	var v := raio * 3.0
	jato(pai, pos + Vector3.UP * 0.2, "smoke_01", {"quantos": 12, "vida": 0.6, "explosao": 0.98, "velocidade": v, "freio": raio * 5.0,
		"roda": true, "tamanho": 0.9, "somar": false, "cor": Color(0.96, 0.93, 0.86, 0.8), "cresce": 1.7, "anel": Vector2(0.25, 0.4)})


## O disco do giro (no jeito do Astro): um anel claro na cintura, com um brilho fraquinho por dentro. Os riscos em
## meia-lua de antes (figuras paradas rodando junto) deram lugar aos rastros de luz das mãos (Rastro). Fica com quem
## chamou, que mostra, gira e esmaece (disco_aceso).
static func disco_do_giro(raio: float) -> Node3D:
	var d := Node3D.new()
	d.name = "DiscoDoGiro"
	var dentro := plano("light_01", raio * 2.0, Color(0.6, 0.95, 1.0, 0.28), 0)
	dentro.position.y = -0.02
	dentro.set_meta("alfa", 0.28)
	d.add_child(dentro)
	var anel := plano("circle_03", raio * 2.2, Color(0.78, 0.97, 1.0, 0.7), 1)
	anel.set_meta("alfa", 0.7)
	d.add_child(anel)
	return d


## Acende o disco do giro de 0 (apagado) a 1, mexendo na transparência (encolher de repente parecia um defeito).
static func disco_aceso(d: Node3D, k: float) -> void:
	d.visible = k > 0.01
	for c in d.get_children():
		var m := (c as MeshInstance3D).material_override as StandardMaterial3D
		m.albedo_color.a = float(c.get_meta("alfa", 1.0)) * k


## Tontinho depois do giro forte: quatro estrelinhas amarelas rodando em cima da cabeça (o capacete do Faísca acaba
## lá pelos 2,3 m). São figuras soltas num pivô que gira.
static func tontura(jogador: Node3D, segundos: float, altura := 2.5) -> void:
	var pivo := Node3D.new()
	pivo.name = "Tontura"
	jogador.add_child(pivo)
	pivo.position = Vector3.UP * altura
	for i in 4:
		var e := Sprite3D.new()
		e.texture = textura("symbol_02")
		e.pixel_size = 1.0 / 512.0
		e.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		e.shaded = false
		e.modulate = Color("ffd23f")
		e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var a := TAU * i / 4.0
		e.position = Vector3(cos(a), 0.06 * sin(a * 2.0), sin(a)) * 0.42
		pivo.add_child(e)
	var tw := pivo.create_tween()
	tw.tween_property(pivo, "rotation:y", TAU * 1.6 * segundos, segundos)
	tw.parallel().tween_property(pivo, "scale", Vector3.ONE * 0.3, segundos * 0.35).set_delay(segundos * 0.65)
	tw.tween_callback(pivo.queue_free)


## Dormindo: um "z" azul clarinho que sobe balançando para o lado `lado` (um vetor no chão) e some.
static func zzz(pai: Node, pos: Vector3, lado: Vector3, grande := false) -> void:
	var z := Label3D.new()
	z.text = "Z" if grande else "z"
	z.font_size = 110
	z.pixel_size = 0.005
	z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z.modulate = Color("bff8ff")
	z.outline_size = 22
	z.outline_modulate = Color("1f4b7a")
	z.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pai.add_child(z)
	z.global_position = pos
	z.scale = Vector3.ONE * 0.5
	var tw := z.create_tween().set_parallel()
	tw.tween_property(z, "global_position", pos + lado * 0.45 + Vector3.UP * 1.1, 1.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(z, "scale", Vector3.ONE * 1.25, 1.8)
	tw.tween_property(z, "modulate:a", 0.0, 0.6).set_delay(1.2)
	tw.tween_property(z, "outline_modulate:a", 0.0, 0.6).set_delay(1.2)
	tw.chain().tween_callback(z.queue_free)


## O clarão na boca do blaster (Ilha Cafuné), na cor do dardo.
static func clarao(pai: Node, pos: Vector3, cor := Color("ffb800"), escala := 1.0) -> void:
	jato(pai, pos, "muzzle_01", {"quantos": 1, "vida": 0.09, "velocidade": 0.0, "tamanho": 1.1 * escala, "varia": 0.1, "cor": cor, "somar": false, "comeca": 1.0})
	jato(pai, pos, "star_08", {"quantos": 1, "vida": 0.1, "velocidade": 0.0, "tamanho": 1.3 * escala, "varia": 0.0, "cor": Color.WHITE, "comeca": 1.0})


## O estouro dos fogos de artifício (Fx.firework): o clarão na cor do fogo e estrelas abrindo em roda.
static func fogos(pai: Node, pos: Vector3, cor: Color) -> void:
	jato(pai, pos, "flare_01", {"quantos": 1, "vida": 0.4, "velocidade": 0.0, "tamanho": 9.0, "varia": 0.0, "cor": cor, "comeca": 0.3})
	jato(pai, pos, "star_07", {"quantos": 16, "vida": 1.3, "velocidade": 9.0, "tamanho": 1.4, "freio": 1.5, "gravidade": Vector3(0, -2.5, 0), "gira": 120.0, "cor": cor, "somar": false, "cresce": 0.2})
	jato(pai, pos, "star_06", {"quantos": 10, "vida": 1.0, "velocidade": 6.0, "tamanho": 0.9, "freio": 2.0, "cor": Color.WHITE, "cresce": 0.2})
