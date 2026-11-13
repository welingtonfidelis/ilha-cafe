class_name Cachoeira
extends Node3D
## Cachoeira que congela (3-1 Pico Gelado, 2026-10-30): a água cai de uma pedra lá no alto, no meio do vão entre duas
## plataformas da Encosta das Avalanches, e quem tenta passar por ela é empurrado de volta para o lado de onde veio
## (sem perder coração). Com o sino da pedra tocado pela bola de neve (Sino.tocou -> congelar), a água vira gelo num
## estalo e a rampa de gelo sobe de `de` até `ate` (as beiradas das duas plataformas, na altura do chão), escorregadia
## como todo gelo. A fase põe o nó no meio do vão; `topo` é a altura de onde a água sai e `fundo`, até onde ela cai.

const EMPURRAO := 7.0

var de := Vector3.ZERO
var ate := Vector3.ZERO
var topo := 0.0
var fundo := 0.0
var largura := 3.2
var congelada := false
var rampa: StaticBody3D
var _agua: MeshInstance3D
var _mat_agua: StandardMaterial3D
var _area: Area3D
var _tempo := 0.0


func _ready() -> void:
	var alt := topo - fundo
	_mat_agua = StandardMaterial3D.new()
	_mat_agua.albedo_texture = _listras()
	_mat_agua.albedo_color = Color(0.55, 0.85, 1.0, 0.72)
	_mat_agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat_agua.roughness = 0.1
	_mat_agua.emission_enabled = true
	_mat_agua.emission = Color("7fd3ff")
	_mat_agua.emission_energy_multiplier = 0.25
	_mat_agua.uv1_scale = Vector3(1.0, alt / 6.0, 1.0)
	_agua = MeshInstance3D.new()
	var caixa := BoxMesh.new()
	caixa.size = Vector3(largura, alt, 1.2)
	_agua.mesh = caixa
	_agua.material_override = _mat_agua
	_agua.position.y = fundo + alt * 0.5 - global_position.y
	# A água se atravessa (empurra de volta pela área).
	add_child(Fase.so_enfeite(_agua))
	var dir := Vector3(ate.x - de.x, 0, ate.z - de.z).normalized()
	_agua.rotation.y = atan2(dir.x, dir.z) + PI / 2.0
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Fase.CAMADA_JOGADOR
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(largura + 0.6, alt, 2.0)
	cs.shape = forma
	cs.position = _agua.position
	cs.rotation.y = _agua.rotation.y
	_area.add_child(cs)
	add_child(_area)
	_area.body_entered.connect(_molhou)
	_montar_rampa()


func _process(delta: float) -> void:
	if congelada:
		return
	_tempo += delta
	_mat_agua.uv1_offset.y = -_tempo * 1.6


## A rampa de gelo, escondida e sem colisão até a água congelar.
func _montar_rampa() -> void:
	var dir := (ate - de).normalized()
	var lado := Vector3.UP.cross(dir).normalized()
	var cima := dir.cross(lado).normalized()
	var comprimento := de.distance_to(ate)
	rampa = StaticBody3D.new()
	Gelo.marcar(rampa)
	var mi := MeshInstance3D.new()
	var malha := BoxMesh.new()
	malha.size = Vector3(largura, 0.5, comprimento)
	mi.mesh = malha
	mi.material_override = Gelo.material()
	rampa.add_child(mi)
	var cs := CollisionShape3D.new()
	var forma := BoxShape3D.new()
	forma.size = Vector3(largura, 0.5, comprimento)
	cs.shape = forma
	cs.disabled = true
	rampa.add_child(cs)
	rampa.visible = false
	get_parent().add_child.call_deferred(rampa)
	rampa.set_meta("lugar", Transform3D(Basis(lado, cima, dir), (de + ate) * 0.5 - cima * 0.25))
	rampa.transform = rampa.get_meta("lugar")


## Encostou na água: volta para o lado de onde veio, um pouco para cima.
func _molhou(corpo: Node3D) -> void:
	if not corpo is Jogador or congelada:
		return
	var meio := (de + ate) * 0.5
	var volta := (de - meio) if corpo.global_position.distance_to(de) < corpo.global_position.distance_to(ate) else (ate - meio)
	volta.y = 0.0
	(corpo as Jogador).empurrar(volta.normalized() * EMPURRAO + Vector3.UP * 4.0)
	Sfx.play_at(get_parent(), "splash", corpo.global_position, -4.0)


## O sino tocou: a água vira gelo e some num estalo, e a rampa de gelo cresce no vão.
func congelar(_sino: Sino = null) -> void:
	if congelada:
		return
	congelada = true
	_area.set_deferred("monitoring", false)
	Sfx.play_at(get_parent(), "gelo", global_position, 2.0)
	_mat_agua.albedo_color = Color(0.85, 0.96, 1.0, 0.9)
	_mat_agua.emission = Color("e9f7ff")
	var tw := create_tween()
	tw.tween_interval(0.25)
	tw.tween_property(_agua, "scale", Vector3(1.0, 0.02, 1.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(_agua.hide)
	# Só o desenho cresce (corpo com escala torta confunde a física); a colisão liga quando ela termina de crescer.
	var desenho := rampa.get_child(0) as MeshInstance3D
	rampa.visible = true
	desenho.scale = Vector3(1.0, 1.0, 0.05)
	var cresce := rampa.create_tween()
	cresce.tween_interval(0.25)
	cresce.tween_property(desenho, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	cresce.tween_callback(func() -> void: (rampa.get_child(1) as CollisionShape3D).disabled = false)
	Fx.confetti(get_parent(), (de + ate) * 0.5 + Vector3.UP, 30, 4.0)


## A rampa já está no lugar (testes).
func rampa_pronta() -> bool:
	return congelada and not (rampa.get_child(1) as CollisionShape3D).disabled


## Listras verticais da água, que descem (a textura anda em `_process`).
func _listras() -> ImageTexture:
	var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0.75))
	var gerador := RandomNumberGenerator.new()
	gerador.seed = 5
	for i in 7:
		var x := gerador.randi_range(0, 31)
		var y0 := gerador.randi_range(0, 63)
		for k in gerador.randi_range(14, 40):
			img.set_pixel(x, (y0 + k) % 64, Color(1, 1, 1, 1))
	return ImageTexture.create_from_image(img)
