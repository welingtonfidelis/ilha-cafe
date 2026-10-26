class_name SkateRider
extends SkeletonModifier3D
## Pose de quem anda de skate (pedido do usuário em 2026-10-26: "empurrando o skate com uma perna como seria
## no mundo real"; o KayKit não tem animação de skate). Por cima da animação parada: os quadris baixam um
## pouco (joelhos dobrados), o pé esquerdo fica firme na tábua e, ao dar impulso, o direito desce para o
## chão ao lado do skate, empurra para trás e volta para a tábua. No ar, os dois pés ficam na tábua e o
## corpo encolhe. Os pés são encaixados com conta de perna de duas partes (coxa e canela), com o joelho
## dobrando para a frente. Espaço do esqueleto: frente +Z, cima +Y, esquerda +X; a tábua fica no y dos pés
## em pé e o chão fica `lift` abaixo.

## Duração de um impulso (s) e trechos dele: desce até CONTACT, empurra até PUSH_END, volta para a tábua.
const CYCLE := 0.75
const CONTACT := 0.18
const PUSH_END := 0.62

## Altura da tábua em relação aos pés (o modelo sobe isso quando sobe no skate).
var lift := 0.24
## Dando impulso agora (o jogador segura para a frente e está no chão).
var pushing := false
var airborne := false
## Andamento do impulso, de 0 a 1 (o jogador lê para empurrar só com o pé no chão).
var phase := 0.0
## Altura do pé direito em relação à tábua no último quadro (negativa: abaixo dela; para os testes, porque
## fora da modificação o esqueleto volta para a pose da animação).
var right_foot_drop := 0.0

var _weight := 0.0
var _bones := {}
## Quadris: o que foi somado no quadro anterior (se a animação não regravar a posição, não acumula).
var _hips_written := Vector3.INF
var _hips_base := Vector3.ZERO
var _rest_foot := {}


func _ready() -> void:
	var sk := get_skeleton()
	if sk == null:
		return
	for b in ["hips", "spine", "chest", "upperleg.l", "lowerleg.l", "foot.l", "upperleg.r", "lowerleg.r", "foot.r"]:
		_bones[b] = sk.find_bone(b)
	for side in ["l", "r"]:
		_rest_foot[side] = sk.get_bone_global_rest(_bones["foot." + side]).origin


## O pé do impulso está no chão (empurrando)?
func foot_down() -> bool:
	return _weight > 0.5 and phase > CONTACT and phase < PUSH_END


func _process_modification() -> void:
	var sk := get_skeleton()
	if sk == null or _bones.is_empty():
		return
	var delta := get_process_delta_time() if not Engine.is_in_physics_frame() else get_physics_process_delta_time()
	if pushing and not airborne:
		phase = fposmod(phase + delta / CYCLE, 1.0)
	elif _weight < 0.05:
		phase = 0.0
	_weight = move_toward(_weight, 1.0 if pushing and not airborne else 0.0, delta * 4.0)
	var crouch := lerpf(0.06 if not airborne else 0.12, 0.2, _weight)
	_lower_hips(sk, crouch)
	_turn(sk, "chest", Vector3.RIGHT, 0.10 + 0.12 * _weight)
	var left_foot: Vector3 = _rest_foot["l"]
	var right_board: Vector3 = _rest_foot["r"]
	var right_foot := right_board.lerp(_push_path(right_board), _weight)
	_leg(sk, "l", left_foot)
	_leg(sk, "r", right_foot)
	right_foot_drop = sk.get_bone_global_pose(_bones["foot.r"]).origin.y - right_board.y


## Caminho do pé do impulso: desce na frente e para fora da tábua, arrasta para trás no chão e sobe de volta.
func _push_path(board: Vector3) -> Vector3:
	var ground_y := board.y - lift
	var front := Vector3(board.x - 0.16, ground_y, board.z + 0.12)
	var back := Vector3(board.x - 0.16, ground_y, board.z - 0.42)
	var up_back := Vector3(board.x - 0.1, board.y + 0.1, board.z - 0.3)
	if phase < CONTACT:
		var t := phase / CONTACT
		return board.lerp(front, t) + Vector3.UP * sin(PI * t) * 0.06
	if phase < PUSH_END:
		return front.lerp(back, smoothstep(0.0, 1.0, (phase - CONTACT) / (PUSH_END - CONTACT)))
	var u := (phase - PUSH_END) / (1.0 - PUSH_END)
	if u < 0.5:
		return back.lerp(up_back, u * 2.0)
	return up_back.lerp(board, (u - 0.5) * 2.0)


func _lower_hips(sk: Skeleton3D, amount: float) -> void:
	var hips: int = _bones["hips"]
	var parent := sk.get_bone_parent(hips)
	var pb := sk.get_bone_global_pose(parent).basis if parent >= 0 else Basis.IDENTITY
	var now := sk.get_bone_pose_position(hips)
	if not now.is_equal_approx(_hips_written):
		_hips_base = now
	_hips_written = _hips_base + pb.inverse() * Vector3(0, -amount, 0)
	sk.set_bone_pose_position(hips, _hips_written)


## Perna de duas partes: coloca o pé em `target` com o joelho dobrando para a frente, e deixa o pé reto.
func _leg(sk: Skeleton3D, side: String, target: Vector3) -> void:
	var up_i: int = _bones["upperleg." + side]
	var low_i: int = _bones["lowerleg." + side]
	var foot_i: int = _bones["foot." + side]
	var foot_basis := Basis(sk.get_bone_global_rest(foot_i).basis.get_rotation_quaternion())
	var hip := sk.get_bone_global_pose(up_i).origin
	var knee := sk.get_bone_global_pose(low_i).origin
	var foot := sk.get_bone_global_pose(foot_i).origin
	var l1 := hip.distance_to(knee)
	var l2 := knee.distance_to(foot)
	var to := target - hip
	var d := clampf(to.length(), absf(l1 - l2) + 0.001, l1 + l2 - 0.001)
	var dir := to.normalized()
	var a := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var h := sqrt(maxf(l1 * l1 - a * a, 0.0))
	var bend := Vector3.BACK - dir * Vector3.BACK.dot(dir)
	bend = bend.normalized() if bend.length() > 0.01 else Vector3.BACK
	var knee_want := hip + dir * a + bend * h
	_aim(sk, up_i, knee - hip, knee_want - hip)
	knee = sk.get_bone_global_pose(low_i).origin
	foot = sk.get_bone_global_pose(foot_i).origin
	_aim(sk, low_i, foot - knee, (hip + dir * d) - knee)
	# Pé reto, como no descanso.
	var low_basis := sk.get_bone_global_pose(low_i).basis.orthonormalized()
	sk.set_bone_pose_rotation(foot_i, (low_basis.inverse() * foot_basis).get_rotation_quaternion())


## Gira o osso (no espaço do esqueleto) para o vetor `from` apontar para `to`.
func _aim(sk: Skeleton3D, bone: int, from: Vector3, to: Vector3) -> void:
	if from.length() < 0.0001 or to.length() < 0.0001:
		return
	var parent := sk.get_bone_parent(bone)
	var pg := sk.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
	var g := sk.get_bone_global_pose(bone).basis.orthonormalized()
	var turned := Basis(Quaternion(from.normalized(), to.normalized())) * g
	sk.set_bone_pose_rotation(bone, (pg.inverse() * turned).get_rotation_quaternion())


func _turn(sk: Skeleton3D, bone_name: String, axis: Vector3, angle: float) -> void:
	var bone: int = _bones.get(bone_name, -1)
	if bone < 0:
		return
	var parent := sk.get_bone_parent(bone)
	var pg := sk.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
	var local := Basis(sk.get_bone_pose_rotation(bone))
	sk.set_bone_pose_rotation(bone, (pg.inverse() * Basis(axis, angle) * pg * local).get_rotation_quaternion())
