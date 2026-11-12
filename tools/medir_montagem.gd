extends SceneTree
## Cronometra cada etapa do Fase._ready de uma fase (sem mexer no projeto: uma subclasse que refaz o _ready medindo).
## Uso: godot --path . -s res://tools/medir_montagem.gd -- --medir 1-1 [sem-vegetacao] [sem-textura] [sem-sombra] [sem-shader]
## (com janela; sem tela, com-vegetacao liga a vegetação). Criado em 2026-11-12 para achar a tela preta da 1-1.


class Medida11 extends Fase11:
	func _ready() -> void:
		Medidor.medir(self)

class Medida12 extends Fase12:
	func _ready() -> void:
		Medidor.medir(self)

class Medida21 extends Fase21:
	func _ready() -> void:
		Medidor.medir(self)

class Medida22 extends Fase22:
	func _ready() -> void:
		Medidor.medir(self)

class Medida23 extends Fase23:
	func _ready() -> void:
		Medidor.medir(self)

class Medida31 extends Fase31:
	func _ready() -> void:
		Medidor.medir(self)

class Medida32 extends Fase32:
	func _ready() -> void:
		Medidor.medir(self)


class Medidor:
	static func medir(f: Fase) -> void:
		# Num Array, para a função de dentro poder atualizar (ela pega as variáveis pelo valor).
		var t := [Time.get_ticks_usec()]
		var marcas := []
		var marca := func(nome: String) -> void:
			var agora := Time.get_ticks_usec()
			marcas.append("%-22s %7.0f ms" % [nome, (agora - int(t[0])) / 1000.0])
			t[0] = agora
		f.add_to_group("fase_do_faisca")
		f._montar_ceu_e_luz()
		marca.call("ceu e luz")
		f._montar()
		marca.call("montar (o caminho)")
		f._montar_nuvens()
		marca.call("nuvens")
		f.pegas = f.ja_pegas.size()
		f.achados = f.ja_achados.size()
		f._mundo_que_reage()
		marca.call("mundo que reage")
		f.pecas_com_textura = TexturaDoChao.na_fase(f, f.superficie, f.pecas_de_chao)
		marca.call("textura do chao")
		if not "sem-vegetacao" in OS.get_cmdline_user_args():
			f._vegetar()
		marca.call("vegetacao")
		for m in marcas:
			print("  ", m)


func _initialize() -> void:
	_rodar.call_deferred()


func _rodar() -> void:
	var fase := "1-1"
	var classes := {"1-1": Medida11, "1-2": Medida12, "2-1": Medida21, "2-2": Medida22, "2-3": Medida23, "3-1": Medida31, "3-2": Medida32}
	for a in OS.get_cmdline_user_args():
		if classes.has(a):
			fase = a
	if "com-vegetacao" in OS.get_cmdline_user_args():
		VegetacaoDaFase.nos_testes = true
	var t0 := Time.get_ticks_usec()
	var n: Node = classes[fase].new()
	var t1 := Time.get_ticks_usec()
	print("fase ", fase, ": new() em %.0f ms" % ((t1 - t0) / 1000.0))
	root.add_child(n)
	var args := OS.get_cmdline_user_args()
	var mis := n.find_children("*", "MeshInstance3D", true, false)
	if "sem-textura" in args:
		for mi: MeshInstance3D in mis:
			mi.material_overlay = null
	if "sem-sombra" in args:
		for l: DirectionalLight3D in n.find_children("*", "DirectionalLight3D", true, false):
			l.shadow_enabled = false
		for mi: MeshInstance3D in mis:
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if "sem-shader" in args:
		for mi: MeshInstance3D in mis:
			if mi.material_override is ShaderMaterial:
				mi.material_override = null
	var t2 := Time.get_ticks_usec()
	var unicos := {}
	var shaders := {}
	for mi: MeshInstance3D in mis:
		for m in [mi.material_override, mi.material_overlay]:
			if m:
				unicos[m.get_instance_id()] = true
				shaders[str(m.get_class()) + (str((m as ShaderMaterial).shader.resource_path) if m is ShaderMaterial else "")] = true
	print("fase ", fase, ": %d malhas, %d materiais únicos, %d tipos" % [mis.size(), unicos.size(), shaders.size()])
	print("fase ", fase, ": add_child (o _ready) em %.0f ms" % ((t2 - t1) / 1000.0))
	await process_frame
	var t3 := Time.get_ticks_usec()
	print("fase ", fase, ": primeiro quadro em %.0f ms" % ((t3 - t2) / 1000.0))
	var t4 := t3
	for k in 8:
		await process_frame
		var agora := Time.get_ticks_usec()
		if (agora - t4) / 1000.0 > 40.0:
			print("fase ", fase, ": quadro %d em %.0f ms" % [k + 2, (agora - t4) / 1000.0])
		t4 = agora
	var veg = n.get("vegetacao")
	if veg:
		var soma := 0
		for k in veg.plantas:
			soma += int(veg.plantas[k])
		print("fase ", fase, ": vegetação com %d peças %s" % [soma, str(veg.plantas)])
	quit()
