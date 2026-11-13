shader_type spatial;
// A água caindo (a cascata da pia transbordando e o jorro da torneira, na 2-1): faixas claras descendo, um pouco
// transparente, sem luz própria (fica sempre clara). UV.y cresce para baixo.
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 cor : source_color = vec4(0.62, 0.86, 1.0, 0.7);
uniform vec4 espuma : source_color = vec4(0.94, 0.98, 1.0, 0.85);
uniform float faixas = 14.0;
uniform float velocidade = 1.6;
uniform float comprimento = 6.0;

float onda(vec2 p) {
	return sin(p.x * 6.2831 + sin(p.y * 2.1) * 1.3) * 0.5 + 0.5;
}

void fragment() {
	vec2 p = vec2(UV.x * faixas, UV.y * comprimento * 0.35 - TIME * velocidade);
	float f = onda(p) * onda(p * vec2(0.53, 1.7) + vec2(0.31, 0.0));
	float claro = smoothstep(0.42, 0.82, f);
	vec4 c = mix(cor, espuma, claro);
	ALBEDO = c.rgb;
	ALPHA = c.a;
}
