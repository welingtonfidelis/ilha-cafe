class_name ControleFaisca
extends RefCounted
## O DualSense no jogo do Faísca (item 3 da lista de melhorias dele, pedido do usuário em 2026-11-11: "Sim,
## começa"). É o `perfil` do nó DualSense: a cada quadro, diz os efeitos dos gatilhos, a cor da barra de luz e os
## 5 LEDs de baixo. O R2 também dá o golpe e o L2 também agarra (Controles).
## - R2: um estalinho em cada soco; segurando (a carga do giro forte), vai ficando duro; girando forte, treme; com o
##   Martelinho de Apito, o estalo forte da pancada; puxado pelo Ioiô, treme como o fio esticado; com a Luva de
##   Neve, um estalo fofo.
## - L2: com uma Bolota agarrada, pesa; sem nada, solto.
## - Luz: o azul do Faísca; a cor do poder da fase (rosa do Balão de Chiclete, verde do Ioiô, branco-azulado da Luva
##   de Neve, laranja do Martelinho); com 1 coração, vermelho piscando; e as piscadas de festa (`piscar`): o
##   Faisquinha salvo, a Estrela Grande, o coração.
## - LEDs: os corações, no desenho de jogador do controle (1 no meio, 2 separados, 3 alternados).
## Com a pausa, cena, tela de fim ou a vibração desligada nos Ajustes, os gatilhos ficam soltos (a luz continua).

const AZUL_FAISCA := Color8(0, 170, 255)
const VERMELHO := Color8(255, 0, 0)
const VERMELHO_FRACO := Color8(50, 0, 0)
const CORES_PODER := {"balao": Color8(255, 70, 170), "ioio": Color8(60, 230, 80), "luva": Color8(170, 220, 255),
	"martelinho": Color8(255, 110, 0)}
const LEDS_VIDA := [0x00, 0x04, 0x0A, 0x15]

var faisca: Jogador
## Devolve se o jogo está ocupado (pausa, cena, tela de fim): gatilhos soltos.
var ocupado: Callable
var _piscada := DualSense.SEM_LUZ
var _piscada_ate := 0.0


func _init(j: Jogador, esta_ocupado: Callable) -> void:
	faisca = j
	ocupado = esta_ocupado


## Uma cor de festa por `segundos` no lugar da de sempre.
func piscar(cor: Color, segundos: float) -> void:
	_piscada = cor
	_piscada_ate = _agora() + segundos


func _agora() -> float:
	return Time.get_ticks_msec() / 1000.0


## [R2, L2, luz, leds]. `tempo` (os testes) troca o relógio de verdade.
func escolher(tempo := -1.0) -> Array:
	var t := tempo if tempo >= 0.0 else _agora()
	var solto := DualSense.efeito_solto()
	if not is_instance_valid(faisca):
		return [solto, solto, AZUL_FAISCA, LEDS_VIDA[3]]
	var leds: int = LEDS_VIDA[clampi(faisca.vida, 0, 3)]
	var luz := cor_da_luz(t)
	var parado: bool = ocupado.is_valid() and ocupado.call()
	if parado or not Ajustes.vibracao or not faisca.controle_ligado:
		return [solto, solto, luz, leds]
	return [gatilho_direito(), gatilho_esquerdo(), luz, leds]


func cor_da_luz(t: float) -> Color:
	if _piscada.a > 0.0 and t < _piscada_ate:
		# A piscada de festa pulsa um pouco (3 vezes por segundo).
		return _piscada.darkened(0.35 * (0.5 + 0.5 * sin(t * TAU * 3.0)))
	if faisca.vida == 1:
		return VERMELHO if fmod(t, 0.8) < 0.4 else VERMELHO_FRACO
	var poder := poder_atual()
	return CORES_PODER[poder] if poder != "" else AZUL_FAISCA


## O poder da fase que ele tem agora ("" sem nenhum).
func poder_atual() -> String:
	if faisca.martelinho:
		return "martelinho"
	if faisca.luva_de_neve:
		return "luva"
	if faisca.ioio:
		return "ioio"
	if faisca.balao_de_chiclete:
		return "balao"
	return ""


func gatilho_direito() -> PackedByteArray:
	if faisca.no_ioio:
		return DualSense.efeito_vibracao(2, 5, 28)
	if faisca.giro_forte > 0.0:
		return DualSense.efeito_vibracao(1, 6, 22)
	var carga := faisca.carga_do_golpe()
	if carga > 0.0:
		# Fica mais duro em 4 degraus (para não mandar um relatório por quadro).
		return DualSense.efeito_resistencia(2, 2 + int(round(carga * 3.0)))
	if faisca.martelinho:
		return DualSense.efeito_arma(3, 6, 8)
	if faisca.luva_de_neve:
		return DualSense.efeito_arma(2, 5, 4)
	return DualSense.efeito_arma(4, 6, 3)


func gatilho_esquerdo() -> PackedByteArray:
	if faisca.agarrada != null:
		return DualSense.efeito_resistencia(1, 5)
	return DualSense.efeito_solto()
