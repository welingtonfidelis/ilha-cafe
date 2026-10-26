class_name Weapons
extends RefCounted
## Os blasters do jogo (nomes de doces) e a granada Brigadeiro.
## Para mudar o jeito de uma arma, mexa só aqui.
##
## pente: balas por pente. estoque: munição de reserva no começo (-1 = infinito).
## estoque_max: quanto cabe na reserva. recarga: segundos. intervalo: segundos entre tiros
## (segurando o gatilho, atira de novo nesse ritmo). tiros: projéteis por disparo (escopeta > 1).
## espalha: graus de abertura do tiro. zoom: campo de visão ao mirar (0 = normal).
## coice: força do coice no blaster a cada tiro (0 a 1,5).
## pos/escala/boca: encaixe do modelo no osso handslot.r e ponta do cano (unidades do modelo).
## A rotação no osso é (0, -90, 0) para todos: na pose de mira o eixo X do osso aponta para a frente
## (tools/weapon_axes.gd), e no Blaster Kit o cano fica na ponta -Z do modelo (conferido olhando as
## pontas com tools/foto_blasters_pontas.gd). pos sai do cabo (onde a mão segura) no modelo:
## pos = -(rotação · cabo) · escala. tools/foto_blasters.gd mostra os blasters de lado com boca e cabo.

const MODEL_DIR := "res://assets/weapons/%s.glb"
const ROTATION := Vector3(0, -90, 0)

const DEFS := [
	{
		"id": "pacoca", "nome": "Paçoca", "modelo": "blaster-a", "maos": 1,
		"descricao": "A pistola de sempre: certeira e nunca acaba a munição.",
		# Estoque infinito de propósito: a pistola é a rede de segurança para nunca ficar sem nada.
		"pente": 12, "estoque": -1, "estoque_max": -1, "recarga": 1.0, "intervalo": 0.22,
		"dano": 1.0, "tiros": 1, "espalha": 0.0, "alcance": 120.0, "zoom": 0.0,
		"pos": Vector3(0.2, 0.15, 0.0), "escala": 1.0, "boca": Vector3(0, 0.06, -0.39),
		"som": "tiro", "cor": Color("#fff3a0"), "coice": 0.9,
	},
	{
		"id": "granulado", "nome": "Granulado", "modelo": "blaster-j", "maos": 2, "preco": 40,
		"descricao": "A primeira metralhadora: segura o gatilho e solta uma chuva de balinhas.",
		"pente": 30, "estoque": 60, "estoque_max": 150, "recarga": 1.6, "intervalo": 0.09,
		"dano": 0.5, "tiros": 1, "espalha": 2.5, "alcance": 90.0, "zoom": 0.0,
		"pos": Vector3(0.22, 0.08, 0.0), "escala": 1.0, "boca": Vector3(0, 0.05, -0.32),
		"som": "granulado", "cor": Color("#9fffd6"), "coice": 0.35,
	},
	{
		"id": "pipoqueira", "nome": "Pipoqueira", "modelo": "blaster-l", "maos": 2, "preco": 50,
		"descricao": "A primeira escopeta: 7 grãos de uma vez, forte de pertinho.",
		"pente": 6, "estoque": 12, "estoque_max": 36, "recarga": 1.8, "intervalo": 0.75,
		"dano": 0.6, "tiros": 7, "espalha": 5.5, "alcance": 28.0, "zoom": 0.0,
		"pos": Vector3(0.18, 0.1, 0.0), "escala": 1.0, "boca": Vector3(0, 0.03, -0.29),
		"som": "pipoqueira", "cor": Color("#ffe08a"), "coice": 1.4,
	},
	{
		"id": "pe_de_moleque", "nome": "Pé-de-Moleque", "modelo": "blaster-e", "maos": 2, "preco": 60,
		"descricao": "O primeiro rifle: luneta para mirar longe, um tiro na cabeça derruba qualquer esqueleto.",
		"pente": 5, "estoque": 10, "estoque_max": 25, "recarga": 2.0, "intervalo": 1.0,
		"dano": 3.0, "tiros": 1, "espalha": 0.0, "alcance": 220.0, "zoom": 28.0,
		"pos": Vector3(0.81, 0.085, 0.04), "escala": 0.85, "boca": Vector3(-0.045, 0.03, -0.03),
		"som": "pe_de_moleque", "cor": Color("#c9a6ff"), "coice": 1.5,
	},
]

## Tipo de cada seta, como a lojinha mostra.
const TYPES := ["Pistola", "Metralhadora", "Escopeta", "Rifle"]

## Blasters a mais da lojinha (seção 8 do doc; pedido do usuário em 2026-10-26). Desde a segunda rodada de
## pedidos, os três da história (Granulado, Pipoqueira, Pé-de-Moleque) também são comprados na lojinha
## ("preco" neles); só a Paçoca vem de graça. Cada um entra num dos quatro
## encaixes ("slot", a mesma seta do direcional e a mesma tecla do blaster de cima), e o jogador escolhe na
## lojinha qual fica equipado em cada seta. Os de pistola também têm estoque infinito (a rede de segurança
## continua). preco em moedas. Encaixe medido nas malhas: o cabo é o ponto mais baixo da metade de trás
## (y no meio da altura de baixo) e a boca é a ponta da frente, como nos quatro de cima; no Suspiro e no
## Bombom (compridos) o mais baixo é o pente, e o cabo foi puxado para o punho atrás dele, olhando a folha
## de tools/foto_blasters.gd.
const SHOP := [
	{
		"id": "jujuba", "slot": 0, "preco": 60, "nome": "Jujuba", "modelo": "blaster-k", "maos": 1,
		"descricao": "Pistola rapidinha: 16 balas, atira quase sem parar. Estoque infinito.",
		"pente": 16, "estoque": -1, "estoque_max": -1, "recarga": 0.9, "intervalo": 0.13,
		"dano": 0.9, "tiros": 1, "espalha": 0.8, "alcance": 110.0, "zoom": 0.0,
		"pos": Vector3(0.14, 0.08, 0.0), "escala": 1.0, "boca": Vector3(0, 0.07, -0.23),
		"som": "tiro", "cor": Color("#ffb3d9"), "coice": 0.5,
	},
	{
		"id": "beijinho", "slot": 1, "preco": 90, "nome": "Beijinho", "modelo": "blaster-q", "maos": 2,
		"descricao": "Rajada turbo: 45 balas, a mais rápida da ilha. Cada tiro tira pouquinho.",
		"pente": 45, "estoque": 90, "estoque_max": 225, "recarga": 1.7, "intervalo": 0.06,
		"dano": 0.35, "tiros": 1, "espalha": 3.5, "alcance": 80.0, "zoom": 0.0,
		"pos": Vector3(0.25, 0.08, 0.0), "escala": 1.0, "boca": Vector3(0, 0.02, -0.36),
		"som": "granulado", "cor": Color("#b8ffcf"), "coice": 0.25,
	},
	{
		"id": "canjica", "slot": 2, "preco": 100, "nome": "Canjica", "modelo": "blaster-g", "maos": 2,
		"descricao": "Escopeta de leque largo: 11 grãos por tiro, ótima de pertinho.",
		"pente": 5, "estoque": 10, "estoque_max": 30, "recarga": 1.9, "intervalo": 0.8,
		"dano": 0.5, "tiros": 11, "espalha": 8.0, "alcance": 22.0, "zoom": 0.0,
		"pos": Vector3(0.26, 0.09, 0.0), "escala": 1.0, "boca": Vector3(0, 0.11, -0.35),
		"som": "pipoqueira", "cor": Color("#fff0b3"), "coice": 1.4,
	},
	{
		"id": "suspiro", "slot": 3, "preco": 110, "nome": "Suspiro", "modelo": "blaster-p", "maos": 2,
		"descricao": "Precisão rápida: 8 tiros seguidos com luneta, 2 de dano cada.",
		"pente": 8, "estoque": 16, "estoque_max": 40, "recarga": 1.8, "intervalo": 0.4,
		"dano": 2.0, "tiros": 1, "espalha": 0.0, "alcance": 200.0, "zoom": 34.0,
		"pos": Vector3(0.26, 0.09, 0.0), "escala": 1.0, "boca": Vector3(0, 0.03, -0.43),
		"som": "tiro", "cor": Color("#e0d4ff"), "coice": 1.0,
	},
	{
		"id": "cocada", "slot": 0, "preco": 130, "nome": "Cocada", "modelo": "blaster-c", "maos": 1,
		"descricao": "Pistola pesada: 6 tiros que valem muito (2,4 de dano). Estoque infinito.",
		"pente": 6, "estoque": -1, "estoque_max": -1, "recarga": 1.3, "intervalo": 0.5,
		"dano": 2.4, "tiros": 1, "espalha": 0.0, "alcance": 120.0, "zoom": 0.0,
		"pos": Vector3(0.15, 0.08, 0.0), "escala": 1.0, "boca": Vector3(0, 0.02, -0.24),
		"som": "pe_de_moleque", "cor": Color("#ffe3c2"), "coice": 1.3,
	},
	{
		"id": "bananada", "slot": 1, "preco": 150, "nome": "Bananada", "modelo": "blaster-d", "maos": 2,
		"descricao": "Rajada forte e certeira: 24 balas de quase 1 de dano.",
		"pente": 24, "estoque": 48, "estoque_max": 120, "recarga": 1.8, "intervalo": 0.14,
		"dano": 0.9, "tiros": 1, "espalha": 1.5, "alcance": 100.0, "zoom": 0.0,
		"pos": Vector3(0.10, 0.09, 0.0), "escala": 1.0, "boca": Vector3(0, 0.06, -0.45),
		"som": "granulado", "cor": Color("#fff59e"), "coice": 0.6,
	},
	{
		"id": "rapadura", "slot": 2, "preco": 160, "nome": "Rapadura", "modelo": "blaster-h", "maos": 2,
		"descricao": "Cano duplo: dois tiros fortes e seguidos, recarga rápida.",
		"pente": 2, "estoque": 8, "estoque_max": 24, "recarga": 1.4, "intervalo": 0.35,
		"dano": 0.8, "tiros": 8, "espalha": 3.5, "alcance": 32.0, "zoom": 0.0,
		"pos": Vector3(0.23, 0.07, 0.0), "escala": 1.0, "boca": Vector3(0, 0.09, -0.32),
		"som": "pipoqueira", "cor": Color("#ffc9a6"), "coice": 1.5,
	},
	{
		"id": "bombom", "slot": 3, "preco": 180, "nome": "Bombom", "modelo": "blaster-f", "maos": 2,
		"descricao": "Superprecisão: 3 tiros de 6 de dano, luneta forte. Na cabeça, derruba até o Golem.",
		"pente": 3, "estoque": 6, "estoque_max": 18, "recarga": 2.4, "intervalo": 1.4,
		"dano": 6.0, "tiros": 1, "espalha": 0.0, "alcance": 250.0, "zoom": 20.0,
		"pos": Vector3(0.27, 0.094, 0.0), "escala": 0.85, "boca": Vector3(0, 0.08, -0.65),
		"som": "pe_de_moleque", "cor": Color("#f2b8ff"), "coice": 1.5,
	},
]

## Melhorias da lojinha (compradas uma vez).
const UPGRADES := [
	{"id": "granada_extra", "preco": 70, "nome": "+1 Brigadeiro", "descricao": "Cabe uma granada a mais: até 4 no bolso."},
	{"id": "coracao_extra", "preco": 250, "nome": "+1 Coração", "descricao": "Um coração a mais de vida, para sempre."},
]

## Granada Brigadeiro: botão próprio (G ou RB), sem trocar de arma.
const GRENADE := {
	"nome": "Brigadeiro", "modelo": "grenade-a", "inicio": 2, "max": 3,
	"dano": 6.0, "dano_borda": 2.0, "dano_chefe": 7.0, "raio": 5.5, "pavio": 1.4, "forca": 13.0,
}

## Pirulitão: golpe corpo a corpo (F no teclado, R3 no controle). Acerta quem está na frente num raio
## curto (o escudo do guerreiro segura pela frente, como no tiro) e estoura bolhas mágicas.
const MELEE := {
	"nome": "Pirulitão", "modelo": "res://assets/props/cemiterio/lollipop_pink.gltf", "escala": 1.7,
	"dano": 3.0, "alcance": 1.5, "raio": 1.3, "impacto": 0.22, "duracao": 0.55, "intervalo": 0.6,
}

## No controle, cada blaster tem uma seta do direcional (na ordem de DEFS): ↑ Paçoca, → Granulado,
## ↓ Pipoqueira, ← Pé-de-Moleque. No teclado são as teclas 1 a 4.
const DPAD := [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT]
## Como a faixa de "novo blaster" fala o direcional (a fonte padrão não tem os glifos de seta).
const DPAD_WORDS := ["para cima", "para a direita", "para baixo", "para a esquerda"]

## Uma caixa de munição devolve um pente de reserva de cada blaster equipado com estoque limitado e uma
## granada.
const CRATE_AMMO := {"granadas": 1}


static func count() -> int:
	return DEFS.size()


static func get_def(index: int) -> Dictionary:
	return DEFS[index]


## Encaixe (seta do direcional) do blaster: o índice em DEFS para os quatro de cima, "slot" para os da lojinha.
static func index_of(id: String) -> int:
	for i in DEFS.size():
		if DEFS[i].id == id:
			return i
	for def in SHOP:
		if def.id == id:
			return def.slot
	return -1


## Todos os blasters (os quatro da história e os da lojinha).
static func all() -> Array:
	return DEFS + SHOP


static func find(id: String) -> Dictionary:
	for def in all():
		if def.id == id:
			return def
	return {}


## Preço em moedas (-1: não se vende, a Paçoca).
static func price(id: String) -> int:
	return int(find(id).get("preco", -1))


static func is_shop(id: String) -> bool:
	return SHOP.any(func(def: Dictionary) -> bool: return def.id == id)


static func infinite(def: Dictionary) -> bool:
	return def.estoque < 0
