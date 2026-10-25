extends SceneTree
## Calcula a rotação e a posição do blaster no osso handslot.r para que, na pose de mira,
## o cano aponte para a frente do personagem e a empunhadura caia na mão.
## Uso: godot --headless --path . -s res://tools/weapon_axes.gd

const GRIP := Vector3(0.0, -0.1, -0.12)  # empunhadura no modelo blaster-a (perto do carregador)


func _init() -> void:
	var model: Node3D = load("res://assets/characters/adventurers/Knight.glb").instantiate()
	root.add_child(model)
	var ap := AnimUtil.make_player(model, ["tiro"])
	ap.play(&"tiro/Ranged_1H_Aiming")
	ap.seek(0.3, true)
	var sk: Skeleton3D = model.find_child("Skeleton3D", true, false)
	var rig: Node3D = model.get_node("Rig_Medium")
	print("Rig_Medium transform: ", rig.transform, " Skeleton3D transform: ", sk.transform)
	var idx := sk.find_bone("handslot.r")
	var bone: Transform3D = sk.get_bone_global_pose(idx)
	print("handslot.r (espaço do modelo): origem ", bone.origin)
	print("  eixo X do osso -> ", bone.basis.x.normalized())
	print("  eixo Y do osso -> ", bone.basis.y.normalized())
	print("  eixo Z do osso -> ", bone.basis.z.normalized())
	# Queremos o cano (+Z do blaster) para +Z do modelo e o topo (+Y) para cima.
	var holder_basis := bone.basis.orthonormalized().inverse()
	var euler := holder_basis.get_euler() * (180.0 / PI)
	var pos := -(holder_basis * GRIP)
	print("weapon_rotation_deg = Vector3(%.1f, %.1f, %.1f)" % [euler.x, euler.y, euler.z])
	print("weapon_position = Vector3(%.3f, %.3f, %.3f)" % [pos.x, pos.y, pos.z])
	quit()
