class_name CapsulaDePoder
extends Area3D
## Cápsula de poder da Nave Aspiratrão (a fase final do Faísca, 2026-11-12, da maquete aprovada pelo usuário): os
## poderes ficam nas fases deles, então a nave tem um tubo de vidro cor-de-rosa para cada um, na entrada do playground
## onde ele serve, com a figura do poder girando lá dentro (a criança vê o que vai ganhar antes de pegar, sem ler).
## Encostar pega: a figura some num brilho, o vidro desce e o poder vale até o fim da fase (o FaiscaJogo tira todos ao
## entrar em outra). Os poderes somam: a nave é o lugar de usar tudo junto.
## `poder`: "chiclete", "ioio", "luva", "martelinho" ou "pipa". O nó fica no chão, no meio da cápsula.

signal pega(c: CapsulaDePoder, j: Jogador)

const NOMES := {"chiclete": "Balão de Chiclete", "ioio": "Ioiô", "luva": "Luva de Neve", "martelinho": "Martelinho de Apito",
	"pipa": "Pipa"}
## A dica do Vovô que cada poder já tem no balão.
const DICAS := {"chiclete": "balao", "ioio": "ioio", "luva": "luva", "martelinho": "martelo", "pipa": "pipa"}
const ROSA := Color("ff8fd0")

var poder := "chiclete"
var pega_ja := false

var _figura: Node3D
var _vidro: MeshInstance3D
var _tempo := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR
	monitorable = false
	var cs := CollisionShape3D.new()
	var cil := CylinderShape3D.new()
	cil.radius = 1.5
	cil.height = 3.4
	cs.shape = cil
	cs.position.y = 1.7
	add_child(cs)
	var escuro := StandardMaterial3D.new()
	escuro.albedo_color = Color("3a3150")
	escuro.metallic = 0.4
	escuro.roughness = 0.4
	for spec in [[1.55, 1.7, 0.5, 0.25], [1.45, 1.45, 0.3, 3.65]]:
		var mi := MeshInstance3D.new()
		var c := CylinderMesh.new()
		c.top_radius = spec[0]
		c.bottom_radius = spec[1]
		c.height = spec[2]
		mi.mesh = c
		mi.material_override = escuro
		mi.position.y = spec[3]
		add_child(Fase.so_enfeite(mi))
	var aro := MeshInstance3D.new()
	var toro := TorusMesh.new()
	toro.inner_radius = 1.4
	toro.outer_radius = 1.62
	aro.mesh = toro
	var rosa := StandardMaterial3D.new()
	rosa.albedo_color = ROSA
	rosa.emission_enabled = true
	rosa.emission = ROSA
	rosa.emission_energy_multiplier = 0.8
	aro.material_override = rosa
	aro.position.y = 0.52
	add_child(Fase.so_enfeite(aro))
	_vidro = MeshInstance3D.new()
	var tubo := CylinderMesh.new()
	tubo.top_radius = 1.32
	tubo.bottom_radius = 1.32
	tubo.height = 3.0
	tubo.cap_top = false
	tubo.cap_bottom = false
	_vidro.mesh = tubo
	var vidro := StandardMaterial3D.new()
	vidro.albedo_color = Color(1.0, 0.65, 0.88, 0.28)
	vidro.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	vidro.cull_mode = BaseMaterial3D.CULL_DISABLED
	vidro.roughness = 0.05
	vidro.rim_enabled = true
	_vidro.material_override = vidro
	_vidro.position.y = 2.0
	_vidro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(Fase.so_enfeite(_vidro))
	_figura = figura(poder)
	_figura.position.y = 2.0
	add_child(_figura)
	var luz := OmniLight3D.new()
	luz.light_color = ROSA
	luz.light_energy = 1.2
	luz.omni_range = 5.0
	luz.position.y = 2.2
	add_child(luz)
	_tempo = randf() * 3.0
	body_entered.connect(func(corpo: Node3D) -> void:
		if corpo is Jogador and not pega_ja:
			pegar(corpo as Jogador))


## O Faísca entrou na cápsula: ganha o poder, a figura some e o vidro desce.
func pegar(j: Jogador) -> void:
	if pega_ja:
		return
	pega_ja = true
	match poder:
		"chiclete":
			j.balao_de_chiclete = true
		"ioio":
			j.ioio = true
		"luva":
			j.luva_de_neve = true
		"martelinho":
			j.martelinho = true
		"pipa":
			j.pipa = true
	j.robo.expressao("feliz", 1.2)
	Fx.confetti(get_parent(), global_position + Vector3.UP * 2.0, 40, 4.0)
	Sfx.play(get_parent(), "bandeira", 0.0, 0.0)
	var tw := create_tween()
	tw.tween_property(_figura, "scale", Vector3.ONE * 0.01, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(_vidro, "scale:y", 0.08, 0.5)
	tw.parallel().tween_property(_vidro, "position:y", 0.62, 0.5)
	tw.tween_callback(_figura.hide)
	pega.emit(self, j)


func _process(delta: float) -> void:
	_tempo += delta
	if _figura.visible:
		_figura.rotation.y = _tempo * 1.6
		_figura.position.y = 2.0 + sin(_tempo * 2.2) * 0.15


## A figura de cada poder (também para as fotos e para quem mais quiser mostrar): o balão rosa, o ioiô vermelho, a luva
## azul com a bola de neve, o martelinho de apito e a pipa.
static func figura(qual: String) -> Node3D:
	var raiz := Node3D.new()
	match qual:
		"chiclete":
			var bola := _bola(0.62, Color("ff8fc8"), raiz)
			bola.scale = Vector3(1, 1.08, 1)
			_bola(0.14, Color("fff4fa"), raiz).position = Vector3(-0.22, 0.25, 0.48)
			var no := MeshInstance3D.new()
			var cone := CylinderMesh.new()
			cone.top_radius = 0.02
			cone.bottom_radius = 0.14
			cone.height = 0.22
			no.mesh = cone
			no.material_override = _cor(Color("e0609f"))
			no.position.y = -0.72
			no.rotation.z = PI
			raiz.add_child(no)
		"ioio":
			for lado in [-0.13, 0.13]:
				var disco := MeshInstance3D.new()
				var c := CylinderMesh.new()
				c.top_radius = 0.5
				c.bottom_radius = 0.5
				c.height = 0.18
				disco.mesh = c
				disco.material_override = _cor(Color("e8333f"))
				disco.rotation.x = PI / 2.0
				disco.position.z = lado
				raiz.add_child(disco)
				var miolo := MeshInstance3D.new()
				var m := CylinderMesh.new()
				m.top_radius = 0.18
				m.bottom_radius = 0.18
				m.height = 0.2
				miolo.mesh = m
				miolo.material_override = _cor(Color("ffd23f"))
				miolo.rotation.x = PI / 2.0
				miolo.position.z = lado * 1.2
				raiz.add_child(miolo)
			var fio := MeshInstance3D.new()
			var f := CylinderMesh.new()
			f.top_radius = 0.025
			f.bottom_radius = 0.025
			f.height = 0.9
			fio.mesh = f
			fio.material_override = _cor(Color("fff8ee"))
			fio.position.y = 0.45
			raiz.add_child(fio)
		"luva":
			var palma := MeshInstance3D.new()
			var p := BoxMesh.new()
			p.size = Vector3(0.62, 0.72, 0.34)
			palma.mesh = p
			palma.material_override = _cor(Color("4a90e2"))
			raiz.add_child(palma)
			var dedao := MeshInstance3D.new()
			var d := BoxMesh.new()
			d.size = Vector3(0.22, 0.38, 0.28)
			dedao.mesh = d
			dedao.material_override = _cor(Color("4a90e2"))
			dedao.position = Vector3(0.4, 0.05, 0)
			dedao.rotation.z = -0.5
			raiz.add_child(dedao)
			var punho := MeshInstance3D.new()
			var u := BoxMesh.new()
			u.size = Vector3(0.7, 0.2, 0.4)
			punho.mesh = u
			punho.material_override = _cor(Color("fff8ee"))
			punho.position.y = -0.45
			raiz.add_child(punho)
			_bola(0.26, Color("f4fbff"), raiz).position = Vector3(-0.1, 0.62, 0.1)
		"martelinho":
			var cabo := MeshInstance3D.new()
			var c := CylinderMesh.new()
			c.top_radius = 0.07
			c.bottom_radius = 0.07
			c.height = 1.1
			cabo.mesh = c
			cabo.material_override = _cor(Color("ffd23f"))
			cabo.position.y = -0.2
			raiz.add_child(cabo)
			var cabeca := MeshInstance3D.new()
			var h := CylinderMesh.new()
			h.top_radius = 0.26
			h.bottom_radius = 0.26
			h.height = 0.66
			cabeca.mesh = h
			cabeca.material_override = _cor(Color("e8333f"))
			cabeca.rotation.z = PI / 2.0
			cabeca.position.y = 0.42
			raiz.add_child(cabeca)
			for lado in [-0.18, 0.0, 0.18]:
				var anel := MeshInstance3D.new()
				var a := CylinderMesh.new()
				a.top_radius = 0.28
				a.bottom_radius = 0.28
				a.height = 0.05
				anel.mesh = a
				anel.material_override = _cor(Color("fff8ee"))
				anel.rotation.z = PI / 2.0
				anel.position = Vector3(lado, 0.42, 0)
				raiz.add_child(anel)
		"pipa":
			var pipa := Node3D.new()
			pipa.scale = Vector3.ONE * 0.62
			pipa.position.y = 0.45
			raiz.add_child(pipa)
			for parte in Pipa.desenho():
				pipa.add_child(parte)
	return raiz


static func _bola(raio: float, cor: Color, pai: Node3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0
	mi.mesh = s
	mi.material_override = _cor(cor)
	pai.add_child(mi)
	return mi


static func _cor(cor: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = 0.45
	return m
