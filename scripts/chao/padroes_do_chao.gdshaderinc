// Desenhos do chão (item 13 da lista do Faísca, ideia do usuário em 2026-11-11: "colocar texturas no solo ao invés
// do chao cru, tanto pro faisca quanto jogo ilha"). Cada padrão é feito por conta, sem imagem, nas coordenadas do
// mundo (`p`, em metros, no plano do chão): não estica nos morros esticados nem emenda entre peças. Cada um devolve
// um multiplicador da cor de baixo, perto de 1: o desenho escurece e clareia a cor que já existe, sem trocar o tom
// (a grama continua do verde dela). `longe` (0 perto, 1 longe) apaga o detalhe fino, que de longe só piscaria.

float pc_h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec2 pc_h22(vec2 p) {
	float n = pc_h21(p);
	return vec2(n, pc_h21(p + n * 17.0));
}

float pc_ruido(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(pc_h21(i), pc_h21(i + vec2(1.0, 0.0)), u.x), mix(pc_h21(i + vec2(0.0, 1.0)), pc_h21(i + vec2(1.0, 1.0)), u.x), u.y);
}

float pc_fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * pc_ruido(p);
		p = p * 2.03 + vec2(7.1, 3.7);
		a *= 0.5;
	}
	return v;
}

// Células de Voronoi: x = distância ao centro mais perto, y = distância até a borda (aproximada), z = sorteio da célula.
vec3 pc_voronoi(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	vec2 id = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 r = g + pc_h22(i + g) * 0.85 + 0.075 - f;
			float d = dot(r, r);
			if (d < d1) {
				d2 = d1;
				d1 = d;
				id = i + g;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return vec3(sqrt(d1), sqrt(d2) - sqrt(d1), pc_h21(id));
}

// Linhas de rejunte numa grade de `tam` (0 no meio da peça, 1 em cima da linha), com a largura `w` em metros.
float pc_rejunte(vec2 p, vec2 tam, float w) {
	vec2 f = fract(p / tam) * tam;
	vec2 b = min(f, tam - f);
	return 1.0 - smoothstep(w * 0.5, w, min(b.x, b.y));
}

// Grama: manchas grandes de sol e sombra, tufos médios e folhinhas curtas viradas para todo lado, com pintinhas claras.
float pc_grama(vec2 p, float longe) {
	float m = mix(0.84, 1.1, pc_fbm(p * 0.07));
	m *= mix(0.93, 1.05, pc_ruido(p * 0.8));
	// Tufinhos em "V" de 1 m em 1 m, que ainda aparecem de meia distância.
	vec2 t = p / 1.1;
	vec2 ti = floor(t);
	vec2 tq = fract(t) - 0.5 - (pc_h22(ti + 9.3) - 0.5) * 0.5;
	float lado = abs(tq.x);
	float v_forma = (1.0 - smoothstep(0.025, 0.06, abs(tq.y - lado * 1.6 + 0.08))) * (1.0 - smoothstep(0.12, 0.17, lado))
			* step(-0.12, tq.y);
	m *= 1.0 - 0.14 * v_forma * step(0.35, pc_h21(ti)) * (1.0 - longe * 0.5);
	vec2 c = p / 0.3;
	vec2 ci = floor(c);
	float folhas = 0.0;
	for (int k = 0; k < 2; k++) {
		vec2 cc = ci + float(k) * 13.7;
		float a = pc_h21(cc) * 6.2832;
		vec2 dir = vec2(cos(a), sin(a));
		vec2 q = fract(c) - 0.5 - (pc_h22(cc + 3.1) - 0.5) * 0.4;
		float ao_longo = dot(q, dir);
		float de_lado = dot(q, vec2(-dir.y, dir.x));
		folhas = max(folhas, (1.0 - smoothstep(0.035, 0.075, abs(de_lado))) * (1.0 - smoothstep(0.16, 0.24, abs(ao_longo))));
	}
	m *= 1.0 - 0.13 * folhas * (1.0 - longe);
	vec3 v = pc_voronoi(p * 1.3);
	m *= 1.0 + 0.1 * step(0.86, v.z) * (1.0 - smoothstep(0.06, 0.12, v.x)) * (1.0 - longe);
	return m;
}

// Terra da trilha: pedrinhas redondas (umas mais claras, outras mais escuras) e a terra manchada em volta.
float pc_terra(vec2 p, float longe) {
	float m = mix(0.9, 1.06, pc_fbm(p * 0.45));
	vec3 v = pc_voronoi(p * 2.4);
	float pedra = 1.0 - smoothstep(0.16, 0.24, v.x);
	m *= 1.0 + (v.z - 0.45) * 0.2 * pedra * (1.0 - longe);
	return m;
}

// Areia: ondinhas do vento e o granulado fino.
float pc_areia(vec2 p, float longe) {
	float m = mix(0.95, 1.04, pc_fbm(p * 0.25));
	float onda = sin(p.x * 1.7 + p.y * 0.6 + pc_fbm(p * 0.2) * 7.0);
	m *= 1.0 + 0.07 * onda * (1.0 - longe * 0.4);
	m *= 0.975 + 0.05 * pc_ruido(p * 18.0) * (1.0 - longe);
	return m;
}

// Pedra: lajes irregulares com as rachaduras escuras entre elas, cada laje num tom.
float pc_pedra(vec2 p, float longe) {
	vec3 v = pc_voronoi(p * 0.55);
	float racha = 1.0 - smoothstep(0.02, 0.07, v.y);
	float m = mix(0.92, 1.05, v.z) * mix(0.93, 1.04, pc_fbm(p * 0.6));
	m *= 1.0 - 0.22 * racha * (1.0 - longe * 0.6);
	return m;
}

// Calçada: ladrilhos quadrados com rejunte e cada um num tom.
float pc_calcada(vec2 p, float tam, float longe) {
	float m = mix(0.95, 1.04, pc_h21(floor(p / tam)));
	m *= 1.0 - 0.2 * pc_rejunte(p, vec2(tam), 0.08) * (1.0 - longe * 0.7);
	m *= mix(0.97, 1.02, pc_ruido(p * 1.5));
	return m;
}

// Tijolinhos da praça, desencontrados a cada fileira.
float pc_praca(vec2 p, float longe) {
	vec2 t = p / vec2(1.2, 0.6);
	t.x += step(1.0, mod(floor(t.y), 2.0)) * 0.5;
	vec2 q = t * vec2(1.2, 0.6);
	float m = mix(0.93, 1.05, pc_h21(floor(t)));
	m *= 1.0 - 0.2 * pc_rejunte(q, vec2(1.2, 0.6), 0.07) * (1.0 - longe * 0.7);
	return m;
}

// Madeira: tábuas compridas (1 m de largura, por causa da cozinha gigante) com as emendas desencontradas e os veios.
float pc_madeira(vec2 p, float longe) {
	float fileira = floor(p.y / 1.0);
	float x = p.x + pc_h21(vec2(fileira, 3.0)) * 7.0;
	float tabua = floor(x / 6.0);
	float m = mix(0.9, 1.06, pc_h21(vec2(fileira, tabua)));
	vec2 f = vec2(fract(x / 6.0) * 6.0, fract(p.y / 1.0));
	float emenda = max(1.0 - smoothstep(0.015, 0.04, min(f.y, 1.0 - f.y)), 1.0 - smoothstep(0.02, 0.05, min(f.x, 6.0 - f.x)));
	m *= 1.0 - 0.28 * emenda * (1.0 - longe * 0.6);
	float veio = sin(p.y * 22.0 + pc_fbm(vec2(x * 0.25, p.y * 3.0)) * 9.0);
	m *= 1.0 + 0.05 * veio * (1.0 - longe);
	return m;
}

// Tapete: a trama de fios em cima e embaixo, em xadrez miúdo, e umas manchinhas de uso.
float pc_tapete(vec2 p, float longe) {
	vec2 t = p / 0.18;
	vec2 f = fract(t) - 0.5;
	float xadrez = mod(floor(t.x) + floor(t.y), 2.0);
	float fio = mix(smoothstep(0.0, 0.5, abs(f.y)), smoothstep(0.0, 0.5, abs(f.x)), xadrez);
	float m = 1.0 - 0.12 * fio * (1.0 - longe);
	m *= mix(0.94, 1.04, pc_fbm(p * 0.3));
	return m;
}

// Neve: montinhos macios e pontinhos que brilham e piscam devagar.
float pc_neve(vec2 p, float longe, float tempo) {
	// Fica entre 0,8 e 1: a neve é quase branca, então o desenho só aparece escurecendo (o pc_cor pinta de azulado).
	// Quase tudo branco; a sombra fica nos montinhos (manchas grandes) e nas marcas onduladas do vento.
	float m = 1.0 - 0.26 * smoothstep(0.5, 0.78, pc_fbm(p * 0.12));
	float vento = 0.5 + 0.5 * sin(p.x * 0.8 + p.y * 0.3 + pc_fbm(p * 0.25) * 6.0);
	m -= 0.1 * smoothstep(0.85, 1.0, vento);
	vec2 c = p / 0.35;
	vec2 ci = floor(c);
	float h = pc_h21(ci);
	float perto = 1.0 - smoothstep(0.03, 0.07, length(fract(c) - pc_h22(ci + 5.0)));
	float pisca = 0.5 + 0.5 * sin(tempo * 2.5 + h * 40.0);
	m *= 1.0 + 0.9 * step(0.9, h) * perto * pisca * (1.0 - longe);
	return m;
}

// Gelo: rachaduras finas e claras e riscos de patins.
float pc_gelo(vec2 p, float longe) {
	vec3 v = pc_voronoi(p * 0.35);
	float racha = 1.0 - smoothstep(0.01, 0.035, v.y);
	float m = mix(0.95, 1.04, pc_fbm(p * 0.2));
	m *= 1.0 + 0.18 * racha * (1.0 - longe * 0.5);
	m *= 1.0 + 0.04 * (1.0 - smoothstep(0.0, 0.02, abs(sin(p.x * 0.7 + p.y * 1.3 + pc_ruido(p * 0.1) * 4.0)))) * (1.0 - longe);
	return m;
}

// Metal: chapas de 2 m com as emendas escuras, os rebites nos cantos e o escovado.
float pc_metal(vec2 p, float longe) {
	float m = mix(0.95, 1.04, pc_h21(floor(p / 2.0)));
	m *= 1.0 - 0.25 * pc_rejunte(p, vec2(2.0), 0.06) * (1.0 - longe * 0.6);
	vec2 f = fract(p / 2.0) * 2.0;
	vec2 canto = min(f, 2.0 - f);
	float rebite = 1.0 - smoothstep(0.05, 0.08, length(canto - vec2(0.18)));
	m *= 1.0 + 0.25 * rebite * (1.0 - longe);
	m *= 1.0 + 0.025 * sin(p.x * 30.0 + pc_ruido(p * vec2(0.5, 6.0)) * 3.0) * (1.0 - longe);
	return m;
}

// Algodão-doce: bolinhas fofas, claras no meio e com a sombrinha entre elas.
float pc_algodao(vec2 p, float longe) {
	vec3 v = pc_voronoi(p * 0.8);
	float fofo = 1.0 - smoothstep(0.0, 0.65, v.x);
	float m = mix(0.85, 1.07, fofo) * mix(0.94, 1.04, pc_fbm(p * 0.35));
	return mix(m, 1.0, longe * 0.4);
}

// O padrão pelo número (a mesma ordem do TexturaDoChao.PADROES).
float pc_padrao(int qual, vec2 p, float longe, float tempo) {
	if (qual == 0) return pc_grama(p, longe);
	if (qual == 1) return pc_terra(p, longe);
	if (qual == 2) return pc_areia(p, longe);
	if (qual == 3) return pc_pedra(p, longe);
	if (qual == 4) return pc_calcada(p, 1.0, longe);
	if (qual == 5) return pc_praca(p, longe);
	if (qual == 6) return pc_madeira(p, longe);
	if (qual == 7) return pc_tapete(p, longe);
	if (qual == 8) return pc_neve(p, longe, tempo);
	if (qual == 9) return pc_gelo(p, longe);
	if (qual == 10) return pc_metal(p, longe);
	if (qual == 11) return pc_algodao(p, longe);
	return 1.0;
}

// Nas encostas (a face em pé), o desenho vai na parede: no plano xy ou zy, o que estiver mais de frente.
vec2 pc_plano(vec3 pos, vec3 normal) {
	if (normal.y > 0.6) return pos.xz;
	return abs(normal.x) > abs(normal.z) ? pos.zy : pos.xy;
}

// De 0 (perto) a 1 (longe): o detalhe fino some entre `perto` e `longe` metros da câmera (na fase, 14 e 55 m; na
// ilha, onde a câmera fica mais longe, mais adiante).
float pc_longe(float distancia, float perto, float longe) {
	return smoothstep(perto, longe, distancia);
}

// A cor do desenho: o multiplicador em cinza; na neve, o escuro vira sombra azulada e o brilho passa de 1.
vec3 pc_cor(int qual, float m) {
	if (qual == 8) {
		// A fase da neve é bem clara (o branco passa do limite da tela): a sombra precisa ser forte para aparecer.
		return mix(vec3(0.5, 0.64, 0.95), vec3(1.0), clamp((m - 0.7) / 0.3, 0.0, 1.0)) * max(m, 1.0);
	}
	return vec3(m);
}
