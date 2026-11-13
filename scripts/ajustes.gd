class_name Ajustes
extends RefCounted
## Ajustes de quem joga, valendo para os dois jogos (item 1 da lista de melhorias, escolhido pelo usuário em
## 2026-11-10): volume da música e dos efeitos, rapidez e distância da câmera, câmera invertida (para cima e para baixo),
## vibração do controle e o Modo Fácil (item 3 da lista, para os menores). O Modo Fácil vale para os dois jogos:
## na ilha, corações que voltam sozinhos fora de luta, mais tempo piscando depois de um golpe, esqueletos mais lentos
## e com mais tempo no "!", guardiões com menos vida e mira mais ajudada; no Faísca, cair não tira coração e as
## Bolotas andam mais devagar. Ficam em user://ajustes.json, fora da campanha e do save do Faísca. O PainelAjustes
## mexe aqui; o Sfx aplica os volumes; o Player, o Jogador e o Kart leem a câmera e a vibração na hora de usar.
## Os testes usam os valores de sempre e não gravam nada (`carregar(true)`), a não ser o que muda o `path`.

## Os volumes vão de 0 (mudo) a PASSOS (o volume de sempre).
const PASSOS := 10
## A rapidez da câmera vai de 1 a 9; 5 é a de sempre e cada passo multiplica por uns 19%.
const CAMERA_MIN := 1
const CAMERA_MAX := 9
const CAMERA_PADRAO := 5
## A distância da câmera (2026-11-13: o usuário achou estranha a câmera mais perto no Faísca e pediu a de antes como a
## de sempre, com a opção no menu) vai de 1 (bem perto) a 5 (bem longe); 3 é a de sempre (7,5 m atrás do Faísca, 5,5 m
## atrás das crianças da ilha) e cada passo muda uns 14%.
const DISTANCIA_MIN := 1
const DISTANCIA_MAX := 5
const DISTANCIA_PADRAO := 3
const NOMES_DISTANCIA := ["", "Bem perto", "Perto", "Normal", "Longe", "Bem longe"]

static var path := "user://ajustes.json"
static var enabled := true
static var musica := PASSOS
static var efeitos := PASSOS
static var camera := CAMERA_PADRAO
static var distancia := DISTANCIA_PADRAO
static var inverter := false
static var vibracao := true
static var facil := false
## Falas dos momentos principais (item 13 da lista de melhorias, Vozes).
static var vozes := true
static var _carregado := false


## Lê o arquivo uma vez por partida (o menu principal e os dois jogos chamam). Nos testes, fica o de sempre.
static func carregar(testando: bool) -> void:
	if _carregado:
		return
	_carregado = true
	enabled = not testando
	if not testando and FileAccess.file_exists(path):
		var f := FileAccess.open(path, FileAccess.READ)
		var dados: Variant = JSON.parse_string(f.get_as_text()) if f else null
		if dados is Dictionary:
			musica = clampi(int(dados.get("musica", PASSOS)), 0, PASSOS)
			efeitos = clampi(int(dados.get("efeitos", PASSOS)), 0, PASSOS)
			camera = clampi(int(dados.get("camera", CAMERA_PADRAO)), CAMERA_MIN, CAMERA_MAX)
			distancia = clampi(int(dados.get("distancia", DISTANCIA_PADRAO)), DISTANCIA_MIN, DISTANCIA_MAX)
			inverter = bool(dados.get("inverter", false))
			vibracao = bool(dados.get("vibracao", true))
			facil = bool(dados.get("facil", false))
			vozes = bool(dados.get("vozes", true))
	Sfx.aplicar_volumes()


static func salvar() -> void:
	if not enabled:
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"musica": musica, "efeitos": efeitos, "camera": camera, "distancia": distancia, "inverter": inverter,
			"vibracao": vibracao, "facil": facil, "vozes": vozes}, "\t"))


## Volta tudo para o de sempre (os testes usam).
static func padrao() -> void:
	musica = PASSOS
	efeitos = PASSOS
	camera = CAMERA_PADRAO
	distancia = DISTANCIA_PADRAO
	inverter = false
	vibracao = true
	facil = false
	vozes = true
	Sfx.aplicar_volumes()


## Quanto a câmera gira em relação à de sempre (de 0,5 a 2 vezes).
static func rapidez_camera() -> float:
	return pow(2.0, float(camera - CAMERA_PADRAO) / 4.0)


## Quanto a câmera fica longe em relação à de sempre (de uns 0,72 a 1,28 vezes).
static func distancia_camera() -> float:
	return 1.0 + 0.14 * float(distancia - DISTANCIA_PADRAO)


## Sinal do olhar para cima e para baixo: -1 com a câmera invertida.
static func sinal_vertical() -> float:
	return -1.0 if inverter else 1.0


## Quanto o volume `passo` tira do volume de sempre, em dB (o mudo o Sfx resolve à parte).
static func decibeis(passo: int) -> float:
	return linear_to_db(maxf(float(passo) / PASSOS, 0.001))
