extends SceneTree
## Imprime a hierarquia importada de um personagem e de um arquivo de animação,
## e os primeiros caminhos de trilha, para conferir se batem.
## Uso: godot --headless --path . -s res://tools/inspect.gd


func _init() -> void:
	var knight: Node = load("res://assets/characters/adventurers/Knight.glb").instantiate()
	print("== Knight")
	_print_tree(knight, 0)
	var anim_scene: Node = load("res://assets/animations/Rig_Medium_MovementBasic.glb").instantiate()
	print("== Rig_Medium_MovementBasic")
	_print_tree(anim_scene, 0, 2)
	var ap: AnimationPlayer = anim_scene.find_child("AnimationPlayer", true, false)
	print("AnimationPlayer em: ", anim_scene.get_path_to(ap), " root_node=", ap.root_node)
	print("bibliotecas: ", ap.get_animation_library_list())
	var lib := ap.get_animation_library(&"")
	print("animações: ", lib.get_animation_list())
	var anim := lib.get_animation(&"Running_A")
	print("Running_A: duração ", anim.length, " loop ", anim.loop_mode, " trilhas ", anim.get_track_count())
	for i in min(4, anim.get_track_count()):
		print("  trilha ", anim.track_get_path(i), " tipo ", anim.track_get_type(i))
	var blaster: Node = load("res://assets/weapons/blaster-a.glb").instantiate()
	print("== blaster-a")
	_print_tree(blaster, 0)
	var sk: Skeleton3D = knight.find_child("Skeleton3D", true, false)
	for b in ["handslot.r", "hand.r", "head", "chest", "hips"]:
		var idx := sk.find_bone(b)
		print("osso ", b, " idx ", idx, " pose global ", sk.get_bone_global_rest(idx).origin)
	quit()


func _print_tree(n: Node, depth: int, max_depth: int = 4) -> void:
	if depth > max_depth:
		return
	var extra := ""
	if n is MeshInstance3D:
		extra = " skin=" + str(n.skin != null) + " aabb=" + str((n as MeshInstance3D).get_aabb().size)
	print("  ".repeat(depth), n.name, " <", n.get_class(), ">", extra)
	for c in n.get_children():
		_print_tree(c, depth + 1, max_depth)
