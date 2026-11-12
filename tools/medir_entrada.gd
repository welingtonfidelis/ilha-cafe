extends SceneTree
## Mede a entrada numa fase do Faísca, quadro a quadro: quanto leva montar a fase, quanto duram os primeiros
## quadros (shaders compilando), quando a tela clareia e quando o Faísca pousa.
## Uso (com janela; sem tela a vegetação nem monta): godot --path . -s res://tools/medir_entrada.gd -- --medir 1-1

var j: Node


func _initialize() -> void:
	change_scene_to_file("res://scenes/faisca.tscn")
	_rodar.call_deferred()


func _rodar() -> void:
	for i in 5:
		await process_frame
	j = current_scene
	var fase := "1-1"
	for a in OS.get_cmdline_user_args():
		if a.contains("-") and not a.begins_with("--"):
			fase = a
	j.abertura_vista = true
	j.comecar_no_farol()
	while not (j.lugar == "hub" and not j.busy()):
		await process_frame
	for i in 90:
		await process_frame
	var f: Node3D = j.faisca
	print("entrando na ", fase)
	var t0 := Time.get_ticks_usec()
	var antes := t0
	j.entrar_fase(fase)
	var linhas := []
	var montou := -1.0
	var clareou := -1.0
	var pousou := -1.0
	var maior := 0.0
	var soma_longos := 0.0
	for i in 600:
		await process_frame
		var agora := Time.get_ticks_usec()
		var dq := (agora - antes) / 1000.0
		antes = agora
		var t := (agora - t0) / 1000.0
		if montou < 0.0 and j.nivel != null:
			montou = t
		var alfa: float = j.fade.modulate.a
		if montou >= 0.0 and clareou < 0.0 and alfa < 0.05:
			clareou = t
		if montou >= 0.0 and pousou < 0.0 and not f.pouso_suave and f.controle_ligado:
			pousou = t
		if dq > maior:
			maior = dq
		if dq > 50.0:
			soma_longos += dq
			linhas.append("  quadro %d em %.0f ms: %.0f ms (escuro %.2f, Faísca y %.1f, pouso %s)" % [i, t, dq, alfa, f.global_position.y, f.pouso_suave])
		if pousou >= 0.0 and t > pousou + 1500.0:
			break
	for l in linhas:
		print(l)
	print("RESUMO: nível montado em %.0f ms; tela clara em %.0f ms; pousou em %.0f ms; maior quadro %.0f ms; quadros >50 ms somam %.0f ms" % [montou, clareou, pousou, maior, soma_longos])
	quit()
