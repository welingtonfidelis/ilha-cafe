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
		# Estoque infinito de propósito: a pistola é a rede de segurança para nunca ficar sem nada.
		"pente": 12, "estoque": -1, "estoque_max": -1, "recarga": 1.0, "intervalo": 0.22,
		"dano": 1.0, "tiros": 1, "espalha": 0.0, "alcance": 120.0, "zoom": 0.0,
		"pos": Vector3(0.2, 0.15, 0.0), "escala": 1.0, "boca": Vector3(0, 0.06, -0.39),
		"som": "tiro", "cor": Color("#fff3a0"), "coice": 0.9,
	},
	{
		"id": "granulado", "nome": "Granulado", "modelo": "blaster-j", "maos": 2,
		"pente": 30, "estoque": 60, "estoque_max": 150, "recarga": 1.6, "intervalo": 0.09,
		"dano": 0.5, "tiros": 1, "espalha": 2.5, "alcance": 90.0, "zoom": 0.0,
		"pos": Vector3(0.22, 0.08, 0.0), "escala": 1.0, "boca": Vector3(0, 0.05, -0.32),
		"som": "granulado", "cor": Color("#9fffd6"), "coice": 0.35,
	},
	{
		"id": "pipoqueira", "nome": "Pipoqueira", "modelo": "blaster-l", "maos": 2,
		"pente": 6, "estoque": 12, "estoque_max": 36, "recarga": 1.8, "intervalo": 0.75,
		"dano": 0.6, "tiros": 7, "espalha": 5.5, "alcance": 28.0, "zoom": 0.0,
		"pos": Vector3(0.18, 0.1, 0.0), "escala": 1.0, "boca": Vector3(0, 0.03, -0.29),
		"som": "pipoqueira", "cor": Color("#ffe08a"), "coice": 1.4,
	},
	{
		"id": "pe_de_moleque", "nome": "Pé-de-Moleque", "modelo": "blaster-e", "maos": 2,
		"pente": 5, "estoque": 10, "estoque_max": 25, "recarga": 2.0, "intervalo": 1.0,
		"dano": 3.0, "tiros": 1, "espalha": 0.0, "alcance": 220.0, "zoom": 28.0,
		"pos": Vector3(0.81, 0.085, 0.04), "escala": 0.85, "boca": Vector3(-0.045, 0.03, -0.03),
		"som": "pe_de_moleque", "cor": Color("#c9a6ff"), "coice": 1.5,
	},
]

## Granada Brigadeiro: botão próprio (G ou RB), sem trocar de arma.
const GRENADE := {
	"nome": "Brigadeiro", "modelo": "grenade-a", "inicio": 2, "max": 3,
	"dano": 3.0, "raio": 5.0, "pavio": 1.4, "forca": 13.0,
}

## No controle, cada blaster tem uma seta do direcional (na ordem de DEFS): ↑ Paçoca, → Granulado,
## ↓ Pipoqueira, ← Pé-de-Moleque. No teclado são as teclas 1 a 4.
const DPAD := [JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_LEFT]
## Como a faixa de "novo blaster" fala o direcional (a fonte padrão não tem os glifos de seta).
const DPAD_WORDS := ["para cima", "para a direita", "para baixo", "para a esquerda"]

## Quanto uma caixa de munição devolve de cada arma (com estoque limitado) e de granadas.
const CRATE_AMMO := {"granulado": 30, "pipoqueira": 6, "pe_de_moleque": 5, "granadas": 1}


static func count() -> int:
	return DEFS.size()


static func get_def(index: int) -> Dictionary:
	return DEFS[index]


static func index_of(id: String) -> int:
	for i in DEFS.size():
		if DEFS[i].id == id:
			return i
	return -1


static func infinite(def: Dictionary) -> bool:
	return def.estoque < 0
