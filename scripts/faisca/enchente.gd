class_name Enchente
extends Node3D
## A cozinha alagando, o momento especial da 2-1 (item 9 da lista do Faísca, 2026-11-11): cada registro girado solta
## mais água, a pia transborda (a cascata na frente dela e o jorro da torneira) e o chão da cozinha inteiro enche, em
## três etapas, abaixo dos tampos. O que boia (as `Boia`) sobe junto e vira caminho. Encostar na água é cair, como
## na pia. Antes da primeira etapa a água fica escondida embaixo do chão (e vale o "chão é lava" de sempre).

signal subindo(etapa: int)
signal parou(etapa: int)

## Altura da água em cada etapa (fora das alturas de tampo das peças, para a água não ficar no mesmo plano delas).
var niveis: Array[float] = [3.1, 5.2, 7.2]
var etapa := 0
var nivel := -0.6
var subindo_agora := false
## O chão da sala (x, z) e o buraco da cuba da pia, onde a água da pia já está (a da enchente não aparece lá dentro).
var sala := Rect2(-63, -127, 126, 134)
var buraco := Rect2(16, -91.7, 12, 35.7)
## A cascata: na face de fora da pia (x), de z0 a z1, caindo do tampo (`borda`).
var cascata_x := 30.05
var cascata_z := Vector2(-90.5, -57.5)
var borda := 8.0
## O bico da torneira (onde começa o jorro) e a água da pia (que sobe até perto da borda).
var bico := Vector3(27.5, 9.8, -87.1)
var agua_da_pia: Node3D
var boias: Array[Boia] = []

var _superficie: Node3D
var _area: Area3D
var _forma: BoxShape3D
var _cascata: MeshInstance3D
var _quadro_cascata: QuadMesh
var _jorro: MeshInstance3D
var _espuma_da_cascata: Node3D
var _som: AudioStreamPlayer3D


func _ready() -> void:
	var agua := StandardMaterial3D.new()
	agua.albedo_color = Color(0.55, 0.82, 1.0, 0.72)
	agua.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	agua.roughness = 0.1
	agua.metallic = 0.2
	_superficie = Node3D.new()
	add_child(Fase.so_enfeite(_superficie))
	# Quatro retângulos em volta do buraco da cuba.
	var partes := [
		Rect2(sala.position.x, sala.position.y, sala.size.x, buraco.position.y - sala.position.y),
		Rect2(sala.position.x, buraco.end.y, sala.size.x, sala.end.y - buraco.end.y),
		Rect2(sala.position.x, buraco.position.y, buraco.position.x - sala.position.x, buraco.size.y),
		Rect2(buraco.end.x, buraco.position.y, sala.end.x - buraco.end.x, buraco.size.y),
	]
	for r: Rect2 in partes:
		var mi := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = r.size
		mi.mesh = pm
		mi.material_override = agua
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(r.get_center().x, 0, r.get_center().y)
		_superficie.add_child(mi)
	# Espuma: bolinhas brancas boiando, espalhadas pela sala (fora da cuba).
	var espuma := StandardMaterial3D.new()
	espuma.albedo_color = Color("f4fbff")
	espuma.roughness = 0.9
	var g := RandomNumberGenerator.new()
	g.seed = 2101
	for i in 160:
		var p := Vector2(g.randf_range(sala.position.x + 1, sala.end.x - 1), g.randf_range(sala.position.y + 1, sala.end.y - 1))
		if buraco.grow(1.0).has_point(p):
			continue
		var bola := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = g.randf_range(0.3, 0.9)
		esfera.height = esfera.radius * 1.1
		bola.mesh = esfera
		bola.material_override = espuma
		bola.position = Vector3(p.x, 0.04, p.y)
		_superficie.add_child(bola)
	_superficie.position.y = nivel
	_superficie.visible = false
	# A água que derruba: uma caixa da sala inteira, do fundo até um tiquinho abaixo da superfície.
	_area = Area3D.new()
	_area.collision_layer = 0
	_area.collision_mask = Fase.CAMADA_JOGADOR
	_area.monitoring = false
	var cs := CollisionShape3D.new()
	_forma = BoxShape3D.new()
	cs.shape = _forma
	_area.add_child(cs)
	add_child(_area)
	_area.body_entered.connect(_mergulhou)
	_ajustar_area()
	# A cascata na frente da pia e o jorro da torneira (aparecem na primeira etapa).
	var mat_cascata := ShaderMaterial.new()
	mat_cascata.shader = load("res://scripts/faisca/cascata.gdshader")
	_cascata = MeshInstance3D.new()
	_quadro_cascata = QuadMesh.new()
	_cascata.mesh = _quadro_cascata
	_cascata.material_override = mat_cascata
	_cascata.rotation.y = PI / 2.0
	_cascata.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cascata.visible = false
	add_child(Fase.so_enfeite(_cascata))
	var mat_jorro := ShaderMaterial.new()
	mat_jorro.shader = mat_cascata.shader
	mat_jorro.set_shader_parameter("faixas", 4.0)
	mat_jorro.set_shader_parameter("velocidade", 2.6)
	_jorro = MeshInstance3D.new()
	var cil := CylinderMesh.new()
	cil.top_radius = 0.32
	cil.bottom_radius = 0.42
	cil.height = bico.y - 7.4
	_jorro.mesh = cil
	_jorro.material_override = mat_jorro
	_jorro.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_jorro.position = Vector3(bico.x, (bico.y + 7.4) * 0.5, bico.z)
	_jorro.visible = false
	add_child(Fase.so_enfeite(_jorro))
	# A espuma onde a cascata bate na água: bolas brancas numa fileira, na frente dela.
	_espuma_da_cascata = Node3D.new()
	_espuma_da_cascata.visible = false
	add_child(Fase.so_enfeite(_espuma_da_cascata))
	var n_bolas := int(absf(cascata_z.y - cascata_z.x) / 1.6)
	for i in n_bolas:
		var bola := MeshInstance3D.new()
		var esfera := SphereMesh.new()
		esfera.radius = g.randf_range(0.6, 1.1)
		esfera.height = esfera.radius * 1.2
		bola.mesh = esfera
		bola.material_override = espuma
		bola.position = Vector3(cascata_x + g.randf_range(0.3, 1.2), 0.1, cascata_z.x + (i + 0.5) * absf(cascata_z.y - cascata_z.x) / n_bolas)
		_espuma_da_cascata.add_child(bola)
	_ajustar_cascata()


## Mais uma etapa: a água sobe até o próximo nível (devagar), com o som da água correndo mais alto enquanto sobe.
func subir() -> void:
	if etapa >= niveis.size():
		return
	etapa += 1
	subindo_agora = true
	_superficie.visible = true
	_cascata.visible = true
	_jorro.visible = true
	_espuma_da_cascata.visible = true
	_area.monitoring = true
	if etapa == 1 and agua_da_pia:
		create_tween().tween_property(agua_da_pia, "position:y", agua_da_pia.position.y + 0.45, 2.0)
	if _som == null:
		_som = Sfx.play_at(self, "enchente", Vector3(cascata_x + 2.0, 5.0, (cascata_z.x + cascata_z.y) * 0.5), -4.0, 0.0)
		if _som:
			_som.max_distance = 90.0
			_som.unit_size = 14.0
			_som.finished.disconnect(_som.queue_free)
			_som.finished.connect(_som.play)
	if _som:
		create_tween().tween_property(_som, "volume_db", 0.0, 0.5)
	subindo.emit(etapa)
	var alvo: float = niveis[etapa - 1]
	var tempo := clampf((alvo - nivel) / 0.7, 2.5, 6.0)
	var tw := create_tween()
	tw.tween_property(self, "nivel", alvo, tempo).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		subindo_agora = false
		if _som:
			create_tween().tween_property(_som, "volume_db", -12.0, 1.5)
		parou.emit(etapa))


## Pula para uma etapa já cheia (os testes e as fotos).
func encher_ate(e: int) -> void:
	etapa = e
	nivel = niveis[e - 1] if e > 0 else -0.6
	var cheia := e > 0
	_superficie.visible = cheia
	_cascata.visible = cheia
	_jorro.visible = cheia
	_espuma_da_cascata.visible = cheia
	_area.monitoring = cheia


func _physics_process(_delta: float) -> void:
	_superficie.position.y = nivel
	_ajustar_area()
	_ajustar_cascata()


func _ajustar_area() -> void:
	var fundo := -6.0
	var topo := nivel - 0.3
	_forma.size = Vector3(sala.size.x, maxf(topo - fundo, 0.1), sala.size.y)
	_area.position = Vector3(sala.get_center().x, (topo + fundo) * 0.5, sala.get_center().y)


func _ajustar_cascata() -> void:
	var altura := maxf(borda - maxf(nivel, 0.0), 0.2)
	_quadro_cascata.size = Vector2(absf(cascata_z.y - cascata_z.x), altura)
	_cascata.position = Vector3(cascata_x, borda - altura * 0.5, (cascata_z.x + cascata_z.y) * 0.5)
	_espuma_da_cascata.position.y = maxf(nivel, 0.0) + sin(Time.get_ticks_msec() / 180.0) * 0.06


func _mergulhou(corpo: Node3D) -> void:
	if corpo is Jogador and etapa > 0:
		Fx.confetti(get_parent(), corpo.global_position, 20, 3.0)
		Sfx.play_at(get_parent(), "poca", corpo.global_position, 0.0)
		(corpo as Jogador).cair()
