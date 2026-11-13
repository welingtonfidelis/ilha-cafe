shader_type spatial;
// Bolha de sabão da pia da 2-1 (2026-11-13: as crianças tinham dificuldade de ver as bolhas, que eram uma esfera azul
// clarinha quase transparente em cima da água azul clara). Agora o corpo é rosa e pouco transparente, e a borda tem a
// película de arco-íris do sabão (rosa, azul e amarelo), que anda devagar com o tempo e muda com o ângulo, e um pouco
// de brilho próprio para aparecer contra a água.

uniform vec3 corpo : source_color = vec3(0.98, 0.6, 0.92);
uniform float brilho = 1.1;

void fragment() {
	float borda = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	vec3 mundo = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float fase = borda * 2.6 + TIME * 0.22 + dot(mundo, vec3(0.11, 0.17, 0.07));
	vec3 arco = 0.55 + 0.45 * cos(6.2832 * (fase + vec3(0.0, 0.33, 0.67)));
	float na_borda = smoothstep(0.15, 0.85, borda);
	ALBEDO = mix(corpo, arco, na_borda);
	ROUGHNESS = 0.04;
	SPECULAR = 0.9;
	EMISSION = arco * pow(borda, 1.3) * brilho + corpo * 0.22;
	ALPHA = clamp(0.58 + pow(borda, 1.4) * 0.42, 0.0, 0.97);
	RIM = 0.5;
	RIM_TINT = 0.4;
}
