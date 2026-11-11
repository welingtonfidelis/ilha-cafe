// O desenho do chão por cima da cor que a peça já tem (vai no material_overlay da malha): multiplica a cor de baixo,
// então cada peça continua com o tom dela. Em cima (a face virada para o céu) vai o `padrao_topo`; nas faces em pé,
// o `padrao_lado` (-1 = nenhum). Os números dos padrões estão no TexturaDoChao.PADROES.
shader_type spatial;
render_mode blend_mul, unshaded, depth_draw_never, cull_back, shadows_disabled, fog_disabled;

#include "res://scripts/chao/padroes_do_chao.gdshaderinc"

uniform int padrao_topo = 0;
uniform int padrao_lado = -1;
uniform float forca : hint_range(0.0, 2.0) = 1.0;
uniform float detalhe_perto = 14.0;
uniform float detalhe_longe = 55.0;

varying vec3 pos_mundo;
varying vec3 normal_mundo;

void vertex() {
	pos_mundo = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	normal_mundo = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = normalize(normal_mundo);
	int qual = n.y > 0.6 ? padrao_topo : padrao_lado;
	vec3 m = vec3(1.0);
	if (qual >= 0) {
		m = pc_cor(qual, pc_padrao(qual, pc_plano(pos_mundo, n), pc_longe(length(VERTEX), detalhe_perto, detalhe_longe), TIME));
	}
	ALBEDO = mix(vec3(1.0), m, forca);
}
