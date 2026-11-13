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
## fim, relativo), gira (graus/s), cor, somar, caixa (meia-medida da caixa de onde saem).
static func jato(pai: Node, pos: Vector3, nome: String, op := {}) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
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
	p.angle_min = -180.0
	p.angle_max = 180.0
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
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * tamanho
	quad.material = material(nome, bool(op.get("somar", true)))
	p.mesh = quad
	pai.add_child(p)
	p.global_position = pos
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


# --- os efeitos ------------------------------------------------------------------------
# As formas (estrelas, faíscas, corações, o "pow!") cobrem o fundo em vez de somar: somando, o branco sumia contra o céu
# claro das fases de dia. Só os clarões somam (de dia somem, no escuro brilham).

## Pegar estrelinha: um clarão dourado e estrelinhas que piscam e se espalham.
static func estrelinha(pai: Node, pos: Vector3) -> void:
	jato(pai, pos, "flare_01", {"quantos": 1, "vida": 0.35, "velocidade": 0.0, "tamanho": 2.6, "varia": 0.0, "cor": Color("ffd23f"), "comeca": 0.2})
	jato(pai, pos, "star_07", {"quantos": 9, "vida": 0.75, "velocidade": 4.5, "tamanho": 1.1, "freio": 3.5, "gira": 200.0, "cor": Color("ffc21a"), "somar": false, "cresce": 0.3})
	jato(pai, pos, "symbol_02", {"quantos": 4, "vida": 0.6, "velocidade": 3.0, "tamanho": 0.45, "freio": 2.0, "gira": 300.0, "cor": Color("fff1a8"), "somar": false})


## A Bolota estourando: o puf de fumaça lilás com brilhinhos e estrelinhas pulando.
static func puf(pai: Node, pos: Vector3, cor := Color("b89bff")) -> void:
	jato(pai, pos, "smoke_05", {"quantos": 7, "vida": 0.8, "velocidade": 2.4, "tamanho": 1.7, "freio": 3.0, "somar": false, "cor": cor, "cresce": 1.6, "gira": 60.0})
	jato(pai, pos, "star_04", {"quantos": 4, "vida": 0.45, "velocidade": 2.5, "tamanho": 1.1, "cor": Color("fff8d0"), "somar": false})
	jato(pai, pos, "symbol_02", {"quantos": 6, "vida": 0.9, "velocidade": 5.0, "tamanho": 0.5, "gravidade": Vector3(0, -9, 0), "cor": Color("ffc21a"), "somar": false, "gira": 300.0})


## O curto do Faísca (perdeu todos os corações): os raios azuis estalando em volta e a fumacinha cinza subindo.
static func curto(pai: Node, pos: Vector3) -> void:
	jato(pai, pos, "spark_04", {"quantos": 7, "vida": 0.22, "explosao": 0.3, "velocidade": 0.5, "tamanho": 1.7, "cor": Color("1fa8e0"), "somar": false, "caixa": Vector3(0.5, 0.6, 0.5)})
	jato(pai, pos, "spark_03", {"quantos": 4, "vida": 0.18, "explosao": 0.2, "velocidade": 0.3, "tamanho": 1.4, "cor": Color("8ff3ff"), "caixa": Vector3(0.4, 0.5, 0.4)})
	jato(pai, pos + Vector3.UP * 0.4, "smoke_03", {"quantos": 6, "vida": 1.2, "explosao": 0.4, "velocidade": 1.2, "abertura": 25.0, "tamanho": 1.1, "somar": false, "cor": Color(0.55, 0.55, 0.62, 0.9), "cresce": 2.2})


## O soco acertando: o "pow!" amarelo, um clarão e estrelinhas.
static func soco(pai: Node, pos: Vector3) -> void:
	jato(pai, pos, "scorch_01", {"quantos": 1, "vida": 0.22, "velocidade": 0.0, "tamanho": 2.5, "varia": 0.0, "cor": Color("ffb800"), "somar": false, "comeca": 0.5, "cresce": 1.3})
	jato(pai, pos, "star_01", {"quantos": 1, "vida": 0.18, "velocidade": 0.0, "tamanho": 2.4, "varia": 0.0, "cor": Color("fff6c2")})
	jato(pai, pos, "symbol_02", {"quantos": 4, "vida": 0.5, "velocidade": 3.5, "tamanho": 0.45, "freio": 4.0, "cor": Color("ffffff"), "somar": false, "gira": 400.0})


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


## O clarão na boca do blaster (Ilha Cafuné), na cor do dardo.
static func clarao(pai: Node, pos: Vector3, cor := Color("ffb800")) -> void:
	jato(pai, pos, "muzzle_01", {"quantos": 1, "vida": 0.09, "velocidade": 0.0, "tamanho": 1.1, "varia": 0.1, "cor": cor, "somar": false, "comeca": 1.0})
	jato(pai, pos, "star_08", {"quantos": 1, "vida": 0.1, "velocidade": 0.0, "tamanho": 1.3, "varia": 0.0, "cor": Color.WHITE, "comeca": 1.0})
