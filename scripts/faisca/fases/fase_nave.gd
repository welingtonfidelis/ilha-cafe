class_name FaseNave
extends Fase
## A fase final do Faísca: por dentro da Nave Aspiratrão, que paira em cima do farol (2026-11-12, da maquete aprovada
## pelo usuário: docs/level-design/maquete-nave-aspiratrao.html, "maquete aprovada"). Um disco enorme e oco, de paredes
## roxas e luzinhas amarelas, com o Tanque de Estrelas no meio (o marco: um cilindro de vidro do fundo até a Sala do
## Trono, cheio das estrelas roubadas). O fundo é um campo de força lilás: quem cai volta no posto. Os cinco
## playgrounds sobem em espiral em volta do tanque e repetem os poderes de cada mundo; cada um tem a cápsula do poder
## dele (CapsulaDePoder), e os poderes somam até o fim:
##   1 Hangar do Bocal (y 0, ao sul): o Faísca chega pelo bocal do aspirador; as três luzes de pouso, acesas com o
##     laser (Lampada), abrem a escotilha. Bolsos: o anel de caixotes (Faisquinha 3) e o alto do dropship (coração)
##   viagem: a cápsula do tubo pneumático
##   2 Depósito de Estrelas (y 8 a 24, a oeste; chiclete e ioiô): a sala redonda com prateleiras de potes gigantes; o
##     soco no ferrolho de três potes (PoteDeEstrelas) solta as estrelas, que voam até o tanque, e destrava o
##     monta-carga. V1 no nicho alto, pelo ioiô; coração na tampa de um pote, pelo chiclete (P1)
##   viagem: o monta-carga
##   3 Sala de Máquinas (y 26, a noroeste; martelinho): o martelinho afunda o pino de três motores (MotorDaNave), e vem
##     o momento especial, "Sem gravidade!": o gerador para, o pulo vai alto e devagar, e as caixas sobem do chão e
##     viram uma escada no ar até a estação do carrinho. V2 no alto, só sem gravidade; a salinha de ferramentas (P2)
##   viagem: o carrinho no trilho do teto
##   4 Estufa Gelada (y 34, a nordeste; luva e pipa): tubos de plantas, chão de gelo e o iglu do coração; a bola de neve
##     nos três sinos do alto dos tubos abre a porta e faz a ponte de luz. V3 no alto do tubo maior, pela coluna de
##     vento com a pipa (P3)
##   5 Corredor do Trono (y 40 a 44, a leste): o corredor em curva com as janelas para a noite, plataformas que andam e
##     barreiras de luz que giram e empurram; três guardas de capacete levam as chaves-coroa da porta do trono (só a
##     pancada do martelinho derruba). Bolso: o telhado da cabine de pilotagem (coração e Faisquinha 4); o Faisquinha
##     5 vai pendurado num guarda (P4)
##   viagem: o elevador até a Sala do Trono
##   Sala do Trono (y 52, no topo, debaixo da cúpula): a luta com o Rei Bolotão (ChefeRei) em três fases, e no fim a
##   cena da estrelinha de bolso (P5). A fase não tem baú: a vitória pede ao FaiscaJogo o final (`final_pedido`).

signal faixa_pedida(titulo: String, sub: String)
signal luta_comecou
signal final_pedido

const NAVE := "res://assets/faisca/nave/"
const NEVE := "res://assets/faisca/neve/"
const LILAS := Color("c9b8f0")
const LILAS_ESCURO := Color("8a6fd0")
const ROXO := Color("5b3fa0")
const ROXO_ESCURO := Color("2e2258")
const BAIXO := Color("3c2a6e")
const CINZA := Color("55607a")
const LARANJA := Color("ff7a22")
const GELO := Color("cfeeff")
const RAIO_CASCO := 128.0
const CHAO_CASCO := -30.0
const TETO := 72.0
## As janelas do casco (de y a y), na frente do corredor.
const JANELA := Vector2(45.0, 60.0)
const RAIO_TANQUE := 9.0
const ARENA_Y := 52.0
const RAIO_ARENA := 24.0
const HANGAR := Vector3(0, 0, 88)
const DEPOSITO := Vector3(-82, 8, 20)
const RAIO_DEPOSITO := 22.0
## As prateleiras do depósito: [altura, de graus, até graus] (graus contados do leste, +X, para o sul, +Z).
const PRATELEIRAS := [[16.0, 95.0, 215.0], [24.0, 235.0, 345.0]]
const MAQUINAS := Vector3(-60, 26, -66)
const TAMANHO_MAQUINAS := Vector2(54, 42)
const ESTUFA := Vector3(54, 34, -64)
const TAMANHO_ESTUFA := Vector2(50, 40)
const RAIO_CORREDOR := 110.0
const CORREDOR_A0 := -0.35
const CORREDOR_PASSO := 0.141
const TRECHOS := 7
## Sem gravidade, o Faísca pesa isto (o pulo vai uns 7 m, devagar).
const GRAVIDADE_ZERO := 0.3
## Na Sala do Trono: onde ficam os pilares, as colunas de vento (fase 2), as lâmpadas (fase 3) e as argolas (fase 1).
const PILARES := [100.0, 220.0, 340.0]
const COLUNAS := [40.0, 160.0, 280.0]
const LAMPADAS := [70.0, 130.0, 250.0, 310.0]
const ARGOLAS := [10.0, 190.0]
const TOPO_TRONO := 8.0
const RAIO_TRONO := 6.5
const TOPO_COLUNA := 12.2
## O cetro puxa a esta velocidade (m/s) quem está no chão e à vista dele.
const PUXAO := 2.8
const VOO_POTE := 1.3

# --- o que a fase guarda (para a luta, os testes e as fotos) ---
var capsulas: Array[CapsulaDePoder] = []
var lampadas_pouso: Array[Lampada] = []
var potes: Array[PoteDeEstrelas] = []
var motores: Array[MotorDaNave] = []
var pinos_dos_motores: Array[Pino] = []
var caixas_no_ar: Array[AnimatableBody3D] = []
var sinos_da_estufa: Array[Sino] = []
var guardas: Array[BolotaMonstro] = []
var colunas: Array[ColunaDeVento] = []
var escotilhas: Array[StaticBody3D] = []
var tubo: Carona
var monta_carga: Carona
var carrinho_do_teto: Carona
var elevador: Carona
var ponte_de_luz: StaticBody3D
var porta_do_trono: StaticBody3D
var chaves := 0
var sem_gravidade := false
var gravidade_ligada := true
## A luta.
var chefe: ChefeRei
var nome_do_chefe := "Rei Bolotão"
var trono: AnimatableBody3D
var botao_do_trono: BotaoDoTrono
var argolas_do_trono: Array[ArgolaDeIoio] = []
var colunas_do_trono: Array[ColunaDeVento] = []
var filtros: Array[Ferrolho] = []
var lampadas_do_trono: Array[Lampada] = []
var pilares: Array[StaticBody3D] = []
var potes_que_acertaram := 0
## Quantas vezes a luta recomeçou do zero (os testes olham).
var vezes_que_recomecou := 0
## Onde o elevador chega na Sala do Trono.
var entrada_do_trono := Vector3.ZERO
var vencida := false
var cena_do_final := 0.0
## Nos testes: a cena do final mais curta.
var rapido := false

var _ambiente: Environment
var _sol: DirectionalLight3D
var _brilho_coluna: MeshInstance3D
var _estrelas_do_tanque: Node3D
var _comecou := false
var _espera := 1.0
var _gravidade_normal := 26.0
var _caixas_chao: Array[Vector3] = []
var _caixas_ar: Array[Vector3] = []
var _soltas: Array[Node3D] = []
var _sirene: Node3D
var _riscos: MultiMeshInstance3D
var _lixo: Array[Node3D] = []
var _trono_caido := false
var _trono_y := 0.0
var _barreiras: Array[AnimatableBody3D] = []
var _barreiras_centro: Array[Vector3] = []
var _guardas_vivos := 0
var _vento_do_cetro := 0.0


## O botão vermelho do trono voador (fase 1 da luta): um soco aperta. Fica no grupo dos alvos dos golpes.
class BotaoDoTrono extends StaticBody3D:
	signal apertado
	var derrotado := false
	var raio_golpe := 1.0
	var _cogumelo: MeshInstance3D
	var _mat: StandardMaterial3D
	var _tempo := 0.0

	func _ready() -> void:
		add_to_group(Alvo.GRUPO)
		collision_layer = 1
		collision_mask = 0
		var base := MeshInstance3D.new()
		var b := CylinderMesh.new()
		b.top_radius = 0.75
		b.bottom_radius = 0.85
		b.height = 0.3
		base.mesh = b
		var escuro := StandardMaterial3D.new()
		escuro.albedo_color = Color("2b2140")
		base.material_override = escuro
		base.position.y = 0.15
		add_child(base)
		_cogumelo = MeshInstance3D.new()
		var s := SphereMesh.new()
		s.radius = 0.62
		s.height = 0.7
		s.is_hemisphere = true
		_cogumelo.mesh = s
		_mat = StandardMaterial3D.new()
		_mat.albedo_color = Color("e8333f")
		_mat.emission_enabled = true
		_mat.emission = Color("ff3b4a")
		_mat.emission_energy_multiplier = 0.6
		_cogumelo.material_override = _mat
		_cogumelo.position.y = 0.3
		add_child(_cogumelo)
		var cs := CollisionShape3D.new()
		var forma := CylinderShape3D.new()
		forma.radius = 0.8
		forma.height = 0.7
		cs.shape = forma
		cs.position.y = 0.35
		add_child(cs)

	func receber_golpe(_dano: int, _de: Vector3, _forca := 6.0, _tipo := "") -> bool:
		if derrotado:
			return false
		derrotado = true
		_cogumelo.scale = Vector3(1.2, 0.4, 1.2)
		_mat.emission_energy_multiplier = 3.0
		Sfx.play_at(get_parent(), "bonk", global_position, 2.0, 0.05)
		apertado.emit()
		return true

	func soltar() -> void:
		derrotado = false
		_cogumelo.scale = Vector3.ONE

	func _process(delta: float) -> void:
		_tempo += delta
		if not derrotado:
			_mat.emission_energy_multiplier = 0.5 + 0.6 * (0.5 + 0.5 * sin(_tempo * 5.0))


func _montar() -> void:
	nome = "Nave Aspiratrão"
	superficie = "metal"
	inicio = Vector3(0, 0.1, 104)
	limite_queda = -24.0
	_casco()
	_tanque()
	_hangar()
	_viagem_tubo()
	_deposito()
	_viagem_monta_carga()
	_maquinas()
	_viagem_carrinho()
	_estufa()
	_corredor()
	_sala_do_trono()
	# O farol lá embaixo, à vista pelas janelas do corredor.
	farol(Vector3(330, -150, 70), 5.0)


func _ready() -> void:
	super()
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j:
		_gravidade_normal = j.gravidade


func _exit_tree() -> void:
	# A gravidade de sempre volta com o Faísca, saindo da fase no meio do "sem gravidade".
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j and not gravidade_ligada:
		j.gravidade = _gravidade_normal


## Só os pisos ganham o desenho do chão (nem o casco, nem o vidro, nem as caixas).
func leva_desenho(mi: MeshInstance3D, _arquivo: String) -> bool:
	return mi.has_meta("piso")


# --- o céu, a luz e o campo de força -------------------------------------------------

## Por dentro da nave: o céu da noite (sem as estrelas, que estão no tanque) aparece só pelas janelas e pela cúpula; a
## luz é lilás, com a "luz do teto" de cima.
func _montar_ceu_e_luz() -> void:
	var ceu := ProceduralSkyMaterial.new()
	ceu.sky_top_color = Color("0b1030")
	ceu.sky_horizon_color = Color("2a2060")
	ceu.ground_horizon_color = Color("2a2060")
	ceu.ground_bottom_color = Color("0b1030")
	ceu.sun_angle_max = 1.0
	var sky := Sky.new()
	sky.sky_material = ceu
	_ambiente = Environment.new()
	_ambiente.background_mode = Environment.BG_SKY
	_ambiente.sky = sky
	_ambiente.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_ambiente.ambient_light_color = Color("dcd2ff")
	_ambiente.ambient_light_energy = 0.9
	_ambiente.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_ambiente.tonemap_exposure = 1.0
	_ambiente.ssao_enabled = true
	_ambiente.glow_enabled = true
	_ambiente.glow_intensity = 0.6
	_ambiente.glow_hdr_threshold = 1.1
	_ambiente.fog_enabled = true
	_ambiente.fog_light_color = Color("4a3a8a")
	_ambiente.fog_density = 0.0022
	_ambiente.fog_sky_affect = 0.0
	var we := WorldEnvironment.new()
	we.environment = _ambiente
	add_child(we)
	_sol = DirectionalLight3D.new()
	_sol.rotation_degrees = Vector3(-68, -30, 0)
	_sol.light_color = Color("fff0fa")
	_sol.light_energy = 0.95
	_sol.shadow_enabled = true
	_sol.shadow_opacity = 0.7
	_sol.directional_shadow_max_distance = 90.0
	add_child(_sol)


## No lugar do mar de nuvens: o campo de força lilás lá embaixo, com os anéis brilhando.
func _montar_nuvens() -> void:
	var campo := MeshInstance3D.new()
	var disco := CylinderMesh.new()
	disco.top_radius = RAIO_CASCO
	disco.bottom_radius = RAIO_CASCO
	disco.height = 0.2
	disco.radial_segments = 96
	campo.mesh = disco
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.62, 0.48, 1.0, 0.25)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	campo.material_override = m
	campo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	campo.position.y = CHAO_CASCO
	add_child(so_enfeite(campo))
	var anel := StandardMaterial3D.new()
	anel.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	anel.albedo_color = Color(0.85, 0.75, 1.0, 0.6)
	anel.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for r in [22.0, 46.0, 70.0, 94.0, 118.0]:
		var mi := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = r - 0.35
		t.outer_radius = r + 0.35
		t.rings = 96
		mi.mesh = t
		mi.material_override = anel
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position.y = CHAO_CASCO + 0.2
		mi.scale.y = 0.2
		add_child(so_enfeite(mi))


# --- peças da fase ------------------------------------------------------------------

## Ponto em volta de `centro`: `graus` contados do leste (+X) para o sul (+Z), a `r` m do meio, na altura `y`.
func em_volta(centro: Vector3, graus: float, r: float, y: float) -> Vector3:
	var a := deg_to_rad(graus)
	return Vector3(centro.x + cos(a) * r, y, centro.z + sin(a) * r)


## Ponto no corredor: `k` é o trecho (0 a 6; com fração anda pelo meio), `dr` m para fora do meio dele.
func no_corredor(k: float, dr := 0.0) -> Vector3:
	var a := CORREDOR_A0 + k * CORREDOR_PASSO
	return Vector3(cos(a) * (RAIO_CORREDOR + dr), 40.0 + 0.6 * k, sin(a) * (RAIO_CORREDOR + dr))


## Para onde o corredor segue no trecho `k`.
func frente_do_corredor(k: float) -> Vector3:
	var a := CORREDOR_A0 + k * CORREDOR_PASSO
	return Vector3(-sin(a), 0, cos(a))


## Piso de caixa com o meio de cima em `topo` (sólido, com o desenho do chão e a barriga mais escura por baixo).
func piso(topo: Vector3, tamanho: Vector3, cor := LILAS, giro := 0.0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = topo - Vector3(0, tamanho.y * 0.5, 0)
	corpo.rotation.y = giro
	add_child(corpo)
	var bm := BoxMesh.new()
	bm.size = tamanho
	var mi := _malha(corpo, bm, cor, Vector3.ZERO)
	mi.set_meta("piso", true)
	var barriga := BoxMesh.new()
	barriga.size = Vector3(tamanho.x * 0.9, 1.6, tamanho.z * 0.9)
	_malha(corpo, barriga, BAIXO, Vector3(0, -tamanho.y * 0.5 - 0.8, 0)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamanho
	cs.shape = forma
	corpo.add_child(cs)
	return corpo


## Piso redondo com o meio de cima em `topo`, a beira roxa e o cone por baixo.
func disco(topo: Vector3, raio: float, cor := LILAS) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = topo
	add_child(corpo)
	var tampa := _malha(corpo, _cilindro(raio, raio, 1.4), cor, Vector3(0, -0.7, 0))
	tampa.set_meta("piso", true)
	var toro := TorusMesh.new()
	toro.inner_radius = raio - 0.2
	toro.outer_radius = raio + 0.25
	toro.rings = 64
	_malha(corpo, toro, ROXO, Vector3(0, -0.05, 0))
	_malha(corpo, _cilindro(raio * 0.9, raio * 0.45, 4.0), BAIXO, Vector3(0, -3.4, 0)).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = raio
	forma.height = 1.4
	cs.shape = forma
	cs.position.y = -0.7
	corpo.add_child(cs)
	return corpo


## Pedaço de anel (de `r1` a `r2` m de `centro`, de `a` a `b` graus) com o topo em `topo` e `grossura` de altura.
func arco_piso(centro: Vector3, r1: float, r2: float, a: float, b: float, topo: float, grossura: float, cor := LILAS) -> StaticBody3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := maxi(1, ceili(absf(b - a) / 5.0))
	var baixo := Vector3.DOWN * grossura
	for i in n:
		var g0 := lerpf(a, b, float(i) / n)
		var g1 := lerpf(a, b, float(i + 1) / n)
		var p := [em_volta(centro, g0, r1, topo), em_volta(centro, g0, r2, topo), em_volta(centro, g1, r2, topo), em_volta(centro, g1, r1, topo)]
		_quad(st, p[0], p[1], p[2], p[3], Vector3.UP)
		_quad(st, p[0] + baixo, p[1] + baixo, p[2] + baixo, p[3] + baixo, Vector3.DOWN)
		var fora := em_volta(Vector3.ZERO, (g0 + g1) * 0.5, 1.0, 0.0)
		_quad(st, p[1], p[2], p[2] + baixo, p[1] + baixo, fora)
		_quad(st, p[0], p[3], p[3] + baixo, p[0] + baixo, -fora)
		if i == 0:
			_quad(st, p[0], p[1], p[1] + baixo, p[0] + baixo, p[0] - p[3])
		if i == n - 1:
			_quad(st, p[3], p[2], p[2] + baixo, p[3] + baixo, p[3] - p[0])
	return _corpo_da_malha(st.commit(), cor, true)


## Parede curva fininha em volta de `centro` (raio `r`, de `a` a `b` graus, de `y0` a `y1`), sólida.
func parede_curva(centro: Vector3, r: float, a: float, b: float, y0: float, y1: float, cor := ROXO) -> StaticBody3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := maxi(1, ceili(absf(b - a) / 5.0))
	for i in n:
		var g0 := lerpf(a, b, float(i) / n)
		var g1 := lerpf(a, b, float(i + 1) / n)
		var p0 := em_volta(centro, g0, r, y0)
		var p1 := em_volta(centro, g1, r, y0)
		var dentro := -em_volta(Vector3.ZERO, (g0 + g1) * 0.5, 1.0, 0.0)
		_quad(st, p0, p1, p1 + Vector3.UP * (y1 - y0), p0 + Vector3.UP * (y1 - y0), dentro)
	return _corpo_da_malha(st.commit(), cor, false)


func _corpo_da_malha(malha: ArrayMesh, cor: Color, e_piso: bool) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	var m := _material(cor)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = m
	if e_piso:
		mi.set_meta("piso", true)
	corpo.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := malha.create_trimesh_shape()
	forma.backface_collision = true
	cs.shape = forma
	corpo.add_child(cs)
	return corpo


## Quadrilátero com a frente para o lado de `fora`.
func _quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, fora: Vector3) -> void:
	var nrm := (p1 - p0).cross(p2 - p0)
	if nrm.length_squared() < 1e-10:
		nrm = (p2 - p0).cross(p3 - p0)
	if nrm.dot(fora) < 0.0:
		var t := p1
		p1 = p3
		p3 = t
		nrm = -nrm
	nrm = nrm.normalized()
	for v in [p0, p2, p1, p0, p3, p2]:
		st.set_normal(nrm)
		st.add_vertex(v)


func _cilindro(r_cima: float, r_baixo: float, altura: float) -> CylinderMesh:
	var cil := CylinderMesh.new()
	cil.top_radius = r_cima
	cil.bottom_radius = r_baixo
	cil.height = altura
	cil.radial_segments = 48
	return cil


func _malha(pai: Node3D, malha: Mesh, cor: Color, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = malha
	mi.material_override = _material(cor)
	mi.position = pos
	pai.add_child(mi)
	return mi


## Material que brilha sozinho (as luzinhas, os vidros iluminados).
func _brilhante(cor: Color, forca := 2.0, alfa := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(cor.r, cor.g, cor.b, alfa)
	m.emission_enabled = true
	m.emission = cor
	m.emission_energy_multiplier = forca
	if alfa < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _vidro(cor: Color, alfa: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(cor.r, cor.g, cor.b, alfa)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.05
	m.rim_enabled = true
	return m


func nave_peca(arquivo: String, pos: Vector3, giro := 0.0, escala: Variant = 1.0, solida := true) -> Node3D:
	return peca_de(NAVE, arquivo, pos, giro, escala, solida)


## Caixote de carga (o vermelho e branco do Space Base) de `lado` m, com o pé em `pe`. Sólido.
func caixote(pe: Vector3, lado := 2.5, giro := 0.0) -> Node3D:
	return nave_peca("cargo_A", pe, giro, lado / 0.5)


func capsula(poder: String, pe: Vector3, giro := 0.0) -> CapsulaDePoder:
	var c := CapsulaDePoder.new()
	c.poder = poder
	c.position = pe
	c.rotation.y = giro
	add_child(c)
	c.pega.connect(func(cap: CapsulaDePoder, _j: Jogador) -> void:
		faixa_pedida.emit(CapsulaDePoder.NOMES[cap.poder] + "!", "Agora o Faísca tem esse poder até o fim da nave")
		dica.emit(CapsulaDePoder.DICAS[cap.poder]))
	capsulas.append(c)
	return c


func lampada(pe: Vector3, estilo := "poste") -> Lampada:
	var l := Lampada.new()
	l.estilo = estilo
	l.position = pe
	add_child(l)
	return l


## Escotilha redonda: o aro laranja em pé, a porta roxa e a parede invisível em volta dela (só abre com a tarefa).
## Atravessa-se em X com `giro` 0.
func escotilha(pe: Vector3, giro := 0.0, largura := 7.4) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.position = pe
	corpo.rotation.y = giro
	add_child(corpo)
	var aro := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 2.9
	t.outer_radius = 3.5
	aro.mesh = t
	aro.material_override = _material(LARANJA)
	aro.rotation.z = PI / 2.0
	aro.position.y = 3.2
	corpo.add_child(aro)
	var porta := MeshInstance3D.new()
	porta.name = "Porta"
	var p := _cilindro(2.95, 2.95, 0.3)
	porta.mesh = p
	porta.material_override = _material(ROXO)
	porta.rotation.z = PI / 2.0
	porta.position.y = 3.2
	corpo.add_child(porta)
	var luz := MeshInstance3D.new()
	var bola := SphereMesh.new()
	bola.radius = 0.4
	bola.height = 0.8
	luz.name = "Luz"
	luz.mesh = bola
	luz.material_override = _brilhante(Color("ff3b4a"), 2.0)
	luz.position = Vector3(0, 6.9, 0)
	corpo.add_child(luz)
	var cs := CollisionShape3D.new()
	cs.name = "Fechada"
	var forma := BoxShape3D.new()
	forma.size = Vector3(0.8, 6.8, largura)
	cs.shape = forma
	cs.position.y = 3.4
	corpo.add_child(cs)
	escotilhas.append(corpo)
	saidas.append(corpo)
	return corpo


## A porta sobe e some, a luz fica verde, e dá para passar.
func abrir_escotilha(e: StaticBody3D) -> void:
	if e.has_meta("aberta"):
		return
	e.set_meta("aberta", true)
	var porta := e.get_node("Porta") as MeshInstance3D
	var tw := porta.create_tween()
	tw.tween_property(porta, "position:y", 9.5, 0.9).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(porta.hide)
	((e.get_node("Luz") as MeshInstance3D).material_override as StandardMaterial3D).emission = Color("4cff7a")
	((e.get_node("Luz") as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = Color("4cff7a")
	(e.get_node("Fechada") as CollisionShape3D).set_deferred("disabled", true)
	Fx.confetti(self, e.global_position + Vector3.UP * 3.2, 40, 4.0)
	Sfx.play_at(self, "ui_ok", e.global_position, 0.0)


func escotilha_aberta(e: StaticBody3D) -> bool:
	return e.has_meta("aberta")


## Tubo de vidro (enfeite, sem colisão) seguindo os pontos.
func tubo_de_vidro(pontos: Array, raio := 2.6, cor := Color(0.85, 0.9, 1.0), alfa := 0.18) -> void:
	var curva := Curve3D.new()
	for p: Vector3 in pontos:
		curva.add_point(p)
	curva.bake_interval = 1.0
	var pts := curva.get_baked_points()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lados := 14
	var anel_antes: Array = []
	for i in pts.size():
		var tg := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var up := Vector3.UP if absf(tg.y) < 0.95 else Vector3.RIGHT
		var x := tg.cross(up).normalized()
		var y := x.cross(tg).normalized()
		var anel: Array = []
		for k in lados:
			var a := TAU * k / lados
			anel.append(pts[i] + (x * cos(a) + y * sin(a)) * raio)
		if not anel_antes.is_empty():
			for k in lados:
				var k2 := (k + 1) % lados
				_quad(st, anel_antes[k], anel_antes[k2], anel[k2], anel[k], (anel_antes[k] + anel[k]) * 0.5 - pts[i])
		anel_antes = anel
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _vidro(cor, alfa)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(so_enfeite(mi))


## Trilho escuro fininho pendurado no teto (enfeite), seguindo os pontos.
func trilho_do_teto(pontos: Array, acima := 4.4) -> void:
	for i in pontos.size() - 1:
		var de: Vector3 = pontos[i] + Vector3.UP * acima
		var ate: Vector3 = pontos[i + 1] + Vector3.UP * acima
		var mi := MeshInstance3D.new()
		var c := _cilindro(0.18, 0.18, de.distance_to(ate))
		mi.mesh = c
		mi.material_override = _material(Color("2b2140"))
		mi.position = (de + ate) * 0.5
		mi.basis = Basis(Quaternion(Vector3.UP, (ate - de).normalized()))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(so_enfeite(mi))


## Coluna de vento com a grade em `pe`, levando até `topo_y`.
func coluna(pe: Vector3, topo_y: float, ligada := true) -> ColunaDeVento:
	var c := ColunaDeVento.new()
	c.position = pe
	c.topo_y = topo_y
	c.ligada = ligada
	add_child(c)
	colunas.append(c)
	return c


## Parede invisível (que o Faísca bate e a câmera atravessa) com o meio em `centro`.
func parede_invisivel(centro: Vector3, tamanho: Vector3, giro := 0.0) -> StaticBody3D:
	var corpo := StaticBody3D.new()
	corpo.collision_layer = CAMADA_LIMITE
	corpo.collision_mask = 0
	corpo.position = centro
	corpo.rotation.y = giro
	add_child(corpo)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = tamanho
	cs.shape = forma
	corpo.add_child(cs)
	return corpo


## Dica do Vovô fora de um ponto de dica, uma vez só.
func _dica_uma_vez(qual: String) -> void:
	if not _dicas_dadas.has(qual):
		_dicas_dadas[qual] = true
		dica.emit(qual)


# --- o casco e o marco ---------------------------------------------------------------

## O casco por dentro: a parede roxa em volta (com as janelas grandes na frente do corredor), as duas fileiras de
## luzinhas amarelas, o teto com o buraco da cúpula e a cúpula de vidro em cima da Sala do Trono. Tudo enfeite.
func _casco() -> void:
	var parede := SurfaceTool.new()
	parede.begin(Mesh.PRIMITIVE_TRIANGLES)
	var vidro := SurfaceTool.new()
	vidro.begin(Mesh.PRIMITIVE_TRIANGLES)
	var teto := SurfaceTool.new()
	teto.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := 96
	var fim := CORREDOR_A0 + CORREDOR_PASSO * (TRECHOS + 0.5)
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var meio := wrapf((a0 + a1) * 0.5, -PI, PI)
		var p0 := Vector3(cos(a0), 0, sin(a0)) * RAIO_CASCO
		var p1 := Vector3(cos(a1), 0, sin(a1)) * RAIO_CASCO
		var dentro := -Vector3(cos(meio), 0, sin(meio))
		var janela := i % 2 == 0 and meio > CORREDOR_A0 - 0.08 and meio < fim
		var cortes := [CHAO_CASCO, JANELA.x, JANELA.y, TETO] if janela else [CHAO_CASCO, TETO]
		for k in range(0, cortes.size(), 2):
			_quad(parede, p0 + Vector3.UP * cortes[k], p1 + Vector3.UP * cortes[k], p1 + Vector3.UP * cortes[k + 1], p0 + Vector3.UP * cortes[k + 1], dentro)
		if janela:
			_quad(vidro, p0 + Vector3.UP * JANELA.x, p1 + Vector3.UP * JANELA.x, p1 + Vector3.UP * JANELA.y, p0 + Vector3.UP * JANELA.y, dentro)
			# A moldura clara em volta da janela.
			for y in [JANELA.x, JANELA.y]:
				var barra := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(0.6, 0.6, p0.distance_to(p1) + 0.6)
				barra.mesh = bm
				barra.material_override = _brilhante(Color("b89bff"), 0.8)
				barra.position = (p0 + p1) * 0.5 + Vector3.UP * y - dentro * 0.2
				barra.rotation.y = atan2(-(p1 - p0).x, -(p1 - p0).z) + PI
				add_child(so_enfeite(barra))
		var t0 := Vector3(cos(a0), 0, sin(a0))
		var t1 := Vector3(cos(a1), 0, sin(a1))
		_quad(teto, t0 * 25.0 + Vector3.UP * TETO, t0 * RAIO_CASCO + Vector3.UP * TETO, t1 * RAIO_CASCO + Vector3.UP * TETO, t1 * 25.0 + Vector3.UP * TETO, Vector3.DOWN)
	for spec in [[parede, ROXO_ESCURO, 1.0], [vidro, Color("1a2a6a"), 0.35], [teto, Color("241a48"), 1.0]]:
		var mi := MeshInstance3D.new()
		mi.mesh = (spec[0] as SurfaceTool).commit()
		var m := _material(spec[1]) if spec[2] >= 1.0 else _vidro(spec[1], spec[2])
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		mi.material_override = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(so_enfeite(mi))
	# As luzinhas amarelas em duas fileiras e os anéis de luz do teto.
	var luzinha := SphereMesh.new()
	luzinha.radius = 0.6
	luzinha.height = 1.2
	luzinha.radial_segments = 8
	luzinha.rings = 4
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = luzinha
	mm.instance_count = 192
	for i in 96:
		var a := TAU * (i + 0.5) / 96.0
		for k in 2:
			mm.set_instance_transform(i * 2 + k, Transform3D(Basis.IDENTITY, Vector3(cos(a), 0, sin(a)) * (RAIO_CASCO - 0.6) + Vector3.UP * (18.0 if k == 0 else 66.0)))
	var luzes := MultiMeshInstance3D.new()
	luzes.multimesh = mm
	luzes.material_override = _brilhante(Color("ffd86a"), 2.4)
	luzes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(so_enfeite(luzes))
	for r in [45.0, 75.0, 105.0]:
		var anel := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = r - 0.4
		t.outer_radius = r + 0.4
		t.rings = 96
		anel.mesh = t
		anel.material_override = _brilhante(Color("8ff3ff"), 1.4)
		anel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		anel.position.y = TETO - 0.4
		anel.scale.y = 0.3
		add_child(so_enfeite(anel))
	var cupula := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 32.0
	esfera.height = 32.0
	esfera.is_hemisphere = true
	esfera.radial_segments = 64
	esfera.rings = 16
	cupula.mesh = esfera
	cupula.material_override = _vidro(Color(0.75, 0.88, 1.0), 0.12)
	cupula.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	cupula.position.y = ARENA_Y
	add_child(so_enfeite(cupula))


## O Tanque de Estrelas: o cilindro de vidro do fundo até a Sala do Trono, cheio das estrelas roubadas girando
## devagar, com os anéis laranja e a luz amarela; em cima, a coluna de luz do marco, que aparece de toda a nave.
func _tanque() -> void:
	var corpo := StaticBody3D.new()
	add_child(corpo)
	var baixo := CHAO_CASCO + 4.0
	var altura := ARENA_Y - baixo
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = RAIO_TANQUE
	forma.height = altura
	cs.shape = forma
	cs.position.y = baixo + altura * 0.5
	corpo.add_child(cs)
	var vidro := MeshInstance3D.new()
	var tubo := _cilindro(RAIO_TANQUE, RAIO_TANQUE, altura)
	tubo.cap_top = false
	tubo.cap_bottom = false
	vidro.mesh = tubo
	vidro.material_override = _vidro(Color(1.0, 0.95, 0.75), 0.22)
	vidro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	vidro.position.y = baixo + altura * 0.5
	corpo.add_child(vidro)
	for k in 6:
		var anel := MeshInstance3D.new()
		var t := TorusMesh.new()
		t.inner_radius = RAIO_TANQUE - 0.1
		t.outer_radius = RAIO_TANQUE + 0.45
		t.rings = 48
		anel.mesh = t
		anel.material_override = _material(LARANJA)
		anel.position.y = baixo + 2.0 + k * 13.0
		corpo.add_child(anel)
	_malha(corpo, _cilindro(RAIO_TANQUE + 1.4, RAIO_TANQUE + 2.0, 3.0), BAIXO, Vector3(0, baixo - 1.5, 0))
	_estrelas_do_tanque = Node3D.new()
	add_child(so_enfeite(_estrelas_do_tanque))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = Forma.estrela(0.7, 0.3, 0.25)
	mm.instance_count = 170
	var g := RandomNumberGenerator.new()
	g.seed = 41
	for i in mm.instance_count:
		var a := g.randf() * TAU
		var r := sqrt(g.randf()) * (RAIO_TANQUE - 1.2)
		var b := Basis.from_euler(Vector3(g.randf() * TAU, g.randf() * TAU, 0)).scaled(Vector3.ONE * g.randf_range(0.7, 1.4))
		mm.set_instance_transform(i, Transform3D(b, Vector3(cos(a) * r, g.randf_range(baixo + 1.0, ARENA_Y - 1.5), sin(a) * r)))
	var estrelas_mm := MultiMeshInstance3D.new()
	estrelas_mm.multimesh = mm
	estrelas_mm.material_override = _brilhante(Color("ffd23f"), 2.2)
	estrelas_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_estrelas_do_tanque.add_child(estrelas_mm)
	for y in [0.0, 30.0]:
		var luz := OmniLight3D.new()
		luz.light_color = Color("ffd86a")
		luz.light_energy = 2.2
		luz.omni_range = 34.0
		luz.position.y = y
		add_child(luz)
	# A coluna de luz do marco, saindo do vidro no meio da Sala do Trono (some quando a luta começa).
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.3, 0.22)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_brilho_coluna = MeshInstance3D.new()
	_brilho_coluna.mesh = _cilindro(1.0, 4.0, 40.0)
	_brilho_coluna.material_override = mat
	_brilho_coluna.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_brilho_coluna.position = Vector3(0, ARENA_Y + 20.0, 0)
	add_child(so_enfeite(_brilho_coluna))
	brilho_do_marco = Vector3(0, ARENA_Y + 24.0, 0)


# --- 1 · Hangar do Bocal ---------------------------------------------------------------

func _hangar() -> void:
	playground("1 · Hangar do Bocal", HANGAR, 30.0, inicio)
	piso(HANGAR, Vector3(60, 1.6, 46))
	# A estação do tubo, atrás da escotilha (a escotilha tapa toda a largura dela).
	piso(Vector3(-35, 0, 82), Vector3(10, 1.6, 6))
	# O bocal do aspirador: o tubo roxo descendo do teto, por onde o Faísca chega.
	var bocal := MeshInstance3D.new()
	var b := _cilindro(3.2, 3.2, TETO - 10.0)
	b.cap_top = false
	b.cap_bottom = false
	bocal.mesh = b
	var roxo := _material(Color("7b4fd6"))
	roxo.cull_mode = BaseMaterial3D.CULL_DISABLED
	bocal.material_override = roxo
	bocal.position = Vector3(inicio.x, 10.0 + (TETO - 10.0) * 0.5, inicio.z)
	add_child(so_enfeite(bocal))
	var boca := MeshInstance3D.new()
	var tb := TorusMesh.new()
	tb.inner_radius = 3.1
	tb.outer_radius = 3.8
	boca.mesh = tb
	boca.material_override = _brilhante(Color("ff8ad8"), 1.4)
	boca.position = Vector3(inicio.x, 10.0, inicio.z)
	add_child(so_enfeite(boca))

	# As três plataformas de pouso, cada uma com a luz no meio; as de 2,5 m com um caixote de degrau, a do meio com mola.
	ponto_de_dica(Vector3(-10, 0.5, 86), 3.5, "lampada")
	for spec in [[Vector3(-16, 2.5, 76), true], [Vector3(0, 5.0, 69), false], [Vector3(16, 2.5, 76), true]]:
		var topo: Vector3 = spec[0]
		if topo.y > 2.05:
			piso(Vector3(topo.x, topo.y - 2.0, topo.z), Vector3(7, topo.y - 2.0, 7), CINZA)
		nave_peca("landingpad_large", topo - Vector3(0, 2.0, 0), 0.0, 4.0)
		var l := lampada(topo, "pouso")
		l.acendeu.connect(_luz_de_pouso)
		lampadas_pouso.append(l)
		roda(topo + Vector3.UP * 1.3, 3.2, 3)
		if spec[1]:
			caixote(Vector3(topo.x, 0, topo.z + 6.4), 1.4, 0.0)
	mola(Vector3(0, 0, 78.5), 19.0)
	estrelinha(Vector3(0, 4.2, 77))
	estrelinha(Vector3(0, 6.8, 73))
	trilha_creme([Vector3(0, 0, 103), Vector3(0, 0, 92), Vector3(-12, 0, 85), Vector3(-28, 0, 82)])
	trilha(Vector3(0, 1.2, 99), Vector3(-10, 1.2, 86), 4)
	trilha(Vector3(-19, 1.2, 83), Vector3(-27, 1.2, 82), 3)
	escotilha(Vector3(-30.5, 0, 82), 0.0)

	# Mini-marco: o dropship parado, com o coração lá no alto (a mola leva).
	nave_peca("dropship", Vector3(20, 2.75, 100), -0.6, 4.5)
	mola(Vector3(11, 0, 93), 21.0)
	coracao(Vector3(20, 8.6, 100))
	roda(Vector3(20, 1.2, 100), 7.5, 6)
	# A esteira (enfeite) com os potes de estrelas passando, atrás do bocal.
	_esteira_de_potes(Vector3(-24, 0, 109), Vector3(-6, 0, 109))
	# Bolso: o anel de caixotes, com uma brecha só, e o Faisquinha 3 lá dentro.
	var meio := Vector3(-20, 0, 97)
	for k in 10:
		if k == 0:
			continue
		var a := TAU * k / 10.0
		caixote(meio + Vector3(cos(a), 0, sin(a)) * 4.2, 2.5, -a)
	faisquinha(meio + Vector3(0, 1.5, 0), "3")
	roda(meio + Vector3(0, 1.2, 0), 1.8, 4)
	# As luzes de enfeite nos cantos e as Bolotas.
	for p in [Vector3(-28, 0, 67), Vector3(28, 0, 67), Vector3(28, 0, 109)]:
		nave_peca("lights", p, 0.0, 3.0)
	bolota(Vector3(-8, 0, 94), true)
	bolota(Vector3(7, 0, 83), false, "ciclope")


## Esteira de enfeite: a faixa escura no chão (dá para pisar) e potinhos de estrela indo de `de` até `ate` sem parar.
func _esteira_de_potes(de: Vector3, ate: Vector3) -> void:
	var comp := de.distance_to(ate)
	var faixa := piso((de + ate) * 0.5 + Vector3.UP * 0.25, Vector3(comp, 0.5, 3.0), Color("3a3150"), atan2(-(ate - de).z, (ate - de).x))
	faixa.get_child(0).remove_meta("piso")
	for k in 4:
		var pote := MeshInstance3D.new()
		pote.mesh = _cilindro(0.55, 0.55, 1.2)
		pote.material_override = _vidro(Color(0.85, 0.9, 1.0), 0.45)
		add_child(so_enfeite(pote))
		var brilho := MeshInstance3D.new()
		brilho.mesh = Forma.estrela(0.35, 0.15, 0.15)
		brilho.material_override = _brilhante(Color("ffd23f"), 1.6)
		pote.add_child(brilho)
		var tw := pote.create_tween().set_loops()
		tw.tween_interval(k * 1.6)
		tw.tween_method(func(t: float) -> void: pote.position = de.lerp(ate, t) + Vector3.UP * 1.1, 0.0, 1.0, 6.4)
		tw.tween_interval(0.0)


func _luz_de_pouso(_l: Lampada) -> void:
	if lampadas_pouso.all(func(l: Lampada) -> bool: return l.acesa):
		abrir_escotilha(escotilhas[0])
		faixa_pedida.emit("A escotilha abriu!", "A cápsula do tubo leva ao Depósito de Estrelas")


# --- viagem 1: a cápsula do tubo pneumático ------------------------------------------------

func _viagem_tubo() -> void:
	var caminho := [Vector3(-36, 0, 82), Vector3(-48, 3, 76), Vector3(-60, 6, 60), Vector3(-67, 8, 44), Vector3(-70, 8, 37)]
	tubo = carona(caminho[0], caminho[caminho.size() - 1], "capsula", 6.0, caminho)
	var acima: Array = []
	for p: Vector3 in caminho:
		acima.append(p + Vector3.UP * 1.6)
	tubo_de_vidro(acima, 2.6)


# --- 2 · Depósito de Estrelas ------------------------------------------------------------

func _deposito() -> void:
	var d := DEPOSITO
	var chegada := Vector3(-70, 8, 37)
	playground("2 · Depósito de Estrelas", d, RAIO_DEPOSITO, chegada)
	disco(d, RAIO_DEPOSITO)
	for p in PRATELEIRAS:
		arco_piso(d, 14.0, 22.0, p[1], p[2], p[0], 1.2)
	parede_curva(d, 22.4, 95.0, 300.0, d.y - 1.4, d.y + 26.0)
	posto(Vector3(-74, 8, 31))
	capsula("chiclete", em_volta(d, 70.0, 14.0, d.y))
	capsula("ioio", em_volta(d, 100.0, 18.0, 16.0))
	trilha_creme([chegada, Vector3(-75, 8, 32), em_volta(d, 120.0, 11.0, d.y)])
	ponto_de_dica(em_volta(d, 150.0, 8.0, d.y + 0.5), 3.0, "freio")
	# Os potes gigantes: três com a trava (um no chão, um em cada prateleira) e os outros de enfeite.
	for spec in [[150.0, 12.0, d.y, true], [260.0, 12.0, d.y, false], [180.0, 18.5, 16.0, true], [130.0, 18.5, 16.0, false],
			[260.0, 18.5, 24.0, true], [300.0, 18.5, 24.0, false]]:
		var p := PoteDeEstrelas.new()
		p.com_trava = spec[3]
		p.destino = Vector3(0, 30, 0)
		p.position = em_volta(d, spec[0], spec[1], spec[2])
		var para_o_meio := Vector3(d.x, 0, d.z) - Vector3(p.position.x, 0, p.position.z)
		p.rotation.y = atan2(para_o_meio.x, para_o_meio.z)
		add_child(p)
		if p.com_trava:
			p.abriu.connect(_pote_aberto)
			potes.append(p)
	# O coração na tampa do pote de enfeite da prateleira de baixo (o chiclete leva).
	coracao(em_volta(d, 130.0, 18.5, 16.0 + 4.9 + 1.4))
	# As bolhas de chiclete que quicam até a prateleira de baixo.
	for g in [120.0, 200.0]:
		var topo := em_volta(d, g, 10.0, d.y + 0.8)
		nuvem_que_quica(topo, 2.2, 21.0)
		arco(topo + Vector3.UP * 1.6, em_volta(d, g, 16.5, 17.4), 4.0, 3)
	# As argolas do ioiô, no vão entre as prateleiras, e a do nicho alto.
	argola_de_ioio(em_volta(d, 222.0, 18.0, 21.8))
	argola_de_ioio(em_volta(d, 240.0, 17.0, 25.6))
	estrelinha(em_volta(d, 222.0, 18.0, 20.4))
	estrelinha(em_volta(d, 240.0, 17.0, 24.2))
	# Bolso: o nicho alto na parede, com o V1 (só pelo ioiô, da prateleira de cima).
	piso(em_volta(d, 285.0, 20.0, 30.0), Vector3(4.4, 0.8, 4.4), LILAS_ESCURO, deg_to_rad(-285.0))
	argola_de_ioio(em_volta(d, 285.0, 17.2, 32.4))
	faisquinha(em_volta(d, 285.0, 20.0, 31.5), "0")
	for g in [278.0, 292.0]:
		estrelinha(em_volta(d, g, 20.0, 31.2))
	# Estrelinhas: a roda do meio, e uma fileira em cada prateleira.
	roda(d + Vector3.UP * 1.2, 6.0, 6)
	for g in [110.0, 145.0, 165.0, 200.0]:
		estrelinha(em_volta(d, g, 16.0, 17.2))
	for g in [245.0, 275.0, 315.0, 335.0]:
		estrelinha(em_volta(d, g, 16.0, 25.2))
	bolota(d + Vector3.UP * 5.0, false, "abelha")
	bolota(em_volta(d, 300.0, 10.0, d.y), false, "porco")
	bolota(em_volta(d, 160.0, 17.0, 16.0), false, "cogumelo")


func _pote_aberto(_p: PoteDeEstrelas) -> void:
	if not potes.all(func(p: PoteDeEstrelas) -> bool: return p.aberto):
		faixa_pedida.emit("As estrelas voltaram pro tanque!", "Faltam %d potes" % potes.filter(func(p: PoteDeEstrelas) -> bool: return not p.aberto).size())
		return
	monta_carga.travada = false
	Fx.confetti(self, monta_carga.global_position + Vector3.UP * 2.0, 40, 4.0)
	faixa_pedida.emit("O monta-carga destravou!", "Ele fica lá na prateleira de cima")


# --- viagem 2: o monta-carga --------------------------------------------------------------

func _viagem_monta_carga() -> void:
	var s := em_volta(DEPOSITO, 335.0, 18.0, 24.0)
	var caminho := [s, s + Vector3.UP * 7.0, Vector3(-64, 31, -40), Vector3(-64, 26, -48)]
	monta_carga = carona(s, caminho[caminho.size() - 1], "montacarga", 5.0, caminho)
	monta_carga.travada = true
	# A moldura laranja em volta da estação (a "saída" do depósito).
	for lado in [-1.0, 1.0]:
		var poste := MeshInstance3D.new()
		poste.mesh = _cilindro(0.25, 0.25, 6.0)
		poste.material_override = _material(LARANJA)
		poste.position = s + Vector3(lado * 2.4, 3.0, 0)
		add_child(so_enfeite(poste))
	var barra := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(5.2, 0.5, 0.5)
	barra.mesh = bm
	barra.material_override = _material(LARANJA)
	barra.position = s + Vector3(0, 6.0, 0)
	add_child(so_enfeite(barra))
	saidas.append(barra)


# --- 3 · Sala de Máquinas -----------------------------------------------------------------

func _maquinas() -> void:
	var m := MAQUINAS
	var chegada := Vector3(-64, 26, -48)
	playground("3 · Sala de Máquinas", m, 26.0, chegada)
	piso(m, Vector3(TAMANHO_MAQUINAS.x, 1.6, TAMANHO_MAQUINAS.y))
	# Paredes invisíveis em volta (sem gravidade, ninguém sai flutuando da sala), com a brecha do monta-carga.
	var x0 := m.x - TAMANHO_MAQUINAS.x * 0.5
	var x1 := m.x + TAMANHO_MAQUINAS.x * 0.5
	var z0 := m.z - TAMANHO_MAQUINAS.y * 0.5
	var z1 := m.z + TAMANHO_MAQUINAS.y * 0.5
	parede_invisivel(Vector3(x0 - 0.3, m.y + 15, m.z), Vector3(0.6, 30, TAMANHO_MAQUINAS.y))
	parede_invisivel(Vector3(x1 + 0.3, m.y + 15, m.z), Vector3(0.6, 30, TAMANHO_MAQUINAS.y))
	parede_invisivel(Vector3(m.x, m.y + 15, z0 - 0.3), Vector3(TAMANHO_MAQUINAS.x, 30, 0.6))
	var brecha := Vector2(-68.0, -60.0)
	parede_invisivel(Vector3((x0 + brecha.x) * 0.5, m.y + 15, z1 + 0.3), Vector3(brecha.x - x0, 30, 0.6))
	parede_invisivel(Vector3((brecha.y + x1) * 0.5, m.y + 15, z1 + 0.3), Vector3(x1 - brecha.y, 30, 0.6))
	posto(Vector3(-70, m.y, -51))
	capsula("martelinho", Vector3(-57, m.y, -51))
	trilha_creme([chegada, Vector3(-66, m.y, -56), Vector3(-73, m.y, -70)])
	ponto_de_dica(Vector3(-74, m.y + 0.5, -71), 3.0, "martelo")
	# Os três motores com o pino em cima e o caixote de degrau na frente.
	for x in [-74.0, -60.0, -46.0]:
		var z := -80.0 if x == -60.0 else -77.0
		var motor := MotorDaNave.new()
		motor.position = Vector3(x, m.y, z)
		add_child(motor)
		motores.append(motor)
		var p := pino(motor.topo())
		p.batido.connect(func(_p: Pino) -> void:
			motor.parar()
			_pino_do_motor())
		pinos_dos_motores.append(p)
		caixote(Vector3(x, m.y, z + 4.4), 1.8)
		estrelinha(motor.topo() + Vector3(1.8, 2.4, 1.8))
	# A esteira de enfeite e o gerador de gravidade, o anel roxo girando no meio da sala.
	_esteira_de_potes(Vector3(-84, m.y, -66), Vector3(-71, m.y, -66))
	var gerador := MeshInstance3D.new()
	gerador.name = "Gerador"
	var t := TorusMesh.new()
	t.inner_radius = 6.2
	t.outer_radius = 7.6
	t.rings = 48
	gerador.mesh = t
	gerador.material_override = _brilhante(Color("9a6bff"), 1.2)
	gerador.position = Vector3(-60, 40, -64)
	gerador.rotation.x = 1.2
	add_child(so_enfeite(gerador))
	var gira := gerador.create_tween().set_loops()
	gira.tween_property(gerador, "rotation:y", TAU, 6.0).from(0.0)
	# As caixas que sobem sem gravidade: no chão, até o momento especial; depois, uma escada no ar até a estação.
	_caixas_ar = [Vector3(-50, 30.0, -58), Vector3(-58, 35.0, -55), Vector3(-67, 40.0, -61), Vector3(-61, 45.0, -70),
		Vector3(-52, 50.0, -75)]
	for i in _caixas_ar.size():
		var ar: Vector3 = _caixas_ar[i]
		var chao := Vector3(ar.x + (2.0 if i % 2 == 0 else -2.0), m.y + 1.5, ar.z)
		_caixas_chao.append(chao)
		var c := AnimatableBody3D.new()
		c.sync_to_physics = false
		c.position = chao
		add_child(c)
		var modelo: Node3D = _cena(NAVE + "cargo_A.gltf").instantiate()
		modelo.scale = Vector3.ONE * 6.0
		modelo.position.y = -1.5
		c.add_child(modelo)
		var cs := CollisionShape3D.new()
		var forma := BoxShape3D.new()
		forma.size = Vector3(3.0, 3.0, 3.0)
		cs.shape = forma
		c.add_child(cs)
		caixas_no_ar.append(c)
		estrelinha(ar + Vector3.UP * 2.8)
	# A estação do carrinho lá no alto, com o aro da escotilha do teto.
	piso(Vector3(-45.5, 56, -80), Vector3(11, 1.0, 7), LILAS_ESCURO)
	var aro := MeshInstance3D.new()
	var ta := TorusMesh.new()
	ta.inner_radius = 3.0
	ta.outer_radius = 3.6
	aro.mesh = ta
	aro.material_override = _material(LARANJA)
	aro.position = Vector3(-48, 55.4, -80)
	add_child(so_enfeite(aro))
	saidas.append(aro)
	estrelinha(Vector3(-48, 57.4, -80))
	# Bolso: o V2 lá no alto, numa plaquinha perto do gerador (só sem gravidade se chega).
	piso(Vector3(-67, 48.4, -66), Vector3(3.4, 0.6, 3.4), LILAS_ESCURO)
	faisquinha(Vector3(-67, 50.0, -66), "1")
	estrelinha(Vector3(-65.4, 49.6, -66))
	# Bolso: a salinha de ferramentas no canto, num degrau.
	piso(Vector3(-37, 29.6, -84), Vector3(7, 3.6, 5))
	caixote(Vector3(-41.4, m.y, -79.6), 1.8)
	nave_peca("cargodepot_A", Vector3(-35.5, 29.6, -85), 0.0, 2.0)
	roda(Vector3(-38, 30.8, -83.5), 1.4, 4)
	# A sirene do teto (aparece no momento especial) e as miudezas soltas que flutuam junto.
	_sirene = Node3D.new()
	_sirene.position = Vector3(-60, 54, -66)
	_sirene.visible = false
	add_child(_sirene)
	var luz := MeshInstance3D.new()
	luz.mesh = _cilindro(0.9, 1.2, 1.2)
	luz.material_override = _brilhante(Color("ff3b4a"), 3.0)
	_sirene.add_child(luz)
	var vermelha := SpotLight3D.new()
	vermelha.light_color = Color("ff4b5a")
	vermelha.light_energy = 6.0
	vermelha.spot_range = 40.0
	vermelha.spot_angle = 30.0
	vermelha.rotation.x = -1.0
	_sirene.add_child(vermelha)
	for k in 10:
		var solta := nave_peca("containers_A" if k % 2 == 0 else "Gem_Medium", Vector3(-80 + k * 4.2, m.y, -85.6), k * 0.7, 3.0, false)
		_soltas.append(solta)
	for p in [Vector3(-56, m.y, -70), Vector3(-66, m.y, -58), Vector3(-48, m.y, -54), Vector3(-78, m.y, -56), Vector3(-40, m.y, -66)]:
		estrelinha(p + Vector3.UP * 1.2)
	guardas_da_maquinas()


func guardas_da_maquinas() -> void:
	bolota(Vector3(-50, MAQUINAS.y, -66), false, "capacete")
	bolota(Vector3(-72, MAQUINAS.y, -64), false, "alien")
	bolota(Vector3(-63, MAQUINAS.y, -59), false, "porco")


func _pino_do_motor() -> void:
	if not pinos_dos_motores.all(func(p: Pino) -> bool: return p.batido_ja):
		return
	ligar_sem_gravidade()


## O momento especial: os três motores pararam, o gerador desliga, a sirene toca e tudo flutua. As caixas sobem e viram
## uma escada no ar até a estação do carrinho; o pulo do Faísca vai alto e devagar enquanto ele estiver na sala.
func ligar_sem_gravidade() -> void:
	if sem_gravidade:
		return
	sem_gravidade = true
	faixa_pedida.emit("Sem gravidade!", "Pule de caixa em caixa até a estação lá no alto")
	_dica_uma_vez("sem_gravidade")
	Sfx.play(self, "alarme", 0.0, 0.0)
	Sfx.play(self, "sem_gravidade", 0.0, 0.0)
	_sirene.visible = true
	var gerador := get_node_or_null("Gerador") as MeshInstance3D
	if gerador:
		(gerador.material_override as StandardMaterial3D).emission_energy_multiplier = 0.1
	for i in caixas_no_ar.size():
		var c := caixas_no_ar[i]
		var tw := c.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
		tw.tween_interval(i * 0.35)
		tw.tween_property(c, "position", _caixas_ar[i], 2.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	for i in _soltas.size():
		var s := _soltas[i]
		var tw := s.create_tween()
		tw.tween_property(s, "position:y", s.position.y + 4.0 + i % 4, 3.0 + i * 0.2).set_trans(Tween.TRANS_SINE)
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j:
		j.tremidinha(0.8)


## O Faísca está na Sala de Máquinas (onde vale o sem gravidade), abaixo da estação.
func na_sala_de_maquinas(p: Vector3) -> bool:
	var x0 := MAQUINAS.x - TAMANHO_MAQUINAS.x * 0.5
	var z0 := MAQUINAS.z - TAMANHO_MAQUINAS.y * 0.5
	return p.x > x0 and p.x < x0 + TAMANHO_MAQUINAS.x and p.z > z0 and p.z < z0 + TAMANHO_MAQUINAS.y and p.y > MAQUINAS.y - 6.0 and p.y < 55.5


# --- viagem 3: o carrinho no trilho do teto -------------------------------------------------

func _viagem_carrinho() -> void:
	# Desce devagar (em descida forte, o Faísca descolava do chão do carrinho e caía) e chega pelo noroeste da estufa,
	# longe dos tubos (parado no meio, o carrinho tapava a bola de neve de quem mirava o primeiro sino).
	var caminho := [Vector3(-42.5, 56, -80), Vector3(-25, 58.5, -88), Vector3(-5, 55, -82), Vector3(12, 47, -66), Vector3(23, 40, -56),
		Vector3(29, 35.6, -51.5), Vector3(33, 34, -50)]
	carrinho_do_teto = carona(caminho[0], caminho[caminho.size() - 1], "cabine", 6.0, caminho)
	trilho_do_teto(caminho, 4.6)


# --- 4 · Estufa Gelada ---------------------------------------------------------------------

func _estufa() -> void:
	var e := ESTUFA
	var chegada := Vector3(33, e.y, -50)
	playground("4 · Estufa Gelada", e, 26.0, chegada)
	piso(Vector3(41.5, e.y, e.z), Vector3(25, 1.6, TAMANHO_ESTUFA.y))
	var gelo := piso(Vector3(66.5, e.y, e.z), Vector3(25, 1.6, TAMANHO_ESTUFA.y), GELO)
	gelo.set_meta("gelo", true)
	posto(Vector3(37, e.y, -54))
	capsula("luva", Vector3(41, e.y, -58))
	capsula("pipa", Vector3(47, e.y, -49))
	trilha_creme([chegada, Vector3(40, e.y, -62), Vector3(52, e.y, -64), Vector3(64, e.y, -57), Vector3(77, e.y, -52)])
	ponto_de_dica(Vector3(42, e.y + 0.5, -68), 3.0, "luva")
	# Os tubos de plantas (o eco module do Space Base esticado), três com um sino no alto e o maior com o V3.
	var tubos := [[Vector3(36, e.y, -80), 12.0], [Vector3(48, e.y, -82), 14.0], [Vector3(62, e.y, -80), 12.0], [Vector3(70, e.y, -60), 18.0]]
	for i in tubos.size():
		var pe: Vector3 = tubos[i][0]
		var h: float = tubos[i][1]
		nave_peca("eco_module", pe, i * 0.6, Vector3(3.0, h * 0.5, 3.0), false)
		var corpo := StaticBody3D.new()
		corpo.position = pe + Vector3.UP * h * 0.5
		add_child(corpo)
		var cs := CollisionShape3D.new()
		var forma := CylinderShape3D.new()
		forma.radius = 2.9
		forma.height = h
		cs.shape = forma
		corpo.add_child(cs)
		if i < 3:
			# O sino fica pendurado do lado de fora do tubo, perto do alto, numa prateleirinha virada para o meio da
			# estufa (em cima do tubo, o próprio tubo tapava a bola de neve de quem está no chão).
			var para := (Vector3(44, 0, -62) - Vector3(pe.x, 0, pe.z)).normalized()
			var giro := atan2(para.x, para.z)
			var apoio := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(3.4, 0.3, 2.2)
			apoio.mesh = bm
			apoio.material_override = _material(Color("3a3150"))
			apoio.position = pe + para * 3.6 + Vector3.UP * (h - 3.75)
			apoio.rotation.y = giro
			add_child(so_enfeite(apoio))
			var s := sino(pe + para * 3.7 + Vector3.UP * (h - 3.6), giro + PI / 2.0)
			s.tocou.connect(_sino_da_estufa)
			sinos_da_estufa.append(s)
			estrelinha(pe + para * 6.0 + Vector3.UP * 1.2)
	# A coluna de vento ao lado do tubo maior (com a pipa, leva ao alto dele) e o V3 lá em cima.
	coluna(Vector3(64, e.y, -60), e.y + 19.5)
	for k in 4:
		estrelinha(Vector3(64, e.y + 4.0 + k * 4.0, -60))
	faisquinha(Vector3(70, e.y + 19.5, -60), "2")
	# O lado gelado: o iglu com o coração, os bonecos de neve e uma roda de estrelinhas.
	_iglu(Vector3(70, e.y, -48), 3.4)
	coracao(Vector3(70, e.y + 1.3, -48))
	peca_de(NEVE, "snowman_A", Vector3(60, e.y, -45), 0.4, 2.4)
	peca_de(NEVE, "snowman_B", Vector3(66, e.y, -71), -0.6, 2.4)
	roda(Vector3(60, e.y + 1.2, -60), 4.0, 6)
	trilha(Vector3(36, e.y + 1.2, -50), Vector3(40, e.y + 1.2, -60), 3)
	# A porta para o corredor e a ponte de luz (aparece com os três sinos).
	escotilha(Vector3(79.6, e.y, -52), 0.0)
	_fazer_ponte_de_luz()
	bolota(Vector3(64, e.y, -70), false, "pinguim")
	bolota(Vector3(50, e.y, -74), false, "fantasma")


## Iglu com a porta virada para o oeste: a cúpula de blocos de gelo (oca e sólida, dá para entrar).
func _iglu(pe: Vector3, raio: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var lados := 24
	var andares := 8
	for i in lados:
		var a0 := TAU * i / lados
		var a1 := TAU * (i + 1) / lados
		for k in andares:
			var b0 := (PI / 2.0) * k / andares
			var b1 := (PI / 2.0) * (k + 1) / andares
			# A porta: virada para -X, nos dois andares de baixo.
			var meio := (a0 + a1) * 0.5
			if k < 3 and absf(angle_difference(meio, PI)) < 0.45:
				continue
			var p := func(a: float, b: float) -> Vector3: return pe + Vector3(cos(a) * cos(b), sin(b), sin(a) * cos(b)) * raio
			_quad(st, p.call(a0, b0), p.call(a1, b0), p.call(a1, b1), p.call(a0, b1), Vector3(cos(meio), 0.3, sin(meio)))
	var corpo := _corpo_da_malha(st.commit(), Color("f4fbff"), false)
	corpo.set_meta("superficie", "neve")


func _sino_da_estufa(_s: Sino) -> void:
	if not sinos_da_estufa.all(func(s: Sino) -> bool: return s.tocado):
		return
	abrir_escotilha(escotilhas[1])
	ponte_de_luz.show()
	ponte_de_luz.process_mode = Node.PROCESS_MODE_INHERIT
	(ponte_de_luz.get_child(1) as CollisionShape3D).set_deferred("disabled", false)
	ponte_de_luz.scale = Vector3(1, 1, 0.05)
	ponte_de_luz.create_tween().tween_property(ponte_de_luz, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_BACK)
	faixa_pedida.emit("A ponte de luz apareceu!", "Ela leva ao Corredor do Trono")


## A ponte de luz da Estufa até o começo do corredor (escondida até os três sinos).
func _fazer_ponte_de_luz() -> void:
	# 2 cm acima dos pisos onde encosta (no mesmo plano, piscava).
	var de := Vector3(78.6, ESTUFA.y + 0.02, -52)
	var ate := no_corredor(0) - frente_do_corredor(0) * 7.6 + Vector3.UP * 0.02
	ponte_de_luz = StaticBody3D.new()
	add_child(ponte_de_luz)
	ponte_de_luz.look_at_from_position((de + ate) * 0.5 + Vector3.DOWN * 0.2, ate + Vector3.DOWN * 0.2, Vector3.UP)
	var comp := de.distance_to(ate) + 0.6
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.6, 0.4, comp)
	mi.mesh = bm
	mi.material_override = _brilhante(Color("8ff3ff"), 1.6, 0.85)
	ponte_de_luz.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = bm.size
	cs.shape = forma
	cs.disabled = true
	ponte_de_luz.add_child(cs)
	ponte_de_luz.hide()
	for k in 4:
		estrelinha(de.lerp(ate, (k + 1) / 5.0) + Vector3.UP * 1.4)


# --- 5 · Corredor do Trono -----------------------------------------------------------------

func _corredor() -> void:
	var chegada := no_corredor(0) - frente_do_corredor(0) * 5.0
	playground("5 · Corredor do Trono", no_corredor(3), 50.0, chegada)
	for k in TRECHOS:
		var c := no_corredor(k)
		var f := frente_do_corredor(k)
		var fora := Vector3(c.x, 0, c.z).normalized()
		var giro := atan2(f.x, f.z)
		if k in [2, 4]:
			movel("4x4x1", "blue", c - f * 4.6, f * 9.2, 5.0, k * 0.7)
			estrelinha(c + Vector3.UP * 1.6)
		else:
			piso(c, Vector3(12, 1.2, CORREDOR_PASSO * RAIO_CORREDOR + 0.2), LILAS, giro)
			estrelinha(c + Vector3.UP * 1.4 + f * 3.0)
			if k != 3:
				# A murinha do lado de dentro (no 3 fica a brecha da cabine).
				var mur := piso(c - fora * 5.8 + Vector3.UP * 0.9, Vector3(0.4, 0.9, CORREDOR_PASSO * RAIO_CORREDOR), ROXO, giro)
				mur.get_child(0).remove_meta("piso")
		parede_invisivel(c + fora * 6.2 + Vector3.UP * 4.0, Vector3(0.4, 8.0, CORREDOR_PASSO * RAIO_CORREDOR + 0.4), giro)
	posto(no_corredor(0) - frente_do_corredor(0) * 3.0)
	# As barreiras de luz que giram e empurram (sem tirar coração), no 1 e no 5.
	for k in [1, 5]:
		var c := no_corredor(k)
		var poste := StaticBody3D.new()
		poste.position = c
		add_child(poste)
		_malha(poste, _cilindro(0.45, 0.6, 1.8), Color("2b2140"), Vector3(0, 0.9, 0))
		var cs := CollisionShape3D.new()
		var forma := CylinderShape3D.new()
		forma.radius = 0.5
		forma.height = 1.8
		cs.shape = forma
		cs.position.y = 0.9
		poste.add_child(cs)
		var barra := AnimatableBody3D.new()
		barra.sync_to_physics = false
		barra.position = c + Vector3.UP * 1.0
		add_child(barra)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(10.0, 0.5, 0.5)
		mi.mesh = bm
		mi.material_override = _brilhante(Color("8ff3ff"), 2.2)
		barra.add_child(mi)
		var cb := CollisionShape3D.new()
		var fb := BoxShape3D.new()
		fb.size = bm.size
		cb.shape = fb
		barra.add_child(cb)
		_barreiras.append(barra)
		_barreiras_centro.append(c + Vector3.UP * 1.0)
	# Os três guardas de capacete com as chaves-coroa (o 5 vai pendurado no do meio).
	for k in [0.55, 3.0, 5.6]:
		var g := bolota(no_corredor(k, -2.0), false, "capacete")
		guardas.append(g)
		g.derrotada.connect(_guarda_vencido)
		if is_equal_approx(k, 3.0):
			faisquinha_na_bolota(g, "5")
	_guardas_vivos = guardas.size()
	ponto_de_dica(no_corredor(0.6, -2.0) + Vector3.UP * 0.5, 3.0, "martelo")
	# As abelhas nas janelas.
	bolota(no_corredor(2.5, 3.0) + Vector3.UP * 3.0, false, "abelha")
	bolota(no_corredor(5.5, 3.0) + Vector3.UP * 3.0, false, "abelha")
	# Bolso: a cabine de pilotagem ao lado do 3, com o coração e o Faisquinha 4 no telhado.
	var lado := no_corredor(3, -13.0)
	var giro3 := atan2(frente_do_corredor(3).x, frente_do_corredor(3).z)
	piso(lado, Vector3(14, 1.2, 14), LILAS, giro3)
	nave_peca("basemodule_A", lado + frente_do_corredor(3) * 1.5, giro3, 3.5)
	caixote(no_corredor(3, -8.0) - frente_do_corredor(3) * 3.5, 1.8)
	coracao(lado + frente_do_corredor(3) * 1.5 + Vector3.UP * 4.9)
	faisquinha(lado + frente_do_corredor(3) * 3.5 + Vector3.UP * 5.0, "4")
	estrelinha(lado + frente_do_corredor(3) * 5.0 + Vector3.UP * 4.9)
	estrelinha(lado + frente_do_corredor(3) * -0.5 + Vector3.UP * 4.9)
	# A porta do trono no fim do corredor, com os três encaixes das chaves; atrás, o elevador.
	var f6 := frente_do_corredor(6)
	var fim := no_corredor(6) + f6 * 7.9
	porta_do_trono = StaticBody3D.new()
	porta_do_trono.position = fim
	porta_do_trono.rotation.y = atan2(f6.x, f6.z) - PI / 2.0
	add_child(porta_do_trono)
	var aro := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = 4.6
	t.outer_radius = 5.4
	aro.mesh = t
	aro.material_override = _brilhante(Color("ffd23f"), 0.6)
	aro.rotation.z = PI / 2.0
	aro.position.y = 5.0
	porta_do_trono.add_child(aro)
	var porta := MeshInstance3D.new()
	porta.name = "Porta"
	porta.mesh = _cilindro(4.65, 4.65, 0.4)
	porta.material_override = _material(Color("7b4fd6"))
	porta.rotation.z = PI / 2.0
	porta.position.y = 5.0
	porta_do_trono.add_child(porta)
	for i in 3:
		var a := TAU * i / 3.0 + PI / 2.0
		var encaixe := MeshInstance3D.new()
		encaixe.name = "Encaixe%d" % i
		encaixe.mesh = _cilindro(0.7, 0.7, 0.2)
		encaixe.material_override = _material(Color("2b2140"))
		encaixe.rotation.z = PI / 2.0
		encaixe.position = Vector3(-0.3, 5.0 + sin(a) * 2.4, cos(a) * 2.4)
		porta_do_trono.add_child(encaixe)
	var cs_porta := CollisionShape3D.new()
	cs_porta.name = "Fechada"
	var fp := BoxShape3D.new()
	fp.size = Vector3(1.0, 10.0, 12.4)
	cs_porta.shape = fp
	cs_porta.position.y = 5.0
	porta_do_trono.add_child(cs_porta)
	saidas.append(porta_do_trono)
	var plataforma := fim + f6 * 4.5
	piso(plataforma, Vector3(9, 1.2, 9), LILAS_ESCURO, atan2(f6.x, f6.z))
	var a6 := CORREDOR_A0 + 6.0 * CORREDOR_PASSO
	var alto := plataforma.y + 16.0
	var caminho := [plataforma, plataforma + Vector3.UP * 16.0, Vector3(cos(a6) * 30.0, alto, sin(a6) * 30.0),
		Vector3(cos(a6) * 21.0, alto, sin(a6) * 21.0), Vector3(cos(a6) * 21.0, ARENA_Y, sin(a6) * 21.0)]
	elevador = carona(plataforma, caminho[caminho.size() - 1], "montacarga", 7.0, caminho)
	elevador.travada = true


## Um guarda caiu: a chave-coroa dele sai voando até um encaixe da porta; com as três, a porta abre e o elevador destrava.
func _guarda_vencido(b: Alvo) -> void:
	_guardas_vivos -= 1
	var i := 2 - _guardas_vivos
	var chave := Node3D.new()
	add_child(chave)
	chave.global_position = b.global_position + Vector3.UP * 1.8
	var ouro := _brilhante(Color("ffd23f"), 1.6)
	var aro := MeshInstance3D.new()
	aro.mesh = _cilindro(0.55, 0.45, 0.4)
	aro.material_override = ouro
	chave.add_child(aro)
	for k in 3:
		var ponta := MeshInstance3D.new()
		ponta.mesh = _cilindro(0.0, 0.18, 0.5)
		ponta.material_override = ouro
		var a := TAU * k / 3.0
		ponta.position = Vector3(cos(a) * 0.42, 0.42, sin(a) * 0.42)
		chave.add_child(ponta)
	var encaixe := porta_do_trono.get_node("Encaixe%d" % clampi(i, 0, 2)) as MeshInstance3D
	var de := chave.global_position
	var tw := chave.create_tween()
	tw.tween_method(func(k: float) -> void:
		if is_instance_valid(encaixe):
			chave.global_position = de.lerp(encaixe.global_position, k) + Vector3.UP * sin(k * PI) * 5.0
			chave.rotation.y = k * TAU * 2.0, 0.0, 1.0, 1.6)
	tw.tween_callback(func() -> void:
		chave.queue_free()
		encaixe.material_override = ouro
		chaves += 1
		Sfx.play_at(self, "ui_ok", encaixe.global_position, 0.0)
		Fx.confetti(self, encaixe.global_position, 16, 2.0)
		if chaves >= 3:
			_abrir_porta_do_trono()
		else:
			faixa_pedida.emit("Uma chave-coroa!", "Faltam %d" % (3 - chaves)))


func _abrir_porta_do_trono() -> void:
	var porta := porta_do_trono.get_node("Porta") as MeshInstance3D
	var tw := porta.create_tween()
	tw.tween_property(porta, "position:y", 15.0, 1.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(porta.hide)
	(porta_do_trono.get_node("Fechada") as CollisionShape3D).set_deferred("disabled", true)
	elevador.travada = false
	Fx.confetti(self, porta_do_trono.global_position + Vector3.UP * 5.0, 60, 6.0)
	Sfx.play(self, "bandeira", 0.0, 0.0)
	faixa_pedida.emit("A porta do trono abriu!", "O elevador sobe até a Sala do Trono")


# --- a Sala do Trono e a luta --------------------------------------------------------------

## Ponto da Sala do Trono: `graus` do leste para o sul, a `r` m do meio, `y` acima do chão dela.
func no_trono(graus: float, r: float, y := 0.0) -> Vector3:
	return em_volta(Vector3.ZERO, graus, r, ARENA_Y + y)


func _sala_do_trono() -> void:
	# A Sala do Trono não entra como playground: o mundo que reage não põe caixas nem poças no meio da luta.
	var a6 := CORREDOR_A0 + 6.0 * CORREDOR_PASSO
	entrada_do_trono = Vector3(cos(a6) * 21.0, ARENA_Y, sin(a6) * 21.0)
	var chao := disco(Vector3(0, ARENA_Y, 0), RAIO_ARENA)
	chao.name = "ChaoDoTrono"
	# O vidro do tanque no meio do chão, com as estrelas brilhando por baixo.
	var vidro := MeshInstance3D.new()
	vidro.mesh = _cilindro(RAIO_TANQUE - 0.2, RAIO_TANQUE - 0.2, 0.06)
	vidro.material_override = _brilhante(Color("ffe9a0"), 1.2, 0.6)
	vidro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	vidro.position.y = ARENA_Y + 0.04
	add_child(so_enfeite(vidro))
	# A parede invisível na beira (baixa: o elevador passa por cima).
	for k in 32:
		var a := TAU * k / 32.0
		parede_invisivel(Vector3(cos(a), 0, sin(a)) * (RAIO_ARENA + 0.3) + Vector3.UP * (ARENA_Y + 2.5),
				Vector3(0.6, 5.0, 2.0 * PI * RAIO_ARENA / 32.0 + 0.6), -a)
	posto(no_trono(rad_to_deg(a6) - 8.0, 17.0))
	# Os pilares (atrás deles o cetro não puxa) e as lâmpadas apagadas.
	for g in PILARES:
		var p := StaticBody3D.new()
		p.position = no_trono(g, 13.0)
		p.set_meta("pilar", true)
		add_child(p)
		_malha(p, _cilindro(1.3, 1.5, 6.0), Color("6a4fb8"), Vector3(0, 3.0, 0))
		for y in [1.0, 5.0]:
			_malha(p, _cilindro(1.45, 1.6, 0.4), Color("ffd23f"), Vector3(0, y, 0))
		var cs := CollisionShape3D.new()
		var forma := CylinderShape3D.new()
		forma.radius = 1.4
		forma.height = 6.0
		cs.shape = forma
		cs.position.y = 3.0
		p.add_child(cs)
		pilares.append(p)
	for g in LAMPADAS:
		var l := lampada(no_trono(g, 16.0), "poste")
		l.acendeu.connect(_lampada_do_trono)
		lampadas_do_trono.append(l)
	# As grades das colunas de vento (ligam na fase 2).
	for g in COLUNAS:
		var c := coluna(no_trono(g, 19.0), ARENA_Y + TOPO_COLUNA, false)
		colunas_do_trono.append(c)
	roda(Vector3(0, ARENA_Y + 1.2, 0), 14.0, 10)
	# O trono voador e o Rei dormindo em cima.
	_fazer_trono()
	chefe = ChefeRei.new()
	chefe.name = "ReiBolotao"
	chefe.arena = self
	add_child(chefe)
	chefe.global_position = trono_topo()
	chefe.fase_mudou.connect(_fase_mudou)
	chefe.vencido.connect(_vitoria)
	# Os riscos brancos do puxão do cetro (fase 2).
	var risco := BoxMesh.new()
	risco.size = Vector3(0.1, 0.1, 2.6)
	risco.material = _brilhante(Color("ffffff"), 1.0, 0.8)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = risco
	mm.instance_count = 40
	_riscos = MultiMeshInstance3D.new()
	_riscos.multimesh = mm
	_riscos.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_riscos.visible = false
	add_child(so_enfeite(_riscos))


func _fazer_trono() -> void:
	trono = AnimatableBody3D.new()
	trono.name = "Trono"
	trono.sync_to_physics = false
	add_child(trono)
	var prata := StandardMaterial3D.new()
	prata.albedo_color = Color("c6ccd8")
	prata.metallic = 0.6
	prata.roughness = 0.3
	var disco_ := MeshInstance3D.new()
	disco_.mesh = Forma.superelipsoide(Vector3(RAIO_TRONO, 1.2, RAIO_TRONO), 0.5, 1.0)
	disco_.material_override = prata
	disco_.position.y = -0.3
	trono.add_child(disco_)
	var aro := MeshInstance3D.new()
	var t := TorusMesh.new()
	t.inner_radius = RAIO_TRONO - 0.2
	t.outer_radius = RAIO_TRONO + 0.3
	t.rings = 48
	aro.mesh = t
	aro.material_override = _brilhante(Color("ffd86a"), 1.6)
	aro.position.y = 0.3
	trono.add_child(aro)
	var bocal := MeshInstance3D.new()
	bocal.mesh = _cilindro(1.6, 2.6, 1.6)
	bocal.material_override = _material(Color("7b4fd6"))
	bocal.position.y = -1.5
	trono.add_child(bocal)
	var cs := CollisionShape3D.new()
	var forma := CylinderShape3D.new()
	forma.radius = RAIO_TRONO
	forma.height = 1.0
	cs.shape = forma
	trono.add_child(cs)
	botao_do_trono = BotaoDoTrono.new()
	botao_do_trono.position = Vector3(0, 0.5, RAIO_TRONO - 1.2)
	trono.add_child(botao_do_trono)
	botao_do_trono.apertado.connect(_botao_do_trono)
	_trono_y = ARENA_Y + TOPO_TRONO - 0.5
	trono.position = Vector3(0, _trono_y, 0)


## O topo do trono (onde o Rei fica em pé na fase 1).
func trono_topo() -> Vector3:
	if not is_instance_valid(trono):
		return Vector3(0, ARENA_Y, 0)
	return trono.global_position + Vector3.UP * 0.5


func _physics_process(delta: float) -> void:
	super(delta)
	# O trono boia e gira devagar (mexido a cada quadro, mesmo parado, por causa da física; ver o MoinhoDeGondolas).
	if is_instance_valid(trono) and not _trono_caido:
		trono.position = Vector3(0, _trono_y + sin(_tempo * 1.3) * 0.25, 0)
		trono.rotation.y = _tempo * 0.22
	for i in _barreiras.size():
		_barreiras[i].position = _barreiras_centro[i]
		_barreiras[i].rotation.y = _tempo * (1.1 if i == 0 else -1.0)
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j:
		var leve := sem_gravidade and na_sala_de_maquinas(j.global_position)
		if leve and gravidade_ligada:
			gravidade_ligada = false
			j.gravidade = _gravidade_normal * GRAVIDADE_ZERO
		elif not leve and not gravidade_ligada:
			gravidade_ligada = true
			j.gravidade = _gravidade_normal


func _process(delta: float) -> void:
	super(delta)
	if is_instance_valid(_estrelas_do_tanque):
		_estrelas_do_tanque.rotation.y += delta * 0.15
	if _sirene and _sirene.visible:
		_sirene.rotation.y += delta * 4.0
	if _comecou or vencida:
		return
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j == null or not j.controle_ligado or not j.is_on_floor():
		return
	var p := j.global_position
	if p.y < ARENA_Y - 0.5 or Vector2(p.x, p.z).length() > RAIO_ARENA:
		_espera = 1.0
		return
	_espera -= delta
	if _espera <= 0.0:
		comecar_luta()


func comecar_luta() -> void:
	if _comecou:
		return
	_comecou = true
	_brilho_coluna.hide()
	# Na luta, só os poderes dela: o ioiô (as argolas do trono) e a pipa (as colunas dos filtros). Sem o martelinho, o
	# golpe no ar volta a ser o giro (para os ferrolhos dos filtros), e sem o chiclete o laser sai na hora (as lâmpadas).
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j:
		j.tirar_poderes()
		j.ioio = true
		j.pipa = true
		Particulas.magia(self, j.global_position + Vector3.UP * 1.2, Color("b89bff"))
	# O posto da sala acende sozinho: quem perder todos os corações volta aqui, e a luta recomeça (item 14).
	if not postos.is_empty() and not postos[postos.size() - 1].acendido:
		postos[postos.size() - 1].acender()
	faixa_pedida.emit("Rei Bolotão!", "Suba pelas argolas do ioiô e soque o botão vermelho do trono")
	dica.emit("ioio")
	luta_comecou.emit()
	_fazer_argolas()
	chefe.comecar()


## O Faísca perdeu todos os corações no meio da luta (item 14): a Sala do Trono volta ao começo, com o Rei dormindo
## no trono e inteiro, as argolas, as colunas e os filtros desfeitos, as lâmpadas apagadas e a luz de volta. A luta
## começa de novo quando ele pisa na sala (o posto dela é onde ele volta).
func recomecar_luta() -> void:
	if not _comecou or vencida:
		return
	vezes_que_recomecou += 1
	for a in argolas_do_trono:
		if is_instance_valid(a):
			a.queue_free()
	argolas_do_trono.clear()
	for fl in filtros:
		if is_instance_valid(fl):
			fl.get_parent().queue_free()
	filtros.clear()
	for c in colunas_do_trono:
		c.desligar()
	for l in lampadas_do_trono:
		l.apagar()
		l.chamando = false
	_riscos.visible = false
	_ambiente.ambient_light_energy = 0.9
	_sol.light_energy = 0.95
	refazer_trono()
	chefe.reiniciar()
	_brilho_coluna.show()
	faixa_pedida.emit("De novo!", "A luta com o Rei recomeça do começo")
	_comecou = false
	_espera = 1.5


func _fazer_argolas() -> void:
	for g in ARGOLAS:
		for spec in [[13.0, 4.6], [8.4, 8.6]]:
			argolas_do_trono.append(argola_de_ioio(no_trono(g, spec[0], spec[1])))


func _fase_mudou(f: int) -> void:
	match f:
		2:
			faixa_pedida.emit("Ele ligou o aspirador!", "Atrás dos pilares ele não puxa. Com a pipa, suba nas colunas e soque os filtros")
			dica.emit("pipa")
			for a in argolas_do_trono:
				if is_instance_valid(a):
					a.queue_free()
			argolas_do_trono.clear()
			for c in colunas_do_trono:
				c.ligar()
			refazer_filtros()
			coracao(no_trono(rad_to_deg(CORREDOR_A0 + 6.0 * CORREDOR_PASSO), 14.0, 1.4))
		3:
			faixa_pedida.emit("As luzes apagaram!", "Acenda as 4 lâmpadas com o laser dos pés")
			dica.emit("lampada")
			_riscos.visible = false
			for fl in filtros:
				if is_instance_valid(fl):
					fl.get_parent().queue_free()
			filtros.clear()
			apagao()
			coracao(no_trono(rad_to_deg(CORREDOR_A0 + 6.0 * CORREDOR_PASSO), 14.0, 1.4))


# --- fase 1: o trono, o botão e os potes ---

func _botao_do_trono() -> void:
	if chefe.fase != 1 or chefe.estado != "no_trono":
		botao_do_trono.soltar()
		return
	_trono_caido = true
	Fx.confetti(self, trono.global_position, 50, 5.0)
	Sfx.play(self, "estouro", 2.0, 0.0)
	tremer_chao(trono.global_position, 0.8)
	var de := trono.position
	var tw := trono.create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.tween_property(trono, "rotation:z", 0.35, 0.3)
	tw.tween_property(trono, "position", Vector3(de.x, ARENA_Y - 6.0, de.z + 9.0), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		trono.hide()
		trono.process_mode = Node.PROCESS_MODE_DISABLED)
	chefe.cair_do_trono(Vector3(0, ARENA_Y + 0.1, 0))


## O tonto passou sem os socos: o trono sobe de novo, inteiro, e o botão volta.
func refazer_trono() -> void:
	_trono_caido = false
	trono.process_mode = Node.PROCESS_MODE_INHERIT
	trono.show()
	trono.rotation = Vector3.ZERO
	trono.position = Vector3(0, _trono_y, 0)
	botao_do_trono.soltar()
	Fx.confetti(self, trono.global_position, 30, 4.0)


## Um pote de estrelas que sai de `de` e cai onde o Faísca está, em VOO_POTE s, com o alvo rosa no chão antes. Estoura
## em estrelinhas (de enfeite) e tira coração de quem estiver em cima.
func jogar_pote(de: Vector3, alvo: Vector3) -> void:
	var espaco := get_world_3d().direct_space_state
	var chao := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(alvo + Vector3.UP * 2.0, alvo + Vector3.DOWN * 20.0, 1))
	var onde: Vector3 = chao.position if not chao.is_empty() else alvo
	var marca := MeshInstance3D.new()
	marca.mesh = _cilindro(1.6, 1.6, 0.05)
	marca.material_override = _brilhante(Color("ff5fae"), 1.2, 0.75)
	marca.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(marca)
	marca.global_position = onde + Vector3.UP * 0.05
	var pote := MeshInstance3D.new()
	pote.mesh = _cilindro(0.6, 0.6, 1.2)
	pote.material_override = _vidro(Color(0.85, 0.9, 1.0), 0.5)
	add_child(pote)
	var estrela := MeshInstance3D.new()
	estrela.mesh = Forma.estrela(0.4, 0.18, 0.15)
	estrela.material_override = _brilhante(Color("ffd23f"), 2.0)
	pote.add_child(estrela)
	pote.global_position = de
	var tw := pote.create_tween()
	tw.tween_method(func(k: float) -> void:
		pote.global_position = de.lerp(onde, k) + Vector3.UP * sin(k * PI) * 5.0
		pote.rotation.x = k * TAU, 0.0, 1.0, VOO_POTE * (1.2 if Ajustes.facil else 1.0))
	tw.tween_callback(func() -> void:
		marca.queue_free()
		pote.queue_free()
		Sfx.play_at(self, "estouro", onde, 0.0, 0.15)
		Fx.confetti(self, onde + Vector3.UP * 0.6, 22, 2.8)
		var j := get_tree().get_first_node_in_group("jogador") as Jogador
		if j:
			var d := Vector2(j.global_position.x - onde.x, j.global_position.z - onde.z).length()
			if d < 1.8 and absf(j.global_position.y - onde.y) < 1.8 and j.receber_dano(onde):
				potes_que_acertaram += 1)


func tremer_chao(onde: Vector3, forca: float) -> void:
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j:
		j.tremidinha(forca * clampf(1.0 - j.global_position.distance_to(onde) / 24.0, 0.2, 1.0))


# --- fase 2: o aspirador, as colunas e os filtros ---

## A cada quadro da fase 2 (o Rei chama): com o cetro ligado, os riscos correm para ele e o Faísca é puxado, se estiver
## no chão (ou pulando baixo), à vista dele e fora das colunas.
func aspirar(rei: ChefeRei, ligado: bool, delta: float) -> void:
	_riscos.visible = ligado
	if not ligado:
		return
	# Os redemoinhos entrando na boca do cetro (Particulas).
	_vento_do_cetro -= delta
	if _vento_do_cetro <= 0.0:
		_vento_do_cetro = 0.5
		Particulas.redemoinho(self, rei.global_position + Vector3.UP * 3.2 + rei.visual.global_basis.z.normalized() * 2.4)
	var boca := rei.global_position + Vector3.UP * 3.0
	var mm := _riscos.multimesh
	for i in mm.instance_count:
		var k := fmod(i * 0.37 + _tempo * 0.6, 1.0)
		var a := TAU * fmod(i * 0.618, 1.0)
		var r := 3.5 + 18.0 * (1.0 - k)
		var p := Vector3(rei.global_position.x + cos(a) * r, ARENA_Y + 0.6 + fmod(i * 0.29, 1.0) * 4.0, rei.global_position.z + sin(a) * r)
		var para := (boca - p).normalized()
		var b := Basis.looking_at(para, Vector3.UP if absf(para.y) < 0.95 else Vector3.RIGHT)
		mm.set_instance_transform(i, Transform3D(b.scaled(Vector3.ONE * clampf(minf(k, 1.0 - k) * 5.0, 0.0, 1.0)), p))
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	if j == null or not j.controle_ligado:
		return
	if j.global_position.y > ARENA_Y + 2.6:
		return
	# Em cima da grade de uma coluna, o puxão não pega (dá tempo de pular e flutuar).
	for c in colunas_do_trono:
		if Vector2(j.global_position.x - c.global_position.x, j.global_position.z - c.global_position.z).length() < c.raio + 0.3:
			return
	var olho := rei.global_position + Vector3.UP * 2.0
	var ate := j.global_position + Vector3.UP * 1.0
	var consulta := PhysicsRayQueryParameters3D.create(olho, ate, 1, [rei.get_rid(), j.get_rid()])
	var batida := get_world_3d().direct_space_state.intersect_ray(consulta)
	if not batida.is_empty() and (batida.collider as Node).has_meta("pilar"):
		return
	var dir := rei.global_position - j.global_position
	dir.y = 0.0
	if dir.length() < 0.5:
		return
	j.move_and_collide(dir.normalized() * PUXAO * (0.7 if Ajustes.facil else 1.0) * delta)


## Três filtros novos, no alto de cada coluna (o soco no ferrolho entope).
func refazer_filtros() -> void:
	for fl in filtros:
		if is_instance_valid(fl):
			fl.get_parent().queue_free()
	filtros.clear()
	for g in COLUNAS:
		var suporte := Node3D.new()
		add_child(suporte)
		var caixa_ := MeshInstance3D.new()
		caixa_.mesh = _cilindro(1.3, 1.3, 2.6)
		caixa_.material_override = _material(Color("6a4fb8"))
		caixa_.position = no_trono(g, 21.4, TOPO_COLUNA + 1.6)
		suporte.add_child(caixa_)
		var cano := MeshInstance3D.new()
		cano.mesh = _cilindro(0.35, 0.35, 14.0)
		cano.material_override = _material(Color("3a3150"))
		cano.position = no_trono(g, 21.4, TOPO_COLUNA + 9.9)
		suporte.add_child(cano)
		var f := Ferrolho.new()
		suporte.add_child(f)
		f.global_position = no_trono(g, 20.2, TOPO_COLUNA + 0.4)
		var para_dentro := -em_volta(Vector3.ZERO, g, 1.0, 0.0)
		f.rotation.y = atan2(para_dentro.x, para_dentro.z)
		f.aberto.connect(_filtro_aberto)
		filtros.append(f)
		estrelinha_de_enfeite(f.global_position + Vector3.UP * 2.0)


## Um brilho que não conta (para a luta não mudar o total de estrelinhas da fase).
func estrelinha_de_enfeite(p: Vector3) -> void:
	var e := MeshInstance3D.new()
	e.mesh = Forma.estrela(0.35, 0.15, 0.12)
	e.material_override = _brilhante(Color("ffd23f"), 2.0)
	add_child(e)
	e.global_position = p
	var tw := e.create_tween().set_loops()
	tw.tween_property(e, "rotation:y", TAU, 2.0).from(0.0)


func _filtro_aberto(_f: Ferrolho) -> void:
	if chefe.fase != 2 or not filtros.all(func(f: Ferrolho) -> bool: return f.aberto_ja):
		return
	# O aspirador entope e estoura numa nuvem de poeira.
	_riscos.visible = false
	var boca := chefe.global_position + Vector3.UP * 4.0
	for k in 4:
		Fx.confetti(self, boca + Vector3(randf_range(-3, 3), randf_range(0, 3), randf_range(-3, 3)), 30, 5.0)
	Sfx.play(self, "estouro", 4.0, 0.0)
	tremer_chao(boca, 1.0)
	faixa_pedida.emit("O aspirador entupiu!", "Soque o Rei enquanto ele está tonto")
	chefe.entupir()


# --- fase 3: o apagão e as lâmpadas ---

## A poeira apaga as luzes: a sala fica no escuro (só o tanque brilha embaixo) e as lâmpadas piscam fraquinho.
func apagao() -> void:
	Sfx.play(self, "interruptor", 2.0, 0.0)
	# As que o Faísca acendeu antes (passando por cima) apagam junto: no escuro, as quatro pedem o laser de novo.
	for l in lampadas_do_trono:
		l.apagar()
	var tw := create_tween()
	tw.tween_property(_ambiente, "ambient_light_energy", 0.14, 0.6)
	tw.parallel().tween_property(_sol, "light_energy", 0.04, 0.6)
	for l in lampadas_do_trono:
		l.chamando = true


func _lampada_do_trono(_l: Lampada) -> void:
	if chefe.fase != 3:
		return
	var acesas := lampadas_do_trono.filter(func(l: Lampada) -> bool: return l.acesa).size()
	create_tween().tween_property(_ambiente, "ambient_light_energy", 0.14 + acesas * 0.12, 0.5)
	chefe.acalmar(acesas)
	if acesas < 4:
		faixa_pedida.emit("Uma lâmpada acesa!", "Faltam %d" % (4 - acesas))


# --- a vitória: a estrelinha de bolso ---

## As quatro lâmpadas acesas: o Rei senta e chora. A cena (sem controle): ele conta que só queria uma luzinha pra dormir,
## o Faísca dá a estrelinha de bolso, as luzes voltam e as estrelas saem do tanque pela cúpula. Depois, o FaiscaJogo
## faz o final lá fora (`final_pedido`).
func _vitoria() -> void:
	vencida = true
	var t := 0.25 if rapido else 1.0
	var j := get_tree().get_first_node_in_group("jogador") as Jogador
	var rei := chefe
	if j:
		j.controle_ligado = false
		j.golpe_atual = -1
		j.velocity = Vector3.ZERO
	await get_tree().create_timer(0.6 * t).timeout
	# O Faísca na frente do Rei, e a câmera de lado, enquadrando os dois.
	var frente := rei.visual.global_basis.z
	frente.y = 0.0
	frente = frente.normalized() if frente.length() > 0.1 else Vector3.BACK
	var cam := Camera3D.new()
	cam.fov = 55.0
	add_child(cam)
	if j:
		j.teleportar(rei.global_position + frente * 7.5 + Vector3.UP * 0.1)
		var olhar := rei.global_position - j.global_position
		j.visual.rotation.y = atan2(olhar.x, olhar.z)
		j.robo.animar("geral/Idle_A", 0.2)
	var lado := frente.cross(Vector3.UP).normalized()
	var meio := rei.global_position + frente * 3.8 + Vector3.UP * 3.0
	cam.global_position = meio + lado * 14.0 + frente * 4.0 + Vector3.UP * 2.0
	cam.look_at(meio)
	cam.make_current()
	faixa_pedida.emit("Buáá! Tá escuro...", "O Rei Bolotão tem medo do escuro")
	await get_tree().create_timer(3.2 * t).timeout
	faixa_pedida.emit("Eu só queria uma luzinha pra dormir...", "Por isso ele pegou as estrelas do céu")
	await get_tree().create_timer(3.4 * t).timeout
	# A estrelinha de bolso: sai do Faísca e voa até a mão do Rei.
	var estrela := MeshInstance3D.new()
	estrela.mesh = Forma.estrela(0.6, 0.26, 0.22)
	estrela.material_override = _brilhante(Color("ffd23f"), 3.0)
	add_child(estrela)
	var de := (j.global_position if j else rei.global_position) + Vector3.UP * 2.4
	estrela.global_position = de
	var luz := OmniLight3D.new()
	luz.light_color = Color("ffd86a")
	luz.light_energy = 2.0
	luz.omni_range = 6.0
	estrela.add_child(luz)
	if j:
		j.robo.animar("festa/Cheering", 0.2)
		j.robo.expressao("feliz", 3.0)
	Sfx.play(self, "faisquinha_salvo", 0.0, 0.0)
	var mao := rei.global_position + frente * 2.6 + Vector3.UP * 3.0
	var tw := estrela.create_tween()
	tw.tween_method(func(k: float) -> void:
		estrela.global_position = de.lerp(mao, k) + Vector3.UP * sin(k * PI) * 2.0
		estrela.rotation.y = k * TAU * 2.0, 0.0, 1.0, 1.4 * maxf(t, 0.5))
	await tw.finished
	faixa_pedida.emit("Uma estrelinha de bolso!", "Agora o Rei tem uma luzinha só dele")
	rei.alegrar()
	var gira := estrela.create_tween().set_loops()
	gira.tween_property(estrela, "rotation:y", TAU, 2.0).from(0.0)
	# As luzes voltam.
	var volta := create_tween()
	volta.tween_property(_ambiente, "ambient_light_energy", 0.9, 1.0)
	volta.parallel().tween_property(_sol, "light_energy", 0.95, 1.0)
	await get_tree().create_timer(3.0 * t).timeout
	# As estrelas saem do tanque pelo vidro do chão e sobem pela cúpula, de volta para o céu.
	faixa_pedida.emit("As estrelas vão voltar pro céu!", "O tanque abriu")
	cam.global_position = Vector3(0, ARENA_Y + 6.0, 0) + lado * 30.0 + frente * 10.0
	cam.look_at(Vector3(0, ARENA_Y + 16.0, 0))
	Sfx.play(self, "bandeira", 0.0, 0.0)
	for k in 46:
		var e := MeshInstance3D.new()
		e.mesh = Forma.estrela(0.6, 0.26, 0.22)
		e.material_override = _brilhante(Color("ffd23f"), 2.6)
		add_child(e)
		var a := randf() * TAU
		var r := randf() * (RAIO_TANQUE - 2.0)
		var inicio_e := Vector3(cos(a) * r, ARENA_Y + 0.2, sin(a) * r)
		var fim_e := Vector3(cos(a) * r * 2.4, ARENA_Y + 34.0 + randf() * 10.0, sin(a) * r * 2.4)
		e.global_position = inicio_e
		e.scale = Vector3.ONE * 0.01
		var sobe := e.create_tween()
		sobe.tween_interval(randf() * 2.2 * t)
		sobe.tween_property(e, "scale", Vector3.ONE, 0.2)
		sobe.tween_property(e, "global_position", fim_e, 2.2 * maxf(t, 0.5)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		sobe.tween_callback(e.queue_free)
	_estrelas_do_tanque.create_tween().tween_property(_estrelas_do_tanque, "scale", Vector3(1.0, 0.02, 1.0), 3.0 * maxf(t, 0.5))
	await get_tree().create_timer(4.2 * t).timeout
	cena_do_final = 1.0
	final_pedido.emit()
