// A grama das fases do Faísca com o desenho do campo da ilha (pedido do usuário em 2026-11-11: "vamos levar essas
// texturas melhores que aplicou na ilha pras fases do faisca"): no lugar do material da peça (o morro do Forest Nature,
// o chão da arena), com a cor dela (a textura do pacote e a cor do material) por baixo. Em cima, o campo da ilha
// (manchas de sol e de grama funda, tufinhos, folhinhas e florzinhas); nas encostas, as lajes de pedra de sempre.
shader_type spatial;
render_mode cull_back;

#include "res://scripts/chao/padroes_do_chao.gdshaderinc"
#include "res://scripts/chao/campo_e_mata.gdshaderinc"

uniform sampler2D textura : source_color, filter_linear_mipmap, repeat_enable, hint_default_white;
uniform vec4 cor_base : source_color = vec4(1.0);
// Nas encostas: o número do padrão (TexturaDoChao.PADROES), -1 = nenhum.
uniform int padrao_lado = 3;
uniform float forca : hint_range(0.0, 1.0) = 1.0;
uniform float tufos = 0.35;
uniform float detalhe_perto = 14.0;
uniform float detalhe_longe = 55.0;

varying vec3 pos_mundo;
varying vec3 normal_mundo;

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 base = texture(textura, UV).rgb * cor_base.rgb;
	vec3 n = normalize(normal_mundo);
	vec2 plano = pc_plano(pos_mundo, n);
	float l = pc_longe(length(VERTEX), detalhe_perto, detalhe_longe);
	float aa = max(fwidth(plano.x), fwidth(plano.y));
	vec3 cor = base;
	if (n.y > 0.6) {
		cor = campo(plano, base, l, aa, tufos);
	} else if (padrao_lado >= 0) {
		cor = base * pc_cor(padrao_lado, pc_padrao(padrao_lado, plano, l, TIME));
	}
	ALBEDO = mix(base, cor, forca);
	ROUGHNESS = 0.95;
}
