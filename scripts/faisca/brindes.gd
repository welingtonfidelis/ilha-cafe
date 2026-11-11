class_name Brindes
extends RefCounted
## Os brindes da Máquina de Brindes do farol (item 4 da lista de melhorias do Faísca, 2026-11-11), como o laboratório
## de brindes do Astro Bot: cada cápsula custa PRECO moedas e traz um brinde que ainda não saiu (não repete).
## - 12 figurinhas para a estante do térreo: os 11 monstros da turma das Bolotas (mexendo, na animação de parado) e
##   um Faisquinha dourado;
## - 6 roupinhas (chapéus) para o Faísca, da lojinha da ilha (Roupas), trocadas no cabide. A coroa da lojinha ficou de
##   fora (é a do Necromante, com caveira).

const PRECO := 25

## id, tipo ("figurinha" ou "roupa"), nome e de onde vem (o tipo do monstro, o chapéu das Roupas ou "faisquinha").
const LISTA := [
	{"id": "fig_alien", "tipo": "figurinha", "nome": "Bolota", "monstro": "alien"},
	{"id": "fig_cogumelo", "tipo": "figurinha", "nome": "Bolota-cogumelo", "monstro": "cogumelo"},
	{"id": "fig_pinguim", "tipo": "figurinha", "nome": "Bolota-pinguim", "monstro": "pinguim"},
	{"id": "fig_cacto", "tipo": "figurinha", "nome": "Bolota-cacto", "monstro": "cacto"},
	{"id": "fig_ciclope", "tipo": "figurinha", "nome": "Bolota-ciclope", "monstro": "ciclope"},
	{"id": "fig_arvore", "tipo": "figurinha", "nome": "Bolota-árvore", "monstro": "arvore"},
	{"id": "fig_caranguejo", "tipo": "figurinha", "nome": "Bolota-caranguejo", "monstro": "caranguejo"},
	{"id": "fig_porco", "tipo": "figurinha", "nome": "Bolota-porquinho", "monstro": "porco"},
	{"id": "fig_fantasma", "tipo": "figurinha", "nome": "Bolota-fantasma", "monstro": "fantasma"},
	{"id": "fig_abelha", "tipo": "figurinha", "nome": "Bolota-abelha", "monstro": "abelha"},
	{"id": "fig_morcego", "tipo": "figurinha", "nome": "Bolota-morcego", "monstro": "morcego"},
	{"id": "fig_faisquinha", "tipo": "figurinha", "nome": "Faisquinha dourado", "monstro": ""},
	{"id": "roupa_palha", "tipo": "roupa", "nome": "Chapéu de palha", "chapeu": "palha"},
	{"id": "roupa_mago", "tipo": "roupa", "nome": "Chapéu de mago", "chapeu": "mago"},
	{"id": "roupa_palhaco", "tipo": "roupa", "nome": "Chapéu de palhaço", "chapeu": "palhaco"},
	{"id": "roupa_urso", "tipo": "roupa", "nome": "Gorro de urso", "chapeu": "urso"},
	{"id": "roupa_duende", "tipo": "roupa", "nome": "Gorro de duende", "chapeu": "duende"},
	{"id": "roupa_soldadinho", "tipo": "roupa", "nome": "Chapéu de soldadinho", "chapeu": "soldadinho"},
]

## Os ids de um tipo, na ordem da lista (a das figurinhas é a ordem da estante; as roupinhas vão para o cabide).
static func ids(tipo: String) -> Array:
	var out := []
	for b: Dictionary in LISTA:
		if b.tipo == tipo:
			out.append(b.id)
	return out


static func dados(id: String) -> Dictionary:
	for b: Dictionary in LISTA:
		if b.id == id:
			return b
	return {}


## Um brinde que ainda não saiu (sorteado), ou "" se já tem todos. Os 3 primeiros intercalam figurinha e roupinha,
## para a criança ver logo as duas coisas.
static func sortear(ja_tem: Array, rng: RandomNumberGenerator) -> String:
	var faltam := LISTA.filter(func(b: Dictionary) -> bool: return not b.id in ja_tem)
	if faltam.is_empty():
		return ""
	if ja_tem.size() < 3:
		var quer := "roupa" if ja_tem.size() == 1 else "figurinha"
		var desse := faltam.filter(func(b: Dictionary) -> bool: return b.tipo == quer)
		if not desse.is_empty():
			faltam = desse
	return faltam[rng.randi_range(0, faltam.size() - 1)].id


## O chapéu (id das Roupas) de uma roupinha.
static func chapeu_de(id: String) -> String:
	return String(dados(id).get("chapeu", ""))


## A figurinha pronta (pé em y = 0, uns 0,6 m): o monstro em 0,3x mexendo, ou o Faisquinha dourado.
static func figurinha(id: String) -> Node3D:
	var b := dados(id)
	if b.is_empty():
		return null
	if String(b.monstro) == "":
		var f := Faisquinha.boneco(Color("ffd23f"))
		f.scale = Vector3.ONE * 0.75
		return f
	var cena: Node3D = load(BolotaMonstro.PASTA + BolotaMonstro.TIPOS[b.monstro][0] + ".gltf").instantiate()
	cena.scale = Vector3.ONE * 0.3
	# O material do pacote vem sem luz: com luz, como o das Bolotas.
	var mat: StandardMaterial3D
	for mi: MeshInstance3D in cena.find_children("*", "MeshInstance3D", true, false):
		if mat == null:
			var original := mi.get_active_material(0) as StandardMaterial3D
			mat = original.duplicate() as StandardMaterial3D if original else StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			mat.roughness = 0.85
		mi.material_override = mat
	var anims := cena.find_children("*", "AnimationPlayer", true, false)
	if not anims.is_empty():
		var a := anims[0] as AnimationPlayer
		var parado := "Idle" if a.has_animation("Idle") else ("Flying" if a.has_animation("Flying") else "")
		if parado != "":
			a.get_animation(parado).loop_mode = Animation.LOOP_LINEAR
			a.play(parado)
	return cena


## O desenho do brinde para a revelação: a figurinha, ou o chapéu sozinho, com o meio dele na origem.
static func modelo(id: String) -> Node3D:
	var b := dados(id)
	if b.get("tipo", "") == "roupa":
		return centrado(Roupas.chapeu(chapeu_de(id)))
	return figurinha(id)


## Os chapéus das Roupas vêm no lugar deles em relação ao osso da cabeça (mais de 1 m acima): embrulhado num nó com o
## meio das malhas na origem (ou, com `pe`, a base delas).
static func centrado(no: Node3D, pe := false) -> Node3D:
	if no == null:
		return null
	var caixa := AABB()
	var primeira := true
	for mi: MeshInstance3D in no.find_children("*", "MeshInstance3D", true, false):
		var a := mi.transform * mi.get_aabb()
		caixa = a if primeira else caixa.merge(a)
		primeira = false
	var raiz := Node3D.new()
	raiz.add_child(no)
	var meio := caixa.get_center()
	no.position = -Vector3(meio.x, caixa.position.y if pe else meio.y, meio.z)
	return raiz
