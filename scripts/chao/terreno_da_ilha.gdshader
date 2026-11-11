// O terreno da ilha com desenho (item 13): a malha gerada pelo tools/gerar_ilha.gd pinta cada triângulo com uma cor
// da paleta dele; aqui a cor diz o que é aquele chão (grama, mata, areia, pedra, terra, calçada, praça, fundo do mar)
// e ganha o desenho do padrão certo, nas coordenadas do mundo.
shader_type spatial;
render_mode cull_back;

#include "res://scripts/chao/padroes_do_chao.gdshaderinc"
#include "res://scripts/chao/campo_e_mata.gdshaderinc"

// A paleta do gerar_ilha.gd, em sRGB (a cor do vértice também vem em sRGB).
const vec3 C_SEABED = vec3(217.0, 196.0, 140.0) / 255.0;
const vec3 C_SAND = vec3(236.0, 217.0, 162.0) / 255.0;
const vec3 C_GRASS = vec3(140.0, 201.0, 107.0) / 255.0;
const vec3 C_GRASS_FOREST = vec3(111.0, 179.0, 90.0) / 255.0;
const vec3 C_DIRT = vec3(201.0, 164.0, 106.0) / 255.0;
const vec3 C_ROCK = vec3(154.0, 163.0, 173.0) / 255.0;
const vec3 C_PAVEMENT = vec3(196.0, 185.0, 161.0) / 255.0;
const vec3 C_PLAZA = vec3(211.0, 185.0, 143.0) / 255.0;

uniform float forca : hint_range(0.0, 2.0) = 1.3;
// A câmera da ilha fica mais longe do chão que a do Faísca: o detalhe vai até mais adiante.
uniform float detalhe_perto = 30.0;
uniform float detalhe_longe = 110.0;

varying vec3 pos_mundo;
varying vec3 normal_mundo;

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

float perto(vec3 a, vec3 b) {
	vec3 d = a - b;
	return dot(d, d);
}

void fragment() {
	vec3 cor = COLOR.rgb;
	vec3 n = normalize(normal_mundo);
	float l = pc_longe(length(VERTEX), detalhe_perto, detalhe_longe);
	// A cor da paleta mais parecida diz o padrão (a grama tem uma variação de até 4% que não atrapalha). O campo e
	// a mata têm desenho próprio, com cor (-1 e -2); os outros usam os padrões de sempre.
	int qual = -1;
	float melhor = perto(cor, C_GRASS);
	float d = perto(cor, C_GRASS_FOREST); if (d < melhor) { melhor = d; qual = -2; }
	d = perto(cor, C_SAND); if (d < melhor) { melhor = d; qual = 2; }
	d = perto(cor, C_SEABED); if (d < melhor) { melhor = d; qual = 2; }
	d = perto(cor, C_DIRT); if (d < melhor) { melhor = d; qual = 1; }
	d = perto(cor, C_ROCK); if (d < melhor) { melhor = d; qual = 3; }
	d = perto(cor, C_PAVEMENT); if (d < melhor) { melhor = d; qual = 4; }
	d = perto(cor, C_PLAZA); if (d < melhor) { melhor = d; qual = 5; }
	vec2 plano = pc_plano(pos_mundo, n);
	float aa = max(fwidth(plano.x), fwidth(plano.y));
	vec3 base = linear(cor);
	if (qual == -1 && n.y > 0.6) {
		ALBEDO = mix(base, campo(plano, base, l, aa, 1.0), min(forca, 1.0));
	} else if (qual == -2 && n.y > 0.6) {
		ALBEDO = mix(base, mata(plano, base, l, aa), min(forca, 1.0));
	} else {
		vec3 m = pc_cor(max(qual, 0), pc_padrao(max(qual, 0), plano, l, TIME));
		ALBEDO = base * mix(vec3(1.0), m, forca);
	}
	ROUGHNESS = 1.0;
}
