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
	"Holding_C", "Working_A", "Working_B", "Working_C", "Hammering", "Digging", "Fishing_Idle",
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
