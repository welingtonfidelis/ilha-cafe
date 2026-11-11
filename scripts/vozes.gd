class_name Vozes
extends RefCounted
## Vozes dos momentos principais (item 13 da lista de melhorias, 2026-11-10): uma fala curta em voz alta quando algo
## importante acontece (o prólogo começa, um guardião aparece, a lanterna apaga, o convite, a festa, fisgar e pegar
## peixe novo, o esconde-esconde, o esqueleto dourado, a figurinha nova, o bilhete, a copa, as três estrelas, o
## presente de fim de ano, ficar tonto). Os arquivos ficam em assets/audio/vozes/<id>.wav: por enquanto saem da voz
## brasileira do Mac (tools/gerar_vozes.sh), e cada um pode ser trocado por uma gravação de verdade com o mesmo nome.
## Uma fala por vez (a nova corta a anterior), no canal dos efeitos; o Ajustes tem a chave "Vozes".

const DIR := "res://assets/audio/vozes/%s.wav"
## Ganho em cima do canal dos efeitos (a fala precisa aparecer por cima do tiroteio).
const VOLUME_DB := 2.0

static var _player: AudioStreamPlayer
static var _ultima := ""
static var _quando := -10.0


## Fala `id` (se o arquivo existir e as vozes estiverem ligadas). A mesma fala colada na anterior não repete.
## `parent` é o jogo (o main): o tocador fica nele.
static func falar(parent: Node, id: String) -> void:
	if Sfx.logging:
		Sfx.played.append("voz:" + id)
	if not Ajustes.vozes or parent == null or not parent.is_inside_tree():
		return
	var agora := Time.get_ticks_msec() / 1000.0
	if id == _ultima and agora - _quando < 2.5:
		return
	var caminho := DIR % id
	if not ResourceLoader.exists(caminho):
		return
	if not is_instance_valid(_player):
		_player = AudioStreamPlayer.new()
		_player.name = "Vozes"
		_player.bus = Sfx.BUS_SFX
		_player.process_mode = Node.PROCESS_MODE_ALWAYS
		parent.add_child(_player)
	_player.stream = load(caminho)
	_player.volume_db = VOLUME_DB
	_player.play()
	_ultima = id
	_quando = agora


static func falando() -> bool:
	return is_instance_valid(_player) and _player.playing
