extends SceneTree
## Lista as peças da ilha que têm tamanho de obstáculo (mais de 0,9 m de altura e de 0,4 m de largura) e que
## nenhuma colisão cobre: o Faísca e o aventureiro atravessam elas.
## Uso: godot --headless --path . -s res://tools/sem_fisica.gd


func _init() -> void:
	var ilha: Node3D = load("res://scenes/ilha.tscn").instantiate()
	root.add_child(ilha)
	await physics_frame
	await physics_frame
	var espaco := ilha.get_world_3d().direct_space_state
	var vistos := {}
	for mi in ilha.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if not m.is_visible_in_tree() or m.mesh == null:
			continue
		var caixa := m.global_transform * m.get_aabb()
		if caixa.size.y < 0.9 or maxf(caixa.size.x, caixa.size.z) < 0.4 or caixa.size.x > 60.0 or caixa.size.z > 60.0:
			continue
		# A peça "de cima" (filha direta de um grupo), para não repetir cada malha do mesmo modelo.
		var dono: Node = m
		while dono.get_parent() != ilha and dono.get_parent().get_parent() != ilha and not (dono.get_parent() is Node3D and dono.get_parent().name in ["Pasto", "Praca", "Festa", "Cidade", "Props"]):
			dono = dono.get_parent()
		var chave := str(ilha.get_path_to(dono))
		if vistos.has(chave):
			continue
		var q := PhysicsShapeQueryParameters3D.new()
		var forma := BoxShape3D.new()
		forma.size = caixa.size * Vector3(0.6, 0.6, 0.6)
		q.shape = forma
		q.transform = Transform3D(Basis(), caixa.get_center())
		q.collision_mask = 1
		if espaco.intersect_shape(q, 1).is_empty():
			vistos[chave] = true
			print("SEM FISICA  %s  (%.1f x %.1f x %.1f) em %s" % [chave, caixa.size.x, caixa.size.y, caixa.size.z, str(caixa.get_center().round())])
	print("FIM: %d peças sem física" % vistos.size())
	quit()
