class_name SkeletonEnemy
extends CharacterBody3D
## Esqueleto do KayKit (e, desde 2026-10-27, os amigos do Morro: Lobinho, Conde, Grandalhão e Golem de Gelo,
## da Mystery Monthly do KayKit). Persegue o jogador e ataca do seu jeito (ver TYPES); ao levar tiros
## suficientes, aparecem balões amarrados nele e ele vai embora voando, acenando, de volta para o
## Morro. Não volta mais. Ninguém morre (regras de tom do doc).
## Todo ataque tem um aviso ("!" em cima da cabeça) antes do golpe, para dar tempo de desviar.
## Duas regiões de impacto presas aos ossos: cabeça (dano em dobro) e corpo.

signal defeated(enemy: SkeletonEnemy)
## Saiu de vez (o balão subiu e sumiu). Logo depois o nó é liberado.
signal gone(enemy: SkeletonEnemy)

enum State { PERSEGUINDO, PREPARANDO, ATACANDO, ESPERANDO, ATINGIDO, INDO_EMBORA, ACORDANDO, COMEMORANDO, DORMINDO, VOLTANDO, AFUNDANDO, SUMIDO }

const SKELETONS := "res://assets/characters/skeletons/%s.glb"
const WEAPONS := "res://assets/weapons/skeleton/%s.gltf"
## Brinquedos e doces no lugar das armas cortantes (pedido do usuário em 2026-10-28: "o tema em geral deve ser
## mais infantilizado"; espada, forcado e machados saíram). Vêm da Coleção Completa do KayKit (Holiday Bits,
## RPG Tools Bits, Mystery Monthly 4 Palhaço e 5 Ajudantes) e não foram feitos para o osso handslot: cada um
## tem escala e ajuste para ficar do tamanho da arma que substitui, segurado pelo cabo, com a cabeça virada
## para onde ia o fio do machado (conferido em --brinquedos-captura). A bengala é segurada pela ponta reta,
## com o gancho na outra ponta; o martelão de palhaço vem com a cabeça de lado no arquivo e gira 90°.
const TOYS := {
	"Bengala": {"file": "candycane_large", "scale": 0.62, "pos": Vector3(0, -0.2, 0)},
	"MartelaoPalhaco": {"file": "clown_hammer", "scale": 1.6, "rot": Vector3(0, 90, 0)},
	"Marreta": {"file": "mallet", "scale": 3.0},
	"Martelinho": {"file": "Hammer", "scale": 1.3},
}
const TOY_DIR := "res://assets/weapons/brinquedos/%s.gltf"
## Armas do pacote que precisam de giro na mão. A besta aponta para +Z no arquivo, mas na mira de duas mãos
## (Ranged_2H do Character Animations) a frente é o +X do osso (o mesmo motivo do Weapons.ROTATION dos
## blasters): sem o giro, o Arqueiro e a Mira-Torta atiravam com a besta virada de lado (o usuário reparou em
## 2026-10-28).
const WEAPON_ROTATION := {"Skeleton_Crossbow": Vector3(0, 90, 0)}
const BALLOONS := ["red/ball_red", "blue/ball_blue", "yellow/ball_yellow", "green/ball_green"]
const PLAT := "res://assets/props/platformer/%s.gltf"
## Saída de balão: tempo até os balões aparecerem, até começar a subir, e até sumir.
const BALLOON_APPEAR := 0.35
const BALLOON_LIFT := 0.9
const BALLOON_GONE := 7.0

## kind: "melee" (golpe de perto), "pancada" (de perto, bate no chão e solta uma onda que se pula),
## "flecha" ou "bolha" (à distância), "rajada" (três dardos de espuma), "bote" (pulo em cima de quem está
## perto), "teleporte" (some e reaparece do lado de quem joga), "investida" (corre em linha reta com o escudo)
## e "bola_de_neve" (joga em arco, com círculo de aviso no chão). range: distância em que começa o ataque.
## windup: tempo do aviso até o golpe sair. rig "Large" usa o esqueleto grande do KayKit (ver LARGE_ANIMS).
## model / weapon_dir: quem não é esqueleto (ver model_path). anims: troca de animações para quem não é
## esqueleto (andar, sair do chão, dormir). skin: outra textura para o modelo.
const TYPES := {
	"Skeleton_Minion": {
		"kind": "melee", "health": 5.0, "speed": 2.4, "range": 1.8, "windup": 0.5, "cooldown": 1.6,
		"attack": "luta/Melee_Unarmed_Attack_Punch_A", "right": "", "left": "",
	},
	"Skeleton_Warrior": {
		"kind": "melee", "health": 8.0, "speed": 1.7, "range": 2.1, "windup": 0.55, "cooldown": 2.2,
		"attack": "luta/Melee_1H_Attack_Chop", "right": "Martelinho", "left": "Skeleton_Shield_Small_A",
		"shield": true,
	},
	"Skeleton_Rogue": {
		"kind": "flecha", "health": 4.0, "speed": 2.2, "range": 12.0, "windup": 0.8, "cooldown": 2.8,
		"aim": "tiro/Ranged_2H_Aiming", "attack": "tiro/Ranged_2H_Shoot", "right": "Skeleton_Crossbow", "left": "",
	},
	"Skeleton_Mage": {
		"kind": "bolha", "health": 4.0, "speed": 1.9, "range": 13.0, "windup": 0.7, "cooldown": 3.8,
		"aim": "tiro/Ranged_Magic_Spellcasting", "attack": "tiro/Ranged_Magic_Shoot", "right": "Skeleton_Staff", "left": "",
	},
	# Golem de Ossos: grandão e lento das ondas da mata. A pancada no chão solta uma onda (pular escapa);
	# empurrão de granada quase não mexe nele.
	"Skeleton_Golem": {
		"kind": "pancada", "health": 16.0, "speed": 1.5, "range": 3.6, "windup": 1.08, "cooldown": 3.0,
		"attack": "luta/Melee_Unarmed_Smash", "attack_speed": 0.85, "recover": 1.4, "right": "", "left": "",
		"rig": "Large", "scale": 0.85, "size": 1.7, "heavy": true,
	},
	# Esqueleto Pistoleiro (pedido do usuário em 2026-10-27: inimigos com pistola): um Minion com blaster do
	# Blaster Kit. Para a uns 9 m, anda de lado enquanto espera e solta três dardos de espuma seguidos (dá para
	# sair do caminho andando de lado).
	"Skeleton_Pistoleiro": {
		"kind": "rajada", "health": 4.0, "speed": 2.3, "range": 11.0, "windup": 0.65, "cooldown": 2.6,
		"aim": "tiro/Ranged_1H_Aiming", "attack": "tiro/Ranged_1H_Shoot", "right": "", "left": "",
		"model": "res://assets/characters/skeletons/Skeleton_Minion.glb", "blaster": "quindim", "strafe": true,
	},
	# Lobinho (Werewolf_Wolf), de pelo cinza (a outra pele do pacote, para não parecer o lenhador): corre rápido
	# e dá um bote em quem está perto; sair de lado escapa, e depois do bote ele fica uns instantes cansado.
	"Lobinho": {
		"kind": "bote", "health": 4.0, "speed": 4.4, "range": 6.5, "windup": 0.55, "cooldown": 1.6, "recover": 1.0,
		"attack": "luta/Melee_Unarmed_Idle", "right": "", "left": "",
		"model": "res://assets/characters/inimigos/Werewolf_Wolf.glb", "skin": "res://assets/characters/inimigos/werewolf_B.png",
		"anims": {"especial/Skeletons_Walking": "mov/Running_A", "especial/Skeletons_Idle": "geral/Idle_A",
			"especial/Skeletons_Spawn_Ground": "geral/Spawn_Ground", "especial/Skeletons_Awaken_Floor": "festa/Sit_Floor_StandUp",
			"especial/Skeletons_Inactive_Floor_Pose": "festa/Sit_Floor_Idle", "especial/Skeletons_Death": "festa/Sit_Floor_Down"},
	},
	# Conde (Vampire): bengala de doce na mão (até 2026-10-28, a espada do pacote). Longe, some numa nuvem de confete roxo e reaparece do lado do aventureiro
	# (um círculo roxo no chão avisa onde) e golpeia depois do "!"; quem sai do círculo escapa.
	"Conde": {
		"kind": "teleporte", "health": 6.0, "speed": 2.1, "range": 2.3, "windup": 0.6, "cooldown": 1.8,
		"attack": "luta/Melee_1H_Attack_Slice_Diagonal", "right": "Bengala", "left": "",
		"model": "res://assets/characters/inimigos/Vampire.glb", "weapon_dir": "res://assets/weapons/inimigos/%s.gltf",
		"anims": {"especial/Skeletons_Walking": "mov/Walking_A", "especial/Skeletons_Idle": "geral/Idle_A",
			"especial/Skeletons_Spawn_Ground": "geral/Spawn_Ground", "especial/Skeletons_Awaken_Floor": "geral/Spawn_Ground",
			"especial/Skeletons_Inactive_Floor_Pose": "geral/Death_A_Pose", "especial/Skeletons_Death": "geral/Death_A"},
	},
	# Grandalhão (Monstrosity, esqueleto grande): martelão de palhaço (até 2026-10-28, um forcado) e porta de
	# celeiro como escudo, que segura tiro de frente até na cabeça. Corre em linha reta (faixa vermelha no chão
	# avisa) e depois fica tonto, de escudo baixo.
	"Grandalhao": {
		"kind": "investida", "health": 14.0, "speed": 1.6, "range": 9.0, "windup": 0.95, "cooldown": 3.0, "recover": 1.8,
		"attack": "luta/Melee_Blocking", "right": "MartelaoPalhaco", "left": "Monstrosity_BarndoorShield_Large",
		"rig": "Large", "scale": 0.75, "size": 1.5, "heavy": true, "shield": true, "shield_head": true,
		"model": "res://assets/characters/inimigos/Monstrosity.glb", "weapon_dir": "res://assets/weapons/inimigos/%s.gltf",
	},
	# Golem de Gelo (FrostGolem, esqueleto grande): de longe joga bolas de neve em arco (um círculo no chão mostra
	# onde caem); de perto, pancada com uma marreta de madeira (até 2026-10-28, um machado de gelo).
	"GolemDeGelo": {
		"kind": "bola_de_neve", "health": 18.0, "speed": 1.3, "range": 17.0, "windup": 1.0, "cooldown": 3.2, "recover": 1.2,
		"attack": "luta/Melee_2H_Attack", "aim": "luta/Melee_2H_Idle", "right": "Marreta", "left": "",
		"rig": "Large", "scale": 0.85, "size": 1.7, "heavy": true,
		"model": "res://assets/characters/inimigos/FrostGolem.glb", "weapon_dir": "res://assets/weapons/inimigos/%s.gltf",
	},
}

## Nomes para as faixas e testes.
const NAMES := {"Skeleton_Minion": "Minion", "Skeleton_Warrior": "Guerreiro", "Skeleton_Rogue": "Arqueiro", "Skeleton_Mage": "Mago",
	"Skeleton_Golem": "Golem de Ossos", "Skeleton_Pistoleiro": "Pistoleiro", "Lobinho": "Lobinho", "Conde": "Conde",
	"Grandalhao": "Grandalhão", "GolemDeGelo": "Golem de Gelo"}
## Investida do Grandalhão e bote do Lobinho.
const CHARGE_SPEED := 10.0
const CHARGE_TIME := 0.8
const LEAP_TIME := 0.55
const BLINK_HIDE := 0.6
const BLINK_MARK := 0.55

## O esqueleto grande só tem parado, andar, levar golpe e golpes de luta: o resto vira o mais parecido.
const LARGE_ANIMS := {
	"especial/Skeletons_Walking": "mov/Walking_A", "especial/Skeletons_Idle": "geral/Idle_A",
	"especial/Skeletons_Awaken_Floor": "geral/Idle_A", "especial/Skeletons_Inactive_Floor_Pose": "geral/Death_A_Pose",
	"especial/Skeletons_Death": "geral/Death_A", "festa/Cheering": "luta/Melee_Unarmed_Idle",
	"festa/Waving": "geral/Idle_B", "geral/Hit_B": "geral/Hit_A",
}

@export var type_name := "Skeleton_Minion"
## Na ilha, o esqueleto começa dormindo (pilha de ossos) e se monta quando o aventureiro chega
## a aggro_radius metros. Se ele se afastar mais que leash_radius da casa, volta e deita de novo.
## Na arena dos testes, start_awake liga e os raios ficam enormes (comportamento antigo).
@export var start_awake := false
@export var aggro_radius := -1.0  # -1: 16 m para golpe de perto, 22 m para quem atira
@export var leash_radius := 45.0
## Esqueleto de onda: sai de uma rachadura (sobe do chão) e persegue o aventureiro por toda a região.
@export var from_crack := false

var target: Player
var health := 3.0
var state := State.ACORDANDO
var hurtboxes: Array[Hurtbox] = []
var config: Dictionary

var visual: Node3D
var model: Node3D
var ap: AnimationPlayer
var _warning: Label3D
var _hand_r: BoneAttachment3D
var _state_time := 0.0
var _rise_length := 1.0
var _balloons: Node3D
var _drift := Vector3.ZERO
var _start_y := 0.0
var _cooldown := 0.0
var _struck := false
var _spawn_point := Vector3.ZERO
## Tamanho relativo ao esqueleto comum (cápsula, regiões de impacto, aviso e balões).
var _size := 1.0
## Pistoleiro: boca do cano e lado para onde anda enquanto espera.
var _muzzle: Marker3D
var _strafe_sign := 1.0
## Bote do Lobinho e investida do Grandalhão: direção, para onde vai e se já acertou.
var _charge_dir := Vector3.ZERO
var _leap_to := Vector3.ZERO
var _hit_done := false
var _stripe: MeshInstance3D
## Grandalhão tonto depois da investida (escudo baixo).
var _dazed := 0.0
## Conde: espera para sumir de novo, ponto onde reaparece e o círculo que avisa.
var _blink_cooldown := 2.0
var _blink_spot := Vector3.ZERO
var _blink_mark: MeshInstance3D
## Contorna o pilar da lanterna, troncos e pedras em vez de empacar empurrando de frente.
var _detour := Detour.new()
## Golpes do Faísca (pedido do usuário em 2026-10-29: ele luta na Festa sem fim): soco, giro, pisão e laser
## chamam receber_golpe, como nas Bolotas das fases. Desmontado ou dormindo não conta como alvo.
var raio_golpe := 0.7
var derrotado: bool:
	get:
		return state in [State.INDO_EMBORA, State.ACORDANDO, State.DORMINDO, State.AFUNDANDO, State.SUMIDO]
var _last_punch := -10.0
var _want := Vector3.ZERO
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * 2.0


func _ready() -> void:
	add_to_group(Alvo.GRUPO)
	config = TYPES[type_name]
	health = config.health
	_size = config.get("size", 1.0)
	raio_golpe = 0.7 * _size
	collision_layer = 1 << 2
	collision_mask = 1 | (1 << 1) | (1 << 2)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.5 * _size
	capsule.height = 2.0 * _size
	shape.shape = capsule
	shape.position.y = 1.0 * _size
	add_child(shape)
	visual = Node3D.new()
	visual.name = "Visual"
	add_child(visual)
	model = load(model_path(type_name)).instantiate()
	model.scale = Vector3.ONE * config.get("scale", 1.0)
	visual.add_child(model)
	if config.has("skin"):
		_apply_skin(model, load(config.skin))
	if _large():
		ap = AnimUtil.make_player(model, ["geral", "mov", "luta"], "Large")
	else:
		ap = AnimUtil.make_player(model, ["geral", "mov", "mov2", "luta", "tiro", "especial", "festa"])
	var sk: Skeleton3D = model.find_child("Skeleton3D", true, false)
	_hand_r = _attach_weapon(sk, "handslot.r", config.right)
	_attach_weapon(sk, "handslot.l", config.left)
	if config.has("blaster"):
		_attach_blaster(config.blaster)
	_build_hurtboxes(sk)
	_warning = Label3D.new()
	_warning.text = "!"
	_warning.font_size = 140
	_warning.outline_size = 24
	_warning.modulate = Color("#ffd23f")
	_warning.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_warning.no_depth_test = true
	_warning.pixel_size = 0.006
	_warning.position.y = 3.0 * _size
	_warning.visible = false
	add_child(_warning)
	_spawn_point = global_position
	if aggro_radius < 0.0:
		aggro_radius = 16.0 if _close_range() else 22.0
	if from_crack and _large():
		# O esqueleto grande não tem animação de sair do chão: sobe da rachadura parado.
		_enter(State.ACORDANDO, "especial/Skeletons_Idle")
		_rise_length = 1.3
		visual.position.y = -2.0 * _size
		var tw := create_tween()
		tw.tween_property(visual, "position:y", 0.0, 1.2).set_ease(Tween.EASE_OUT)
		Fx.dust(get_parent(), global_position + Vector3.UP * 0.2)
	elif from_crack:
		# A animação de sair do chão tem 3,6 s: tocada 1,6x mais rápida para a onda não demorar.
		_enter(State.ACORDANDO, "")
		ap.play(&"especial/Skeletons_Spawn_Ground", 0.1, 1.6)
		_rise_length = ap.current_animation_length / 1.6
		visual.position.y = -1.2
		var tw := create_tween()
		tw.tween_property(visual, "position:y", 0.0, 0.6).set_ease(Tween.EASE_OUT)
		Fx.dust(get_parent(), global_position + Vector3.UP * 0.2)
	elif start_awake:
		_enter(State.ACORDANDO, "especial/Skeletons_Awaken_Floor")
	else:
		_enter(State.DORMINDO, "especial/Skeletons_Inactive_Floor_Pose")


## Onda cancelada: afunda de volta na rachadura e some (não conta como derrotado).
func sink_away() -> void:
	if state in [State.INDO_EMBORA, State.AFUNDANDO]:
		return
	_enter(State.AFUNDANDO, "especial/Skeletons_Death")
	velocity = Vector3.ZERO
	collision_mask = 0
	Fx.dust(get_parent(), global_position + Vector3.UP * 0.3)
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(visual, "position:y", -2.6, 0.9).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


## Volta para o lugar de origem (usado quando o aventureiro reaparece na bandeira):
## na ilha deita de novo; na arena acorda na hora. Quem já está indo embora segue o balão.
func reset_to_spawn() -> void:
	if state in [State.INDO_EMBORA, State.AFUNDANDO] or from_crack:
		return
	global_position = _spawn_point
	velocity = Vector3.ZERO
	health = config.health
	_cooldown = 1.5
	if start_awake:
		_enter(State.ACORDANDO, "especial/Skeletons_Awaken_Floor")
	else:
		_enter(State.DORMINDO, "especial/Skeletons_Inactive_Floor_Pose")


func _too_far(dist: float) -> bool:
	var from_home := Vector2(global_position.x - _spawn_point.x, global_position.z - _spawn_point.z).length()
	return from_home > leash_radius or dist > leash_radius + 15.0


## O .glb de um tipo: os esqueletos pelo nome; os outros (e o Pistoleiro, um Minion) em "model".
static func model_path(type_name: String) -> String:
	return TYPES.get(type_name, {}).get("model", SKELETONS % type_name)


## As armas do KayKit foram feitas para o osso handslot: encaixam sem ajuste. Os brinquedos (TOYS) vêm com o
## ajuste deles.
func _attach_weapon(sk: Skeleton3D, bone: String, weapon: String) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	sk.add_child(attachment)
	if weapon != "":
		attachment.add_child(held_item(weapon, config.get("weapon_dir", WEAPONS)))
	return attachment


## O que vai na mão: um brinquedo de TOYS (com escala e ajuste) ou uma arma do pacote, pelo nome.
static func held_item(item: String, weapon_fmt := WEAPONS) -> Node3D:
	if not TOYS.has(item):
		var w: Node3D = load(weapon_fmt % item).instantiate()
		w.rotation_degrees = WEAPON_ROTATION.get(item, Vector3.ZERO)
		return w
	var toy: Dictionary = TOYS[item]
	var n: Node3D = load(TOY_DIR % toy.file).instantiate()
	n.scale = Vector3.ONE * toy.scale
	n.rotation_degrees = toy.get("rot", Vector3.ZERO)
	n.position = toy.get("pos", Vector3.ZERO)
	return n


## Blaster do Blaster Kit na mão direita, encaixado como o do aventureiro (Weapons), com a boca do cano.
func _attach_blaster(id: String) -> void:
	var def := Weapons.find(id)
	var holder := Node3D.new()
	holder.position = def.pos
	holder.rotation_degrees = Weapons.ROTATION
	holder.scale = Vector3.ONE * def.escala
	_hand_r.add_child(holder)
	holder.add_child(load(Weapons.MODEL_DIR % def.modelo).instantiate())
	_muzzle = Marker3D.new()
	_muzzle.position = def.boca
	holder.add_child(_muzzle)


## Troca a textura de todas as malhas (o Lobinho de pelo cinza).
func _apply_skin(root: Node, tex: Texture2D) -> void:
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		for i in mesh.get_surface_count():
			var mat := mesh.surface_get_material(i)
			if mat is StandardMaterial3D:
				var copy: StandardMaterial3D = mat.duplicate()
				copy.albedo_texture = tex
				mi.set_surface_override_material(i, copy)


func _build_hurtboxes(sk: Skeleton3D) -> void:
	var head := SphereShape3D.new()
	head.radius = 0.5 * _size
	_add_hurtbox(sk, "head", "cabeça", 2.0, head, Vector3(0, 0.45, 0) * _size, Color(1, 0.85, 0.2, 0.35))
	var body := CapsuleShape3D.new()
	body.radius = 0.4 * _size
	body.height = 1.1 * _size
	_add_hurtbox(sk, "chest", "corpo", 1.0, body, Vector3(0, -0.2, 0) * _size, Color(1, 0.3, 0.3, 0.35))


func _large() -> bool:
	return config.get("rig", "Medium") == "Large"


## Quem ataca chegando perto (o golpe começa junto com o aviso).
func _close_range() -> bool:
	return config.kind in ["melee", "pancada", "bote", "teleporte", "investida"]


func _anim(anim_name: String) -> StringName:
	var own: Dictionary = config.get("anims", {})
	if own.has(anim_name):
		return StringName(own[anim_name])
	if _large():
		return StringName(LARGE_ANIMS.get(anim_name, anim_name))
	return StringName(anim_name)


func _add_hurtbox(sk: Skeleton3D, bone: String, region: String, mult: float, shape: Shape3D, offset: Vector3, debug_color: Color) -> void:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	sk.add_child(attachment)
	var hb := Hurtbox.new()
	hb.region = region
	hb.multiplier = mult
	hb.owner_target = self
	# O auxílio de mira do controle puxa para o corpo (alvo grande); a cabeça fica por conta de quem mira.
	hb.aim_assist = region == "corpo"
	attachment.add_child(hb)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = offset
	hb.add_child(cs)
	# Desenho da região, escondido; F3 mostra (grupo "regioes_de_impacto").
	var dbg := MeshInstance3D.new()
	if shape is SphereShape3D:
		var sm := SphereMesh.new()
		sm.radius = shape.radius
		sm.height = shape.radius * 2.0
		dbg.mesh = sm
	else:
		var cm := CapsuleMesh.new()
		cm.radius = shape.radius
		cm.height = shape.height
		dbg.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = debug_color
	mat.no_depth_test = true
	dbg.material_override = mat
	dbg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dbg.position = offset
	dbg.visible = false
	dbg.add_to_group(&"regioes_de_impacto")
	hb.add_child(dbg)
	hurtboxes.append(hb)


func _physics_process(delta: float) -> void:
	_state_time += delta
	_cooldown -= delta
	if state == State.INDO_EMBORA:
		_fly_away(delta)
		return
	if state == State.AFUNDANDO:
		return
	if not is_on_floor():
		velocity.y -= _gravity * delta
	var to_target := Vector3.ZERO
	var dist := INF
	if is_instance_valid(target):
		to_target = target.global_position - global_position
		to_target.y = 0.0
		dist = to_target.length()
	var target_down := is_instance_valid(target) and target.is_dizzy()

	# Com o aventureiro tonto, os esqueletos comemoram em vez de atacar.
	if target_down and state in [State.PERSEGUINDO, State.PREPARANDO, State.ATACANDO, State.ESPERANDO]:
		_hide_stripe()
		_enter(State.COMEMORANDO, "festa/Cheering")

	if state in [State.PERSEGUINDO, State.ESPERANDO] and _too_far(dist):
		_enter(State.VOLTANDO, "especial/Skeletons_Walking")

	match state:
		State.DORMINDO:
			_move(Vector3.ZERO)
			if dist < aggro_radius and not target_down:
				_enter(State.ACORDANDO, "especial/Skeletons_Awaken_Floor")
		State.VOLTANDO:
			var home := _spawn_point - global_position
			home.y = 0.0
			if dist < aggro_radius * 0.6 and not target_down:
				_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
			elif home.length() < 1.2:
				_move(Vector3.ZERO)
				_enter(State.DORMINDO, "especial/Skeletons_Death")
			else:
				_move(home.normalized() * config.speed)
				_face(home.normalized(), delta)
		State.PERSEGUINDO:
			_blink_cooldown -= delta
			if config.kind == "teleporte" and dist > 6.0 and dist < 40.0 and _blink_cooldown <= 0.0:
				_vanish()
			elif dist <= config.range and _cooldown <= 0.0 and _can_see_target():
				_start_attack()
			elif not _close_range() and dist <= config.range:
				_enter(State.ESPERANDO, "especial/Skeletons_Idle")
			elif dist < INF:
				var dir := to_target / dist
				_move(dir * config.speed)
				_face(dir, delta)
		State.ESPERANDO:
			_dazed -= delta
			if config.get("strafe", false) and dist < INF and _dazed <= 0.0:
				# O Pistoleiro anda de lado enquanto espera, trocando de lado de tempos em tempos.
				if fmod(_state_time, 1.6) < delta:
					_strafe_sign = -_strafe_sign if randf() < 0.7 else _strafe_sign
				var side := to_target.normalized().cross(Vector3.UP) * _strafe_sign
				_move(side * 1.7)
				var strafe_anim := _anim("mov2/Running_Strafe_Right" if _strafe_sign > 0.0 else "mov2/Running_Strafe_Left")
				if ap.current_animation != strafe_anim:
					ap.play(strafe_anim, 0.2, 0.8)
			else:
				_move(Vector3.ZERO)
			if dist < INF:
				_face(to_target.normalized(), delta)
			if _cooldown <= 0.0:
				if dist <= config.range and _can_see_target():
					_start_attack()
				elif dist > config.range:
					_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
		State.PREPARANDO:
			_move(Vector3.ZERO)
			if config.kind == "investida":
				# A faixa segue o aventureiro até pouco antes da largada.
				if _state_time < config.windup - 0.35 and dist < INF:
					_charge_dir = to_target.normalized()
					_face(_charge_dir, delta * 2.0)
				_place_stripe()
			elif dist < INF:
				_face(to_target.normalized(), delta * 0.6)
			if _state_time >= config.windup and not _struck:
				_struck = true
				_warning.visible = false
				_strike(dist, to_target)
				_enter(State.ATACANDO, _attack_anim())
		State.ATACANDO:
			match config.kind:
				"bote":
					_leap_step(delta)
				"investida":
					_charge_step(delta)
				_:
					_move(Vector3.ZERO)
					if _state_time > config.get("recover", 0.5):
						_cooldown = config.cooldown
						_enter(State.ESPERANDO, "especial/Skeletons_Idle")
		State.SUMIDO:
			_move(Vector3.ZERO)
			_blink_step(to_target)
		State.ATINGIDO:
			_move(Vector3.ZERO)
			if _state_time > 0.45:
				_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
		State.ACORDANDO:
			_move(Vector3.ZERO)
			if _state_time > _rise_length:
				health = config.health
				_set_hittable(true)
				_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")
		State.COMEMORANDO:
			_move(Vector3.ZERO)
			if not target_down:
				_cooldown = 1.0
				_enter(State.PERSEGUINDO if dist <= aggro_radius else State.VOLTANDO, "especial/Skeletons_Walking")
	move_and_slide()
	_detour.update(self, _want, delta)


func _start_attack() -> void:
	_struck = false
	_warning.visible = true
	Sfx.play_at(get_parent(), "alerta", global_position + Vector3.UP * 3.0)
	# Golpe de perto: a animação já começa no aviso e o dano sai no meio dela.
	_enter(State.PREPARANDO, config.attack if _close_range() else config.aim, config.get("attack_speed", 1.0))
	if config.kind == "investida" and is_instance_valid(target):
		var to := target.global_position - global_position
		to.y = 0.0
		_charge_dir = to.normalized() if to.length() > 0.01 else visual.global_basis.z
		_show_stripe()


func _strike(dist: float, to_target: Vector3) -> void:
	if not is_instance_valid(target):
		return
	match config.kind:
		"melee":
			Sfx.play_at(get_parent(), "golpe_ar", global_position + Vector3.UP * 1.2)
			var forward := visual.global_basis.z
			if dist <= config.range + 0.8 and forward.dot(to_target.normalized()) > 0.3:
				target.take_damage(1, global_position, name)
		"pancada":
			# Bate no chão na frente: quem está bem ali leva o golpe, e a onda corre pelo chão.
			var forward := visual.global_basis.z
			var center := global_position + forward * 1.8 * _size
			Sfx.play_at(get_parent(), "pancada", center)
			Fx.dust(get_parent(), center + Vector3.UP * 0.3)
			var wave := Boss.Shockwave.new()
			wave.target = target
			wave.max_radius = 9.0
			wave.speed = 7.0
			wave.source = name
			get_parent().add_child(wave)
			wave.global_position = Vector3(center.x, global_position.y + 0.05, center.z)
			if dist < 14.0:
				target.shake(0.15)
			if dist <= config.range and forward.dot(to_target.normalized()) > 0.3:
				target.take_damage(1, global_position, name)
		"flecha", "bolha":
			var from := _hand_r.global_position + Vector3.UP * 0.2 + visual.global_basis.z * 0.5
			var kind := Projectile.Kind.FLECHA if config.kind == "flecha" else Projectile.Kind.BOLHA
			get_parent().add_child(Projectile.create(kind, from, target))
			Sfx.play_at(get_parent(), config.kind, from)
		"rajada":
			_burst()
		"teleporte":
			Sfx.play_at(get_parent(), "golpe_ar", global_position + Vector3.UP * 1.2)
			if dist <= config.range + 0.8 and visual.global_basis.z.dot(to_target.normalized()) > 0.3:
				target.take_damage(1, global_position, name)
		"bote":
			_start_leap()
		"investida":
			_hide_stripe()
			_hit_done = false
			Sfx.play_at(get_parent(), "golpe_ar", global_position + Vector3.UP * 2.0, 3.0)
		"bola_de_neve":
			var forward := visual.global_basis.z
			if dist < 4.5:
				# De perto, marretada na frente.
				Sfx.play_at(get_parent(), "golpe_ar", global_position + Vector3.UP * 2.0)
				if forward.dot(to_target.normalized()) > 0.3:
					target.take_damage(1, global_position, name)
			else:
				var from := _hand_r.global_position + Vector3.UP * 0.4
				# Mira um pouco à frente de quem anda, para correr em linha reta não bastar.
				var lead := Vector3(target.velocity.x, 0.0, target.velocity.z) * 0.5
				var land := target.global_position + lead
				get_parent().add_child(Snowball.create(from, land, target, name))
				Sfx.play_at(get_parent(), "arremesso", from)


## Animação do golpe (a de perto já começou no aviso).
func _attack_anim() -> String:
	match config.kind:
		"bote":
			return "mov/Jump_Idle"
		"investida":
			return "mov/Running_A"
		"teleporte":
			return ""
	return config.attack if not _close_range() else ""


# --- Pistoleiro: três dardos de espuma -------------------------------------------------

func _burst() -> void:
	for k in 3:
		get_tree().create_timer(0.17 * k, false).timeout.connect(func() -> void:
			if not is_instance_valid(target) or state in [State.INDO_EMBORA, State.AFUNDANDO, State.ATINGIDO]:
				return
			var from := _muzzle.global_position if is_instance_valid(_muzzle) else _hand_r.global_position
			var dart := Projectile.create(Projectile.Kind.DARDO, from, target)
			dart.direction = dart.direction.rotated(Vector3.UP, deg_to_rad(randf_range(-3.0, 3.0)))
			get_parent().add_child(dart)
			if is_instance_valid(_muzzle):
				Fx.muzzle_flash(_muzzle)
			Sfx.play_at(get_parent(), "tiro", from, -6.0))


# --- Lobinho: bote ---------------------------------------------------------------------

## Pula até onde o aventureiro estava quando o "!" acabou (no máximo 7,5 m).
func _start_leap() -> void:
	var to := target.global_position - global_position
	to.y = 0.0
	if to.length() > 7.5:
		to = to.normalized() * 7.5
	_leap_to = global_position + to
	_charge_dir = to / LEAP_TIME
	_hit_done = false
	velocity = Vector3(_charge_dir.x, _gravity * LEAP_TIME * 0.5, _charge_dir.z)
	_want = Vector3.ZERO
	Sfx.play_at(get_parent(), "pulo", global_position)


func _leap_step(_delta: float) -> void:
	if _state_time < LEAP_TIME:
		velocity.x = _charge_dir.x
		velocity.z = _charge_dir.z
		_want = Vector3.ZERO
		return
	_move(Vector3.ZERO)
	if not _hit_done:
		_hit_done = true
		ap.play(_anim("mov/Jump_Land"), 0.1)
		Fx.dust(get_parent(), global_position + Vector3.UP * 0.2)
		if is_instance_valid(target) and target.global_position.distance_to(global_position) < 1.8:
			target.take_damage(1, global_position, name)
	if _state_time > LEAP_TIME + config.recover:
		_cooldown = config.cooldown
		_enter(State.PERSEGUINDO, "especial/Skeletons_Walking")


# --- Grandalhão: investida com a porta ----------------------------------------------------

func _charge_step(delta: float) -> void:
	if _state_time < CHARGE_TIME and _dazed <= 0.0:
		velocity.x = _charge_dir.x * CHARGE_SPEED
		velocity.z = _charge_dir.z * CHARGE_SPEED
		_want = Vector3.ZERO
		_face(_charge_dir, delta * 2.0)
		if not _hit_done and is_instance_valid(target) and target.global_position.distance_to(global_position) < 1.2 * _size + 0.6:
			_hit_done = true
			target.take_damage(1, global_position, name)
		var wall := false
		for i in get_slide_collision_count():
			var c := get_slide_collision(i)
			if not (c.get_collider() is Player) and absf(c.get_normal().y) < 0.5 and c.get_normal().dot(_charge_dir) < -0.5:
				wall = true
		if not wall:
			return
	# Acabou a corrida (ou bateu): fica tonto uns instantes, de escudo baixo.
	velocity.x = 0.0
	velocity.z = 0.0
	_dazed = config.recover
	_cooldown = config.cooldown
	Fx.popup_text(get_parent(), global_position + Vector3.UP * 3.2 * _size, "tonto!", Color("#ffd23f"))
	Sfx.play_at(get_parent(), "tonto", global_position + Vector3.UP * 2.0)
	_enter(State.ESPERANDO, "geral/Hit_A")


func _show_stripe() -> void:
	if not is_instance_valid(_stripe):
		_stripe = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.4 * _size, 0.05, CHARGE_SPEED * CHARGE_TIME)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1.0, 0.3, 0.35, 0.4)
		box.material = mat
		_stripe.mesh = box
		_stripe.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_stripe.top_level = true
		add_child(_stripe)
	_stripe.visible = true
	_place_stripe()


func _place_stripe() -> void:
	if not is_instance_valid(_stripe) or _charge_dir == Vector3.ZERO:
		return
	var mid := global_position + _charge_dir * (CHARGE_SPEED * CHARGE_TIME * 0.5)
	mid.y = global_position.y + 0.06
	_stripe.global_transform = Transform3D(Basis(Vector3.UP, atan2(_charge_dir.x, _charge_dir.z)), mid)


func _hide_stripe() -> void:
	if is_instance_valid(_stripe):
		_stripe.visible = false


# --- Conde: some e reaparece --------------------------------------------------------------

func _vanish() -> void:
	_enter(State.SUMIDO, "")
	_set_hittable(false)
	visual.visible = false
	_blink_spot = Vector3.INF
	Fx.confetti(get_parent(), global_position + Vector3.UP * 1.2, 40, 4.0)
	Sfx.play_at(get_parent(), "estouro", global_position + Vector3.UP)


func _blink_step(to_target: Vector3) -> void:
	if _state_time >= BLINK_HIDE and _blink_spot == Vector3.INF and is_instance_valid(target):
		# Do lado ou atrás de quem joga, a 2,6 m, num chão livre; o círculo roxo avisa.
		var base := target.global_position
		var away := -to_target.normalized() if to_target.length() > 0.1 else Vector3.BACK
		_blink_spot = base + away.rotated(Vector3.UP, randf_range(-1.2, 1.2)) * 2.6
		var query := PhysicsRayQueryParameters3D.create(_blink_spot + Vector3.UP * 4.0, _blink_spot + Vector3.DOWN * 6.0, 1)
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		_blink_spot = hit.position if hit else base
		_show_blink_mark()
	if _state_time >= BLINK_HIDE + BLINK_MARK and _blink_spot != Vector3.INF:
		global_position = _blink_spot + Vector3.UP * 0.1
		velocity = Vector3.ZERO
		visual.visible = true
		_set_hittable(true)
		if is_instance_valid(_blink_mark):
			_blink_mark.visible = false
		var look := target.global_position - global_position if is_instance_valid(target) else Vector3.FORWARD
		look.y = 0.0
		if look.length() > 0.01:
			visual.rotation.y = atan2(look.x, look.z)
		Fx.confetti(get_parent(), global_position + Vector3.UP * 1.2, 40, 4.0)
		Sfx.play_at(get_parent(), "estouro", global_position + Vector3.UP)
		_blink_cooldown = 4.5
		_start_attack()


func _show_blink_mark() -> void:
	if not is_instance_valid(_blink_mark):
		_blink_mark = MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 1.1
		disc.bottom_radius = 1.1
		disc.height = 0.05
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(0.69, 0.42, 1.0, 0.55)
		disc.material = mat
		_blink_mark.mesh = disc
		_blink_mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_blink_mark.top_level = true
		add_child(_blink_mark)
	_blink_mark.visible = true
	_blink_mark.global_position = _blink_spot + Vector3.UP * 0.05


func _can_see_target() -> bool:
	if not is_instance_valid(target):
		return false
	if _close_range():
		return true
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 1.5, target.global_position + Vector3.UP * 1.2, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _move(v: Vector3) -> void:
	_want = v
	v = _detour.steer(v)
	velocity.x = v.x
	velocity.z = v.z


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.01:
		return
	visual.rotation.y = lerp_angle(visual.rotation.y, atan2(dir.x, dir.z), 1.0 - exp(-8.0 * delta))


## anim_name vazio mantém a animação atual (o golpe de perto continua tocando).
func _enter(new_state: State, anim_name: String, speed := 1.0) -> void:
	state = new_state
	_state_time = 0.0
	if new_state != State.PREPARANDO:
		_warning.visible = false
	if anim_name != "":
		ap.play(_anim(anim_name), 0.15, speed)
	if new_state == State.ACORDANDO:
		_rise_length = ap.current_animation_length if ap.current_animation != "" else 1.0
		_set_hittable(false)
		if is_inside_tree():
			Sfx.play_at(get_parent(), "remontar", global_position + Vector3.UP, -3.0)
	elif new_state in [State.INDO_EMBORA, State.DORMINDO, State.AFUNDANDO]:
		_set_hittable(false)


func _set_hittable(on: bool) -> void:
	for hb in hurtboxes:
		hb.set_active(on)
	# Desmontado, o jogador passa por cima da pilha; a máscara continua batendo no chão.
	collision_layer = (1 << 2) if on else 0


func take_hit(amount: float, point: Vector3, hb: Hurtbox) -> void:
	if state in [State.INDO_EMBORA, State.ACORDANDO, State.DORMINDO, State.AFUNDANDO, State.SUMIDO]:
		return
	# O guerreiro segura o escudo na frente: tiro no corpo de frente não passa,
	# a não ser quando ele está erguendo o martelinho.
	var covered: bool = hb.region == "corpo" or config.get("shield_head", false)
	if config.get("shield", false) and covered and state != State.PREPARANDO and state != State.ATACANDO and _dazed <= 0.0:
		var from_front := visual.global_basis.z.dot((point - global_position).normalized()) > 0.2
		if from_front:
			Fx.dust(get_parent(), point)
			Fx.popup_text(get_parent(), point + Vector3.UP * 0.3, "bloqueou!", Color("#c9d1dc"))
			Sfx.play_at(get_parent(), "escudo", point)
			return
	_apply_damage(amount, point, hb.multiplier > 1.0)


## Golpe do Faísca: cada ponto do golpe vale 1,5 de dano (um soco tira mais que um tiro da Paçoca, mas o soco
## é mais lento e precisa chegar perto). O escudo não segura; o empurrão não mexe nos pesados. Um instante de
## imunidade dá o ritmo do laser, que encosta em todo quadro.
func receber_golpe(dano: int, de: Vector3, forca := 6.0, _tipo := "") -> bool:
	var now := Time.get_ticks_msec() / 1000.0
	if derrotado or now - _last_punch < 0.3:
		return false
	_last_punch = now
	if not config.get("heavy", false):
		var away := global_position - de
		away.y = 0.0
		velocity += (away.normalized() if away.length() > 0.05 else Vector3.ZERO) * forca * 0.6 + Vector3.UP * 2.0
	_apply_damage(dano * 1.5, global_position + Vector3.UP * 1.6 * _size, false)
	return true


## Explosão da granada: o escudo não segura, e o dano já vem com a distância descontada.
func take_explosion(amount: float, center: Vector3) -> void:
	if state in [State.INDO_EMBORA, State.ACORDANDO, State.DORMINDO, State.AFUNDANDO, State.SUMIDO]:
		return
	var away := global_position - center
	away.y = 0.0
	if not config.get("heavy", false):
		velocity += away.normalized() * 4.0 + Vector3.UP * 3.0
	_apply_damage(amount, global_position + Vector3.UP * 1.8, false)


func _apply_damage(amount: float, point: Vector3, crit: bool) -> void:
	health -= amount
	var shown := "%.1f" % amount if fmod(amount, 1.0) > 0.01 else "%d" % int(amount)
	Fx.popup_text(get_parent(), point + Vector3.UP * 0.3, "x2!" if crit else "-" + shown,
			Color("#ffd23f") if crit else Color.WHITE)
	if health <= 0.0:
		Fx.confetti(get_parent(), global_position + Vector3.UP * 1.2, 50, 5.0)
		_start_leaving()
		defeated.emit(self)
	else:
		# Levar tiro interrompe o ataque: dá chance para quem está aprendendo. No ar (bote) ou correndo
		# (investida) não dá para parar.
		if state == State.ATACANDO and config.kind in ["bote", "investida"]:
			return
		_hide_stripe()
		_cooldown = maxf(_cooldown, 0.8)
		_enter(State.ATINGIDO, "geral/Hit_A")


# --- indo embora de balão ----------------------------------------------------

func _start_leaving() -> void:
	_hide_stripe()
	if is_instance_valid(_blink_mark):
		_blink_mark.visible = false
	visual.visible = true
	_enter(State.INDO_EMBORA, "geral/Hit_B")
	velocity = Vector3.ZERO
	# Sem colisão: sobe atravessando telhados e copas sem enroscar.
	collision_mask = 0
	_start_y = global_position.y
	# Deriva de leve na direção do Morro (centro da ilha) enquanto sobe.
	var home := -global_position
	home.y = 0.0
	_drift = home.normalized() * 1.2 if home.length() > 1.0 else Vector3.ZERO
	_build_balloons()


## Três balões coloridos (bolas do Platformer Pack, um pouco esticadas) com cordinhas até
## um nó acima da cabeça. Nascem pequenos e enchem com um pulinho.
func _build_balloons() -> void:
	_balloons = Node3D.new()
	_balloons.name = "Baloes"
	_balloons.position.y = 2.6 * _size
	_balloons.scale = Vector3.ONE * 0.01
	add_child(_balloons)
	var colors := BALLOONS.duplicate()
	colors.shuffle()
	var spots := [Vector3(0, 2.2, 0), Vector3(-0.7, 1.7, 0.25), Vector3(0.7, 1.75, -0.2)]
	var string_mat := Fx.flat_material(Color(1, 1, 1, 1), false)
	for k in 3:
		var ball: Node3D = load(PLAT % colors[k]).instantiate()
		ball.scale = Vector3(0.42, 0.5, 0.42)
		ball.position = spots[k]
		_balloons.add_child(ball)
		var bottom: Vector3 = spots[k] - Vector3(0, 0.5, 0)
		var cord := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.015
		cyl.bottom_radius = 0.015
		cyl.height = bottom.length()
		cyl.material = string_mat
		cord.mesh = cyl
		cord.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cord.transform = Transform3D(Basis(Quaternion(Vector3.UP, bottom.normalized())), bottom * 0.5)
		_balloons.add_child(cord)
	var tw := _balloons.create_tween()
	tw.tween_interval(BALLOON_APPEAR)
	tw.tween_callback(func() -> void: Sfx.play_at(get_parent(), "balao", global_position + Vector3.UP * 3.0))
	tw.tween_property(_balloons, "scale", Vector3.ONE * sqrt(_size), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _fly_away(delta: float) -> void:
	if _state_time < BALLOON_LIFT:
		return
	if ap.current_animation != _anim("festa/Waving"):
		ap.play(_anim("festa/Waving"), 0.3)
		Fx.popup_text(get_parent(), global_position + Vector3.UP * 3.2 * _size, "Tchau!", Color("#ffd6f3"))
	var t := _state_time - BALLOON_LIFT
	var up := minf(0.6 + t * 1.4, 4.0)
	global_position += (Vector3.UP * up + _drift) * delta
	visual.rotation.z = sin(_state_time * 2.2) * 0.08
	_balloons.rotation.z = sin(_state_time * 2.2 + 0.6) * 0.12
	if _state_time > BALLOON_GONE or global_position.y - _start_y > 24.0:
		Fx.confetti(get_parent(), global_position + Vector3.UP * 4.0, 30, 3.0)
		gone.emit(self)
		queue_free()
