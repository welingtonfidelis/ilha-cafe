class_name BolotaMonstro
extends Bolota
## A Bolota das fases com o corpo e as animações de um monstro do Cute Monsters Pack (Quaternius, CC0). O teste
## com o Alien foi aprovado pelo usuário em 2026-10-30 ("eu gostei, ficou bom"), e o pacote virou a turma do Rei
## Bolotão: o Alien é a Bolota de sempre, e cada outro monstro traz uma regra, porque nem todo inimigo apanha
## igual (ideia do usuário: "uns não pode pular em cima, outros não pode dar soco").
## Regras (`regra`):
##   base       apanha de tudo
##   espinhos   pisar em cima espeta: o Faísca perde um coração e é jogado longe; soco, giro e laser derrubam
##   garras     soco e giro de frente batem nas garras e o Faísca volta; pisão, laser e golpe pelas costas
##              derrubam (ele vira devagar, para dar tempo de dar a volta)
##   investida  vê o Faísca, pula no lugar e dispara em linha reta; no fim da corrida fica tonto
##   fantasma   soco, giro e pisão atravessam; só o laser e Bolota arremessada acertam
##   voa        flutua no alto, longe do soco, e dá rasantes; no rasante dá para bater, e acertado ele cai tonto

const PASTA := "res://assets/faisca/monstros/"
const ALIEN := PASTA + "Alien.gltf"
## Tipo -> [arquivo do modelo, regra]. Os 11 escolhidos pelo usuário em 2026-10-30.
const TIPOS := {
	"alien": ["Alien", "base"],
	"cogumelo": ["Mushroom", "base"],
	"pinguim": ["Penguin", "base"],
	"cacto": ["Cactus", "espinhos"],
	"ciclope": ["Cyclops", "espinhos"],
	"arvore": ["Tree", "espinhos"],
	"caranguejo": ["Crab", "garras"],
	"porco": ["Pig", "investida"],
	"fantasma": ["Ghost", "fantasma"],
	"abelha": ["Bee", "voa"],
	"morcego": ["Bat", "voa"],
}
## Os monstros têm uns 2 m de altura; em 0,8x o corpo fica da largura da Bolota.
const ESCALA := 0.8
## A textura pintada do pacote fica escura com a luz da fase: um pouco de brilho próprio clareia (e pisca forte quando apanha).
const BRILHO := 0.45
const BRILHO_PISCANDO := 2.2
## Animações que repetem (as outras tocam uma vez).
const EM_LACO := ["Idle", "Walk", "No", "Jump", "Dance", "Flying"]
## Os que voam (Morcego e Abelha) só têm Flying, Bite_Front, HitRecieve e Death: no lugar das que faltam, tocam estas.
const SUBSTITUTAS := {"Idle": "Flying", "Walk": "Flying", "Jump": "Flying", "No": "HitRecieve", "Bite_InPlace": "Bite_Front"}
## Garras: até este ângulo da frente dele, soco e giro batem nas garras.
const FRENTE_DAS_GARRAS := deg_to_rad(75.0)
## Investida: tempo pulando no lugar antes de correr, quanto corre e a velocidade.
const TEMPO_CARGA := 0.8
const TEMPO_CORRIDA := 1.4
const VEL_CORRIDA := 8.5
## Voa: altura acima da casa dele (fora do soco, mas perto o bastante para ver o Faísca: a Bolota só segue até
## 2,5 m de diferença), distância máxima da casa, e o rasante (desce, fica embaixo e sobe).
const ALTURA_VOO := 2.3
const COLEIRA_VOO := 9.0
const TEMPO_RASANTE := 1.6
const RASANTE_EMBAIXO := 1.0

var tipo := "alien"
var regra := "base"
var modelo := ALIEN
var anim: AnimationPlayer
## Tempo que falta da animação de uma vez só (levar golpe, encostar), antes de voltar a andar ou parar.
var _uma_vez := 0.0
## Depois de se defender, um instante sem se defender de novo (o mesmo golpe não conta duas vezes).
var _defesa := 0.0
var _carga := 0.0
var _correndo := 0.0
var _dir := Vector3.ZERO
var _rasante := 0.0
var _espera_rasante := 1.5


## `qual` é um dos TIPOS ou o caminho de um .gltf (a regra fica "base").
func _init(qual := "alien") -> void:
	if TIPOS.has(qual):
		tipo = qual
		modelo = PASTA + TIPOS[qual][0] + ".gltf"
		regra = TIPOS[qual][1]
	else:
		modelo = qual
		tipo = qual.get_file().get_basename().to_lower()


func _ready() -> void:
	if regra == "garras":
		giro_olhar = 1.2
	if regra == "voa":
		velocidade = 2.4
	super()


func _montar_visual() -> void:
	var cena: Node3D = load(modelo).instantiate()
	cena.scale = Vector3.ONE * ESCALA
	_corpo.add_child(cena)
	# Um material só para o corpo todo, com luz (o do pacote vem sem luz) e o brilho branco quando apanha.
	for mi: MeshInstance3D in cena.find_children("*", "MeshInstance3D", true, false):
		var original := mi.get_active_material(0) as StandardMaterial3D
		if _mat_corpo == null:
			_mat_corpo = original.duplicate() as StandardMaterial3D if original else StandardMaterial3D.new()
			_mat_corpo.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
			_mat_corpo.roughness = 0.85
			_mat_corpo.emission = Color.WHITE
			_mat_corpo.emission_texture = _mat_corpo.albedo_texture
			# Multiplicando, o brilho é a cor da própria textura (somando, o branco desbotava tudo).
			_mat_corpo.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
			_mat_corpo.emission_energy_multiplier = BRILHO
			if regra == "fantasma":
				_mat_corpo.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				_mat_corpo.albedo_color.a = 0.8
		mi.material_override = _mat_corpo
	anim = cena.find_children("*", "AnimationPlayer", true, false)[0]
	for nome: String in EM_LACO:
		if anim.has_animation(nome):
			anim.get_animation(nome).loop_mode = Animation.LOOP_LINEAR
	_animar("Idle")


func _physics_process(delta: float) -> void:
	var pausa_antes := _pausa
	if regra == "voa":
		_voar_no_alto(delta)
	super(delta)
	_mat_corpo.emission_enabled = true
	_mat_corpo.emission_energy_multiplier = BRILHO_PISCANDO if _piscar > 0.0 else BRILHO
	_uma_vez -= delta
	_defesa -= delta
	# A Bolota acabou de encostar no Faísca (a pausa pulou para 1 s).
	if _pausa > pausa_antes + 0.5 and not derrotado:
		_animar("Bite_InPlace", 1.3, true)
	if regra == "investida":
		_investida(delta)
	_escolher_animacao()


func receber_golpe(dano: int, de: Vector3, forca := 6.0, tipo_golpe := "") -> bool:
	if not derrotado and not agarrada and not voando and _bloqueia(tipo_golpe, de):
		if _defesa <= 0.0:
			_defender(tipo_golpe, de)
		return false
	var levou := super(dano, de, forca, tipo_golpe)
	if levou and not derrotado:
		_carga = 0.0
		_correndo = 0.0
		_rasante = 0.0
		# Acertado no ar, quem voa cai tonto (é a hora de agarrar).
		if regra == "voa" and tonta <= 0.0:
			ficar_tonta()
		if tonta <= 0.0:
			_animar("HitRecieve", 1.0, true)
	return levou


## Se este golpe não pega nele (tonto, pega tudo).
func _bloqueia(tipo_golpe: String, de: Vector3) -> bool:
	if tonta > 0.0 or tipo_golpe == "":
		return false
	match regra:
		"espinhos":
			return tipo_golpe == "pisao"
		"fantasma":
			return tipo_golpe in ["soco", "giro", "pisao"]
		"garras":
			if not tipo_golpe in ["soco", "giro"]:
				return false
			var para := de - global_position
			para.y = 0.0
			var frente := visual.global_basis.z
			frente.y = 0.0
			return para.length() > 0.05 and frente.length() > 0.01 and frente.angle_to(para) < FRENTE_DAS_GARRAS
	return false


## O golpe não pegou: cada um reage do seu jeito, e o Faísca é jogado para trás (no espinho, também perde coração).
func _defender(tipo_golpe: String, _de: Vector3) -> void:
	_defesa = 0.35
	if dormindo:
		_acordar()
	var jogador := get_tree().get_first_node_in_group("jogador") as Jogador
	var fora := Vector3.ZERO
	if jogador:
		fora = jogador.global_position - global_position
		fora.y = 0.0
		# Bem em cima dele, sai para um lado qualquer.
		fora = fora.normalized() if fora.length() > 0.05 else Vector3.BACK.rotated(Vector3.UP, randf() * TAU)
	match regra:
		"espinhos":
			_amasso = -0.2
			_animar("Yes", 1.4, true)
			# O empurrão do dano (uns 0,9 m no ar) deixava o Faísca em cima dele: este tira de cima.
			if jogador:
				jogador.receber_dano(global_position)
				jogador.velocity = fora * 14.0 + Vector3.UP * 7.0
		"garras":
			Sfx.play_at(get_parent(), "escudo", global_position, -2.0, 0.1)
			_amasso = 0.25
			_animar("Yes", 1.6, true)
			if jogador:
				jogador.velocity = fora * 6.5 + Vector3.UP * 2.5
				jogador.golpe_atual = -1
		"fantasma":
			Sfx.play_at(get_parent(), "golpe_ar", global_position, -4.0, 0.1)
			var tw := create_tween()
			tw.tween_property(_mat_corpo, "albedo_color:a", 0.25, 0.1)
			tw.tween_property(_mat_corpo, "albedo_color:a", 0.8, 0.4)
			if jogador and tipo_golpe == "pisao":
				jogador.velocity = fora * 4.0 + Vector3.UP * 4.0


func _andar(delta: float) -> Vector3:
	if regra == "voa":
		return _andar_voando()
	if regra == "investida":
		if _correndo > 0.0:
			if not _tem_chao(global_position + _dir * 1.0):
				_fim_da_corrida(false)
				return Vector3.ZERO
			return _dir * VEL_CORRIDA
		if _carga > 0.0:
			return Vector3.ZERO
	return super(delta)


func _olhar_jogador() -> bool:
	return super() and _carga <= 0.0 and _correndo <= 0.0


## Investida: perto do Faísca (nem colado, nem longe), pula no lugar e dispara para onde ele estava.
func _investida(delta: float) -> void:
	if derrotado or agarrada or voando or dormindo or tonta > 0.0:
		_carga = 0.0
		_correndo = 0.0
		return
	if _correndo > 0.0:
		_correndo -= delta
		if is_on_wall():
			_fim_da_corrida(true)
		elif _correndo <= 0.0:
			_fim_da_corrida(false)
		return
	if _carga > 0.0:
		_carga -= delta
		_corpo.rotation.z = sin(_tempo * 40.0) * 0.1
		if _carga <= 0.0:
			_corpo.rotation.z = 0.0
			_correndo = TEMPO_CORRIDA
			Sfx.play_at(get_parent(), "golpe_ar", global_position, -2.0, 0.1)
		return
	var jogador := get_tree().get_first_node_in_group("jogador") as Node3D
	if jogador == null or not _seguindo or _pausa > 0.0 or not is_on_floor():
		return
	var d := jogador.global_position - global_position
	var longe := Vector2(d.x, d.z).length()
	if longe > 1.8 and longe < 8.0 and absf(d.y) < 1.5:
		d.y = 0.0
		_dir = d.normalized()
		visual.rotation.y = atan2(_dir.x, _dir.z)
		_carga = TEMPO_CARGA


## Fim da corrida: bateu em alguma coisa ou cansou (na beirada também para). Fica tonto nos dois casos.
func _fim_da_corrida(bateu: bool) -> void:
	_correndo = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	if bateu:
		Sfx.play_at(get_parent(), "bonk", global_position, 0.0, 0.1)
		_amasso = 0.35
	ficar_tonta()


func _tem_chao(p: Vector3) -> bool:
	var de := p + Vector3.UP * 0.5
	return not get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(de, de + Vector3.DOWN * 1.6, 1)).is_empty()


## Voa: no alto (sem gravidade) segue o Faísca de longe e, de vez em quando, desce num rasante até ele. Tonto,
## arremessado, agarrado ou dormindo, a gravidade volta e ele cai.
func _voar_no_alto(delta: float) -> void:
	if derrotado or agarrada or voando or dormindo or tonta > 0.0:
		_gravidade = 26.0
		_rasante = 0.0
		return
	_gravidade = 0.0
	var jogador := get_tree().get_first_node_in_group("jogador") as Node3D
	var alto := _origem.y + ALTURA_VOO + sin(_tempo * 2.2) * 0.15
	_espera_rasante -= delta
	if _rasante > 0.0:
		_rasante -= delta
		var passou := TEMPO_RASANTE - _rasante
		if jogador and passou < 0.45 + RASANTE_EMBAIXO:
			alto = jogador.global_position.y + 0.1
		if _rasante <= 0.0:
			_espera_rasante = randf_range(2.0, 3.2)
	elif jogador and _seguindo and _espera_rasante <= 0.0 and _pausa <= 0.0:
		var d := jogador.global_position - global_position
		if Vector2(d.x, d.z).length() < 2.5:
			_rasante = TEMPO_RASANTE
			_animar("Bite_Front", 1.0, true)
	velocity.y = clampf((alto - global_position.y) * 5.0, -9.0, 6.0)


func _andar_voando() -> Vector3:
	if _pausa > 0.0:
		return Vector3.ZERO
	var alvo := _origem
	var jogador := get_tree().get_first_node_in_group("jogador") as Node3D
	if _seguindo and jogador:
		alvo = jogador.global_position
		var da_casa := alvo - _origem
		da_casa.y = 0.0
		if da_casa.length() > COLEIRA_VOO:
			alvo = _origem + da_casa.normalized() * COLEIRA_VOO
	var d := alvo - global_position
	d.y = 0.0
	if d.length() < 0.4:
		return Vector3.ZERO
	return d.normalized() * (velocidade * 0.5 if _rasante > 0.0 else velocidade)


func _escolher_animacao() -> void:
	if derrotado:
		return
	if agarrada:
		_animar("Jump", 1.6)
	elif voando:
		_animar("HitRecieve")
	elif tonta > 0.0:
		_animar("No", 0.7)
	elif dormindo:
		_animar("Idle", 0.35)
	elif _correndo > 0.0:
		_animar("Walk", 2.6)
	elif _carga > 0.0:
		_animar("Jump", 1.8)
	elif _uma_vez > 0.0:
		return
	else:
		var rapidez := Vector2(velocity.x, velocity.z).length()
		if rapidez > 0.4:
			_animar("Walk", clampf(rapidez / 1.6, 0.8, 1.8))
		else:
			_animar("Idle")


## Toca `nome` (se já não estiver tocando). Com `uma_vez`, segura as outras até ela acabar.
func _animar(nome: String, rapidez := 1.0, uma_vez := false) -> void:
	if anim == null:
		return
	if not anim.has_animation(nome):
		nome = SUBSTITUTAS.get(nome, "")
		if not anim.has_animation(nome):
			return
	anim.speed_scale = rapidez
	if uma_vez:
		anim.play(nome, 0.08)
		anim.seek(0.0, true)
		_uma_vez = anim.get_animation(nome).length / rapidez
	elif anim.current_animation != nome:
		anim.play(nome, 0.15)


## A bolotinha que sai quicando é o próprio monstro pequenininho, pulando.
func _mini() -> Node3D:
	var mini := Node3D.new()
	var cena: Node3D = load(modelo).instantiate()
	cena.scale = Vector3.ONE * ESCALA * 0.32
	mini.add_child(cena)
	var a: AnimationPlayer = cena.find_children("*", "AnimationPlayer", true, false)[0]
	var pulo := "Jump" if a.has_animation("Jump") else "Flying"
	a.get_animation(pulo).loop_mode = Animation.LOOP_LINEAR
	a.play(pulo)
	a.speed_scale = 1.8
	return mini
