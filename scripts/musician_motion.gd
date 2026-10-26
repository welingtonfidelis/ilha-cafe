class_name MusicianMotion
extends SkeletonModifier3D
## Movimento de quem toca na banda, por cima da pose de base (o KayKit não tem animação de tocar):
## - "sopro" (trompete): os braços sobem até o trompete (que fica na boca), o tronco marca o tempo indo e
##   voltando, a cabeça acompanha e, a cada frase, o músico inclina para trás como numa nota longa;
## - "cordas" (violão): o antebraço direito faz a palhetada, o esquerdo troca de acorde devagar e o corpo
##   balança de um lado para o outro.
## No ritmo do tema (112 batidas por minuto). Os eixos são do modelo: frente +Z, cima +Y, esquerda +X.

const BPM := 112.0

@export var style := "sopro"
## Desencontro entre músicos, para não balançarem todos iguais.
@export var phase := 0.0

var _bones := {}


func _ready() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	for b in ["spine", "chest", "head", "upperarm.r", "upperarm.l", "lowerarm.r", "lowerarm.l"]:
		_bones[b] = sk.find_bone(b)


func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or _bones.is_empty():
		return
	var t := Time.get_ticks_msec() / 1000.0 + phase
	var beat := TAU * BPM / 60.0 * t
	if style == "sopro":
		var phrase := maxf(sin(t * 0.9), 0.0)
		_turn(sk, "spine", Vector3.FORWARD, sin(beat * 0.5) * 0.05)
		_turn(sk, "chest", Vector3.RIGHT, sin(beat) * 0.06 - phrase * 0.12)
		_turn(sk, "head", Vector3.RIGHT, sin(beat + 0.6) * 0.05 - phrase * 0.06)
		_turn(sk, "upperarm.r", Vector3.RIGHT, -0.38)
		_turn(sk, "upperarm.l", Vector3.RIGHT, -0.38)
	else:
		_turn(sk, "spine", Vector3.FORWARD, sin(beat * 0.5) * 0.07)
		_turn(sk, "head", Vector3.RIGHT, absf(sin(beat)) * 0.12 - 0.04)
		_turn(sk, "lowerarm.r", Vector3.RIGHT, sin(beat * 2.0) * 0.32)
		_turn(sk, "lowerarm.l", Vector3.UP, sin(t * 1.3) * 0.08)


## Gira o osso em volta de um eixo do modelo, a partir da pose que a animação deixou.
func _turn(sk: Skeleton3D, bone_name: String, axis: Vector3, angle: float) -> void:
	var bone: int = _bones.get(bone_name, -1)
	if bone < 0:
		return
	var parent := sk.get_bone_parent(bone)
	var pg := sk.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
	var local := Basis(sk.get_bone_pose_rotation(bone))
	var turned := pg.inverse() * Basis(axis, angle) * pg * local
	sk.set_bone_pose_rotation(bone, turned.get_rotation_quaternion())
