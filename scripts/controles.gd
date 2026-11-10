class_name Controles
extends RefCounted
## As ações de teclado, mouse e controle do jogo inteiro: o menu principal, a ilha e o Faísca. Vieram do
## main.gd quando o menu principal separou os dois jogos (pedido do usuário em 2026-11-10); o InputMap vale
## para todas as cenas, então configurar duas vezes duplicaria os botões.

static var _feito := false


## Teclado e mouse mais controle. Os nomes de botão seguem o controle de Xbox
## (no de PlayStation: A = X, B = círculo, LT/RT = L2/R2, LB/RB = L1/R1, Back = Share, Start = Options).
static func configurar() -> void:
	if _feito:
		return
	_feito = true
	_bind_key("frente", [KEY_W, KEY_UP])
	_bind_key("tras", [KEY_S, KEY_DOWN])
	_bind_key("esquerda", [KEY_A, KEY_LEFT])
	_bind_key("direita", [KEY_D, KEY_RIGHT])
	_bind_axis("frente", JOY_AXIS_LEFT_Y, -1.0)
	_bind_axis("tras", JOY_AXIS_LEFT_Y, 1.0)
	_bind_axis("esquerda", JOY_AXIS_LEFT_X, -1.0)
	_bind_axis("direita", JOY_AXIS_LEFT_X, 1.0)
	_bind_axis("olhar_esquerda", JOY_AXIS_RIGHT_X, -1.0)
	_bind_axis("olhar_direita", JOY_AXIS_RIGHT_X, 1.0)
	_bind_axis("olhar_cima", JOY_AXIS_RIGHT_Y, -1.0)
	_bind_axis("olhar_baixo", JOY_AXIS_RIGHT_Y, 1.0)

	_bind_key("correr", [KEY_SHIFT])
	_bind_button("correr_alternar", JOY_BUTTON_LEFT_STICK)
	_bind_key("pular", [KEY_SPACE])
	_bind_button("pular", JOY_BUTTON_A)
	_bind_mouse("atirar", MOUSE_BUTTON_LEFT)
	_bind_axis("atirar", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_bind_key("recarregar", [KEY_R])
	_bind_button("recarregar", JOY_BUTTON_X)
	_bind_key("granada", [KEY_G])
	_bind_button("granada", JOY_BUTTON_RIGHT_SHOULDER)
	_bind_key("interagir", [KEY_E])
	_bind_button("interagir", JOY_BUTTON_B)
	_bind_key("corpo_a_corpo", [KEY_F])
	_bind_mouse("corpo_a_corpo", MOUSE_BUTTON_MIDDLE)
	_bind_button("corpo_a_corpo", JOY_BUTTON_RIGHT_STICK)
	_bind_mouse("arma_proxima", MOUSE_BUTTON_WHEEL_UP)
	_bind_button("arma_proxima", JOY_BUTTON_Y)
	_bind_mouse("arma_anterior", MOUSE_BUTTON_WHEEL_DOWN)
	for i in Weapons.count():
		_bind_key("arma_%d" % (i + 1), [KEY_1 + i])
		_bind_button("arma_%d" % (i + 1), Weapons.DPAD[i])
	_bind_mouse("mirar", MOUSE_BUTTON_RIGHT)
	_bind_axis("mirar", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_bind_button("mirar", JOY_BUTTON_LEFT_SHOULDER)
	InputMap.action_set_deadzone("atirar", 0.3)
	InputMap.action_set_deadzone("mirar", 0.3)

	_bind_key("regioes", [KEY_F3])
	# Lojinha no celular (pedido do usuário: o botão Select; no controle de PlayStation, Share/Create).
	_bind_key("celular", [KEY_C])
	_bind_button("celular", JOY_BUTTON_BACK)
	_bind_key("menu", [KEY_TAB, KEY_ESCAPE])
	_bind_button("menu", JOY_BUTTON_START)
	# Faísca (Parte 2): golpe no X / quadrado (F, J ou clique) e Back / R volta ao começo da fase. Na ilha
	# os mesmos botões são do aventureiro (recarregar, celular); só um dos dois lê o controle de cada vez.
	_bind_key("golpe", [KEY_F, KEY_J])
	_bind_mouse("golpe", MOUSE_BUTTON_LEFT)
	_bind_button("golpe", JOY_BUTTON_X)
	_bind_key("recomecar", [KEY_R])
	_bind_button("recomecar", JOY_BUTTON_BACK)
	# Movimentos do Astro (2026-10-29): Y agarra a Bolota (E, K ou botão direito) e a seta para baixo dança (V).
	_bind_key("agarrar", [KEY_E, KEY_K])
	_bind_mouse("agarrar", MOUSE_BUTTON_RIGHT)
	_bind_button("agarrar", JOY_BUTTON_Y)
	_bind_key("dancar", [KEY_V])
	_bind_button("dancar", JOY_BUTTON_DPAD_DOWN)
	# Na Godot 4.7 os menus aceitam o direcional, mas confirmar e voltar não vêm ligados ao controle.
	_bind_button("ui_accept", JOY_BUTTON_A)
	_bind_button("ui_cancel", JOY_BUTTON_B)


static func _ensure_action(action: String) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)


static func _bind_key(action: String, keys: Array) -> void:
	_ensure_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


static func _bind_mouse(action: String, button: MouseButton) -> void:
	_ensure_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)


static func _bind_button(action: String, button: JoyButton) -> void:
	_ensure_action(action)
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	ev.device = -1
	InputMap.action_add_event(action, ev)


static func _bind_axis(action: String, axis: JoyAxis, direction: float) -> void:
	_ensure_action(action)
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = direction
	ev.device = -1
	InputMap.action_add_event(action, ev)
