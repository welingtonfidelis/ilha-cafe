class_name Brindes
extends RefCounted
## Os brindes da Máquina de Brindes do farol (item 4 da lista de melhorias do Faísca, 2026-11-11), como o laboratório
## de brindes do Astro Bot: cada cápsula custa PRECO moedas e traz um brinde que ainda não saiu (não repete).
## - 12 figurinhas para a estante do térreo: os 11 monstros da turma das Bolotas (mexendo, na animação de parado) e
##   um Faisquinha dourado;
## - 6 tintas para pintar o Faísca (as partes laranja dele), escolhidas na lojinha das tintas, que o soco no cabide
##   abre (PainelTintas, com a prévia). Até 2026-11-12 eram 6 chapéus da lojinha da ilha, trocados a cada soco no
##   cabide; o usuário achou que não ficou legal e pediu as tintas. Quem já tinha chapéus ganha as tintas no lugar
##   (`migrar`).

const PRECO := 25
## A cor de fábrica do Faísca (a tinta "" é ela).
const COR_ORIGINAL := Color("ff7a22")
## Os chapéus de antes viram estas tintas, na mesma ordem (o save de quem já tinha).
const DE_CHAPEU := {
	"roupa_palha": "tinta_azul", "roupa_mago": "tinta_verde", "roupa_palhaco": "tinta_roxa",
	"roupa_urso": "tinta_rosa", "roupa_duende": "tinta_vermelha", "roupa_soldadinho": "tinta_dourada",
}

## id, tipo ("figurinha" ou "tinta"), nome e de onde vem (o tipo do monstro ou "" para o Faisquinha dourado; a cor da
## tinta, e "metal" na dourada, que brilha).
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
	{"id": "tinta_azul", "tipo": "tinta", "nome": "Azul", "cor": Color("2f8cff")},
	{"id": "tinta_verde", "tipo": "tinta", "nome": "Verde", "cor": Color("34c759")},
	{"id": "tinta_roxa", "tipo": "tinta", "nome": "Roxo", "cor": Color("9a5cf5")},
	{"id": "tinta_rosa", "tipo": "tinta", "nome": "Rosa", "cor": Color("ff5fae")},
	{"id": "tinta_vermelha", "tipo": "tinta", "nome": "Vermelho", "cor": Color("e8333f")},
	{"id": "tinta_dourada", "tipo": "tinta", "nome": "Dourado", "cor": Color("ffc53a"), "metal": true},
]

## Os ids de um tipo, na ordem da lista (a das figurinhas é a ordem da estante; a das tintas, a dos ganchos do cabide e
## dos cartões da lojinha).
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


## Um brinde que ainda não saiu (sorteado), ou "" se já tem todos. Os 3 primeiros intercalam figurinha e tinta,
## para a criança ver logo as duas coisas.
static func sortear(ja_tem: Array, rng: RandomNumberGenerator) -> String:
	var faltam := LISTA.filter(func(b: Dictionary) -> bool: return not b.id in ja_tem)
	if faltam.is_empty():
		return ""
	if ja_tem.size() < 3:
		var quer := "tinta" if ja_tem.size() == 1 else "figurinha"
		var desse := faltam.filter(func(b: Dictionary) -> bool: return b.tipo == quer)
		if not desse.is_empty():
			faltam = desse
	return faltam[rng.randi_range(0, faltam.size() - 1)].id


## A cor de uma tinta ("" é a de fábrica).
static func cor_de(id: String) -> Color:
	return dados(id).get("cor", COR_ORIGINAL)


## A tinta dourada brilha como metal.
static func metal(id: String) -> bool:
	return bool(dados(id).get("metal", false))


## Os brindes de um save antigo, com os chapéus trocados pelas tintas (sem repetir).
static func migrar(lista: Array) -> Array:
	var out := []
	for id in lista:
		var novo: String = DE_CHAPEU.get(String(id), String(id))
		if not novo in out:
			out.append(novo)
	return out


## A lata de tinta (o balde de metal do KayKit RPG Tools Bits, com a tinta em cima e um escorrido de cada lado),
## com o pé em y = 0 e uns 0,5 m de altura.
static func lata(cor: Color, de_metal := false) -> Node3D:
	var raiz := Node3D.new()
	var balde: Node3D = load("res://assets/faisca/tintas/bucket_metal.gltf").instantiate()
	raiz.add_child(balde)
	var tinta := StandardMaterial3D.new()
	tinta.albedo_color = cor
	tinta.roughness = 0.25 if de_metal else 0.18
	tinta.metallic = 0.4 if de_metal else 0.0
	tinta.clearcoat_enabled = true
	tinta.clearcoat = 0.6
	# Medidas do balde: aro de cima com raio de uns 0,42 e altura de 0,74 na escala 1.
	var caixa := AABB()
	var primeira := true
	for mi: MeshInstance3D in balde.find_children("*", "MeshInstance3D", true, false):
		if mi.name.contains("handle"):
			continue
		var a := mi.transform * mi.get_aabb()
		caixa = a if primeira else caixa.merge(a)
		primeira = false
	var topo := caixa.end.y
	var raio := minf(caixa.size.x, caixa.size.z) * 0.5
	var superficie := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = raio * 0.86
	disco.bottom_radius = raio * 0.86
	disco.height = 0.03
	disco.radial_segments = 32
	superficie.mesh = disco
	superficie.material_override = tinta
	superficie.position = Vector3(caixa.get_center().x, topo - 0.05, caixa.get_center().z)
	raiz.add_child(superficie)
	# O rótulo: uma faixa na cor da tinta em volta do corpo, entre os dois frisos do balde, para a cor aparecer de
	# qualquer lado (pendurada no cabide, a lata fica de perfil). O corpo vai de raio 0,323 em y 0,203 a 0,370 em
	# y 0,517 (medido no .bin); a faixa fica 6 mm para fora.
	var rotulo := MeshInstance3D.new()
	var faixa := CylinderMesh.new()
	faixa.bottom_radius = 0.335
	faixa.top_radius = 0.371
	faixa.height = 0.24
	faixa.radial_segments = 32
	faixa.cap_top = false
	faixa.cap_bottom = false
	rotulo.mesh = faixa
	var rotulo_mat := tinta.duplicate() as StandardMaterial3D
	rotulo_mat.clearcoat_enabled = false
	rotulo_mat.roughness = 0.5 if not de_metal else 0.3
	rotulo.material_override = rotulo_mat
	rotulo.position.y = 0.36
	raiz.add_child(rotulo)
	for lado in [-1.0, 1.0]:
		var pingo := MeshInstance3D.new()
		var gota := CapsuleMesh.new()
		gota.radius = raio * 0.13
		gota.height = caixa.size.y * (0.42 if lado > 0.0 else 0.28)
		pingo.mesh = gota
		pingo.material_override = tinta
		var a := 0.6 if lado > 0.0 else 2.4
		pingo.position = Vector3(cos(a) * raio * 0.98, topo - gota.height * 0.5 + 0.02, sin(a) * raio * 0.98) + Vector3(caixa.get_center().x, 0, caixa.get_center().z)
		raiz.add_child(pingo)
	raiz.position.y = -caixa.position.y
	var fora := Node3D.new()
	fora.add_child(raiz)
	fora.scale = Vector3.ONE * (0.5 / maxf(caixa.size.y, 0.01))
	return fora


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


## O desenho do brinde para a revelação: a figurinha, ou a lata de tinta, com o meio dela na origem.
static func modelo(id: String) -> Node3D:
	var b := dados(id)
	if b.get("tipo", "") == "tinta":
		var l := lata(cor_de(id), metal(id))
		l.position.y = -0.25
		var meio := Node3D.new()
		meio.add_child(l)
		return meio
	return figurinha(id)
