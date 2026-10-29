class_name AreaDeMola
extends Area3D
## A área que joga o Faísca para o alto, usada pela mola, pelo cristal da 1-2 e pelo sorvete da 2-1. Confere a
## cada quadro quem está dentro, em vez de só quem entra: quem pula em cima entra subindo e pousa já dentro,
## sem "entrar" de novo, e antes ficava parado em cima sem pular (achado na 2-1, em 2026-10-29). Joga quem
## estiver dentro sem estar subindo, e o `visual` dá a amassadinha.

var forca := 17.0
var visual: Node3D
var escala_normal := Vector3.ONE
var amassado := Vector3.ONE
var _espera := 0.0


func _init() -> void:
	collision_layer = 0
	collision_mask = Fase.CAMADA_JOGADOR


func _physics_process(delta: float) -> void:
	_espera -= delta
	if _espera > 0.0:
		return
	for corpo in get_overlapping_bodies():
		if corpo is Jogador and (corpo as Jogador).velocity.y <= 1.0:
			(corpo as Jogador).lancar(forca)
			_espera = 0.25
			if is_instance_valid(visual):
				var tw := visual.create_tween()
				tw.tween_property(visual, "scale", amassado, 0.06)
				tw.tween_property(visual, "scale", escala_normal, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
			return
