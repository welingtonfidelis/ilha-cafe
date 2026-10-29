class_name Robo
extends Node3D
## Faísca: robozinho minimalista montado por código no esqueleto Rig_Medium do KayKit (o mesmo
## dos Protagonists). Cada peça fica presa a um osso, então as animações do KayKit servem nele.
## Capacete branco quadrado e arredondado com tela preta e olhos de LED, orelhas laranja,
## tronco em forma de ovo laranja com a barriga branca, braços e pernas finos e brancos com
## juntas cinza, garrinhas de três pontas e botas brancas de sola laranja. As medidas abaixo
## estão no espaço do esqueleto em T-pose, olhando para +Z, com o chão em y = 0.

const RIG := "res://assets/characters/protagonists/Protagonist_B.glb"

## Mão relaxada: um pouquinho dobrada. Golpes e comemoração fecham o punho (1.0).
const PUNHO_SOLTO := 0.1
## Garrinhas: quanto as pontas abrem com a mão solta e quanto passam do reto ao fechar (graus).
const PINCA_ABERTA := 22.0
const PINCA_FECHADA := 16.0

var esqueleto: Skeleton3D
var mat := {}
var _rig: Node3D
var _anexos := {}
var _ap: AnimationPlayer
var _jatos: Array[MeshInstance3D] = []
## Pontas das garrinhas: [nó que gira, +1 nas de cima, -1 na de baixo].
var _pincas := []
var _punho := PUNHO_SOLTO


func _ready() -> void:
	_rig = load(RIG).instantiate()
	add_child(_rig)
	esqueleto = _rig.find_children("*", "Skeleton3D", true, false)[0]
	for m in _rig.find_children("*", "MeshInstance3D", true, false):
		m.queue_free()
	_criar_materiais()
	_montar()


## Raiz do .glb do esqueleto, onde as animações ligam (o Player vestido de Faísca usa a árvore de animação dele).
func rig() -> Node3D:
	return _rig


## Sentado no kart só aparece da cintura para cima: as pernas e as botas somem.
func esconder_pernas() -> void:
	for chave: String in _anexos:
		if chave.contains("leg") or chave.contains("foot"):
			(_anexos[chave] as Node3D).visible = false


## Volta para a pose de descanso do esqueleto, que é a T-pose.
func tpose() -> void:
	if _ap:
		_ap.stop()
	esqueleto.reset_bone_poses()


## Congela o esqueleto num instante de uma animação ("biblioteca/nome", ver AnimUtil.SETS).
func posar(anim: String, tempo: float) -> void:
	_player().play(anim)
	_ap.seek(tempo, true)
	_ap.pause()


## Toca uma animação, misturando com a anterior. Repetir o pedido a cada quadro não recomeça.
func animar(anim: String, mistura := 0.15, ritmo := 1.0) -> void:
	var ap := _player()
	ap.speed_scale = ritmo
	if ap.current_animation != anim or not ap.is_playing():
		ap.play(anim, mistura)


## Recomeça a animação do instante `inicio`, mesmo que já esteja tocando (golpes em sequência).
func animar_desde(anim: String, inicio: float, mistura := 0.05, ritmo := 1.0) -> void:
	var ap := _player()
	ap.speed_scale = ritmo
	ap.play(anim, mistura)
	ap.seek(inicio, true)


## Ponto debaixo de cada tênis (0 = esquerdo, 1 = direito), de onde sai o laser.
func ponta_do_pe(i: int) -> Vector3:
	return _jatos[i].global_position


func animacao_atual() -> String:
	return _ap.current_animation if _ap else ""


## Jatos de luz debaixo dos tênis. Desde 2026-10-29 o voo mostra só o laser (pedido do usuário) e o
## Jogador não liga mais; os nós continuam marcando a ponta de cada pé, de onde o laser sai.
func jatos(ligados: bool) -> void:
	for j in _jatos:
		j.visible = ligados


func _process(delta: float) -> void:
	# A animação anda aqui (modo manual) para a cópia da pose sair sempre no mesmo quadro.
	if _ap:
		_ap.advance(delta)
	# assigned_animation vale também com a animação pausada (fotos do estúdio).
	var anim: String = _ap.assigned_animation if _ap else ""
	# O soco do KayKit dá um passo de uns 40 cm com o quadril e volta; o Faísca golpeia no lugar.
	if anim.begins_with("luta/"):
		var quadril := esqueleto.find_bone("hips")
		var pos := esqueleto.get_bone_pose_position(quadril)
		var descanso := esqueleto.get_bone_rest(quadril).origin
		esqueleto.set_bone_pose_position(quadril, Vector3(descanso.x, pos.y, descanso.z))
	# Mão fechada nos golpes e na comemoração.
	var fechado: bool = anim.begins_with("luta/") or anim == "festa/Cheering"
	_punho = move_toward(_punho, 1.0 if fechado else PUNHO_SOLTO, delta * 10.0)
	for p in _pincas:
		p[0].rotation.z = p[1] * deg_to_rad(lerpf(PINCA_ABERTA, -PINCA_FECHADA, _punho))
	if _jatos.size() > 0 and _jatos[0].visible:
		mat.jato.emission_energy_multiplier = 3.0 + randf() * 1.5
		for j in _jatos:
			j.scale = Vector3(1.0, 0.85 + randf() * 0.3, 1.0)


func _player() -> AnimationPlayer:
	if _ap == null:
		_ap = AnimUtil.make_player(_rig, ["geral", "mov", "festa", "luta", "ferramentas"])
		_ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	return _ap


## Garrinha de três pontas: duas em cima (frente e trás) e uma embaixo, curvadas umas para as
## outras, brancas com a ponta laranja. `boca` é onde as pontas nascem, `d` para onde a mão
## aponta na T-pose e `tamanho` o raio da mão. Cada ponta gira numa dobradiça presa ao osso, e
## `_punho` abre e fecha (ver _process).
func _garra(osso: String, sk: Skeleton3D, boca: Vector3, d: Vector3, tamanho: float) -> void:
	var eixos := Basis(d, Vector3.UP, d.cross(Vector3.UP))
	var comprimento := tamanho * 1.7
	var branco := Forma.garra(comprimento, tamanho * 0.4, tamanho * 0.3, 0.85, 0.0, 0.62)
	var ponta := Forma.garra(comprimento, tamanho * 0.4, tamanho * 0.3, 0.85, 0.6, 1.0)
	for p in [[Vector3(0, 0.42, 0.38), 1.0], [Vector3(0, 0.42, -0.38), 1.0], [Vector3(0, -0.45, 0), -1.0]]:
		var dobradica := _no_preso(osso, Transform3D(eixos, boca + eixos * (p[0] * tamanho)), sk)
		var giro := Node3D.new()
		dobradica.add_child(giro)
		_pincas.append([giro, p[1]])
		# A de baixo é a mesma ponta virada de cabeça para baixo, curvando para cima.
		var rot := Vector3(PI, 0, 0) if p[1] < 0.0 else Vector3.ZERO
		_filho(giro, branco, mat.branco, Vector3.ZERO, rot)
		_filho(giro, ponta, mat.laranja, Vector3.ZERO, rot)


func _criar_materiais() -> void:
	mat.branco = _plastico(Color("f4f5f9"), 0.32, 0.7)
	mat.visor = _plastico(Color("0c0e16"), 0.08, 1.0)
	mat.visor.metallic = 0.25
	mat.cinza = _plastico(Color("3e4352"), 0.35, 0.4)
	mat.cinza.metallic = 0.3
	mat.laranja = _plastico(Color("ff7a22"), 0.45, 0.5)
	mat.olho = _led(Color("8ff3ff"), 2.2)
	mat.jato = _led(Color("8ff3ff"), 3.5)
	mat.jato.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.jato.albedo_color.a = 0.75


func _montar() -> void:
	# ----- cabeça: capacete branco quadrado e arredondado, tela preta, olhos e orelhas -----
	_peca("head", Forma.superelipsoide(Vector3(0.56, 0.47, 0.5), 0.72, 0.72), mat.branco, Vector3(0, 1.72, 0))
	_peca("head", Forma.superelipsoide(Vector3(0.44, 0.29, 0.24), 0.6, 0.6), mat.visor, Vector3(0, 1.68, 0.3))
	for lado in [-1.0, 1.0]:
		_peca("head", _capsula(0.058, 0.21), mat.olho, Vector3(0.14 * lado, 1.69, 0.535), Vector3.ZERO, Vector3(1, 1, 0.35))
		_peca("head", _cilindro(0.14, 0.14, 0.1), mat.laranja, Vector3(0.555 * lado, 1.7, 0), Vector3(0, 0, PI / 2))
		_peca("head", _cilindro(0.07, 0.07, 0.04), mat.branco, Vector3(0.61 * lado, 1.7, 0), Vector3(0, 0, PI / 2))

	# ----- tronco: ovo laranja com a barriga branca; pescoço e quadril de junta cinza -----
	_peca("chest", _cilindro(0.1, 0.1, 0.14), mat.cinza, Vector3(0, 1.22, 0))
	_peca("chest", Forma.ovo(Vector3(0.29, 0.31, 0.24), 0.12), mat.laranja, Vector3(0, 0.88, 0))
	_peca("chest", Forma.superelipsoide(Vector3(0.17, 0.19, 0.08)), mat.branco, Vector3(0, 0.83, 0.17))
	_peca("hips", _esfera(0.11), mat.cinza, Vector3(0, 0.63, 0))

	for lado in [-1.0, 1.0]:
		var s := ".l" if lado > 0 else ".r"
		# ----- braços finos: ombro, cotovelo e pulso cinza, punho branco e a garrinha -----
		# O osso "wrist" não gira nas animações; quem gira é o "hand", em torno de x = 0,787.
		# Por isso o antebraço vai até lá e a junta cinza fica bem no centro do giro: o punho
		# gira em volta dela sem descolar do braço.
		_peca("upperarm" + s, _esfera(0.075), mat.cinza, Vector3(0.235 * lado, 1.107, 0))
		_peca("upperarm" + s, _capsula(0.062, 0.25), mat.branco, Vector3(0.345 * lado, 1.107, 0), Vector3(0, 0, PI / 2))
		_peca("lowerarm" + s, _esfera(0.062), mat.cinza, Vector3(0.454 * lado, 1.107, 0))
		_peca("lowerarm" + s, _capsula(0.066, 0.26), mat.branco, Vector3(0.6 * lado, 1.107, 0), Vector3(0, 0, PI / 2))
		_peca("lowerarm" + s, _cilindro(0.07, 0.07, 0.04), mat.cinza, Vector3(0.735 * lado, 1.107, 0), Vector3(0, 0, PI / 2))
		_peca("hand" + s, _esfera(0.06), mat.cinza, Vector3(0.787 * lado, 1.107, 0))
		_peca("hand" + s, Forma.superelipsoide(Vector3(0.075, 0.092, 0.092), 0.7, 0.7), mat.branco, Vector3(0.86 * lado, 1.107, 0))
		_garra("hand" + s, esqueleto, Vector3(0.905 * lado, 1.107, 0), Vector3(lado, 0, 0), 0.1)
		# ----- pernas finas e botas brancas de sola laranja -----
		_peca("upperleg" + s, _esfera(0.07), mat.cinza, Vector3(0.171 * lado, 0.52, 0))
		_peca("upperleg" + s, _capsula(0.066, 0.24), mat.branco, Vector3(0.171 * lado, 0.405, 0))
		_peca("lowerleg" + s, _esfera(0.064), mat.cinza, Vector3(0.171 * lado, 0.292, 0.005))
		_peca("lowerleg" + s, _capsula(0.068, 0.2), mat.branco, Vector3(0.171 * lado, 0.2, 0))
		_peca("foot" + s, Forma.superelipsoide(Vector3(0.13, 0.1, 0.2), 0.65, 0.7), mat.branco, Vector3(0.171 * lado, 0.13, 0.04))
		_peca("foot" + s, Forma.superelipsoide(Vector3(0.138, 0.034, 0.208), 0.6, 0.6), mat.laranja, Vector3(0.171 * lado, 0.034, 0.04))
		var jato := _peca("foot" + s, _cilindro(0.11, 0.0, 0.4), mat.jato, Vector3(0.171 * lado, -0.2, 0.04))
		jato.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		jato.visible = false
		_jatos.append(jato)


## Cria a peça já na posição da T-pose (espaço do Robo) e a prende no osso de `sk`
## (o esqueleto do KayKit, se não disser outro).
func _peca(osso: String, malha: Mesh, material: Material, pos: Vector3, rot := Vector3.ZERO, escala := Vector3.ONE, sk: Skeleton3D = null) -> MeshInstance3D:
	if sk == null:
		sk = esqueleto
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = material
	var desejado := Transform3D(Basis.from_euler(rot) * Basis.from_scale(escala), pos)
	var descanso := global_transform.affine_inverse() * sk.global_transform * sk.get_bone_global_rest(sk.find_bone(osso))
	mi.transform = descanso.affine_inverse() * desejado
	_anexo(osso, sk).add_child(mi)
	return mi


## Nó vazio preso a um osso, na posição e no giro pedidos (espaço do Robo, T-pose).
func _no_preso(osso: String, desejado: Transform3D, sk: Skeleton3D) -> Node3D:
	var no := Node3D.new()
	var descanso := global_transform.affine_inverse() * sk.global_transform * sk.get_bone_global_rest(sk.find_bone(osso))
	no.transform = descanso.affine_inverse() * desejado
	_anexo(osso, sk).add_child(no)
	return no


## Peça presa a outra (posição e giro no espaço da peça mãe).
func _filho(pai: Node3D, malha: Mesh, material: Material, pos: Vector3, rot := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = material
	mi.transform = Transform3D(Basis.from_euler(rot), pos)
	pai.add_child(mi)
	return mi


func _anexo(osso: String, sk: Skeleton3D) -> BoneAttachment3D:
	var chave := "%d/%s" % [sk.get_instance_id(), osso]
	if not _anexos.has(chave):
		var a := BoneAttachment3D.new()
		a.name = "Anexo_" + osso
		a.bone_name = osso
		sk.add_child(a)
		_anexos[chave] = a
	return _anexos[chave]


func _plastico(cor: Color, rugosidade: float, verniz := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.roughness = rugosidade
	if verniz > 0.0:
		m.clearcoat_enabled = true
		m.clearcoat = verniz
		m.clearcoat_roughness = 0.15
	return m


func _led(cor: Color, forca: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = cor
	m.emission_enabled = true
	m.emission = cor
	m.emission_energy_multiplier = forca
	return m


func _capsula(raio: float, altura: float) -> CapsuleMesh:
	var c := CapsuleMesh.new()
	c.radius = raio
	c.height = altura
	c.radial_segments = 32
	c.rings = 12
	return c


func _cilindro(raio_cima: float, raio_baixo: float, altura: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = raio_cima
	c.bottom_radius = raio_baixo
	c.height = altura
	c.radial_segments = 32
	return c


func _esfera(raio: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0
	s.radial_segments = 32
	s.rings = 16
	return s
