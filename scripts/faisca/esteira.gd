class_name Esteira
extends StaticBody3D
## Esteira rolante (a conveyor_4x8x1 do Platformer Pack), pedido do usuário em 2026-10-29 ("as fases estão
## muito curtas"): ela empurra quem está em cima na direção do comprimento, a `velocidade` m/s. Quem empurra é a
## física: o corpo parado com `constant_linear_velocity` leva junto quem pisa nele, igual a uma plataforma que se
## mexe. Por cima vão setinhas brancas andando na mesma direção, para a criança ver para onde ela leva.
## O comprimento fica no Z do nó e ela leva sempre para o +Z dele (o giro do nó escolhe o sentido).

const LARGURA := 4.2
const COMPRIMENTO := 8.0
const ALTURA := 1.0

var velocidade := 3.0
var cor := "blue"
var _setas: StandardMaterial3D


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	constant_linear_velocity = global_basis.z * velocidade
	var modelo: Node3D = load(Fase.PLATAFORMA + "conveyor_4x8x1_%s.gltf" % cor).instantiate()
	add_child(modelo)
	var cs := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(LARGURA, ALTURA, COMPRIMENTO)
	cs.shape = caixa
	cs.position.y = ALTURA * 0.5
	add_child(cs)
	# Setinhas: um plano por cima da faixa, com a textura repetida e andando.
	_setas = StandardMaterial3D.new()
	_setas.albedo_texture = _textura_setas()
	_setas.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_setas.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_setas.uv1_scale = Vector3(1, COMPRIMENTO / 2.0, 1)
	var faixa := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(LARGURA - 1.4, COMPRIMENTO - 0.6)
	faixa.mesh = plano
	faixa.material_override = _setas
	faixa.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	faixa.position.y = ALTURA + 0.02
	add_child(faixa)


func _process(delta: float) -> void:
	# A textura anda no sentido da esteira (o v do plano cresce para +Z).
	_setas.uv1_offset.y = fposmod(_setas.uv1_offset.y - delta * velocidade / 2.0, 1.0)


## Uma seta branca apontando para +Z (para baixo na imagem), num quadro de 64 x 64 com fundo transparente.
static func _textura_setas() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for y in 64:
		for x in 64:
			# Chevron: duas faixas em V com a ponta embaixo.
			var d := absf(x - 32.0)
			var linha := 44.0 - d * 0.9
			if y > linha - 9.0 and y < linha and d < 26.0:
				img.set_pixel(x, y, Color(1, 1, 1, 0.85))
	return ImageTexture.create_from_image(img)
