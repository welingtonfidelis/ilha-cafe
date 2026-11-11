class_name Roupas
extends RefCounted
## Roupinhas da lojinha (item 11 da lista de melhorias, 2026-11-10): chapéus para as crianças e pinturas para os
## blasters. Os chapéus vêm dos personagens do KayKit (todos no mesmo esqueleto): a malha do chapéu sai do modelo de
## origem e vai para o osso da cabeça de quem joga, no mesmo lugar em relação ao osso, com um ajuste de tamanho e de
## altura para cada um (as cabeças das crianças são maiores e já têm o boné ou o cabelo). As pinturas tingem as
## malhas dos blasters. Os modelos de origem que ficavam na pasta dos aventureiros (fora da build) foram copiados
## para assets/characters/roupas/.

## Chapéus: id, nome, preço, modelo de origem, malha, e o ajuste [escala, deslocamento no espaço do osso da cabeça].
const CHAPEUS := [
	{"id": "coroa", "nome": "Coroa", "preco": 60, "glb": "res://assets/characters/skeletons/Necromancer.glb", "malha": "Necromancer_Crown",
		"ajuste": [1.0, Vector3.ZERO]},
	{"id": "mago", "nome": "Chapéu de mago", "preco": 40, "glb": "res://assets/characters/pilotos/Mage.glb", "malha": "Mage_Hat",
		"ajuste": [1.0, Vector3.ZERO]},
	{"id": "bruxa", "nome": "Chapéu de bruxa", "preco": 40, "glb": "res://assets/characters/moradores/Witch.glb", "malha": "Witch_Hat",
		"ajuste": [1.0, Vector3.ZERO]},
	{"id": "palhaco", "nome": "Chapéu de palhaço", "preco": 30, "glb": "res://assets/characters/moradores/Clown.glb", "malha": "Clown_Hat",
		"ajuste": [1.0, Vector3.ZERO]},
	{"id": "palha", "nome": "Chapéu de palha", "preco": 25, "glb": "res://assets/characters/moradores/Farmer_A.glb", "malha": "Farmer_A_Hat",
		"ajuste": [1.0, Vector3.ZERO]},
	{"id": "soldadinho", "nome": "Chapéu de soldadinho", "preco": 35, "glb": "res://assets/characters/moradores/ToySoldier.glb",
		"malha": "ToySoldier_Hat", "ajuste": [1.0, Vector3.ZERO]},
	{"id": "trilha", "nome": "Chapéu de trilha", "preco": 25, "glb": "res://assets/characters/moradores/Hiker.glb", "malha": "Hiker_Hat",
		"ajuste": [1.0, Vector3.ZERO]},
	{"id": "urso", "nome": "Gorro de urso", "preco": 50, "glb": "res://assets/characters/roupas/Barbarian.glb", "malha": "Barbarian_BearHat",
		"ajuste": [1.0, Vector3.ZERO]},
	{"id": "elmo", "nome": "Elmo de cavaleiro", "preco": 50, "glb": "res://assets/characters/roupas/Knight.glb", "malha": "Knight_Helmet",
		"ajuste": [1.0, Vector3.ZERO]},
	{"id": "duende", "nome": "Gorro de duende", "preco": 35, "glb": "res://assets/characters/roupas/Helper_A.glb", "malha": "Helper_A_Hat",
		"ajuste": [1.0, Vector3.ZERO]},
]
## Pinturas dos blasters: id, nome, preço e cor.
const PINTURAS := [
	{"id": "rosa", "nome": "Rosa-chiclete", "preco": 20, "cor": Color("#ff7ac0")},
	{"id": "azul", "nome": "Azul-piscina", "preco": 20, "cor": Color("#4ad0ff")},
	{"id": "verde", "nome": "Verde-limão", "preco": 20, "cor": Color("#8aff5a")},
	{"id": "roxo", "nome": "Roxo-uva", "preco": 20, "cor": Color("#b37aff")},
	{"id": "dourado", "nome": "Dourado", "preco": 50, "cor": Color("#ffd23f")},
]

static var _cache := {}


static func dados(id: String) -> Dictionary:
	for c: Dictionary in CHAPEUS + PINTURAS:
		if c.id == id:
			return c
	return {}


static func e_chapeu(id: String) -> bool:
	return CHAPEUS.any(func(c: Dictionary) -> bool: return c.id == id)


## O chapéu pronto para ir num BoneAttachment3D do osso "head": um Node3D com a malha no lugar certo.
static func chapeu(id: String) -> Node3D:
	var spec := dados(id)
	if spec.is_empty() or not e_chapeu(id):
		return null
	if not _cache.has(id):
		_cache[id] = _extrair(spec)
	var c: Dictionary = _cache[id]
	if c.is_empty():
		return null
	var raiz := Node3D.new()
	raiz.name = "Chapeu"
	var mi := MeshInstance3D.new()
	mi.mesh = c.mesh
	for i in c.materiais.size():
		if c.materiais[i]:
			mi.set_surface_override_material(i, c.materiais[i])
	var ajuste: Array = spec.ajuste
	mi.transform = Transform3D(Basis.from_scale(Vector3.ONE * float(ajuste[0])), ajuste[1]) * c.local
	raiz.add_child(mi)
	return raiz


## Tira do modelo de origem a malha do chapéu e onde ela fica em relação ao osso da cabeça (na pose de descanso).
static func _extrair(spec: Dictionary) -> Dictionary:
	var modelo: Node3D = load(spec.glb).instantiate()
	var sk: Skeleton3D = modelo.find_child("Skeleton3D", true, false)
	var mi := modelo.find_child(spec.malha, true, false) as MeshInstance3D
	if sk == null or mi == null:
		modelo.free()
		return {}
	var cabeca := sk.find_bone("head")
	var rest := sk.get_bone_global_rest(cabeca)
	# Onde a malha fica no espaço do esqueleto: soma os transforms do nó até o esqueleto (sem precisar da árvore).
	var t := Transform3D.IDENTITY
	var n: Node = mi
	while n != null and n != sk:
		if n is Node3D:
			t = (n as Node3D).transform * t
		n = n.get_parent()
	var materiais := []
	for i in mi.mesh.get_surface_count():
		materiais.append(mi.get_surface_override_material(i) if mi.get_surface_override_material(i) else mi.mesh.surface_get_material(i))
	var out := {"mesh": mi.mesh, "materiais": materiais, "local": rest.affine_inverse() * t}
	modelo.free()
	return out


## Pinta as malhas de um blaster (cópia do material com a cor multiplicando a textura). Cor branca tira a pintura.
static func pintar(raiz: Node, cor: Color) -> void:
	for m: MeshInstance3D in raiz.find_children("*", "MeshInstance3D", true, false):
		for i in m.mesh.get_surface_count():
			if cor == Color.WHITE:
				m.set_surface_override_material(i, null)
				continue
			var base := m.mesh.surface_get_material(i)
			if base is StandardMaterial3D:
				var copia: StandardMaterial3D = base.duplicate()
				copia.albedo_color = (base as StandardMaterial3D).albedo_color * cor
				m.set_surface_override_material(i, copia)
