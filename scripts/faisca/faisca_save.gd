class_name FaiscaSave
extends RefCounted
## Progresso do jogo do Faísca num JSON em user:// (faisca.json, ao lado da campanha da ilha), separado dela desde
## que o menu principal separou os dois jogos (pedido do usuário em 2026-11-10). Guarda as estrelinhas pegas por
## fase (e na escada do farol), as Estrelas Grandes devolvidas, os vaga-lumes achados e se a abertura já passou.
## Quem jogou a Parte 2 dentro da ilha (campanha versão 3, chave "parte2") ganha esse progresso aqui uma vez
## (`migrar`, chamado pelo menu principal antes de a ilha salvar a campanha sem a Parte 2). Os testes desligam o
## salvamento (`enabled`) ou usam outro arquivo (`path`), como no SaveGame.

const VERSAO := 1

static var path := "user://faisca.json"
static var enabled := true


static func existe() -> bool:
	return FileAccess.file_exists(path)


static func ler() -> Dictionary:
	if not existe():
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var dados: Variant = JSON.parse_string(f.get_as_text())
	return dados if dados is Dictionary else {}


static func gravar(dados: Dictionary) -> void:
	if not enabled:
		return
	dados["versao"] = VERSAO
	dados["salvo_em"] = Time.get_datetime_string_from_system()
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(dados, "\t"))


static func apagar() -> void:
	if existe():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


## Traz a Parte 2 da campanha da ilha, se ainda não houver o arquivo do Faísca. Devolve se trouxe.
static func migrar() -> bool:
	if not enabled or existe() or not SaveGame.exists():
		return false
	var parte2: Dictionary = SaveGame.read().get("parte2", {})
	var estrelas: Dictionary = parte2.get("estrelas", {})
	if not parte2.get("aberta", false) and estrelas.is_empty():
		return false
	gravar({"estrelas": estrelas, "grandes": parte2.get("grandes", []), "vaga_lumes": parte2.get("vaga_lumes", {}),
		"abertura": true})
	return true
