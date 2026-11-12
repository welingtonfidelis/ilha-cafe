class_name TesteMundo
extends RefCounted
## Confere o mundo que reage (item 6 da lista do Faísca, 2026-11-11):
## - em cada uma das 7 fases, os playgrounds ganham plantas do mundo dela, coisas que quebram e poças, tudo em chão
##   firme: nenhuma caixa encostada em outra coisa sólida, nenhuma poça torta; e o chão ganha a textura (item 13),
##   menos o que se mexe;
## - na 1-1: a planta dobra para longe do Faísca e volta balançando quando ele sai, e o giro empurra de mais longe;
## - o soco quebra a caixa (some a colisão, voam os cacos e saem 3 moedas) e o pisão em cima quebra e faz quicar;
## - pisar na poça muda o chão do controle para "agua", cair de um pulo nela espirra alto e correr espirra a cada passo;
## - a Bolota perto da dancinha para, dança junto, solta coraçõezinhos e não machuca; no fim, aplaude e volta a seguir.
## Uso: godot --headless --path . -- --faisca-mundo

const FASES := ["1-1", "1-2", "2-1", "2-2", "2-3", "3-1", "3-2", "3-3"]

var solo: Node
var j: Jogador
var _ok := true


func _init(s: Node) -> void:
	solo = s
	j = solo.jogador


func _conferir(nome: String, cond: bool, extra := "") -> bool:
	print("%s %s %s" % ["OK    " if cond else "FALHOU", nome, extra])
	_ok = _ok and cond
	return cond


func _esperar(s: float) -> void:
	var t := 0.0
	while t < s:
		await solo.get_tree().physics_frame
		t += solo.get_physics_process_delta_time()


func _ate(cond: Callable, s: float) -> bool:
	var t := 0.0
	while t < s:
		if cond.call():
			return true
		await solo.get_tree().physics_frame
		t += solo.get_physics_process_delta_time()
	return cond.call()


func _moedas(n: Fase) -> int:
	return n.get_children().filter(func(c: Node) -> bool: return c is Moeda and not c.is_queued_for_deletion()).size()


func rodar() -> void:
	# A vegetação das fases só é montada com tela; aqui, para conferir onde ela nasce.
	VegetacaoDaFase.nos_testes = true
	for id in FASES:
		await _conferir_fase(id)
	await _na_1_1()
	print("MUNDO OK" if _ok else "MUNDO COM FALHAS")
	solo.get_tree().quit()


func _conferir_fase(id: String) -> void:
	var n := TesteFaisquinhas.nova_fase(id)
	n.name = "Fase"
	solo.add_child(n)
	j.limite_queda = n.limite_queda
	j.teleportar(n.inicio)
	await _esperar(0.3)
	var plantas := n.mato.plantas.size() if n.mato else 0
	var sem_plantas: bool = (Fase.ESTILOS[n.superficie][0] as Array).is_empty()
	_conferir("%s: plantas, coisas que quebram e poças nos playgrounds" % id,
			(plantas >= 3 * n.playgrounds.size() or sem_plantas) and n.quebraveis.size() >= n.playgrounds.size()
			and n.pocas.size() >= 1, "(%d plantas, %d que quebram, %d poças, %d playgrounds)" % [plantas, n.quebraveis.size(),
			n.pocas.size(), n.playgrounds.size()])
	# Cada caixa em pé no chão e sem nada sólido encostado (fora o próprio chão).
	var espaco := n.get_world_3d().direct_space_state
	var tortas: Array[String] = []
	for q in n.quebraveis:
		var forma := BoxShape3D.new()
		forma.size = q.tamanho - Vector3(0.1, 0.1, 0.1)
		var consulta := PhysicsShapeQueryParameters3D.new()
		consulta.shape = forma
		consulta.transform = Transform3D(q.global_basis, q.global_position + Vector3.UP * (q.tamanho.y * 0.5 + 0.08))
		consulta.collision_mask = 1
		consulta.exclude = [q.get_rid()]
		var chao := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(q.global_position + Vector3.UP * 0.3,
				q.global_position + Vector3.DOWN * 0.3, 1, [q.get_rid()]))
		if chao.is_empty() or not espaco.intersect_shape(consulta, 1).is_empty():
			tortas.append("%s %s" % [q.tipo, q.global_position.snapped(Vector3.ONE * 0.1)])
	_conferir("%s: as coisas que quebram estão em pé no chão e com espaço em volta" % id, tortas.is_empty(), str(tortas))
	var poca_torta := n.pocas.filter(func(p: Poca) -> bool:
		for k in 4:
			var s := p.global_position + Vector3(cos(k * PI / 2.0), 0, sin(k * PI / 2.0)) * p.raio * 0.9
			var r := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(s + Vector3.UP * 0.5, s + Vector3.DOWN * 0.5, 1))
			if r.is_empty() or absf(r.position.y - p.global_position.y) > 0.1:
				return true
		return false)
	_conferir("%s: as poças estão em chão reto" % id, poca_torta.is_empty(), "(%d tortas)" % poca_torta.size())
	# A textura no chão (item 13): as peças de chão ganham o desenho, e nada do que se mexe ganha.
	var mexendo := n.find_children("*", "MeshInstance3D", true, false).filter(func(mi: Node) -> bool:
		if (mi as MeshInstance3D).material_overlay == null:
			return false
		var a: Node = mi.get_parent()
		while a and a != n:
			if a is AnimatableBody3D or a.get_script() != null:
				return true
			a = a.get_parent()
		return false)
	_conferir("%s: o chão tem textura, e só o que fica parado" % id, n.pecas_com_textura >= 10 and mexendo.is_empty(),
			"(%d peças, %d que se mexem)" % [n.pecas_com_textura, mexendo.size()])
	await _conferir_vegetacao(id, n)
	if n.superficie == "grama":
		var com_cor := n.find_children("*", "MeshInstance3D", true, false).filter(func(mi: Node) -> bool:
			var m := (mi as MeshInstance3D).material_override as ShaderMaterial
			return m != null and m.shader.resource_path.ends_with("grama_das_fases.gdshader")).size()
		_conferir("%s: a grama ganha o campo da ilha, com cor" % id, com_cor >= 10, "(%d peças)" % com_cor)
	n.queue_free()
	await _esperar(0.1)


## A vegetação e as miudezas do mundo (VegetacaoDaFase): nascem nas peças de chão e nenhuma fica embaixo de outra coisa,
## em cima do gelo, nem perto de botão, mola, posto ou poça (até 400 de cada fase, sorteadas).
func _conferir_vegetacao(id: String, n: Fase) -> void:
	await _ate(func() -> bool: return n.vegetacao != null, 1.0)
	var v := n.vegetacao
	var total := 0
	if v:
		for k in v.plantas:
			total += int(v.plantas[k])
	var minimo := 100 if n.superficie == "madeira" else 300
	_conferir("%s: a vegetação do mundo nasce no chão" % id, total >= minimo, "(%s)" % (v.plantas if v else {}))
	if v == null:
		return
	var espaco := n.get_world_3d().direct_space_state
	var usados: Array[Node3D] = []
	for c in n.get_children():
		if c is Node3D and c.get_script() != null and not (c is Quebravel or c is Mato or c is VegetacaoDaFase or c is Poca):
			if c is Area3D or c is StaticBody3D or c is AnimatableBody3D:
				usados.append(c)
	var ruins: Array[String] = []
	var vistas := 0
	for par in v.amostra:
		var tipo: String = par[0]
		var p: Vector3 = par[1]
		vistas += 1
		var r := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 2.0, p + Vector3.DOWN * 0.3, 1))
		if r.is_empty() or absf((r.position as Vector3).y - p.y) > 0.25 or (r.collider as Node).has_meta("gelo"):
			ruins.append("%s embaixo ou no gelo %s" % [tipo, p.snapped(Vector3.ONE * 0.1)])
		elif _na_poca(n, p):
			ruins.append("%s na poça" % tipo)
		else:
			for c in usados:
				var no := c as Node3D
				var raio := 0.5 if no is Area3D else 1.0
				if Vector2(no.global_position.x - p.x, no.global_position.z - p.z).length() < raio and absf(no.global_position.y - p.y) < 2.0:
					ruins.append("%s perto de %s" % [tipo, no.name])
					break
		if ruins.size() > 4:
			break
	_conferir("%s: nada da vegetação embaixo de outra coisa, no gelo, na poça ou em cima do que se usa" % id, ruins.is_empty(),
			"(%d vistas %s)" % [vistas, ruins.slice(0, 4)])


func _na_poca(n: Fase, p: Vector3) -> bool:
	for o in n.pocas:
		if Vector2(o.global_position.x - p.x, o.global_position.z - p.z).length() < o.raio and absf(o.global_position.y - p.y) < 1.0:
			return true
	return false


func _na_1_1() -> void:
	var n := TesteFaisquinhas.nova_fase("1-1")
	n.name = "Fase"
	solo.add_child(n)
	j.limite_queda = n.limite_queda
	j.teleportar(n.inicio)
	j.controle_ligado = true
	await _esperar(0.4)
	j._invencivel = 999.0
	# A planta: dobra para longe e volta balançando.
	var m := n.mato
	var i := 0
	var pl: Dictionary = m.plantas[i]
	var pe: Vector3 = pl.pe
	j.teleportar(pe + Vector3(0.5, 0.1, 0))
	await _esperar(0.35)
	var t: Vector2 = m.plantas[i].topo
	_conferir("a planta dobra para longe do Faísca", m.dobra(i) > 0.2 and t.x < 0.0, "(%.2f rad, x %.2f)" % [m.dobra(i), t.x])
	j.teleportar(pe + Vector3(8, 0.1, 0))
	var balancou := [false]
	await _ate(func() -> bool:
		if (m.plantas[i].topo as Vector2).x > 0.02:
			balancou[0] = true
		return false, 0.8)
	await _esperar(2.0)
	_conferir("ele sai e ela volta balançando até parar", balancou[0] and m.dobra(i) < 0.03, "(%.3f rad)" % m.dobra(i))
	j.teleportar(pe + Vector3(2.2, 0.1, 0))
	await _esperar(0.3)
	var parada := m.dobra(i)
	j.girando = 0.4
	await _esperar(0.2)
	_conferir("o giro empurra de mais longe", parada < 0.05 and m.dobra(i) > 0.15, "(%.2f -> %.2f)" % [parada, m.dobra(i)])
	# O soco na caixa.
	var q: Quebravel = n.quebraveis[0]
	j.teleportar(q.global_position + Vector3(0, 0.1, 0) + Vector3(1.0, 0, 0) * (q.raio_golpe + 0.9))
	j.visual.rotation.y = atan2(-1.0, 0.0)
	await _esperar(0.3)
	var antes := _moedas(n)
	j.forcar_golpe = true
	await _ate(func() -> bool: return q.derrotado, 1.0)
	await _esperar(0.1)
	_conferir("o soco quebra a caixa: some a colisão, voam os cacos e saem as moedas", q.derrotado and q.collision_layer == 0
			and not q._cacos.is_empty() and _moedas(n) >= antes + q.moedas, "(%s, %d moedas)" % [q.tipo, _moedas(n) - antes])
	await _esperar(1.6)
	_conferir("os cacos somem depois de quicar", q._cacos.is_empty())
	# O pisão em cima da outra.
	var q2: Quebravel = n.quebraveis[1]
	j.teleportar(q2.global_position + Vector3.UP * (q2.tamanho.y + 2.5))
	var subiu := [false]
	await _ate(func() -> bool:
		if q2.derrotado and j.velocity.y > 3.0:
			subiu[0] = true
		return subiu[0], 2.0)
	_conferir("o pisão em cima quebra e faz o Faísca quicar", q2.derrotado and subiu[0], "(%s)" % q2.tipo)
	# A poça.
	var p: Poca = n.pocas[0]
	j.teleportar(p.global_position + Vector3.UP * 3.0)
	var antes_espirros := p.espirros
	await _ate(func() -> bool: return not j.is_on_floor(), 0.5)
	await _ate(func() -> bool: return j.is_on_floor(), 2.0)
	await _esperar(0.1)
	_conferir("cair de um pulo na poça espirra, e o chão do controle vira água", p.espirros > antes_espirros
			and j.na_poca == p and j.superficie_embaixo() == "agua", "(%d espirros, chão %s)" % [p.espirros, j.superficie_embaixo()])
	# Correndo de fora, atravessando a poça de um lado ao outro (do lado que tiver chão).
	var de := _chao_ao_lado(n, p.global_position, p.raio + 2.5)
	j.teleportar(p.global_position + de + Vector3.UP * 0.1)
	await _esperar(0.2)
	var antes_passos := p.espirros
	j.yaw = atan2(de.z, -de.x)
	j.forcar_direcao = Vector2(1, 0)
	await _esperar((2.0 * p.raio + 2.5) / j.velocidade)
	j.forcar_direcao = Vector2.ZERO
	_conferir("correndo na poça, os passos espirram", p.espirros >= antes_passos + 1, "(%d)" % (p.espirros - antes_passos))
	j.teleportar(p.global_position + Vector3(p.raio + 4.0, 0.1, 0))
	await _esperar(0.3)
	_conferir("saindo da poça, o chão volta", j.na_poca == null and j.superficie_embaixo() != "agua")
	# A Bolota que olha a dança: uma acordada que anda no chão.
	var b: Bolota = null
	for a in n.alvos:
		if a is Bolota and not a.dormindo and not a.derrotado and not (a is BolotaMonstro and (a as BolotaMonstro).regra == "voa"):
			b = a
			break
	if not _conferir("tem uma Bolota acordada na 1-1", b != null):
		return
	var lado := _chao_ao_lado(n, b.global_position, 4.0)
	j.teleportar(b.global_position + lado + Vector3.UP * 0.1)
	await _esperar(0.4)
	j._invencivel = 0.0
	j.vida = Jogador.VIDA_MAX
	j.forcar_danca = true
	await _ate(func() -> bool: return b.assistindo, 1.0)
	await _esperar(0.6)
	var rapidez := Vector2(b.velocity.x, b.velocity.z).length()
	var dancando: bool = not b is BolotaMonstro or (b as BolotaMonstro).anim.current_animation == "Dance"
	var coracoes := b.get_children().filter(func(c: Node) -> bool: return c is MeshInstance3D and (c as MeshInstance3D).top_level).size()
	_conferir("com o Faísca dançando perto, a Bolota para, dança junto e solta coraçõezinhos", b.assistindo and rapidez < 0.3
			and dancando and coracoes > 0, "(rapidez %.2f, %d corações)" % [rapidez, coracoes])
	j._invencivel = 999.0
	await _ate(func() -> bool: return not b.assistindo, Jogador.TEMPO_DANCA + 1.0)
	var aplaudiu: bool = not b is BolotaMonstro or (b as BolotaMonstro).anim.current_animation == "Yes"
	_conferir("a dança acaba: ela aplaude", not b.assistindo and aplaudiu and b.vezes_que_assistiu == 1,
			"(%s, %d vezes)" % [(b as BolotaMonstro).anim.current_animation if b is BolotaMonstro else "-", b.vezes_que_assistiu])
	_conferir("o tempo da dança acaba e o Faísca para de dançar sozinho", not j.robo._dancando and j.dancando <= 0.0)
	await _esperar(1.0)
	_conferir("e volta a seguir o Faísca", Vector2(b.velocity.x, b.velocity.z).length() > 0.3,
			"(%.2f)" % Vector2(b.velocity.x, b.velocity.z).length())
	# Com o Faísca parado, ela encosta e machuca (antes parava encostada, a 1,12 m, e nunca alcançava).
	j._invencivel = 0.0
	await _ate(func() -> bool: return j.vida < Jogador.VIDA_MAX, 4.0)
	_conferir("com o Faísca parado, a Bolota encosta e machuca", j.vida < Jogador.VIDA_MAX)
	j.vida = Jogador.VIDA_MAX
	j._invencivel = 999.0
	# O empurrão da batida joga o Faísca longe: de volta, já encostado nela (no lado que tem chão), e ele dança.
	await _esperar(1.2)
	j.teleportar(b.global_position + lado.normalized() * 1.15 + Vector3.UP * 0.05)
	await _esperar(0.3)
	j._invencivel = 0.15
	j.forcar_danca = true
	await _esperar(1.0)
	var longe := Vector2(b.global_position.x - j.global_position.x, b.global_position.z - j.global_position.z).length()
	_conferir("colada nele, olhando a dança, ela não machuca", j.vida == Jogador.VIDA_MAX and b.assistindo and j.dancando > 0.0
			and longe < Bolota.ALCANCE_TOQUE, "(vida %d, olhando %s, dança %.1f, a %.2f m)" % [j.vida, b.assistindo, j.dancando, longe])


## Um passo de `longe` metros de `centro` para um lado que tenha chão na mesma altura (para pôr o Faísca ali).
func _chao_ao_lado(n: Fase, centro: Vector3, longe: float) -> Vector3:
	var espaco := n.get_world_3d().direct_space_state
	for k in 16:
		var a := TAU * k / 16.0
		var lado := Vector3(cos(a), 0, sin(a)) * longe
		var ok := true
		for f: float in [0.5, 1.0]:
			var q := centro + lado * f
			var r := espaco.intersect_ray(PhysicsRayQueryParameters3D.create(q + Vector3.UP * 1.5, q + Vector3.DOWN * 1.5, 1))
			if r.is_empty() or absf(r.position.y - centro.y) > 0.4:
				ok = false
		if ok:
			return lado
	return Vector3(0, 0, longe)


## Fotos (com janela), em tools/capturas/faisca/mundo/: de cada mundo, o tufo de plantas com o Faísca passando, a
## coisa que quebra antes e depois do soco, e a poça espirrando; e a Bolota da 1-1 olhando a dança.
func capturar() -> void:
	var dir := ProjectSettings.globalize_path("res://tools/capturas/faisca/mundo/")
	DirAccess.make_dir_recursive_absolute(dir)
	var cam := Camera3D.new()
	cam.fov = 50.0
	solo.add_child(cam)
	cam.make_current()
	j._invencivel = 999.0
	for id in FASES:
		var n := TesteFaisquinhas.nova_fase(id)
		n.name = "Fase"
		solo.add_child(n)
		j.limite_queda = n.limite_queda
		j.teleportar(n.inicio)
		j.controle_ligado = true
		await _esperar(0.5)
		if n.mato and not n.mato.plantas.is_empty():
			var pe: Vector3 = n.mato.plantas[n.mato.plantas.size() / 2].pe
			var lado := _chao_ao_lado(n, pe, 1.6)
			j.teleportar(pe + lado + Vector3.UP * 0.05)
			await _esperar(0.3)
			j.forcar_direcao = Vector2(1, 0)
			j.yaw = atan2(lado.z, -lado.x)
			await _esperar(0.3)
			j.forcar_direcao = Vector2.ZERO
			_mirar(cam, n, pe + Vector3.UP * 0.6, 4.5)
			await _foto(dir + "%s_mato.png" % id)
		if not n.quebraveis.is_empty():
			var q: Quebravel = n.quebraveis[0]
			var c := q.global_position + Vector3.UP * q.tamanho.y * 0.5
			j.teleportar(q.global_position + _chao_ao_lado(n, q.global_position, q.raio_golpe + 1.0) + Vector3.UP * 0.05)
			_mirar(cam, n, c, 5.0)
			await _esperar(0.3)
			await _foto(dir + "%s_caixa.png" % id)
			q.quebrar(j.global_position)
			await _esperar(0.14)
			await _foto(dir + "%s_quebrou.png" % id)
		if not n.pocas.is_empty():
			var p: Poca = n.pocas[0]
			j.teleportar(p.global_position + Vector3.UP * 2.5)
			_mirar(cam, n, p.global_position + Vector3.UP * 0.5, 4.5)
			await _ate(func() -> bool: return not j.is_on_floor(), 0.5)
			await _ate(func() -> bool: return j.is_on_floor(), 2.0)
			await _esperar(0.1)
			await _foto(dir + "%s_poca.png" % id)
		if id == "1-1":
			var b: Bolota = null
			for a in n.alvos:
				if a is BolotaMonstro and not a.dormindo and (a as BolotaMonstro).regra != "voa":
					b = a
					break
			if b:
				var lado := _chao_ao_lado(n, b.global_position, 3.0)
				j.teleportar(b.global_position + lado + Vector3.UP * 0.05)
				await _esperar(0.3)
				j.forcar_danca = true
				await _esperar(1.6)
				_mirar(cam, n, (b.global_position + j.global_position) * 0.5 + Vector3.UP * 1.0, 5.0)
				await _foto(dir + "1-1_bolota_olhando.png")
		n.queue_free()
		await _esperar(0.1)
	solo.get_tree().quit()


## Põe a câmera a `longe` m de `alvo`, um pouco de cima, no primeiro lado de onde se vê o alvo sem nada no meio.
func _mirar(cam: Camera3D, n: Fase, alvo: Vector3, longe: float) -> void:
	var espaco := n.get_world_3d().direct_space_state
	var melhor := alvo + Vector3(longe, longe * 0.6, longe)
	for k in 16:
		var a := TAU * k / 16.0 + PI / 4.0
		var p := alvo + Vector3(cos(a) * longe, longe * 0.6, sin(a) * longe)
		if espaco.intersect_ray(PhysicsRayQueryParameters3D.create(alvo + Vector3.UP * 0.3, p, 1, [j.get_rid()])).is_empty():
			melhor = p
			break
	cam.global_position = melhor
	cam.look_at(alvo)


func _foto(caminho: String) -> void:
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	solo.get_viewport().get_texture().get_image().save_png(caminho)
	print("foto: ", caminho.get_file())
