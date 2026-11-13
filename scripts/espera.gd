class_name Espera
extends RefCounted
## Animações de espera (pedido do usuário em 2026-11-13), do Faísca (Jogador) e do menino e da menina da ilha
## (Player): parado sem ninguém mexer no controle, olha em volta (OLHAR), depois brinca sozinho de tempos em tempos
## (BRINCAR e, entre uma e outra, ENTRE) e, bem parado (DORMIR), deita e dorme. Qualquer mexida acorda na hora, menos
## mexer na câmera. Quem usa diz o que é "mexer" (atualizar), toca a animação do passo de agora (anim) e faz o que vai
## junto pelos sinais (a dancinha do Faísca, os "z" do sono, guardar o blaster das crianças).

signal comecou(nome: String)
signal acabou(nome: String, acordou: bool)

const OLHAR := 5.0
const BRINCAR := 10.0
const ENTRE := 7.0
const DORMIR := 34.0
## Cada espera é uma lista de passos [animação, segundos]; "dancinha" é a dança de robô do Faísca por cima do parado.
## Os segundos ficam um tiquinho abaixo da duração das animações que não repetem (senão ela recomeçava por um quadro).
const PASSOS := {
	"olhar": [["geral/Idle_B", 2.1]],
	"acenar": [["festa/Waving", 4.2]],
	"flexoes": [["festa/Push_Ups", 3.0]],
	"abdominais": [["festa/Sit_Ups", 3.4]],
	"sentar": [["festa/Sit_Floor_Down", 0.95], ["festa/Sit_Floor_Idle", 4.0], ["festa/Sit_Floor_StandUp", 1.08]],
	"dancinha": [["dancinha", 4.0]],
	"dormir": [["festa/Lie_Down", 2.95], ["festa/Lie_Idle", INF]],
}

## As brincadeiras que este personagem sorteia (o Faísca dança; as crianças não).
var brincadeiras: Array
## Há quanto tempo está parado, e a espera tocando ("" é nenhuma) e o passo dela.
var parado := 0.0
var nome := ""
var passo := 0
var _resta := 0.0
var _olhou := false
var _proxima := BRINCAR
var _ultima := ""
## O sorteio é dele (não gasta o sorteio do jogo).
var _sorteio := RandomNumberGenerator.new()
## As ações que acordam (ver apertando_algo), guardadas na primeira vez.
static var _acoes: Array[StringName] = []
static var _total_de_acoes := -1


func _init(lista: Array) -> void:
	brincadeiras = lista


## Algum botão ou direção do jogo apertado. A câmera não conta (o analógico direito, as setas de olhar e o mouse não
## acordam: pedido do usuário em 2026-11-13), nem as ações do menu (ui_*), que repetem as do jogo. O
## Input.is_anything_pressed não serve: o analógico direito passando da zona morta conta como as ações "olhar_".
static func apertando_algo() -> bool:
	var todas := InputMap.get_actions()
	if todas.size() != _total_de_acoes:
		_total_de_acoes = todas.size()
		_acoes.clear()
		for a in todas:
			if not String(a).begins_with("olhar_") and not String(a).begins_with("ui_"):
				_acoes.append(a)
	for a in _acoes:
		if Input.is_action_pressed(a):
			return true
	return false


## A animação do passo de agora ("" sem espera).
func anim() -> String:
	return "" if nome == "" else String(PASSOS[nome][passo][0])


## A cada quadro de física. `mexeu`: alguém mexeu no controle, ou o personagem está fazendo outra coisa.
func atualizar(delta: float, mexeu: bool) -> void:
	if mexeu:
		acordar()
		return
	parado += delta
	if nome != "":
		_resta -= delta
		if _resta <= 0.0:
			passo += 1
			if passo < PASSOS[nome].size():
				_resta = PASSOS[nome][passo][1]
			else:
				_terminar(false)
		return
	if parado >= DORMIR:
		comecar("dormir")
	elif parado >= _proxima:
		var opcoes: Array = brincadeiras.filter(func(b: String) -> bool: return b != _ultima)
		_ultima = opcoes[_sorteio.randi() % opcoes.size()]
		comecar(_ultima)
	elif parado >= OLHAR and not _olhou:
		comecar("olhar")


func comecar(qual: String) -> void:
	nome = qual
	passo = 0
	_resta = PASSOS[qual][0][1]
	# O olhar em volta é só o primeiro (com o relógio adiantado, não vem depois de uma brincadeira).
	_olhou = true
	comecou.emit(qual)


## Para a espera na hora e o relógio volta a zero (mexeram no controle, ou o personagem foi levado para outro lugar).
func acordar() -> void:
	if nome != "":
		_terminar(true)
	parado = 0.0
	_olhou = false
	_proxima = BRINCAR


func _terminar(acordou: bool) -> void:
	var era := nome
	# O olhar em volta não empurra a primeira brincadeira (ela continua nos BRINCAR).
	if era != "olhar" and not acordou:
		_proxima = parado + ENTRE
	nome = ""
	passo = 0
	acabou.emit(era, acordou)
