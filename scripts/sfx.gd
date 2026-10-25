class_name Sfx
extends RefCounted
## Toca os efeitos sonoros e a música. Os arquivos vêm de tools/gerar_sons.py.
## Dois canais de áudio além do Master: "Musica" e "Efeitos", para dar para regular separado.
## Sons do aventureiro e da interface tocam "na cabeça" (2D); os dos esqueletos têm posição no mundo.

const SFX_DIR := "res://assets/audio/sfx/%s.wav"
const MUSIC_DIR := "res://assets/audio/musica/%s.wav"
const BUS_MUSIC := &"Musica"
const BUS_SFX := &"Efeitos"

## Todos os efeitos que tools/gerar_sons.py gera.
const ALL := [
	"tiro", "acerto", "acerto_cabeca", "ossos", "remontar", "alerta", "golpe_ar", "escudo",
	"flecha", "ventosa", "bolha", "estouro", "bonk", "tonto", "bandeira", "coracao", "pulo",
	"reaparecer", "ui_mover", "ui_ok",
]

## Nos testes, anota o nome de cada som tocado (não dá para ouvir num teste sem tela).
static var logging := false
static var played: Array[String] = []
static var _cache := {}


static func setup_buses(music_db := -9.0, sfx_db := 0.0) -> void:
	for bus_name in [BUS_MUSIC, BUS_SFX]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, &"Master")
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), music_db)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), sfx_db)


static func stream(sfx_name: String) -> AudioStream:
	if not _cache.has(sfx_name):
		_cache[sfx_name] = load(SFX_DIR % sfx_name)
	return _cache[sfx_name]


## Efeito sem posição (aventureiro, interface). Um pouco de variação de altura evita a repetição robótica.
static func play(parent: Node, sfx_name: String, volume_db := 0.0, pitch_jitter := 0.06) -> AudioStreamPlayer:
	if logging:
		played.append(sfx_name)
	var p := AudioStreamPlayer.new()
	p.stream = stream(sfx_name)
	p.bus = BUS_SFX
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	parent.add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
	return p


## Efeito com posição no mundo (esqueletos, flechas, bolhas): mais baixo quando está longe.
static func play_at(parent: Node, sfx_name: String, pos: Vector3, volume_db := 0.0, pitch_jitter := 0.06) -> AudioStreamPlayer3D:
	if logging:
		played.append(sfx_name)
	var p := AudioStreamPlayer3D.new()
	p.stream = stream(sfx_name)
	p.bus = BUS_SFX
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	p.unit_size = 8.0
	p.max_distance = 60.0
	parent.add_child(p)
	p.global_position = pos
	p.play()
	p.finished.connect(p.queue_free)
	return p


## Música em loop no canal "Musica". O WAV gerado já emenda sem corte.
static func music(parent: Node, music_name: String) -> AudioStreamPlayer:
	var s: AudioStreamWAV = load(MUSIC_DIR % music_name)
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_begin = 0
	s.loop_end = int(s.get_length() * s.mix_rate)
	var p := AudioStreamPlayer.new()
	p.name = "Musica"
	p.stream = s
	p.bus = BUS_MUSIC
	parent.add_child(p)
	p.play()
	return p
