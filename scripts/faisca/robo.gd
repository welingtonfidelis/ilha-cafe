class_name Robo
extends Node3D
## Faísca: robozinho montado por código no esqueleto Rig_Medium do KayKit (o mesmo dos
## Protagonists). Cada peça fica presa a um osso, então as animações do KayKit servem nele.
## Capacete branco quadrado e arredondado com a tela de vidro e olhos de LED, friso e orelhas
## laranja. Desde 2026-10-29 o corpo segue o jeito do Astro Bot (pedido do usuário), com as cores e
## os detalhes do Faísca: tronco em feijão branco com placa laranja e estrela no peito, braços e
## coxas gordinhos e redondos, antebraço com anel prateado e faixa laranja, mão de luva e pernas que
## afinam até uma ponta laranja, sem bota. As medidas abaixo estão no espaço do esqueleto em T-pose,
## olhando para +Z, com o chão em y = 0.
## A tela usa o shader `rosto_led.gdshader` (pedido do usuário: "viseira brilhante com olhos de LED
## que mudam de expressão"): o Faísca pisca, dá olhadinhas parado e muda de cara (ver `expressao`).

const RIG := "res://assets/characters/protagonists/Protagonist_B.glb"

## Mão relaxada: um pouquinho dobrada. Golpes e comemoração fecham o punho (1.0).
const PUNHO_SOLTO := 0.1
## Dedos da luva: quanto dobram com a mão solta e com o punho fechado (graus).
const DEDO_SOLTO := 12.0
const DEDO_FECHADO := 105.0
const POLEGAR_FECHADO := 70.0
## Tronco: a Forma.ovo branca (raios, afina e altura do meio). As placas do peito e das costas seguem a curva dele.
const TRONCO := Vector3(0.31, 0.34, 0.27)
const TRONCO_AFINA := -0.13
const TRONCO_Y := 0.86
## Caras da tela (o número é a `forma` do shader). "piscando" é a normal de olhos fechados.
const EXPRESSOES := {"normal": 0, "piscando": 0, "feliz": 1, "surpreso": 2, "bravo": 3, "dor": 4, "tonto": 5, "coracao": 6}
const COR_LED := Color("8ff3ff")
const COR_CORACAO := Color("ff7eb6")
## Duração de uma piscada (fecha e abre). A troca de cara acontece no meio, de olho fechado.
const PISCADA := 0.16

var esqueleto: Skeleton3D
var mat := {}
var _rig: Node3D
var _anexos := {}
var _ap: AnimationPlayer
var _jatos: Array[MeshInstance3D] = []
## Dedos da luva: [nó que gira, eixo (espaço da T-pose), ângulo solto, ângulo fechado].
var _dedos := []
var _punho := PUNHO_SOLTO
## LEDs das costas (o voo que resta).
var _carga: Array[MeshInstance3D] = []
## Para onde os olhos olham na tela (metros); quem controla o Faísca pode mandar (o laser olha para baixo).
var olhando := Vector2.ZERO
## Sem piscadas e olhadinhas sozinhas (fotos do estúdio).
var rosto_parado := false
var _expr := "normal"
var _expr_pedida := "normal"
var _expr_resta := 0.0
var _piscada := -1.0
var _prox_piscada := 2.0
var _olhar := Vector2.ZERO
var _olhar_alvo := Vector2.ZERO
var _prox_olhada := 2.5
var _feliz_da_festa := false
## Dancinha (Jogador.dancando): peso da dança por cima da animação de parado e o tempo dela.
var _dancando := false
var _danca := 0.0
var _danca_t := 0.0


func _ready() -> void:
	_rig = load(RIG).instantiate()
	add_child(_rig)
	esqueleto = _rig.find_children("*", "Skeleton3D", true, false)[0]
	for m in _rig.find_children("*", "MeshInstance3D", true, false):
		m.queue_free()
	_criar_materiais()
	_montar()
	_aplicar_expressao("normal")


## Raiz do .glb do esqueleto, onde as animações ligam (o Player vestido de Faísca usa a árvore de animação dele).
func rig() -> Node3D:
	return _rig


## Sentado no kart só aparece da cintura para cima: as pernas e as pontas dos pés somem.
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
## As de festa (comemorar, acenar) deixam a cara feliz enquanto duram.
func animar(anim: String, mistura := 0.15, ritmo := 1.0) -> void:
	var ap := _player()
	ap.speed_scale = ritmo
	var festa := anim.begins_with("festa/")
	if festa != _feliz_da_festa:
		_feliz_da_festa = festa
		expressao("feliz" if festa else "normal")
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


## Liga e desliga a dancinha (a animação por baixo continua; a dança entra e sai misturando).
func dancar(on: bool) -> void:
	if on and not _dancando:
		_danca_t = 0.0
	_dancando = on


## Quanto voo ainda resta (0 a 1): os três LEDs das costas apagam um a um enquanto ele flutua.
func carga(v: float) -> void:
	for i in _carga.size():
		_carga[i].material_override = mat.led_costas if v > i / 3.0 + 0.001 else mat.led_apagado


## Muda a cara da tela (ver EXPRESSOES). Com `duracao`, volta para a normal depois desse tempo.
## A troca vem com uma piscada; `ja` troca na hora, sem piscar.
func expressao(nome: String, duracao := 0.0, ja := false) -> void:
	_expr_resta = duracao
	if ja:
		_expr_pedida = nome
		_piscada = -1.0
		_aplicar_expressao(nome)
		return
	if nome == _expr_pedida:
		return
	_expr_pedida = nome
	if _piscada < 0.0:
		_piscada = 0.0


func expressao_atual() -> String:
	return _expr_pedida


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
	for d in _dedos:
		d[0].basis = Basis(d[1], lerpf(d[2], d[3], _punho))
	_danca = move_toward(_danca, 1.0 if _dancando else 0.0, delta * 6.0)
	if _danca > 0.0:
		_danca_t += delta
		_pose_de_danca(_danca_t, _danca)
	_rosto(delta)
	if _jatos.size() > 0 and _jatos[0].visible:
		mat.jato.emission_energy_multiplier = 3.0 + randf() * 1.5
		for j in _jatos:
			j.scale = Vector3(1.0, 0.85 + randf() * 0.3, 1.0)


## Dancinha de robô no ritmo de 120 batidas por minuto: em cada batida o quadril desce dobrando os joelhos, o
## corpo balança de um lado para o outro e os braços trocam (um para cima, o outro para baixo com o antebraço para
## a frente). Cada osso recebe um giro no espaço do robô (a partir da T-pose); daí sai o giro local, misturado com
## a animação por `peso`.
func _pose_de_danca(t: float, peso: float) -> void:
	var batida := t / 0.5
	var lado := sin(PI * batida)
	# Os braços trocam rápido e seguram a pose (jeito de robô).
	var troca := 0.5 + 0.5 * signf(lado) * pow(absf(lado), 0.35)
	var desce := 0.5 + 0.5 * cos(TAU * batida)
	var giros := {}
	giros["hips"] = Basis(Vector3.UP, 0.2 * lado)
	giros["spine"] = giros["hips"]
	giros["chest"] = giros["hips"] * Basis(Vector3.BACK, 0.12 * lado)
	giros["head"] = giros["chest"] * Basis(Vector3.BACK, -0.2 * lado) * Basis(Vector3.RIGHT, 0.12 * desce)
	# O braço de cima vai aberto e um pouco para a frente: reto para cima, o cabeção escondia a mão.
	var cima_braco := Vector3(0.85, 0.45, 0.28)
	var cima_mao := Vector3(0.5, 0.82, 0.3)
	var baixo_braco := Vector3(0.45, -0.85, 0.25)
	var baixo_mao := Vector3(0.2, -0.15, 0.97)
	for l in [1.0, -1.0]:
		var s := ".l" if l > 0.0 else ".r"
		var m := Vector3(l, 1, 1)
		var k := troca if l > 0.0 else 1.0 - troca
		var braco := (baixo_braco * m).lerp(cima_braco * m, k).normalized()
		var mao := (baixo_mao * m).lerp(cima_mao * m, k).normalized()
		giros["upperarm" + s] = Basis(Quaternion(Vector3(l, 0, 0), braco))
		giros["lowerarm" + s] = Basis(Quaternion(Vector3(l, 0, 0), mao))
		giros["wrist" + s] = giros["lowerarm" + s]
		giros["hand" + s] = giros["lowerarm" + s]
		# Joelhos dobram para o quadril descer uns 4 cm com os pés no chão.
		giros["upperleg" + s] = Basis(Vector3.RIGHT, -0.45 * desce)
		giros["lowerleg" + s] = Basis(Vector3.RIGHT, 0.45 * desce)
		giros["foot" + s] = Basis.IDENTITY
	var globais := {}
	for nome: String in ["hips", "spine", "chest", "head", "upperarm.l", "lowerarm.l", "wrist.l", "hand.l", "upperarm.r",
			"lowerarm.r", "wrist.r", "hand.r", "upperleg.l", "lowerleg.l", "foot.l", "upperleg.r", "lowerleg.r", "foot.r"]:
		var i := esqueleto.find_bone(nome)
		var pai := esqueleto.get_bone_parent(i)
		var desejado: Basis = giros[nome] * esqueleto.get_bone_global_rest(i).basis.orthonormalized()
		globais[i] = desejado
		var base_pai: Basis = globais[pai] if globais.has(pai) else esqueleto.get_bone_global_rest(pai).basis.orthonormalized()
		var local := (base_pai.inverse() * desejado).get_rotation_quaternion()
		esqueleto.set_bone_pose_rotation(i, esqueleto.get_bone_pose_rotation(i).slerp(local, peso))
	var quadril := esqueleto.find_bone("hips")
	esqueleto.set_bone_pose_position(quadril, esqueleto.get_bone_pose_position(quadril) + Vector3.DOWN * 0.045 * desce * peso)


## Piscadas, a volta para a cara normal e as olhadinhas para os lados quando está parado.
func _rosto(delta: float) -> void:
	if _expr_resta > 0.0:
		_expr_resta -= delta
		if _expr_resta <= 0.0:
			expressao("feliz" if _feliz_da_festa else "normal")
	var abertura := 1.0
	if _piscada >= 0.0:
		_piscada += delta
		var t := _piscada / PISCADA
		if t >= 0.5 and _expr != _expr_pedida:
			_aplicar_expressao(_expr_pedida)
		abertura = absf(1.0 - 2.0 * minf(t, 1.0))
		if t >= 1.0:
			_piscada = -1.0
	elif not rosto_parado and _expr in ["normal", "bravo", "surpreso"]:
		_prox_piscada -= delta
		if _prox_piscada <= 0.0:
			_piscada = 0.0
			_prox_piscada = randf_range(2.0, 5.0)
	if _expr == "piscando":
		abertura = 0.0
	if olhando != Vector2.ZERO:
		_olhar_alvo = olhando
	elif rosto_parado or _expr != "normal" or not animacao_atual().begins_with("geral/Idle"):
		_olhar_alvo = Vector2.ZERO
	else:
		_prox_olhada -= delta
		if _prox_olhada <= 0.0:
			_prox_olhada = randf_range(1.2, 3.5)
			_olhar_alvo = Vector2.ZERO if randf() < 0.4 else Vector2(randf_range(-0.04, 0.04), randf_range(-0.015, 0.02))
	# Olho mexe rápido, como olhadinha de verdade.
	_olhar = _olhar.lerp(_olhar_alvo, 1.0 - exp(-18.0 * delta))
	mat.rosto.set_shader_parameter("abertura", maxf(abertura, 0.06))
	mat.rosto.set_shader_parameter("olhar", _olhar)
	mat.led_orelha.emission_energy_multiplier = 1.4 + 0.7 * sin(Time.get_ticks_msec() * 0.003)


func _aplicar_expressao(nome: String) -> void:
	_expr = nome
	mat.rosto.set_shader_parameter("forma", EXPRESSOES.get(nome, 0))
	var cor := COR_CORACAO if nome == "coracao" else COR_LED
	mat.rosto.set_shader_parameter("cor_led", cor)
	for m: StandardMaterial3D in [mat.led_orelha, mat.led_costas]:
		m.albedo_color = cor
		m.emission = cor
	if nome == "piscando":
		mat.rosto.set_shader_parameter("abertura", 0.06)


func _player() -> AnimationPlayer:
	if _ap == null:
		# O soco do KayKit é do braço direito; o esquerdo é ele espelhado (os golpes alternam os dois).
		AnimUtil.add_mirrored("luta", "Melee_Unarmed_Attack_Punch_A", "Soco_Esquerdo", esqueleto)
		_ap = AnimUtil.make_player(_rig, ["geral", "mov", "festa", "luta", "ferramentas"])
		_ap.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	return _ap


## Ponto do tronco na altura `y`, no meio (x = 0), na frente (`frente` = 1) ou nas costas (-1), com a
## normal da superfície ali e o giro em X que deita uma placa como ela. O tronco é a Forma.ovo de
## TRONCO: na altura y, o raio para a frente é TRONCO.z (1 + afina sen) cos.
func _no_tronco(y: float, frente: float) -> Array:
	var fundo := func(yy: float) -> float:
		var sn := clampf((yy - TRONCO_Y) / TRONCO.y, -1.0, 1.0)
		return TRONCO.z * (1.0 + TRONCO_AFINA * sn) * sqrt(1.0 - sn * sn)
	var inclinacao: float = (fundo.call(y + 0.01) - fundo.call(y - 0.01)) / 0.02
	var normal := Vector3(0, -inclinacao, frente).normalized()
	return [Vector3(0, y, fundo.call(y) * frente), normal, atan2(-normal.y * frente, normal.z * frente)]


## Placa laranja deitada no tronco (ver _no_tronco), saindo 2 cm para fora no meio.
func _placa(no: Array, raios: Vector3) -> void:
	_peca("chest", Forma.superelipsoide(raios, 0.8, 0.8), mat.laranja, no[0] + no[1] * (0.02 - raios.z), Vector3(no[2], 0, 0))


## Mão de luva: palma redonda, três dedos gordinhos e o polegar na frente. Cada dedo gira numa dobradiça
## presa ao osso da mão; `_punho` dobra os dedos para baixo da palma (as palmas ficam para baixo na
## T-pose) e o polegar por baixo (ver _process).
func _mao(osso: String, lado: float) -> void:
	_peca(osso, Forma.superelipsoide(Vector3(0.07, 0.062, 0.088), 0.75, 0.75), mat.branco, Vector3(0.845 * lado, 1.107, 0))
	for z in [-0.052, 0.0, 0.052]:
		var dobradica := _no_preso(osso, Transform3D(Basis.IDENTITY, Vector3(0.895 * lado, 1.1, z)), esqueleto)
		var giro := Node3D.new()
		dobradica.add_child(giro)
		_dedos.append([giro, Vector3(0, 0, -lado), deg_to_rad(DEDO_SOLTO), deg_to_rad(DEDO_FECHADO)])
		_filho(giro, _capsula(0.03, 0.115 if z == 0.0 else 0.1), mat.branco, Vector3(0.035 * lado, 0, 0), Vector3(0, 0, PI / 2))
	var base := _no_preso(osso, Transform3D(Basis.IDENTITY, Vector3(0.83 * lado, 1.095, 0.07)), esqueleto)
	var polegar := Node3D.new()
	base.add_child(polegar)
	_dedos.append([polegar, Vector3(1, 0, 0), deg_to_rad(DEDO_SOLTO), deg_to_rad(POLEGAR_FECHADO)])
	# Aponta para a frente e um pouco para o lado dos dedos.
	_filho(polegar, _capsula(0.032, 0.1), mat.branco, Vector3(0.019 * lado, 0, 0.035), Vector3(PI / 2, 0.5 * lado, 0))


func _criar_materiais() -> void:
	mat.branco = _plastico(Color("f4f5f9"), 0.32, 0.7)
	mat.cinza = _plastico(Color("3e4352"), 0.35, 0.4)
	mat.cinza.metallic = 0.3
	mat.laranja = _plastico(Color("ff7a22"), 0.45, 0.5)
	# Prata meio metálica: bem metálico, sem céu para refletir (estúdio, sala escura), fica preto.
	mat.cromo = _plastico(Color("dfe3ec"), 0.24, 0.8)
	mat.cromo.metallic = 0.55
	mat.rosto = ShaderMaterial.new()
	mat.rosto.shader = preload("res://scripts/faisca/rosto_led.gdshader")
	mat.led_orelha = _led(COR_LED, 1.6)
	mat.led_costas = _led(COR_LED, 1.8)
	mat.led_apagado = _plastico(Color("2a3140"), 0.3, 0.6)
	mat.estrela = _plastico(Color("ffc93a"), 0.3, 0.8)
	mat.estrela.emission_enabled = true
	mat.estrela.emission = Color("ffb21a")
	mat.estrela.emission_energy_multiplier = 0.55
	# A Forma.estrela tem as faces viradas para dentro; sem isso, na barriga só aparece o contorno.
	mat.estrela.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.jato = _led(Color("8ff3ff"), 3.5)
	mat.jato.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.jato.albedo_color.a = 0.75


func _montar() -> void:
	# ----- cabeça: capacete branco quadrado e arredondado, tela preta, olhos e orelhas -----
	_peca("head", Forma.superelipsoide(Vector3(0.56, 0.47, 0.5), 0.72, 0.72), mat.branco, Vector3(0, 1.72, 0))
	# A tela desenha os olhos (rosto_led.gdshader); a moldura laranja aparece só como um friso em volta.
	_peca("head", Forma.superelipsoide(Vector3(0.44, 0.29, 0.24), 0.6, 0.6, -PI / 2.0, 40, 96), mat.rosto, Vector3(0, 1.68, 0.3))
	_peca("head", Forma.tubo_fechado(_borda_da_tela(), 0.02), mat.laranja, Vector3.ZERO)
	for lado in [-1.0, 1.0]:
		# Orelhas: disco laranja de quina redonda, tampa branca e um LED que respira no meio.
		_peca("head", _disco(0.14, 0.11), mat.laranja, Vector3(0.555 * lado, 1.7, 0), Vector3(0, 0, PI / 2))
		_peca("head", _disco(0.08, 0.05), mat.branco, Vector3(0.615 * lado, 1.7, 0), Vector3(0, 0, PI / 2))
		_peca("head", _disco(0.032, 0.03), mat.led_orelha, Vector3(0.638 * lado, 1.7, 0), Vector3(0, 0, PI / 2))
	# Grade de ventilação atrás do capacete (a câmera fica atrás dele quase o tempo todo).
	for i in 3:
		_peca("head", _capsula(0.02, 0.2), mat.cinza, Vector3(0, 1.62 + i * 0.065, -0.494), Vector3(0, 0, PI / 2))

	# ----- tronco: feijão branco mais largo embaixo, placa laranja com a estrela na frente e a das
	# luzes de voo atrás; pescoço cromado. O quadril branco tapa a emenda quando o tronco dobra. -----
	_peca("chest", _disco(0.09, 0.09), mat.cromo, Vector3(0, 1.215, 0))
	_peca("chest", Forma.ovo(TRONCO, TRONCO_AFINA), mat.branco, Vector3(0, TRONCO_Y, 0))
	_peca("hips", Forma.superelipsoide(Vector3(0.25, 0.14, 0.21)), mat.branco, Vector3(0, 0.6, 0))
	# As placas deitam como a superfície do tronco na altura delas: ele é mais largo embaixo, então
	# a frente vai para trás conforme sobe, e uma placa reta afundava na parte de baixo.
	var peito := _no_tronco(0.975, 1.0)
	_placa(peito, Vector3(0.18, 0.14, 0.1))
	# A marca dele: uma estrelinha dourada acesa no peito (é o acendedor de estrelas).
	_peca("chest", Forma.estrela(0.08, 0.036, 0.04), mat.estrela, peito[0] + peito[1] * 0.014, Vector3(peito[2], 0, 0))
	# Costas: placa laranja com três LEDs que mostram quanto voo ainda resta (ver `carga`).
	var costas := _no_tronco(0.95, -1.0)
	_placa(costas, Vector3(0.15, 0.14, 0.1))
	for i in 3:
		var led: Vector3 = costas[0] + costas[1] * 0.017 + Vector3((i - 1) * 0.06, 0, 0)
		_carga.append(_peca("chest", _disco(0.024, 0.02), mat.led_costas, led, Vector3(costas[2] + PI / 2, 0, 0)))

	for lado in [-1.0, 1.0]:
		var s := ".l" if lado > 0 else ".r"
		# ----- braços gordinhos: ombro redondo, antebraço com anel cromado e faixa laranja, mão de luva -----
		# O osso "wrist" não gira nas animações; quem gira é o "hand", em torno de x = 0,787. A faixa
		# laranja vai até perto dali e a bola branca da mão fica no centro do giro.
		_peca("upperarm" + s, _esfera(0.088), mat.branco, Vector3(0.22 * lado, 1.107, 0))
		_peca("upperarm" + s, Forma.superelipsoide(Vector3(0.14, 0.085, 0.085)), mat.branco, Vector3(0.33 * lado, 1.107, 0))
		_peca("lowerarm" + s, _esfera(0.074), mat.branco, Vector3(0.454 * lado, 1.107, 0))
		_peca("lowerarm" + s, Forma.superelipsoide(Vector3(0.13, 0.078, 0.078)), mat.branco, Vector3(0.575 * lado, 1.107, 0))
		_peca("lowerarm" + s, _disco(0.086, 0.035), mat.cromo, Vector3(0.635 * lado, 1.107, 0), Vector3(0, 0, PI / 2))
		_peca("lowerarm" + s, _disco(0.102, 0.085), mat.laranja, Vector3(0.7 * lado, 1.107, 0), Vector3(0, 0, PI / 2))
		_peca("hand" + s, _esfera(0.06), mat.branco, Vector3(0.787 * lado, 1.107, 0))
		_mao("hand" + s, lado)
		# ----- pernas: coxa redonda, canela que afina com faixa laranja e anel cromado, e a ponta
		# laranja de onde sai o laser (sem bota). -----
		_peca("upperleg" + s, _disco(0.07, 0.03), mat.cromo, Vector3(0.285 * lado, 0.47, 0), Vector3(0, 0, PI / 2))
		_peca("upperleg" + s, Forma.ovo(Vector3(0.124, 0.155, 0.124), 0.12), mat.branco, Vector3(0.171 * lado, 0.41, 0))
		_peca("lowerleg" + s, _esfera(0.085), mat.branco, Vector3(0.171 * lado, 0.292, 0.004))
		_peca("lowerleg" + s, Forma.ovo(Vector3(0.094, 0.12, 0.094), 0.1), mat.branco, Vector3(0.171 * lado, 0.24, 0))
		_peca("lowerleg" + s, _disco(0.084, 0.055), mat.laranja, Vector3(0.171 * lado, 0.165, -0.005))
		_peca("foot" + s, _disco(0.074, 0.04), mat.cromo, Vector3(0.171 * lado, 0.122, -0.005))
		_peca("foot" + s, Forma.ovo(Vector3(0.072, 0.07, 0.08), 0.22), mat.laranja, Vector3(0.171 * lado, 0.07, 0.008))
		_peca("foot" + s, _disco(0.04, 0.012), mat.led_orelha, Vector3(0.171 * lado, 0.006, 0.008))
		var jato := _peca("foot" + s, _cilindro(0.11, 0.0, 0.4), mat.jato, Vector3(0.171 * lado, -0.2, 0.008))
		jato.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		jato.visible = false
		_jatos.append(jato)


## Emenda entre a tela e o capacete (onde a tela some dentro dele), para o friso laranja. As duas peças
## são superelipsoides de expoentes iguais, então cada uma é |x/a|^n + |y/b|^n + |z/c|^n = 1. Para cada
## direção na tela, anda do meio para fora pela frente dela até entrar no capacete.
func _borda_da_tela() -> PackedVector3Array:
	var tela := Vector3(0.44, 0.29, 0.24)
	var nt := 2.0 / 0.6
	var centro_tela := Vector3(0, 1.68, 0.3)
	var capacete := Vector3(0.56, 0.47, 0.5)
	var nc := 2.0 / 0.72
	var centro_capacete := Vector3(0, 1.72, 0)
	var frente := func(x: float, y: float) -> Vector3:
		var resto := 1.0 - pow(absf(x / tela.x), nt) - pow(absf(y / tela.y), nt)
		return centro_tela + Vector3(x, y, tela.z * pow(maxf(resto, 0.0), 1.0 / nt))
	var dentro := func(p: Vector3) -> bool:
		var d := (p - centro_capacete) / capacete
		return pow(absf(d.x), nc) + pow(absf(d.y), nc) + pow(absf(d.z), nc) < 1.0
	var pontos := PackedVector3Array()
	for i in 120:
		var a := TAU * i / 120.0
		var dir := Vector2(cos(a), sin(a))
		# Até onde a tela vai nessa direção (a borda da superelipse).
		var limite := 1.0 / pow(pow(absf(dir.x / tela.x), nt) + pow(absf(dir.y / tela.y), nt), 1.0 / nt)
		var fora := 0.0
		var em := limite
		for _k in 30:
			var meio := (fora + em) / 2.0
			if dentro.call(frente.call(dir.x * meio, dir.y * meio)):
				em = meio
			else:
				fora = meio
		pontos.append(frente.call(dir.x * fora, dir.y * fora))
	return pontos


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


## Cilindro de quina redonda (em pé, no eixo Y): superelipsoide quase reta em cima e embaixo.
func _disco(raio: float, altura: float) -> ArrayMesh:
	return Forma.superelipsoide(Vector3(raio, altura / 2.0, raio), 0.3, 1.0, -PI / 2.0, 16, 32)


func _esfera(raio: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = raio
	s.height = raio * 2.0
	s.radial_segments = 32
	s.rings = 16
	return s
