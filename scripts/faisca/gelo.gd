class_name Gelo
extends RefCounted
## O gelo que escorrega, a novidade da 3-1 Pico Gelado (2026-10-30). Chão de gelo é sempre azul bem claro, brilhante e
## riscado (o mesmo material em toda parte), para não confundir com a neve, que é branca, fosca e firme. Em pé num
## corpo marcado aqui, o Faísca acelera e freia devagar (Jogador.ACELERACAO_GELO).

static var _material: StandardMaterial3D
static var _material_cubo: StandardMaterial3D


## Marca o corpo como chão de gelo e devolve ele.
static func marcar(corpo: Node) -> Node:
	corpo.set_meta("gelo", true)
	return corpo


## O material do chão de gelo: azul clarinho, liso e com riscos brancos.
static func material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.albedo_texture = _riscos()
		_material.albedo_color = Color("a9dcff")
		_material.roughness = 0.08
		_material.metallic = 0.15
		_material.rim_enabled = true
		_material.rim = 0.5
		_material.uv1_triplanar = true
		_material.uv1_scale = Vector3.ONE * 0.18
	return _material


## Gelo transparente dos cubos e das paredes (o cubo do pinguim, a porta do cume).
static func material_cubo() -> StandardMaterial3D:
	if _material_cubo == null:
		_material_cubo = StandardMaterial3D.new()
		_material_cubo.albedo_color = Color(0.75, 0.92, 1.0, 0.55)
		_material_cubo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material_cubo.roughness = 0.05
		_material_cubo.metallic = 0.2
		_material_cubo.rim_enabled = true
		_material_cubo.rim = 0.8
		_material_cubo.emission_enabled = true
		_material_cubo.emission = Color("bfe9ff")
		_material_cubo.emission_energy_multiplier = 0.2
	return _material_cubo


## Textura de riscos: o azul quase branco com umas linhas brancas de patins.
static func _riscos() -> ImageTexture:
	var img := Image.create(128, 128, false, Image.FORMAT_RGB8)
	img.fill(Color("e9f7ff"))
	var gerador := RandomNumberGenerator.new()
	gerador.seed = 31
	for i in 9:
		var de := Vector2(gerador.randf_range(0, 128), gerador.randf_range(0, 128))
		var dir := Vector2.RIGHT.rotated(gerador.randf_range(-0.6, 0.6) + (PI * 0.5 if i % 3 == 0 else 0.0))
		var comprimento := gerador.randf_range(30, 90)
		for k in int(comprimento):
			var p := de + dir * k
			var x := posmod(int(p.x), 128)
			var y := posmod(int(p.y), 128)
			img.set_pixel(x, y, Color.WHITE)
			img.set_pixel(posmod(x + 1, 128), y, Color("f7fcff"))
	return ImageTexture.create_from_image(img)
