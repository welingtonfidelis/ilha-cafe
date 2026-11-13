# Inimigos novos do Faísca: prompts para a arte 2D

> **Substituído em 2026-10-30:** o usuário preferiu usar o Cute Monsters Pack da Quaternius (ver "A turma de monstros" em `docs/ILHA-CAFUNE.md`). Este arquivo fica de registro.

Pedido do usuário em 2026-10-30: "precisamos de novos inimigos, cria prompts pra eu gerar em 2d assets iniciais pra validação de novos inimigos, não precisam ser muitos, uns 3 ou 4 inimigos base inspirados no do astro bot".

São quatro primas da Bolota. Cada uma ensina um jeito de vencer, como os inimigos de base dos jogos de plataforma de mascote. Os desenhos são nossos e seguem o tema infantil: elas seguram doces e brinquedos, nunca armas.

| Bolota | O que tem | O que ensina | Como vence | Aviso antes de atacar | Estreia (sugestão) |
|---|---|---|---|---|---|
| **Escudeira** | pirulito gigante na frente, como escudo | pisar | soco de frente quica no pirulito; pisão, laser de cima ou soco pelas costas | vira devagar para ficar de frente | 2-1, na cozinha |
| **Confeitada** | espinhos de jujuba nas costas | socar | pisão quica e tira coração; soco de frente ou do lado, giro, laser | arrepia os espinhos quando o Faísca está em cima | 2-1, na cozinha |
| **Balão** | voa presa em três balões e solta chicletes | laser | laser nos balões, de cima; sem balões, cai tonta e pode ser agarrada | sacode o saquinho antes de soltar o chiclete | 2-2, nas nuvens de algodão doce |
| **Rolona** | dentro de uma bola de hamster | desviar e agarrar | pular de lado; ela bate na parede, a bola abre e ela fica tonta | se inclina para trás e a bola treme | 2-3, no quarto de brinquedos |

## Como usar

1. Anexe a `referencia-bolota.png` (desta pasta) no gerador de imagem. Ela mostra a Bolota de frente, de três quartos e ao lado do Faísca, para a escala.
2. Cole um prompt por vez. Os prompts estão em inglês porque os geradores entendem melhor, e cada um já traz o estilo inteiro, então funciona sozinho.
3. Se a Bolota sair diferente da referência, repita com a frase: `Keep the exact same base creature as the attached reference image.`
4. Sem referência anexada, o próprio prompt descreve a Bolota.

**Folha não vai para o 3D.** As folhas abaixo servem para validar no 2D. Mandada para o gerador 3D, uma folha vira vários modelos do mesmo bicho em posições diferentes, um para cada figura (o usuário viu isso em 2026-10-30). Para o 3D, use os prompts da seção "Para o 3D", que pedem uma Bolota só.

Cada prompt de folha pede duas linhas:
- em cima, quatro vistas (frente, três quartos, lado e costas);
- embaixo, quatro poses de jogo (andando, o aviso, tonta e derrotada).

As poses são o que ajuda a validar se a criança entende a regra só de olhar.

**Para conferir cada folha:**
- a silhueta, mesmo toda preta, já diz qual Bolota é;
- dá para entender como vencer olhando as poses;
- não tem arma, dente nem cara de medo;
- não usa o amarelo-ouro das estrelinhas, nem o branco e laranja do Faísca, como cor principal;
- continua parecendo da família da Bolota: roxa, um olho, sobrancelha em V, antena com bolinha.

## 1. Bolota Escudeira

Anda devagar atrás de um pirulito redondo enorme, que segura com dois bracinhos. Soco de frente quica no pirulito, que balança com um "boing". Para vencer: pular e pisar em cima, usar o laser flutuando por cima ou dar a volta e socar pelas costas. Ela gira devagar para ficar de frente, então dar a volta funciona.

```text
Character design sheet for a cute 3D platformer game for young children. Stylized toy-like 3D render: smooth rounded shapes, soft glossy vinyl-toy plastic, chunky simple forms with very few small details, bright candy pastel colors, soft studio lighting with gentle shadows, plain light grey background. Friendly and silly, never scary. No text, no labels, no logos.

The character is a variant of the attached reference creature. If no reference is attached: a round purple blob creature (color #9B5DE5) about as tall as a child's waist, with one single big white eye with a dark navy pupil in the middle of its face, a thick dark-purple V-shaped eyebrow that makes it look grumpy but cute, a lighter lilac oval belly patch, two tiny stubby dark-purple feet, no mouth, and a thin antenna on top ending in a small pinkish-red ball. Keep that exact body, eye, eyebrow, belly, feet and antenna.

Variant "Shield Bolota": it has two tiny stubby purple arms and holds a giant round swirl lollipop in front of its body like a shield — a thick pink and white spiral candy disc on a short white stick, slightly wider than the body. From the front, the lollipop hides most of the body; only the top of the eye, the eyebrow and the antenna peek over it.

Layout: top row with four views of the same character in a neutral standing pose — front, three-quarter, side, back. Bottom row with four small gameplay poses: 1) walking slowly behind the lollipop; 2) a punch bouncing off the lollipop, which wobbles like a spring with a small cartoon puff; 3) squashed flat and dizzy after being stomped from above, little golden stars circling the antenna, lollipop dropped beside it; 4) defeated, popping into a burst of tiny golden stars. Same character, same proportions and colors in every view.
```

## 2. Bolota Confeitada

Tem as costas e o topo cobertos de espinhos macios de jujuba colorida, como um ouriço de doce. Quando o Faísca pula em cima, ela arrepia os espinhos: o pisão quica e tira um coração. Para vencer: soco de frente ou do lado, giro, ou laser. É o contrário da Escudeira, e as duas juntas ensinam a escolher o golpe.

```text
Character design sheet for a cute 3D platformer game for young children. Stylized toy-like 3D render: smooth rounded shapes, soft glossy vinyl-toy plastic, chunky simple forms with very few small details, bright candy pastel colors, soft studio lighting with gentle shadows, plain light grey background. Friendly and silly, never scary. No text, no labels, no logos.

The character is a variant of the attached reference creature. If no reference is attached: a round purple blob creature (color #9B5DE5) about as tall as a child's waist, with one single big white eye with a dark navy pupil in the middle of its face, a thick dark-purple V-shaped eyebrow that makes it look grumpy but cute, a lighter lilac oval belly patch, two tiny stubby dark-purple feet, no mouth, and a thin antenna on top ending in a small pinkish-red ball. Keep that exact body, eye, eyebrow, belly, feet and antenna.

Variant "Candy-spike Bolota": its top and back are covered with soft, rounded cone spikes that look like gumdrop candies in pink, mint green and sky blue, with a light dusting of sugar sparkles, like a cute candy hedgehog. The spikes look soft and sugary, not sharp. The face, eye, eyebrow and belly stay smooth and fully visible.

Layout: top row with four views of the same character in a neutral standing pose — front, three-quarter, side, back. Bottom row with four small gameplay poses: 1) waddling forward; 2) puffing up and raising all its candy spikes, looking up, as a warning that something is above it; 3) knocked onto its back after a punch from the front, dizzy, little golden stars circling the antenna; 4) defeated, popping into a burst of tiny golden stars. Same character, same proportions and colors in every view.
```

## 3. Bolota Balão

Flutua presa em três balões amarrados na antena e solta chicletes que quicam no chão. Antes de soltar, sacode o saquinho. Para vencer: flutuar por cima e acertar os balões com o laser dos pés. A cada balão estourado ela pende para um lado. Sem balões, cai tonta e o Faísca pode agarrar e arremessar. É o inimigo que dá motivo para usar o laser.

```text
Character design sheet for a cute 3D platformer game for young children. Stylized toy-like 3D render: smooth rounded shapes, soft glossy vinyl-toy plastic, chunky simple forms with very few small details, bright candy pastel colors, soft studio lighting with gentle shadows, plain light grey background. Friendly and silly, never scary. No text, no labels, no logos.

The character is a variant of the attached reference creature. If no reference is attached: a round purple blob creature (color #9B5DE5) about as tall as a child's waist, with one single big white eye with a dark navy pupil in the middle of its face, a thick dark-purple V-shaped eyebrow that makes it look grumpy but cute, a lighter lilac oval belly patch, two tiny stubby dark-purple feet, no mouth, and a thin antenna on top ending in a small pinkish-red ball. Keep that exact body, eye, eyebrow, belly, feet and antenna.

Variant "Balloon Bolota": it floats in the air, hanging under a bunch of three round shiny party balloons (cherry red, mint green and turquoise) tied to its antenna with curly ribbon. Its tiny feet dangle below. It has two tiny stubby purple arms hugging a small striped paper candy bag full of colorful round gumballs.

Layout: top row with four views of the same character floating in a neutral pose — front, three-quarter, side, back. Bottom row with four small gameplay poses: 1) floating calmly with feet dangling; 2) shaking the bag and dropping one bouncy gumball; 3) one balloon popped, tilting to one side with a wide surprised eye; 4) all balloons popped, falling down dizzy with little golden stars circling the antenna. Same character, same proportions and colors in every view.
```

## 4. Bolota Rolona

Fica dentro de uma bola transparente de hamster. Quando vê o Faísca, se inclina para trás, a bola treme e ela dispara em linha reta. Para vencer: pular de lado. Ela bate na parede ou numa pedra, a bola abre ao meio e ela fica tonta do lado de fora, pronta para levar soco ou ser agarrada. Usa a regra que o jogo já tem: o Faísca só agarra Bolota tonta.

```text
Character design sheet for a cute 3D platformer game for young children. Stylized toy-like 3D render: smooth rounded shapes, soft glossy vinyl-toy plastic, chunky simple forms with very few small details, bright candy pastel colors, soft studio lighting with gentle shadows, plain light grey background. Friendly and silly, never scary. No text, no labels, no logos.

The character is a variant of the attached reference creature. If no reference is attached: a round purple blob creature (color #9B5DE5) about as tall as a child's waist, with one single big white eye with a dark navy pupil in the middle of its face, a thick dark-purple V-shaped eyebrow that makes it look grumpy but cute, a lighter lilac oval belly patch, two tiny stubby dark-purple feet, no mouth, and a thin antenna on top ending in a small pinkish-red ball. Keep that exact body, eye, eyebrow, belly, feet and antenna.

Variant "Hamster-ball Bolota": it sits inside a big clear transparent toy ball, like a hamster ball, with a bright teal plastic ring around its middle and a few small round air holes. The Bolota inside is fully visible through the clear plastic, its tiny feet running on the inside; the antenna fits inside the ball.

Layout: top row with four views of the same character in its ball, neutral pose — front, three-quarter, side, back. Bottom row with four small gameplay poses: 1) idle inside the ball; 2) winding up before a charge — leaning back, eyebrow pulled down, ball wobbling, small dust puffs; 3) rolling fast in a straight line with speed lines; 4) after crashing into a wall, the clear ball split open into two halves and the Bolota sitting outside, dizzy, with little golden stars circling the antenna. Same character, same proportions and colors in every view.
```

## A família inteira

Depois das quatro folhas, este prompt mostra a Bolota de hoje e as quatro primas lado a lado. Serve para ver se as silhuetas se diferenciam e se continuam parecendo da mesma família.

```text
Lineup illustration of a family of five cute enemy characters for a children's 3D platformer game, standing side by side facing the viewer on a plain light grey background, same height and same stylized toy-like 3D render: smooth rounded shapes, soft glossy vinyl-toy plastic, chunky simple forms, bright candy pastel colors, soft studio lighting. Friendly and silly, never scary. No text, no labels, no logos.

All five share the same base creature from the attached reference: a round purple blob (color #9B5DE5) with one single big white eye with a dark navy pupil, a thick dark-purple V-shaped eyebrow, a lighter lilac belly patch, tiny dark-purple feet, no mouth, and a thin antenna ending in a small pinkish-red ball.

From left to right: 1) the plain base creature; 2) holding a giant pink and white swirl lollipop in front of it like a shield; 3) covered on top and back with soft gumdrop-candy spikes in pink, mint green and sky blue; 4) floating under three party balloons (cherry red, mint green, turquoise) tied to its antenna, hugging a small bag of gumballs; 5) sitting inside a clear transparent hamster ball with a teal ring around the middle.
```

## Para o 3D: uma Bolota por imagem

O gerador 3D (o Tripo, como no corpo do Faísca) faz um modelo para cada figura da imagem. Por isso estes prompts pedem um personagem só, uma vez, de frente e meio virado, em fundo branco, sem chão e sem sombra. Anexe a `referencia-bolota.png` também.

Se você já gostou de uma folha, dá para recortar só a vista de frente ou a de três quartos e mandar o recorte para o 3D, sem gerar de novo.

### Escudeira

O pirulito fica do lado do corpo, e não na frente, para o modelo ter a cara e a barriga. No jogo, ela levanta o pirulito.

```text
One single character only, shown once. Full-body picture of a cute enemy character for a children's 3D platformer game, made as a clean reference for image-to-3D modeling. Stylized toy-like 3D render: smooth rounded shapes, soft glossy vinyl-toy plastic, chunky simple forms, bright candy pastel colors, soft even studio lighting. Friendly and silly, never scary.

The character is a variant of the attached reference creature. If no reference is attached: a round purple blob creature (color #9B5DE5) with one single big white eye with a dark navy pupil in the middle of its face, a thick dark-purple V-shaped eyebrow that makes it look grumpy but cute, a lighter lilac oval belly patch, two tiny stubby dark-purple feet, no mouth, and a thin antenna on top ending in a small pinkish-red ball. Keep that exact body, eye, eyebrow, belly, feet and antenna.

Variant "Shield Bolota": it has two tiny stubby purple arms and holds a giant round swirl lollipop (a thick pink and white spiral candy disc on a short white stick) upright beside its body, at its side, so the face and belly stay fully visible.

Framing: the character facing the camera in a slight three-quarter view, centered, the whole body and everything it holds inside the frame with some margin, nothing covering the body. Plain pure white background, no floor, no shadow, no text. Do not draw other characters, extra views, extra poses or a character sheet.
```

### Confeitada

Meio virada, para os espinhos das costas aparecerem.

```text
One single character only, shown once. Full-body picture of a cute enemy character for a children's 3D platformer game, made as a clean reference for image-to-3D modeling. Stylized toy-like 3D render: smooth rounded shapes, soft glossy vinyl-toy plastic, chunky simple forms, bright candy pastel colors, soft even studio lighting. Friendly and silly, never scary.

The character is a variant of the attached reference creature. If no reference is attached: a round purple blob creature (color #9B5DE5) with one single big white eye with a dark navy pupil in the middle of its face, a thick dark-purple V-shaped eyebrow that makes it look grumpy but cute, a lighter lilac oval belly patch, two tiny stubby dark-purple feet, no mouth, and a thin antenna on top ending in a small pinkish-red ball. Keep that exact body, eye, eyebrow, belly, feet and antenna.

Variant "Candy-spike Bolota": its top and back are covered with soft, rounded cone spikes that look like gumdrop candies in pink, mint green and sky blue, with a light dusting of sugar sparkles, like a cute candy hedgehog. The spikes look soft and sugary, not sharp. The face, eye, eyebrow and belly stay smooth and fully visible. Show it turned enough that the spikes on its back are visible.

Framing: the character facing the camera in a slight three-quarter view, centered, the whole body and everything it holds inside the frame with some margin, nothing covering the body. Plain pure white background, no floor, no shadow, no text. Do not draw other characters, extra views, extra poses or a character sheet.
```

### Balão

Os balões precisam caber inteiros na imagem. As fitas finas podem sair grossas ou somem no 3D; no jogo dá para refazer as fitas.

```text
One single character only, shown once. Full-body picture of a cute enemy character for a children's 3D platformer game, made as a clean reference for image-to-3D modeling. Stylized toy-like 3D render: smooth rounded shapes, soft glossy vinyl-toy plastic, chunky simple forms, bright candy pastel colors, soft even studio lighting. Friendly and silly, never scary.

The character is a variant of the attached reference creature. If no reference is attached: a round purple blob creature (color #9B5DE5) with one single big white eye with a dark navy pupil in the middle of its face, a thick dark-purple V-shaped eyebrow that makes it look grumpy but cute, a lighter lilac oval belly patch, two tiny stubby dark-purple feet, no mouth, and a thin antenna on top ending in a small pinkish-red ball. Keep that exact body, eye, eyebrow, belly, feet and antenna.

Variant "Balloon Bolota": it floats in the air, hanging under a bunch of three round shiny party balloons (cherry red, mint green and turquoise) tied to its antenna with short, thick curly ribbons. Its tiny feet dangle below. It has two tiny stubby purple arms hugging a small striped paper candy bag full of colorful round gumballs. The whole balloon bunch fits inside the picture.

Framing: the character facing the camera in a slight three-quarter view, centered, the whole body and everything it holds inside the frame with some margin, nothing covering the body. Plain pure white background, no floor, no shadow, no text. Do not draw other characters, extra views, extra poses or a character sheet.
```

### Rolona

O gerador 3D não faz plástico transparente: a bola de hamster sairia opaca e esconderia a Bolota. Gere a Bolota sem a bola, na pose de correr. A bola transparente com o anel é uma forma simples e sai melhor feita no jogo.

```text
One single character only, shown once. Full-body picture of a cute enemy character for a children's 3D platformer game, made as a clean reference for image-to-3D modeling. Stylized toy-like 3D render: smooth rounded shapes, soft glossy vinyl-toy plastic, chunky simple forms, bright candy pastel colors, soft even studio lighting. Friendly and silly, never scary.

The character is a variant of the attached reference creature. If no reference is attached: a round purple blob creature (color #9B5DE5) with one single big white eye with a dark navy pupil in the middle of its face, a thick dark-purple V-shaped eyebrow that makes it look grumpy but cute, a lighter lilac oval belly patch, two tiny stubby dark-purple feet, no mouth, and a thin antenna on top ending in a small pinkish-red ball. Keep that exact body, eye, eyebrow, belly, feet and antenna.

Variant "Hamster-ball Bolota", shown WITHOUT its ball: it wears a small bright teal sporty headband just under the antenna and stands in a running pose, leaning forward, one tiny foot lifted, eyebrow pulled down in a determined look.

Framing: the character facing the camera in a slight three-quarter view, centered, the whole body and everything it holds inside the frame with some margin, nothing covering the body. Plain pure white background, no floor, no shadow, no text. Do not draw other characters, extra views, extra poses or a character sheet.
```

### No jogo

O pirulito, os balões e a bola mexem sozinhos nas lutas: o pirulito sobe, cada balão estoura e a bola abre ao meio. O mais provável é fazer essas peças separadas no jogo, como a Bolota de hoje (`scripts/faisca/alvo.gd`), que é toda feita de formas simples. Aí o modelo 3D gerado serve para validar o visual, e a folha 2D vira o molde das cores e das proporções.
