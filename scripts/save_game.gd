class_name SaveGame
extends RefCounted
## Progresso da campanha num JSON em user:// (no Linux, ~/.local/share/godot/app_userdata/Ilha Cafuné/).
## Guarda a etapa da história, as defesas vencidas, os blasters, os corações máximos, a bandeira atual,
## o personagem, as fotos do álbum e os recordes. Os testes automáticos desligam o salvamento (enabled) ou
## usam outro arquivo (path), para nunca mexer na campanha de quem joga.

const VERSION := 1

static var path := "user://campanha.json"
static var enabled := true
## Depois de "Nova campanha" a cena recarrega e vai direto para a escolha de personagem.
static var go_new := false
## Fase do teste de salvar e carregar (sobrevive ao recarregar a cena).
static var test_phase := 0
static var test_ok := true


## Fotos do álbum ficam numa pasta ao lado do arquivo da campanha (user://campanha_album/).
static func album_dir() -> String:
	return path.get_basename() + "_album/"


static func exists() -> bool:
	return FileAccess.file_exists(path)


static func read() -> Dictionary:
	if not exists():
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data: Variant = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}


static func write(data: Dictionary) -> void:
	if not enabled:
		return
	data["versao"] = VERSION
	data["salvo_em"] = Time.get_datetime_string_from_system()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))


## Apaga a campanha e as fotos do álbum.
static func erase() -> void:
	if exists():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var dir := DirAccess.open(album_dir())
	if dir:
		for f in dir.get_files():
			dir.remove(f)


## Guarda uma foto do álbum e devolve o nome do arquivo ("" com o salvamento desligado).
static func save_photo(image: Image, index: int) -> String:
	if not enabled:
		return ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(album_dir()))
	var file := "foto_%02d.png" % index
	image.save_png(ProjectSettings.globalize_path(album_dir() + file))
	return file


static func load_photo(file: String) -> Image:
	if file == "":
		return null
	var full := ProjectSettings.globalize_path(album_dir() + file)
	if not FileAccess.file_exists(full):
		return null
	return Image.load_from_file(full)


## Texto curto da etapa, para o botão "Continuar".
static func stage_label(stage: String) -> String:
	match stage:
		"antes", "prologo":
			return "Prólogo"
		"cidade":
			return "Lanternas da cidade"
		"mata":
			return "Lanternas da mata"
		"cemiterio":
			return "Cemitério do Morro"
		"festa":
			return "A Festa do Cafuné"
		"fim":
			return "Depois do final"
	return stage
