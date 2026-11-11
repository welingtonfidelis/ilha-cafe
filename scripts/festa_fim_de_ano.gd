class_name FestaFimDeAno
extends Node3D
## Festa de fim de ano (item 12 da lista de melhorias, 2026-11-10): em dezembro (e no dia 1º de janeiro), pela data
## do computador, a ilha entra no clima. Na praia, ao lado do aquário, uma árvore de Natal gigante enfeitada (Holiday
## Bits do KayKit) com presentes em volta, dois bonecos de neve e a casinha de biscoito; neve fininha caindo em volta
## do aventureiro; os moradores que não têm chapéu ganham o gorro de duende. Embaixo da árvore, o presente do dia
## brilha: B abre (confete e moedas, mais no dia 24, no 25 e no 31) e só volta no dia seguinte. No dia 31 e no
## 1º de janeiro, à noite, fogos sobem da praia. Os testes ligam com `forcar` e mudam o dia com `hoje_teste`.

const ARVORE := Vector3(22.0, 0.0, 203.0)
const MODELOS := "res://assets/props/festa/doces/%s.gltf"
const PRESENTES := ["present_A_red", "present_B_blue", "present_C_yellow", "present_D_green", "present_E_white", "present_F_red",
	"present_A_yellow", "present_C_blue"]
const MOEDAS := 10
const MOEDAS_ESPECIAL := 25
const ABRIR := 2.4

## Nos testes: liga sem esperar dezembro, e o dia de hoje ("2026-12-24").
static var forcar := false
static var hoje_teste := ""
## Nos testes a data do computador não vale (em dezembro, todos os testes iam ter a festa): só com `forcar`.
static var testando := false

var game: Node
var story: Story
var ativa := false
## O último dia em que abriu o presente ("2026-12-05").
var aberto_em := ""
var presente_do_dia: Node3D
var neve: GPUParticles3D
var fogos := 0
var _arvore: Node3D
var _luz_presente: OmniLight3D
var _t := 0.0
var _proximo_fogo := 2.0
var _gorros := 0


func _ready() -> void:
	ativa = forcar or (not testando and esta_na_epoca(hoje()))
	if not ativa:
		return
	_montar.call_deferred()


static func esta_na_epoca(dia: String) -> bool:
	var partes := dia.split("-")
	if partes.size() < 3:
		return false
	var mes := int(partes[1])
	return mes == 12 or (mes == 1 and int(partes[2]) == 1)


func hoje() -> String:
	if hoje_teste != "":
		return hoje_teste
	var d := Time.get_date_dict_from_system()
	return "%04d-%02d-%02d" % [d.year, d.month, d.day]


func _dia_de_fogos() -> bool:
	var d := hoje()
	return d.ends_with("-12-31") or d.ends_with("-01-01")


func _dia_especial() -> bool:
	var d := hoje()
	return d.ends_with("-12-24") or d.ends_with("-12-25") or d.ends_with("-12-31")


# --- os enfeites -------------------------------------------------------------------

func _montar() -> void:
	await get_tree().physics_frame
	var chao: Vector3 = game._ground_point(ARVORE)
	_arvore = _modelo("christmas_tree_decorated", chao, 3.4, 0.0)
	var luz := OmniLight3D.new()
	luz.light_color = Color("#ffe9a8")
	luz.light_energy = 1.6
	luz.omni_range = 9.0
	luz.position = Vector3(0, 4.0, 0)
	_arvore.add_child(luz)
	for i in PRESENTES.size():
		var a := TAU * i / PRESENTES.size() + 0.3
		var p := chao + Vector3(cos(a), 0, sin(a)) * 3.0
		_modelo(PRESENTES[i], game._ground_point(p), 1.5, randf() * TAU)
	# O presente do dia: o grandão dourado na frente da árvore (para o lado da praça), brilhando.
	var frente := chao + Vector3(0, 0, -4.4)
	presente_do_dia = _modelo("present_A_yellow", game._ground_point(frente), 2.4, 0.4)
	_luz_presente = OmniLight3D.new()
	_luz_presente.light_color = Color("#ffd23f")
	_luz_presente.light_energy = 2.0
	_luz_presente.omni_range = 3.5
	_luz_presente.position.y = 1.0
	presente_do_dia.add_child(_luz_presente)
	_modelo("snowman_A", game._ground_point(chao + Vector3(-6.5, 0, -2.0)), 2.2, 0.6)
	_modelo("snowman_B", game._ground_point(chao + Vector3(6.0, 0, -3.0)), 2.2, -0.5)
	_modelo("gingerbread_house_decorated", game._ground_point(chao + Vector3(9.5, 0, 4.0)), 2.6, -0.9)
	for k in 3:
		_modelo("gingerbread_man", game._ground_point(chao + Vector3(8.0 + k * 0.9, 0, 1.2)), 1.4, PI)
	# O tronco da árvore segura quem esbarra. Fica fora do nó da árvore (a escala de 3,4 esticaria a forma) e entra
	# depois de tudo posto no chão (senão os presentes iam parar em cima dela).
	var corpo := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var cilindro := CylinderShape3D.new()
	cilindro.radius = 1.6
	cilindro.height = 6.0
	forma.shape = cilindro
	forma.position.y = 3.0
	corpo.add_child(forma)
	add_child(corpo)
	corpo.global_position = chao
	_montar_neve()
	_gorros_nos_moradores()
	atualizar_presente()


func _modelo(nome: String, pos: Vector3, escala: float, giro: float) -> Node3D:
	var m: Node3D = load(MODELOS % nome).instantiate()
	m.scale = Vector3.ONE * escala
	m.rotation.y = giro
	add_child(m)
	m.global_position = pos
	return m


## Neve fininha caindo numa caixa de 50 m em volta do aventureiro (o nó segue ele).
func _montar_neve() -> void:
	neve = GPUParticles3D.new()
	neve.amount = 700
	neve.lifetime = 7.0
	neve.preprocess = 7.0
	neve.visibility_aabb = AABB(Vector3(-30, -20, -30), Vector3(60, 40, 60))
	var proc := ParticleProcessMaterial.new()
	proc.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	proc.emission_box_extents = Vector3(25, 1, 25)
	proc.direction = Vector3(0, -1, 0)
	proc.spread = 15.0
	proc.initial_velocity_min = 1.6
	proc.initial_velocity_max = 2.4
	proc.gravity = Vector3(0.3, -0.4, 0.0)
	proc.scale_min = 0.6
	proc.scale_max = 1.2
	neve.process_material = proc
	var floco := QuadMesh.new()
	floco.size = Vector2(0.12, 0.12)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 1, 1, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	floco.material = mat
	neve.draw_pass_1 = floco
	neve.top_level = true
	add_child(neve)


## Quem não tem chapéu ganha o gorro de duende (os moradores e os esqueletos amigos).
func _gorros_nos_moradores() -> void:
	for t in get_tree().get_nodes_in_group(&"moradores"):
		var sk := (t as Node).find_child("Skeleton3D", true, false) as Skeleton3D
		if sk == null or sk.find_bone("head") < 0:
			continue
		var tem_chapeu := false
		for m: MeshInstance3D in sk.find_children("*", "MeshInstance3D", true, false):
			if m.visible and ("Hat" in m.name or "Helmet" in m.name or "Hood" in m.name or "Crown" in m.name):
				tem_chapeu = true
		if tem_chapeu or sk.has_node("GorroDeNatal"):
			continue
		var osso := BoneAttachment3D.new()
		osso.name = "GorroDeNatal"
		osso.bone_name = "head"
		sk.add_child(osso)
		var gorro := Roupas.chapeu("duende")
		if gorro:
			osso.add_child(gorro)
			_gorros += 1


func gorros() -> int:
	return _gorros


# --- o presente do dia e os fogos ----------------------------------------------------

func pode_abrir() -> bool:
	return ativa and is_instance_valid(presente_do_dia) and aberto_em != hoje() and game.menu_state == "" \
			and game.player.global_position.distance_to(presente_do_dia.global_position) < ABRIR + 0.6


func dica(botao: String) -> String:
	if pode_abrir():
		return "Aperte %s para abrir o presente do dia" % botao
	return ""


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interagir") and pode_abrir():
		abrir()
		get_viewport().set_input_as_handled()


func abrir() -> void:
	aberto_em = hoje()
	var n := MOEDAS_ESPECIAL if _dia_especial() else MOEDAS
	var em := presente_do_dia.global_position + Vector3.UP * 1.6
	Fx.confetti(game, em, 50, 4.5)
	Sfx.play(game, "estrelinha", 0.0, 0.0)
	story.add_coins(n, em + Vector3.UP * 1.2)
	game.banner("Feliz fim de ano!", "O presente do dia tinha %d moedas. Amanhã tem outro!" % n, Color("#ff9d9d"), 3.4)
	atualizar_presente()
	story.save()


## Fechado (brilhando e pulando) ou já aberto hoje (sem brilho, mais baixinho).
func atualizar_presente() -> void:
	if not is_instance_valid(presente_do_dia):
		return
	var fechado := aberto_em != hoje()
	_luz_presente.visible = fechado
	presente_do_dia.scale = Vector3.ONE * (2.4 if fechado else 1.6)


func _process(delta: float) -> void:
	if not ativa:
		return
	_t += delta
	if is_instance_valid(neve) and is_instance_valid(game.player):
		neve.global_position = game.player.global_position + Vector3.UP * 16.0
	if is_instance_valid(presente_do_dia) and aberto_em != hoje():
		presente_do_dia.rotation.y += delta * 0.8
	if _dia_de_fogos() and is_instance_valid(_arvore):
		var noite: bool = game.day_night == null or game.day_night.is_night()
		if noite:
			_proximo_fogo -= delta
			if _proximo_fogo <= 0.0:
				_proximo_fogo = randf_range(2.5, 5.0)
				var de := _arvore.global_position + Vector3(randf_range(-14, 14), 0, randf_range(6, 18))
				Fx.firework(game, de, randf_range(14.0, 22.0), Color.from_hsv(randf(), 0.7, 1.0))
				fogos += 1


func dados_salvos() -> Dictionary:
	return {"presente": aberto_em}


func carregar(dados: Dictionary) -> void:
	aberto_em = String(dados.get("presente", ""))
	atualizar_presente()
