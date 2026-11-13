// O campo e a mata (pedido do usuário em 2026-11-11: "melhorar a textura da parte de grama e mata"), em comum entre o
// terreno da ilha (terreno_da_ilha.gdshader) e a grama das fases do Faísca (grama_das_fases.gdshader): desenho com cor,
// não só claro e escuro. Precisa do padroes_do_chao.gdshaderinc antes. A cor de entrada e a de saída são em linear.

vec3 linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

// Florzinha de 5 pétalas (1 dentro), com `q` em metros a partir do meio dela e `r` o raio das pétalas.
float flor(vec2 q, float r, float aa) {
	float borda = r * (0.6 + 0.4 * abs(cos(atan(q.y, q.x) * 2.5)));
	return 1.0 - smoothstep(borda - aa, borda + aa, length(q));
}

// O campo (pedido do usuário em 2026-11-11: "melhorar a textura da parte de grama e mata"): manchas de sol
// amareladas e de grama funda azulada, tufinhos em "V" escuros com a pontinha clara, as folhinhas curtas e
// canteirinhos de florzinhas brancas, amarelas e cor-de-rosa. A cor sai pronta (em linear).
// `tufos` é a força dos tufinhos em "V" (1 na ilha; nas fases, com a câmera mais baixa, eles apareciam como setinhas).
vec3 campo(vec2 p, vec3 base, float longe, float aa, float tufos) {
	float sol = smoothstep(0.28, 0.72, pc_fbm(p * 0.045));
	vec3 cor = base * mix(vec3(0.66, 0.82, 0.8), vec3(1.2, 1.1, 0.72), sol);
	cor *= mix(0.86, 1.06, pc_ruido(p * 0.55));
	float perto_ = 1.0 - longe;
	// Tufinhos: um "V" escuro e, logo acima, a pontinha clara e amarelada.
	vec2 t = p / 0.7;
	vec2 ti = floor(t);
	if (pc_h21(ti) > 0.4) {
		// Cada tufinho virado para um lado (todos iguais formavam fileiras de setinhas).
		vec2 tq0 = (fract(t) - 0.5 - (pc_h22(ti + 9.3) - 0.5) * 0.5) * 0.7;
		float giro = (pc_h21(ti + 4.4) - 0.5) * 2.4;
		vec2 tq = vec2(tq0.x * cos(giro) - tq0.y * sin(giro), tq0.x * sin(giro) + tq0.y * cos(giro));
		float lado = abs(tq.x);
		float braco = abs(tq.y - lado * 1.7 + 0.05);
		float v_forma = (1.0 - smoothstep(0.02 - aa, 0.045 + aa, braco)) * (1.0 - smoothstep(0.13, 0.17, lado)) * step(-0.06, tq.y);
		float ponta = (1.0 - smoothstep(0.015 - aa, 0.035 + aa, abs(tq.y - lado * 1.7 - 0.02))) * (1.0 - smoothstep(0.1, 0.16, lado))
				* smoothstep(0.05, 0.1, lado);
		cor *= 1.0 - 0.36 * tufos * v_forma * perto_;
		cor = mix(cor, cor * vec3(1.3, 1.25, 0.85), ponta * 0.8 * tufos * perto_);
	}
	// As folhinhas curtas, viradas para todo lado.
	vec2 c = p / 0.32;
	vec2 ci = floor(c);
	float a = pc_h21(ci) * 6.2832;
	vec2 dir = vec2(cos(a), sin(a));
	vec2 q = (fract(c) - 0.5 - (pc_h22(ci + 3.1) - 0.5) * 0.4) * 0.32;
	float folha = (1.0 - smoothstep(0.012 - aa, 0.026 + aa, abs(dot(q, vec2(-dir.y, dir.x))))) * (1.0 - smoothstep(0.05, 0.08, abs(dot(q, dir))));
	cor *= 1.0 - 0.22 * folha * perto_;
	// Florzinhas: só nos canteirinhos (manchas do prado), uma por célula de 1,3 m em parte das células.
	float prado = smoothstep(0.46, 0.62, pc_fbm(p * 0.07 + 13.0));
	vec2 fc = p / 0.9;
	vec2 fi = floor(fc);
	float h = pc_h21(fi + 21.0);
	if (h > 1.0 - 0.6 * prado) {
		vec2 meio = (fi + 0.25 + 0.5 * pc_h22(fi + 7.0)) * 0.9;
		vec2 fq = p - meio;
		float tam = 0.1 + 0.06 * pc_h21(fi + 2.0);
		float k = pc_h21(fi + 5.0);
		vec3 petala = k < 0.45 ? vec3(1.0, 1.0, 0.95) : (k < 0.75 ? vec3(1.0, 0.82, 0.18) : vec3(1.0, 0.55, 0.78));
		vec3 miolo = k < 0.45 ? vec3(1.0, 0.78, 0.15) : vec3(1.0, 0.95, 0.75);
		// Some antes do resto: de longe, florzinha vira chuvisco.
		float mostra = perto_ * perto_ * prado;
		cor = mix(cor, linear(petala) * 0.95, flor(fq, tam, aa) * mostra);
		cor = mix(cor, linear(miolo), (1.0 - smoothstep(tam * 0.32 - aa, tam * 0.32 + aa, length(fq))) * mostra);
	}
	return cor;
}

// O chão da mata: verde mais fechado com manchas de musgo claro e de sombra, a grama curta, folhas secas espalhadas
// (laranja, amarelas, marrons e vermelhas, mais onde não tem musgo) e uns gravetinhos.
vec3 mata(vec2 p, vec3 base, float longe, float aa) {
	float musgo = smoothstep(0.35, 0.7, pc_fbm(p * 0.06 + 5.0));
	vec3 cor = base * mix(vec3(0.74, 0.84, 0.86), vec3(1.06, 1.18, 0.82), musgo);
	cor *= mix(0.88, 1.05, pc_ruido(p * 0.7));
	float perto_ = 1.0 - longe;
	vec2 c = p / 0.32;
	vec2 ci = floor(c);
	float a = pc_h21(ci) * 6.2832;
	vec2 dir = vec2(cos(a), sin(a));
	vec2 q = (fract(c) - 0.5 - (pc_h22(ci + 3.1) - 0.5) * 0.4) * 0.32;
	float folhinha = (1.0 - smoothstep(0.012 - aa, 0.026 + aa, abs(dot(q, vec2(-dir.y, dir.x))))) * (1.0 - smoothstep(0.04, 0.07, abs(dot(q, dir))));
	cor *= 1.0 - 0.18 * folhinha * perto_;
	// Folhas secas em montinhos (manchas do chão longe do musgo), em duas camadas de células de 0,45 m desencontradas.
	float pilha = smoothstep(0.42, 0.68, pc_fbm(p * 0.1 + 31.0)) * (1.0 - musgo * 0.75);
	for (int k = 0; k < 2; k++) {
		vec2 fc = p / 0.45 + vec2(0.5 * float(k), 0.37 * float(k));
		vec2 fi = floor(fc);
		float h = pc_h21(fi + float(k) * 31.0);
		if (h < 0.06 + 0.5 * pilha) {
			vec2 fq = (fract(fc) - (0.3 + 0.4 * pc_h22(fi + 3.0 + float(k)))) * 0.45;
			float ang = pc_h21(fi + 11.0 + float(k)) * 6.2832;
			vec2 r = vec2(dot(fq, vec2(cos(ang), sin(ang))), dot(fq, vec2(-sin(ang), cos(ang))));
			float e = length(r / vec2(0.13, 0.075));
			float dentro = 1.0 - smoothstep(1.0 - aa * 14.0, 1.0 + aa * 14.0, e);
			float nervura = (1.0 - smoothstep(0.004, 0.009 + aa, abs(r.y))) * dentro;
			float t = pc_h21(fi + 17.0 + float(k));
			vec3 seca = t < 0.3 ? vec3(0.9, 0.48, 0.15) : (t < 0.55 ? vec3(0.92, 0.74, 0.22) : (t < 0.85 ? vec3(0.58, 0.36, 0.18) : vec3(0.78, 0.26, 0.14)));
			vec3 cor_folha = linear(seca) * (0.7 + 0.25 * h);
			cor = mix(cor, cor_folha, dentro * 0.85 * perto_);
			cor = mix(cor, cor_folha * 0.7, nervura * perto_);
		}
	}
	// Gravetinhos: um risco marrom fino de vez em quando.
	vec2 gc = p / 2.2;
	vec2 gi = floor(gc);
	if (pc_h21(gi + 41.0) > 0.7) {
		vec2 gq = (fract(gc) - 0.5) * 2.2;
		float ang = pc_h21(gi + 43.0) * 3.1416;
		vec2 gd = vec2(cos(ang), sin(ang));
		float graveto = (1.0 - smoothstep(0.012, 0.022 + aa, abs(dot(gq, vec2(-gd.y, gd.x))))) * (1.0 - smoothstep(0.32, 0.36, abs(dot(gq, gd))));
		cor = mix(cor, linear(vec3(0.42, 0.28, 0.16)), graveto * perto_);
	}
	return cor;
}

