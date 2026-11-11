class_name DualSense
extends Node
## Gatilhos adaptáveis do DualSense (item 14 da lista de melhorias, pedido do usuário em 2026-11-10: "colocar efeito
## de pressão pra controle dual sense se conectado"). A Godot 4.7 não tem nada para os gatilhos: aqui o jogo escreve o
## relatório de saída direto no controle, pelo /dev/hidrawN do Linux (o PC Bazzite; as regras da Steam já deixam o
## usuário escrever no DualSense). Em outro sistema, ou sem o controle, ou sem permissão, não faz nada.
## Os bytes são os mesmos da página de teste do usuário (Projects/others/teste-dualsense, conferidos com o SDL e o
## fork do KytyPS5): o bloco comum de 47 bytes, com os efeitos do R2 no byte 10 e do L2 no 21 (11 bytes cada); no
## USB vai no relatório 0x02 (48 bytes com o id) e no Bluetooth no 0x31 (78 bytes, com o CRC32 no fim). Só as
## bandeiras dos gatilhos vão ligadas (0x04 e 0x08): a vibração dos motores continua com a Godot.
## O que cada gatilho faz no jogo (`escolher`): o R2 muda com o blaster (estalinho na pistola, tremidinho na rajada da
## metralhadora, estalo forte na escopeta, gatilho duro no rifle), o L2 tem uma resistência leve para mirar, no kart o
## R2 acelera macio e o L2 freia duro, e com menu aberto, tonto ou a vibração desligada nos Ajustes, tudo solto.

const SONY := "054c"
const DUALSENSE := ["0ce6", "0df2"]

## Caminho do dispositivo e se é Bluetooth (vazio: nenhum DualSense achado).
var caminho := ""
var bluetooth := false
## O par de efeitos que está no controle agora (R2, L2), para só mandar quando muda.
var atual := []
## Quantos relatórios foram mandados (os testes olham).
var enviados := 0
var game: Node
var _arquivo: FileAccess
var _procurar := 0.0


func _ready() -> void:
	procurar()


func _exit_tree() -> void:
	soltar()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		soltar()


## Procura um DualSense nos hidraw do Linux (USB 0003 ou Bluetooth 0005, Sony 054C, DualSense ou DualSense Edge).
func procurar() -> bool:
	caminho = ""
	if OS.get_name() != "Linux" or not DirAccess.dir_exists_absolute("/sys/class/hidraw"):
		return false
	# Os hidraw são links simbólicos para pastas; em vez de listar, tenta os 32 primeiros nomes.
	for n in 32:
		var nome := "hidraw%d" % n
		var arquivo_uevent := "/sys/class/hidraw/%s/device/uevent" % nome
		if not FileAccess.file_exists(arquivo_uevent):
			continue
		var uevent := FileAccess.get_file_as_string(arquivo_uevent)
		var info := ler_uevent(uevent)
		if info.is_empty():
			continue
		caminho = "/dev/" + nome
		bluetooth = info.bluetooth
		_arquivo = FileAccess.open(caminho, FileAccess.WRITE)
		if _arquivo == null:
			caminho = ""
			continue
		return true
	return false


## Da linha HID_ID do uevent ("HID_ID=0005:0000054C:00000CE6"): é DualSense? por Bluetooth?
static func ler_uevent(texto: String) -> Dictionary:
	for linha in texto.split("\n"):
		if not linha.begins_with("HID_ID="):
			continue
		var partes := linha.substr(7).to_lower().split(":")
		if partes.size() < 3:
			return {}
		var vid := partes[1].right(4)
		var pid := partes[2].right(4)
		if vid == SONY and pid in DUALSENSE:
			return {"bluetooth": partes[0].right(4) == "0005"}
	return {}


func _physics_process(delta: float) -> void:
	if caminho == "":
		# O controle pode ser ligado depois: procura de novo a cada 5 s.
		_procurar -= delta
		if _procurar <= 0.0:
			_procurar = 5.0
			procurar()
		return
	var par := escolher()
	if par != atual:
		mandar(par[0], par[1])


## Os efeitos de agora: [R2, L2].
func escolher() -> Array:
	var solto := [efeito_solto(), efeito_solto()]
	if game == null or not Ajustes.vibracao or game.menu_state != "":
		return solto
	var p: Player = game.player
	if not is_instance_valid(p) or p.dizzy or p.parked or not p.using_gamepad:
		return solto
	if p.in_vehicle:
		return [efeito_resistencia(2, 3), efeito_resistencia(1, 7)]
	if p.pescando or p.using_phone:
		return solto
	var r2 := efeito_solto()
	match Weapons.index_of(p.current_weapon().id):
		0:
			r2 = efeito_arma(4, 6, 4)
		1:
			r2 = efeito_vibracao(3, 6, 14)
		2:
			r2 = efeito_arma(3, 6, 8)
		3:
			r2 = efeito_resistencia(2, 7)
	return [r2, efeito_resistencia(1, 2)]


func soltar() -> void:
	if caminho != "" and atual != [efeito_solto(), efeito_solto()]:
		mandar(efeito_solto(), efeito_solto())


func mandar(r2: PackedByteArray, l2: PackedByteArray) -> void:
	atual = [r2, l2]
	if _arquivo == null:
		return
	_arquivo.store_buffer(relatorio(bloco_comum(r2, l2), bluetooth))
	_arquivo.flush()
	if _arquivo.get_error() != OK:
		# Desligou ou caiu: procura de novo depois.
		_arquivo = null
		caminho = ""
		return
	enviados += 1


# --- os bytes ------------------------------------------------------------------------

static func efeito_solto() -> PackedByteArray:
	var e := PackedByteArray()
	e.resize(11)
	e[0] = 0x05
	return e


## Zonas de 0 a 9 com força de 0 (nada) a 8; tipo 0x21 é resistência e 0x26 é vibração.
static func efeito_zonas(tipo: int, forcas: Array, frequencia := 0) -> PackedByteArray:
	var e := PackedByteArray()
	e.resize(11)
	var ativas := 0
	var juntas := 0
	for i in 10:
		var s: int = forcas[i]
		if s > 0:
			ativas |= 1 << i
			juntas |= (s - 1) << (3 * i)
	e[0] = tipo if ativas != 0 and (tipo != 0x26 or frequencia != 0) else 0x05
	e[1] = ativas & 0xff
	e[2] = (ativas >> 8) & 0xff
	e[3] = juntas & 0xff
	e[4] = (juntas >> 8) & 0xff
	e[5] = (juntas >> 16) & 0xff
	e[6] = (juntas >> 24) & 0xff
	e[9] = frequencia & 0xff
	return e


static func _a_partir(posicao: int, forca: int) -> Array:
	var s := []
	for i in 10:
		s.append(forca if i >= posicao else 0)
	return s


## Resistência do ponto `posicao` (0 a 9) para baixo, com força 1 a 8.
static func efeito_resistencia(posicao: int, forca: int) -> PackedByteArray:
	return efeito_zonas(0x21, _a_partir(posicao, forca))


## Tremidinho do ponto `posicao` para baixo (amplitude 1 a 8, frequência em Hz).
static func efeito_vibracao(posicao: int, amplitude: int, frequencia: int) -> PackedByteArray:
	return efeito_zonas(0x26, _a_partir(posicao, amplitude), frequencia)


## Estalo de gatilho de arma: resistência entre `inicio` (2 a 7) e `fim` (inicio+1 a 8) que solta de repente.
static func efeito_arma(inicio: int, fim: int, forca: int) -> PackedByteArray:
	var e := PackedByteArray()
	e.resize(11)
	var zonas := (1 << inicio) | (1 << fim)
	e[0] = 0x25
	e[1] = zonas & 0xff
	e[2] = (zonas >> 8) & 0xff
	e[3] = forca - 1
	return e


## O bloco comum de 47 bytes: só as bandeiras dos dois gatilhos, R2 no byte 10 e L2 no 21.
static func bloco_comum(r2: PackedByteArray, l2: PackedByteArray) -> PackedByteArray:
	var c := PackedByteArray()
	c.resize(47)
	c[0] = 0x04 | 0x08
	for i in 11:
		c[10 + i] = r2[i]
		c[21 + i] = l2[i]
	return c


## O relatório completo para escrever no hidraw (com o id na frente): USB 0x02 (48 bytes) ou Bluetooth 0x31 (78
## bytes, com o cabeçalho 0x02 do SDL e o CRC32 de [0xA2, 0x31] + os 73 primeiros bytes de dados no fim).
static func relatorio(comum: PackedByteArray, bt: bool) -> PackedByteArray:
	var r := PackedByteArray()
	if not bt:
		r.append(0x02)
		r.append_array(comum)
		return r
	var d := PackedByteArray()
	d.resize(77)
	d[0] = 0x02
	for i in comum.size():
		d[1 + i] = comum[i]
	var semente := PackedByteArray([0xA2, 0x31])
	var crc := crc32(d.slice(0, 73), crc32(semente))
	d[73] = crc & 0xff
	d[74] = (crc >> 8) & 0xff
	d[75] = (crc >> 16) & 0xff
	d[76] = (crc >> 24) & 0xff
	r.append(0x31)
	r.append_array(d)
	return r


static var _tabela := PackedInt64Array()


## CRC32 do zlib, que continua de onde parou: crc32(b, crc32(a)) == crc32(a + b).
static func crc32(bytes: PackedByteArray, crc := 0) -> int:
	if _tabela.is_empty():
		_tabela.resize(256)
		for n in 256:
			var c := n
			for k in 8:
				c = (0xEDB88320 ^ (c >> 1)) if (c & 1) != 0 else (c >> 1)
			_tabela[n] = c
	var c := (~crc) & 0xFFFFFFFF
	for b in bytes:
		c = _tabela[(c ^ b) & 0xff] ^ (c >> 8)
	return (~c) & 0xFFFFFFFF
