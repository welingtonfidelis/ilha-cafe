class_name AnimUtil
extends RefCounted
## Carrega as bibliotecas de animação do KayKit e liga num AnimationPlayer.
## As animações vêm de arquivos .glb separados; como aventureiros, moradores e esqueletos usam o
## mesmo esqueleto, as trilhas ("Rig_Medium/Skeleton3D:<osso>") servem para todos. O Golem usa o
## esqueleto grande (Rig_Large), com menos animações: só "geral", "mov" e "luta".

const ANIM_DIR := "res://assets/animations/Rig_%s_%s.glb"

## Nome curto da biblioteca no jogo -> arquivo do KayKit.
const SETS := {
	"geral": "General",
	"mov": "MovementBasic",
	"mov2": "MovementAdvanced",
	"tiro": "CombatRanged",
	"luta": "CombatMelee",
	"especial": "Special",
	"festa": "Simulation",
	"ferramentas": "Tools",
}

## O glTF chega sem loop; estas precisam repetir.
const LOOPING := [
	"Idle_A", "Idle_B", "Walking_A", "Walking_B", "Walking_C", "Running_A", "Running_B",
	"Jump_Idle", "Running_HoldingRifle", "Running_Strafe_Left", "Running_Strafe_Right",
	"Walking_Backwards", "Ranged_1H_Shooting",
	"Ranged_2H_Shooting", "Skeletons_Idle", "Skeletons_Walking", "Skeletons_Inactive_Floor_Pose",
	"Cheering", "Waving", "Melee_Blocking", "Melee_Unarmed_Idle", "Melee_2H_Idle",
	"Ranged_Magic_Spellcasting", "Sit_Chair_Idle", "Sit_Floor_Idle", "Lie_Idle", "Holding_A", "Holding_B",
	"Holding_C", "Working_A", "Working_B", "Working_C", "Hammering", "Digging", "Fishing_Idle", "Chopping", "Melee_Blocking", "Ranged_Bow_Aiming_Idle",
]

static var _cache := {}


static func library(short_name: String, rig := "Medium") -> AnimationLibrary:
	var key := rig + "/" + short_name
	if _cache.has(key):
		return _cache[key]
	var scene: Node = load(ANIM_DIR % [rig, SETS[short_name]]).instantiate()
	var ap: AnimationPlayer = scene.find_child("AnimationPlayer", true, false)
	var lib: AnimationLibrary = ap.get_animation_library(&"").duplicate(true)
	for anim_name in lib.get_animation_list():
		if String(anim_name) in LOOPING:
			lib.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	scene.free()
	_cache[key] = lib
	return lib


## Cria uma pose parada (animação de um quadro só) a partir de um instante de outra animação.
## As "miras" do KayKit levantam o braço, seguram e abaixam de novo no fim; repetidas, o braço
## sobe e desce sem parar. A pose congela o braço estendido.
static func add_pose(short_name: String, anim_name: String, time: float, pose_name: String) -> void:
	var lib := library(short_name)
	if lib.has_animation(pose_name):
		return
	var src := lib.get_animation(anim_name)
	var pose := Animation.new()
	pose.length = 0.5
	pose.loop_mode = Animation.LOOP_LINEAR
	for i in src.get_track_count():
		var type := src.track_get_type(i)
		if type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			continue
		var t := pose.add_track(type)
		pose.track_set_path(t, src.track_get_path(i))
		match type:
			Animation.TYPE_POSITION_3D:
				pose.position_track_insert_key(t, 0.0, src.position_track_interpolate(i, time))
			Animation.TYPE_ROTATION_3D:
				pose.rotation_track_insert_key(t, 0.0, src.rotation_track_interpolate(i, time))
			Animation.TYPE_SCALE_3D:
				pose.scale_track_insert_key(t, 0.0, src.scale_track_interpolate(i, time))
	lib.add_animation(pose_name, pose)


## Pose parada de duas mãos iguais (duas pistolas): o braço direito de `anim_name` no instante `time`, e o
## esquerdo como o espelho dele. A mira de uma mão do KayKit gira o tronco de lado; no jogo o quadril vem da
## animação de andar, então a pose fica com quadril, tronco e cabeça retos (os do descanso) e os braços com a
## mesma direção que tinham no mundo, apontando para a frente. O espelho é feito no espaço do esqueleto
## (reflexo no plano do meio do corpo), comparando com o descanso de cada lado, porque os eixos locais dos
## ossos .l e .r do rig não são espelhados de um jeito simples. `skeleton` é um Skeleton3D do mesmo rig.
static func add_mirrored_pose(short_name: String, anim_name: String, time: float, pose_name: String, skeleton: Skeleton3D) -> void:
	var lib := library(short_name)
	if lib.has_animation(pose_name):
		return
	var src := lib.get_animation(anim_name)
	var rot := {}
	var pos := {}
	for i in src.get_track_count():
		var bone := String(src.track_get_path(i)).get_slice(":", 1)
		match src.track_get_type(i):
			Animation.TYPE_ROTATION_3D:
				rot[bone] = src.rotation_track_interpolate(i, time)
			Animation.TYPE_POSITION_3D:
				pos[bone] = src.position_track_interpolate(i, time)
	var order := range(skeleton.get_bone_count())
	order.sort_custom(func(a: int, b: int) -> bool: return _depth(skeleton, a) < _depth(skeleton, b))
	# Pose original no espaço do esqueleto.
	var source := {}
	for i in order:
		var name := skeleton.get_bone_name(i)
		var rest := skeleton.get_bone_rest(i)
		var local := Transform3D(Basis(rot.get(name, rest.basis.get_rotation_quaternion())), pos.get(name, rest.origin))
		var parent := skeleton.get_bone_parent(i)
		source[i] = (source[parent] as Transform3D) * local if parent >= 0 else local
	var arm := ["upperarm", "lowerarm", "wrist", "hand", "handslot", "shoulder"]
	var flip := Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
	var built := {}
	var result := {}
	for i in order:
		var name := skeleton.get_bone_name(i)
		var rest := skeleton.get_bone_rest(i)
		var parent := skeleton.get_bone_parent(i)
		var parent_basis: Basis = (built[parent] as Transform3D).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
		var is_arm := arm.any(func(b: String) -> bool: return name.begins_with(b + "."))
		var q: Quaternion = rest.basis.get_rotation_quaternion()
		if is_arm and name.ends_with(".r"):
			q = (parent_basis.inverse() * (source[i] as Transform3D).basis.orthonormalized()).get_rotation_quaternion()
		elif is_arm and name.ends_with(".l"):
			var r := skeleton.find_bone(name.trim_suffix(".l") + ".r")
			if r >= 0:
				var fix := (flip * skeleton.get_bone_global_rest(r).basis.orthonormalized()).inverse() * skeleton.get_bone_global_rest(i).basis.orthonormalized()
				var want := flip * (source[r] as Transform3D).basis.orthonormalized() * fix
				q = (parent_basis.inverse() * want).get_rotation_quaternion()
		result[name] = q
		var local := Transform3D(Basis(q), pos.get(name, rest.origin))
		built[i] = (built[parent] as Transform3D) * local if parent >= 0 else local
	var pose := Animation.new()
	pose.length = 0.5
	pose.loop_mode = Animation.LOOP_LINEAR
	for i in src.get_track_count():
		var type := src.track_get_type(i)
		if type not in [Animation.TYPE_POSITION_3D, Animation.TYPE_ROTATION_3D, Animation.TYPE_SCALE_3D]:
			continue
		var bone := String(src.track_get_path(i)).get_slice(":", 1)
		var t := pose.add_track(type)
		pose.track_set_path(t, src.track_get_path(i))
		match type:
			Animation.TYPE_POSITION_3D:
				pose.position_track_insert_key(t, 0.0, src.position_track_interpolate(i, time))
			Animation.TYPE_ROTATION_3D:
				pose.rotation_track_insert_key(t, 0.0, result.get(bone, src.rotation_track_interpolate(i, time)))
			Animation.TYPE_SCALE_3D:
				pose.scale_track_insert_key(t, 0.0, src.scale_track_interpolate(i, time))
	lib.add_animation(pose_name, pose)


static func _depth(sk: Skeleton3D, bone: int) -> int:
	var d := 0
	while sk.get_bone_parent(bone) >= 0:
		bone = sk.get_bone_parent(bone)
		d += 1
	return d


## Cria um AnimationPlayer como filho de `model_root` (a raiz do .glb instanciado),
## com as bibliotecas pedidas. As animações ficam como "<biblioteca>/<nome>".
static func make_player(model_root: Node, short_names: Array, rig := "Medium") -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	model_root.add_child(ap)
	for n in short_names:
		ap.add_animation_library(StringName(n), library(n, rig))
	return ap


## Ossos da parte de cima do corpo, para misturar mira e tiro só no tronco.
static func upper_body_paths() -> Array[NodePath]:
	var bones := [
		"spine", "chest", "head", "upperarm.l", "lowerarm.l", "wrist.l", "hand.l", "handslot.l",
		"upperarm.r", "lowerarm.r", "wrist.r", "hand.r", "handslot.r",
	]
	var paths: Array[NodePath] = []
	for b in bones:
		paths.append(NodePath("Rig_Medium/Skeleton3D:" + b))
	return paths
