// A vegetação da ilha (tufos de grama, trevos, florzinhas e samambaias, desenhados aos milhares por MultiMesh).
// - A cor de cada planta vem da instância (a cor do chão onde ela nasceu), com as mesmas manchas de sol e de musgo
//   do desenho do chão (terreno_da_ilha.gdshader), para a grama e o chão combinarem; as pétalas (alfa 0 no vértice)
//   pegam a cor do custom_data. O custom_data.a diz se é campo (0) ou mata (1).
// - O pé é mais escuro e a ponta mais clara (UV.y vai de 0 no pé a 1 na ponta).
// - A ponta balança com o vento e abre para longe de quem passa (`jogador`).
// - De longe, a planta encolhe até sumir (entre `some_de` e `some_ate` da câmera): ali o desenho do chão assume.
// - A normal aponta para cima, para a luz pegar igual à do chão.
// - Com `rigido` (as miudezas das fases: pedrinha, granulado, porca...), nada balança e a luz usa as normais delas.
shader_type spatial;
render_mode cull_disabled;

#include "res://scripts/chao/padroes_do_chao.gdshaderinc"

uniform vec3 jogador = vec3(0.0, -9999.0, 0.0);
uniform float some_de = 26.0;
uniform float some_ate = 38.0;
uniform float vento = 1.0;
uniform float pe_escuro = 0.62;
uniform float ponta_clara = 1.12;
// As miudezas das fases (pedrinha, granulado, porca...): não balançam nem abrem, e a luz usa as normais delas.
uniform bool rigido = false;
uniform float aspereza = 0.95;
uniform float metalico = 0.0;
uniform float especular = 0.15;

varying vec3 v_cor;
varying float v_t;

vec3 linear(vec3 c) {
	return mix(c / 12.92, pow((c + 0.055) / 1.055, vec3(2.4)), step(vec3(0.04045), c));
}

void vertex() {
	vec3 origem = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float t = UV.y;
	vec3 cor = linear(COLOR.rgb);
	// As mesmas manchas do chão embaixo (sol e grama funda no campo; musgo e sombra na mata).
	vec2 p = origem.xz;
	// custom.a: 0 campo, 1 mata, 2 sem mancha (as miudezas).
	if (INSTANCE_CUSTOM.a < 1.5) {
		vec3 mancha = INSTANCE_CUSTOM.a < 0.5
				? mix(vec3(0.66, 0.82, 0.8), vec3(1.2, 1.1, 0.72), smoothstep(0.28, 0.72, pc_fbm(p * 0.045)))
				: mix(vec3(0.74, 0.84, 0.86), vec3(1.06, 1.18, 0.82), smoothstep(0.35, 0.7, pc_fbm(p * 0.06 + 5.0)));
		cor *= mancha;
	}
	// Pétala: a cor da flor (sem a mancha nem o escurecido do pé).
	float petala = 1.0 - COLOR.a;
	v_cor = mix(cor, linear(INSTANCE_CUSTOM.rgb), petala);
	v_t = mix(t, 0.75, petala);
	float tam = 1.0 - smoothstep(some_de, some_ate, distance(CAMERA_POSITION_WORLD, origem));
	if (rigido) {
		VERTEX *= tam;
	} else {
		// O vento: duas ondas que passam pelo campo, mais forte na ponta.
		float fase = TIME * 1.6 + origem.x * 0.31 + origem.z * 0.23;
		float w = sin(fase) * 0.6 + sin(fase * 2.3 + 1.7) * 0.25;
		vec3 desloca = vec3(w * 0.09, 0.0, w * 0.05 + sin(fase * 0.7) * 0.03) * t * t * vento;
		// Quem passa abre a grama: a ponta vai para longe e para baixo.
		vec2 d = origem.xz - jogador.xz;
		float dist = length(d);
		float perto = (1.0 - smoothstep(0.3, 1.1, dist)) * (1.0 - smoothstep(1.2, 2.2, abs(origem.y - jogador.y)));
		vec2 fora = dist > 0.001 ? d / dist : vec2(1.0, 0.0);
		desloca.xz += fora * perto * 0.4 * t;
		desloca.y -= perto * 0.22 * t;
		// De longe, encolhe até sumir.
		mat3 m = mat3(MODEL_MATRIX);
		VERTEX = VERTEX * tam + inverse(m) * desloca * tam;
		NORMAL = normalize(transpose(m) * vec3(0.0, 1.0, 0.0));
	}
}

void fragment() {
	ALBEDO = v_cor * mix(pe_escuro, ponta_clara, v_t);
	ROUGHNESS = aspereza;
	METALLIC = metalico;
	SPECULAR = especular;
}
