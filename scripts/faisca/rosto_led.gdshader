shader_type spatial;
// Tela do capacete do Faísca (pedido do usuário em 2026-10-29: "viseira brilhante com olhos de LED que mudam
// de expressão"). Vidro preto envernizado com os olhos de LED desenhados por distância (SDF) no espaço da
// própria malha da viseira, então os olhos acompanham a curva da tela. O `Robo` escolhe a forma, pisca e
// mexe o olhar pelos parâmetros.

uniform vec3 cor_led : source_color = vec3(0.56, 0.95, 1.0);
uniform float energia = 2.2;
// 0 normal, 1 feliz, 2 surpreso, 3 bravo, 4 dor, 5 tonto, 6 coração (ver Robo.EXPRESSOES).
uniform int forma = 0;
// 1 aberto; perto de 0, fechado (piscando).
uniform float abertura = 1.0;
// Deslocamento dos dois olhos juntos, em metros na tela (olhadinhas para os lados).
uniform vec2 olhar = vec2(0.0);
uniform float separacao = 0.14;
uniform float altura = 0.01;

varying vec3 p;

void vertex() {
	p = VERTEX;
}

float segmento(vec2 q, vec2 a, vec2 b) {
	vec2 pa = q - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
	return length(pa - ba * h);
}

// Coração de ponta para baixo em y = 0, uns 1,06 de altura (a fórmula do Inigo Quilez).
float coracao(vec2 q) {
	q.x = abs(q.x);
	if (q.y + q.x > 1.0) {
		return length(q - vec2(0.25, 0.75)) - sqrt(2.0) / 4.0;
	}
	vec2 m = q - 0.5 * max(q.x + q.y, 0.0);
	return sqrt(min(dot(q - vec2(0.0, 1.0), q - vec2(0.0, 1.0)), dot(m, m))) * sign(q.x - q.y);
}

// Um olho, com x positivo para fora (longe do meio da tela) e y para cima. `lado` é -1 ou 1.
float olho(vec2 q, float lado) {
	if (forma == 1) {
		// Feliz: arco de cabeça para baixo (^ ^).
		vec2 r = q - vec2(0.0, -0.03);
		if (r.y > 0.0) {
			return abs(length(r) - 0.058) - 0.019;
		}
		return length(vec2(abs(r.x) - 0.058, r.y)) - 0.019;
	}
	if (forma == 2) {
		// Surpreso: bolona.
		return length(q) - 0.072;
	}
	if (forma == 3) {
		// Bravo (golpes): a pílula com o topo cortado em diagonal, mais baixo do lado de dentro.
		float d = segmento(q, vec2(0.0, -0.047), vec2(0.0, 0.047)) - 0.058;
		return max(d, (q.y - 0.018 - 0.6 * q.x) / sqrt(1.36));
	}
	if (forma == 4) {
		// Dor: > <, com a ponta para dentro.
		float d = min(segmento(q, vec2(-0.045, 0.0), vec2(0.04, 0.052)), segmento(q, vec2(-0.045, 0.0), vec2(0.04, -0.052)));
		return d - 0.018;
	}
	if (forma == 5) {
		// Tonto: espiral girando, cada olho para um lado.
		float r = length(q);
		float a = atan(q.y, q.x) + TIME * 7.0 * lado;
		float passo = 0.027;
		float t = r / passo - a / TAU;
		return max(abs(t - round(t)) * passo - 0.0075, r - 0.078);
	}
	if (forma == 6) {
		// Coração.
		float s = 0.13;
		return coracao((q - vec2(0.0, -0.068)) / s) * s;
	}
	// Normal: pílula em pé.
	return segmento(q, vec2(0.0, -0.047), vec2(0.0, 0.047)) - 0.058;
}

void fragment() {
	vec2 c = p.xy - olhar - vec2(0.0, altura);
	float lado = c.x < 0.0 ? -1.0 : 1.0;
	vec2 q = vec2(abs(c.x) - separacao, c.y / max(abertura, 0.06));
	float d = olho(q, lado);
	float aa = max(fwidth(d), 0.0004);
	float frente = step(0.0, p.z);
	float led = (1.0 - smoothstep(-aa, aa, d)) * frente;
	// Brilho fraquinho em volta do LED, como luz atrás do vidro.
	float halo = exp(-max(d, 0.0) / 0.016) * 0.3 * frente;
	// Miolo mais claro, quase branco.
	float miolo = (1.0 - smoothstep(-0.04, -0.012, d)) * led;
	// Linhas de LED: só aparecem de perto (somem quando ficam menores que um pixel).
	float linhas = 0.5 + 0.5 * cos(p.y * TAU / 0.011);
	float de_perto = clamp(1.0 - fwidth(p.y) / 0.0035, 0.0, 1.0);
	float faixa = mix(1.0, 0.78 + 0.22 * linhas, de_perto);

	// Reflexo pintado no canto de cima, à esquerda: uma faixa curva e um pontinho. Garante o
	// brilho do vidro mesmo onde a luz da cena não faz reflexo.
	vec2 g = p.xy - vec2(0.12, -0.34);
	float ang = atan(g.y, g.x);
	float arco = abs(length(g) - 0.55);
	float trecho = smoothstep(1.92, 2.05, ang) * (1.0 - smoothstep(2.32, 2.45, ang));
	float reflexo = (1.0 - smoothstep(0.008, 0.02, arco)) * trecho;
	reflexo += 1.0 - smoothstep(0.008, 0.016, length(p.xy - vec2(-0.355, 0.075)));
	reflexo *= frente * (1.0 - led);

	vec3 vidro = vec3(0.012, 0.016, 0.028);
	ALBEDO = mix(mix(vidro, vec3(0.85), reflexo * 0.5), cor_led * 0.5, led);
	ROUGHNESS = mix(0.06, 0.35, led);
	METALLIC = 0.25 * (1.0 - led);
	SPECULAR = 0.75;
	CLEARCOAT = 1.0;
	CLEARCOAT_ROUGHNESS = 0.04;
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
	EMISSION = cor_led * energia * (led * faixa + halo) + vec3(1.0) * miolo * 0.3 * energia * faixa
			+ vec3(0.3, 0.5, 0.65) * fresnel * 0.22 + vec3(0.9) * reflexo * 0.12;
}
