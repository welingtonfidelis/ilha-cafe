shader_type spatial;
// Contorno de luz do Faísca (2026-11-13, o usuário quer ele mais simpático e destacado, como o Astro): uma segunda
// passada por cima do plástico que soma um azul clarinho nas beiradas viradas para longe da câmera. Separa o robô
// branco do cenário claro e dá o brilho de borda do Astro.
render_mode blend_add, unshaded, depth_draw_never, cull_back, shadows_disabled;

uniform vec3 cor : source_color = vec3(0.45, 0.8, 1.0);
uniform float forca = 0.85;
uniform float largura = 2.2;

void fragment() {
	float borda = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), largura);
	ALBEDO = cor * borda * forca;
}
