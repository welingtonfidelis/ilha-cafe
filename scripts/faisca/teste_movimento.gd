class_name TesteMovimento
extends RefCounted
## Medidas do movimento do Faísca (pedido do usuário em 2026-11-10: "movimentos mais fluidos e ágeis estilo o
## Astro Bot"). Monta uma pista lisa de 150 m longe do resto e mede, com o controle simulado (forcar_direcao e
## forcar_pulo): o tempo até a velocidade máxima, o tempo e a distância para parar, o tempo para inverter a
## corrida e para o corpo virar, a altura do pulo curto e do pulo segurando (sem o laser), a distância do pulo mais
## longo (correndo, segurando o pulo e flutuando) e quanto ele consegue voltar no ar. Imprime "MEDIDA nome valor" e
## confere cada uma contra o alvo (as fases dependem da altura e da distância: não podem crescer).
## Uso: godot --headless --path . -- --faisca-movimento

const PISTA := Vector3(300, 0, 0)

## Alvos: [nome, mínimo, máximo] (INF quando não tem).
const ALVOS := [
	["acelerar_90", 0.0, 0.16],
	["parar_tempo", 0.0, 0.2],
	["parar_distancia", 0.0, 0.6],
	["inverter_tempo", 0.0, 0.22],
	["virar_corpo", 0.0, 0.12],
	["pulo_curto", 0.6, 1.2],
	["pulo_alto", 2.0, 2.35],
	["pulo_longo", 10.0, 12.25],
	["voltar_no_ar", 4.0, INF],
]

var solo: Node
var j: Jogador
var medidas := {}


func _init(s: Node) -> void:
	solo = s
	j = solo.jogador


func rodar() -> void:
	var tree := solo.get_tree()
	var pista := StaticBody3D.new()
	var forma := CollisionShape3D.new()
	var caixa := BoxShape3D.new()
	caixa.size = Vector3(30, 2, 150)
	forma.shape = caixa
	pista.add_child(forma)
	solo.add_child(pista)
	pista.global_position = PISTA + Vector3(0, -1, 0)
	await _esperar(0.3)
	await _medir_corrida()
	await _medir_pulos()
	await _medir_pulo_longo()
	await _medir_ar()
	var tudo_ok := true
	for alvo in ALVOS:
		var v: float = medidas.get(alvo[0], -1.0)
		var ok: bool = v >= float(alvo[1]) and v <= float(alvo[2])
		print("%s %s %.3f (alvo %s a %s)" % ["OK    " if ok else "FALHOU", alvo[0], v, str(alvo[1]), str(alvo[2])])
		tudo_ok = tudo_ok and ok
	print("MOVIMENTO OK" if tudo_ok else "MOVIMENTO COM FALHAS")
	tree.quit()


func _esperar(s: float) -> void:
	var t := 0.0
	while t < s:
		await solo.get_tree().physics_frame
		t += solo.get_physics_process_delta_time()


## Começa perto do fim de +Z: para a frente (-Z) sobram uns 130 m de pista.
func _zerar(z := 60.0) -> void:
	j.forcar_direcao = Vector2.ZERO
	j.forcar_pulo = false
	j.teleportar(PISTA + Vector3(0, 0.1, z))
	j.velocity = Vector3.ZERO
	j.yaw = 0.0
	await _esperar(0.4)


func _vel_h() -> float:
	return Vector2(j.velocity.x, j.velocity.z).length()


func _medida(nome: String, valor: float) -> void:
	medidas[nome] = valor
	print("MEDIDA %s %.3f" % [nome, valor])


## Para a frente (-Z do mundo, a câmera olhando para lá): acelerar, parar, inverter e o corpo virar.
func _medir_corrida() -> void:
	await _zerar()
	var dt := solo.get_physics_process_delta_time()
	j.forcar_direcao = Vector2(0, -1)
	var t := 0.0
	while _vel_h() < j.velocidade * 0.9 and t < 2.0:
		await solo.get_tree().physics_frame
		t += dt
	_medida("acelerar_90", t)
	await _esperar(0.6)
	var de := j.global_position
	j.forcar_direcao = Vector2.ZERO
	t = 0.0
	while _vel_h() > 0.3 and t < 2.0:
		await solo.get_tree().physics_frame
		t += dt
	_medida("parar_tempo", t)
	_medida("parar_distancia", Vector2(j.global_position.x - de.x, j.global_position.z - de.z).length())
	await _zerar()
	j.forcar_direcao = Vector2(0, -1)
	await _esperar(0.8)
	j.forcar_direcao = Vector2(0, 1)
	t = 0.0
	var corpo := -1.0
	var inverteu := -1.0
	while t < 1.5 and (corpo < 0.0 or inverteu < 0.0):
		await solo.get_tree().physics_frame
		t += dt
		# O corpo olha para +Z do modelo: virado para trás (+Z do mundo) é rotation.y perto de 0.
		if corpo < 0.0 and absf(wrapf(j.visual.rotation.y, -PI, PI)) < deg_to_rad(30.0):
			corpo = t
		if inverteu < 0.0 and j.velocity.z > j.velocidade * 0.5:
			inverteu = t
	_medida("inverter_tempo", inverteu if inverteu >= 0.0 else 2.0)
	_medida("virar_corpo", corpo if corpo >= 0.0 else 2.0)
	j.forcar_direcao = Vector2.ZERO


## Pulo curto (um toque) e pulo alto (segurando até o topo, sem chegar a flutuar).
func _medir_pulos() -> void:
	await _zerar()
	var y0 := j.global_position.y
	j.forcar_pulo = true
	await solo.get_tree().physics_frame
	await solo.get_tree().physics_frame
	j.forcar_pulo = false
	var topo := y0
	var t := 0.0
	while t < 2.5:
		await solo.get_tree().physics_frame
		t += solo.get_physics_process_delta_time()
		topo = maxf(topo, j.global_position.y)
		if t > 0.2 and j.is_on_floor():
			break
	_medida("pulo_curto", topo - y0)
	await _zerar()
	y0 = j.global_position.y
	j.forcar_pulo = true
	topo = y0
	t = 0.0
	while t < 2.5:
		await solo.get_tree().physics_frame
		t += solo.get_physics_process_delta_time()
		topo = maxf(topo, j.global_position.y)
		if t > 0.15 and j.velocity.y <= 0.0:
			j.forcar_pulo = false
		if t > 0.2 and j.is_on_floor():
			break
	_medida("pulo_alto", topo - y0)
	_medida("tempo_no_ar", t)


## O pulo mais longo: correndo, pula segurando e continua segurando (flutua com o laser) até pousar.
func _medir_pulo_longo() -> void:
	await _zerar()
	j.forcar_direcao = Vector2(0, -1)
	await _esperar(0.8)
	var de := j.global_position
	j.forcar_pulo = true
	var t := 0.0
	while t < 5.0:
		await solo.get_tree().physics_frame
		t += solo.get_physics_process_delta_time()
		if t > 0.2 and j.is_on_floor():
			break
	j.forcar_pulo = false
	j.forcar_direcao = Vector2.ZERO
	_medida("pulo_longo", Vector2(j.global_position.x - de.x, j.global_position.z - de.z).length())


## Controle no ar: pula para a frente correndo e, no topo, puxa para trás; mede quanto a velocidade virou em 0,35 s.
func _medir_ar() -> void:
	await _zerar()
	j.forcar_direcao = Vector2(0, -1)
	await _esperar(0.8)
	j.forcar_pulo = true
	var t := 0.0
	while t < 1.5 and not (t > 0.1 and j.velocity.y <= 0.5):
		await solo.get_tree().physics_frame
		t += solo.get_physics_process_delta_time()
	j.forcar_pulo = false
	var antes := j.velocity.z
	j.forcar_direcao = Vector2(0, 1)
	await _esperar(0.35)
	_medida("voltar_no_ar", j.velocity.z - antes)
	j.forcar_direcao = Vector2.ZERO
	await _esperar(1.0)


## Fotos do movimento (com janela), em tools/capturas/faisca/movimento/: correndo de lado na ilha de teste, a
## curva (inclinado), a derrapada (poeira e corpo para trás), o pulo saindo (esticado) e o pouso (achatado).
## Uso: godot --path . -- --faisca-movimento-captura
func capturar() -> void:
	var dir := ProjectSettings.globalize_path("res://tools/capturas/faisca/movimento/")
	DirAccess.make_dir_recursive_absolute(dir)
	await _esperar(0.8)
	j.teleportar(Vector3(-9, 0.1, 13))
	j.yaw = 0.0
	j.pitch = -0.28
	await _esperar(0.5)
	j.forcar_direcao = Vector2(1, 0)
	await _esperar(0.55)
	j.forcar_direcao = Vector2(0.75, -0.66)
	await _esperar(0.12)
	await _foto(dir + "mov_1_curva.png")
	j.forcar_direcao = Vector2(1, 0)
	await _esperar(0.5)
	j.forcar_direcao = Vector2(-1, 0)
	await _esperar(0.05)
	await _foto(dir + "mov_2_derrapada.png")
	j.forcar_direcao = Vector2.ZERO
	await _esperar(0.6)
	j.forcar_pulo = true
	await _esperar(0.07)
	await _foto(dir + "mov_3_pulo.png")
	j.forcar_pulo = false
	var t := 0.0
	while not j.is_on_floor() and t < 2.0:
		await solo.get_tree().physics_frame
		t += solo.get_physics_process_delta_time()
	await _esperar(0.03)
	await _foto(dir + "mov_4_pouso.png")
	solo.get_tree().quit()


func _foto(caminho: String) -> void:
	await RenderingServer.frame_post_draw
	solo.get_viewport().get_texture().get_image().save_png(caminho)
	print("foto: ", caminho.get_file())
