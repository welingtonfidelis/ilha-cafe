class_name AnimUtil
extends RefCounted
## Carrega as bibliotecas de animação do KayKit (Rig_Medium) e liga num AnimationPlayer.
## As animações vêm de arquivos .glb separados; como aventureiros e esqueletos usam o
## mesmo esqueleto, as trilhas ("Rig_Medium/Skeleton3D:<osso>") servem para todos.

const ANIM_DIR := "res://assets/animations/Rig_Medium_%s.glb"

## Nome curto da biblioteca no jogo -> arquivo do KayKit.
const SETS := {
	"geral": "General",
	"mov": "MovementBasic",
	"mov2": "MovementAdvanced",
	"tiro": "CombatRanged",
	"luta": "CombatMelee",
	"especial": "Special",
	"festa": "Simulation",
}

## O glTF chega sem loop; estas precisam repetir.
const LOOPING := [
	"Idle_A", "Idle_B", "Walking_A", "Walking_B", "Walking_C", "Running_A", "Running_B",
	"Jump_Idle", "Running_HoldingRifle", "Running_Strafe_Left", "Running_Strafe_Right",
	"Walking_Backwards", "Ranged_1H_Aiming", "Ranged_2H_Aiming", "Ranged_1H_Shooting",
	"Ranged_2H_Shooting", "Skeletons_Idle", "Skeletons_Walking", "Skeletons_Inactive_Floor_Pose",
	"Cheering", "Waving", "Melee_Blocking", "Melee_Unarmed_Idle", "Melee_2H_Idle",
	"Ranged_Magic_Spellcasting",
]

static var _cache := {}


static func library(short_name: String) -> AnimationLibrary:
	if _cache.has(short_name):
		return _cache[short_name]
	var scene: Node = load(ANIM_DIR % SETS[short_name]).instantiate()
	var ap: AnimationPlayer = scene.find_child("AnimationPlayer", true, false)
	var lib: AnimationLibrary = ap.get_animation_library(&"").duplicate(true)
	for anim_name in lib.get_animation_list():
		if String(anim_name) in LOOPING:
			lib.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR
	scene.free()
	_cache[short_name] = lib
	return lib


## Cria um AnimationPlayer como filho de `model_root` (a raiz do .glb instanciado),
## com as bibliotecas pedidas. As animações ficam como "<biblioteca>/<nome>".
static func make_player(model_root: Node, short_names: Array) -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	model_root.add_child(ap)
	for n in short_names:
		ap.add_animation_library(StringName(n), library(n))
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
