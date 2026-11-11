class_name TexturaDoChao
extends RefCounted
## Textura no chão em vez da cor lisa (item 13 da lista do Faísca, ideia do usuário em 2026-11-11: "colocar texturas
## no solo ao invés do chao cru, tanto pro faisca quanto jogo ilha"). Os desenhos são feitos por conta no shader
## (`padroes_do_chao.gdshaderinc`), sem imagem baixada, nas coordenadas do mundo: escurecem e clareiam a cor que o
## chão já tem, sem trocar o tom.
## - Na ilha, o terreno gerado ganha o `terreno_da_ilha.gdshader`, que escolhe o desenho pela cor de cada pedaço
##   (grama, mata, areia, pedra das encostas, terra das trilhas, calçada e praça da cidade).
## - Nas fases do Faísca, cada peça de chão ganha o `detalhe_do_chao.gdshader` por cima (material_overlay), com o
##   desenho da `superficie` da fase. A grama (os morros do Forest Nature e o chão da arena do Bolotão Fofão) ganha o
##   campo da ilha, com cor, no `grama_das_fases.gdshader` no lugar do material, e pedra nas encostas.

## A mesma ordem do `pc_padrao` do shader.
const PADROES := ["grama", "terra", "areia", "pedra", "calcada", "praca", "madeira", "tapete", "neve", "gelo", "metal", "algodao"]
## Superfície da fase -> desenho do chão dela.
const DA_SUPERFICIE := {
	"grama": "grama", "pedra": "pedra", "madeira": "madeira", "algodao": "algodao", "nuvem": "algodao",
	"tapete": "tapete", "neve": "neve", "gelo": "gelo", "metal": "metal",
}
## Só ganha desenho o que tem cara de chão: pelo menos isto de largura nos dois lados.
const LARGURA_MINIMA := 3.0

static var _materiais := {}


## O material por cima (overlay) com o desenho `topo` em cima e `lado` nas faces em pé ("" = nenhum).
static func por_cima(topo: String, lado := "") -> ShaderMaterial:
	var chave := topo + "/" + lado
	if not _materiais.has(chave):
		var m := ShaderMaterial.new()
		m.shader = load("res://scripts/chao/detalhe_do_chao.gdshader")
		m.set_shader_parameter("padrao_topo", PADROES.find(topo))
		m.set_shader_parameter("padrao_lado", PADROES.find(lado) if lado != "" else -1)
		_materiais[chave] = m
	return _materiais[chave]


## O material do terreno da ilha.
static func da_ilha() -> ShaderMaterial:
	if not _materiais.has("ilha"):
		var m := ShaderMaterial.new()
		m.shader = load("res://scripts/chao/terreno_da_ilha.gdshader")
		_materiais["ilha"] = m
	return _materiais["ilha"]


## Põe o desenho no terreno da ilha (o nó "Terreno/Malha" da cena gerada). Devolve se achou.
static func na_ilha(ilha: Node) -> bool:
	var malha := ilha.get_node_or_null("Terreno/Malha") as MeshInstance3D
	if malha == null:
		return false
	malha.material_override = da_ilha()
	return true


## Põe o desenho em cada peça de chão da fase: o que é sólido, largo, de material comum (nem transparente, nem de
## shader próprio, como a água) e não é enfeite, personagem ou coisa de pegar. As plataformas de plástico do
## Platformer ficam lisas (são brinquedo). Devolve quantas peças ganharam; cada uma vai também para a `lista`
## ([peça, desenho]), onde a VegetacaoDaFase espalha as plantas e as miudezas.
static func na_fase(fase: Node3D, superficie: String, lista: Array = []) -> int:
	var padrao: String = DA_SUPERFICIE.get(superficie, "")
	var n := 0
	for no in fase.find_children("*", "MeshInstance3D", true, false):
		var mi := no as MeshInstance3D
		if mi.material_overlay != null or not _e_chao(mi, fase):
			continue
		var cena := String(mi.owner.scene_file_path) if mi.owner else ""
		var arquivo := cena.get_file()
		# A fase pode escolher o que leva o desenho (a cozinha da 2-1: só a madeira ganha tábuas).
		if fase.has_method("leva_desenho") and not fase.call("leva_desenho", mi, arquivo):
			continue
		var topo := padrao
		var lado := ""
		if arquivo.begins_with("Hill_"):
			topo = "grama" if superficie in ["grama", "pedra", ""] else padrao
			lado = "pedra"
		elif arquivo.begins_with("platform") or cena.contains("/plataforma/"):
			continue
		if _no_gelo(mi, fase):
			topo = "gelo"
		if topo == "":
			continue
		# A grama ganha o campo da ilha, com cor (no lugar do material); o resto, o desenho por cima.
		lista.append([mi, topo])
		if topo == "grama" and _grama_com_cor(mi, lado):
			n += 1
			continue
		mi.material_overlay = por_cima(topo, lado)
		n += 1
	return n


## Troca o material da peça de grama pelo `grama_das_fases.gdshader`, com a textura e a cor dela por baixo. Só quando
## dá: um material só, comum (StandardMaterial3D), sem cor de vértice. Devolve se trocou.
static func _grama_com_cor(mi: MeshInstance3D, lado: String) -> bool:
	var mat := mi.get_active_material(0) as StandardMaterial3D
	if mat == null or mat.vertex_color_use_as_albedo:
		return false
	for k in range(1, mi.mesh.get_surface_count()):
		if mi.get_active_material(k) != mat:
			return false
	var chave := "grama/%s/%s/%s" % [mat.albedo_texture.resource_path if mat.albedo_texture else "", mat.albedo_color.to_html(), lado]
	if not _materiais.has(chave):
		var m := ShaderMaterial.new()
		m.shader = load("res://scripts/chao/grama_das_fases.gdshader")
		if mat.albedo_texture:
			m.set_shader_parameter("textura", mat.albedo_texture)
		m.set_shader_parameter("cor_base", mat.albedo_color)
		m.set_shader_parameter("padrao_lado", PADROES.find(lado) if lado != "" else -1)
		_materiais[chave] = m
	mi.material_override = _materiais[chave]
	return true


## O chão de gelo (meta "gelo" no corpo, como o lago da 3-1) leva o desenho do gelo.
static func _no_gelo(mi: MeshInstance3D, fase: Node) -> bool:
	for c in mi.get_children():
		if c is StaticBody3D and c.has_meta("gelo"):
			return true
	var n: Node = mi
	while n and n != fase:
		if n.has_meta("gelo"):
			return true
		n = n.get_parent()
	return false


static func _e_chao(mi: MeshInstance3D, fase: Node) -> bool:
	if mi.mesh == null or not mi.visible:
		return false
	var mat := mi.get_active_material(0)
	if mat is ShaderMaterial or (mat is BaseMaterial3D and (mat as BaseMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED):
		return false
	var solido := mi.get_children().any(func(c: Node) -> bool: return c is StaticBody3D)
	var n: Node = mi
	while n and n != fase:
		if n.has_meta("enfeite") or n is Area3D or n is CharacterBody3D or n is RigidBody3D:
			return false
		# O que se mexe ou tem regra própria (plataforma que anda, pizza que gira, nuvem que some, caixa que quebra):
		# o desenho é preso no mundo e escorregaria por cima dela.
		if n is AnimatableBody3D or (n != mi and n.get_script() != null):
			return false
		if n is StaticBody3D or n is AnimatableBody3D:
			solido = true
		n = n.get_parent()
	# O meta "chao" marca de propósito o desenho de um chão cuja colisão é um corpo à parte (a arena do Bolotão Fofão).
	if not solido and not mi.has_meta("chao"):
		return false
	var caixa := mi.global_transform * mi.get_aabb()
	return caixa.size.x >= LARGURA_MINIMA and caixa.size.z >= LARGURA_MINIMA
