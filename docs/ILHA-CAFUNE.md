# Ilha Cafuné — documentação única

Versão do documento: 2026-10-25 (elenco trocado para o KayKit)
Jogo: **Ilha Cafuné** (título provisório): tiro em terceira pessoa infantil, num mundo aberto pequeno.
Motor: Godot 4.7 (3D), com exportação para Windows (`.exe`) e macOS.
Arte: **só pacotes prontos e CC0**, quase tudo do KayKit (Kay Lousberg). Os blasters vêm do Kenney, porque o KayKit não tem armas de fogo. Lista completa na seção 8.

**Estado atual: jogo completo do começo ao fim, com desfecho, festa à noite, créditos com álbum, pós-jogo e campanha salva (2026-10-26).** Projeto Godot 4.7.2 na raiz desta pasta, versionado em git (branch `main`, publicado em github.com/welingtonfidelis/ilha-cafe, público). Pedidos do usuário em 2026-10-26 depois de testar: luta do prólogo na praia do cais, cais de madeira, cavalos, correr (Shift / L3), lenhador partindo tronco, bandeira com raio maior, chefes mais difíceis (menos o Mestre Ossinho, que estava bom), Morro dos Ventos com topo plano e o portão do cemitério que abre. O jogo abre na ilha de verdade (`scenes/ilha.tscn`, seção 3.1). Já dá para jogar o prólogo na praça, as duas defesas da cidade (Ossão e Mira-Torta), atravessar a ponte e as duas da mata (Torre de Ossinhos e Minionzão), ganhando o Granulado, a Pipoqueira, +1 coração e o Pé-de-Moleque, até a cúpula do cemitério cair. A praça tem a festa montada (palco com banda e o urso do violão, mesas de comida e doces, presentes, barraca dos fazendeiros, barraca de poções da bruxa, barraca de tiro ao alvo e o cantinho do palhaço) e 22 moradores na festa e pela ilha (inclusive lenhador e pescador) que falam, torcem nas ondas e comemoram; cada região vencida ganha convidados e uma mesa de festa. O Golem de Ossos aparece nas ondas da mata, e o Bosque das Copas tem o desafio opcional do Guerreiro Planta. Com a cúpula caída, a defesa final no meio do cemitério do Morro traz 3 ondas e o Mestre Ossinho (o Necromancer do KayKit) em três fases; derrotado, ele senta, tira a coroa e as crianças entregam o convite numa cena com câmera própria. Na noite seguinte vem a Festa do Cafuné na praça (esqueletos convidados descendo de balão, luzinhas, lua, estrelas e fogos); subir no palco abre os créditos com o álbum de fotos da partida, e depois a ilha fica em festa de dia, com os esqueletos amigos e a "Festa sem fim" (ondas de verdade) no cemitério (seção 4). Guardiões e ondas dão moedas para a Lojinha de Blasters da praia, que vende 8 blasters novos e 2 melhorias (seção 8). A campanha salva sozinha; o menu inicial tem Continuar e Nova campanha (seção 4, "Campanha salva e menu inicial"). Aventureiro escolhível, câmera em terceira pessoa, 4 blasters com pente, recarga e estoque limitado, granada e caixas de munição, controle com auxílio de mira; esqueletos com armas que atacam cada um do seu jeito, vida em corações, tonto com estrelinhas, pontos de retorno e coração que cai (modelos do Platformer Pack); 30 efeitos sonoros e música de fundo gerados por síntese. Pacotes brutos em `vendor/` (fora do git e com `.gdignore`), só os arquivos usados copiados para `assets/`. Como rodar e o que falta: seção 9.1.

## Índice

1. [Visão geral](#1-visão-geral)
2. [Regras de tom](#2-regras-de-tom)
3. [O mundo](#3-o-mundo)
4. [História](#4-história)
5. [Progressão no mundo aberto](#5-progressão-no-mundo-aberto)
6. [Personagens jogáveis](#6-personagens-jogáveis)
7. [Esqueletos e chefes](#7-esqueletos-e-chefes)
8. [Blasters, itens e pacotes de arte](#8-blasters-itens-e-pacotes-de-arte)
9. [Notas técnicas na Godot](#9-notas-técnicas-na-godot)
10. [Decisões em aberto](#10-decisões-em-aberto)

---

## 1. Visão geral

Na véspera da Festa do Cafuné, o Mestre Ossinho acende quatro Lanternas Mágicas que abrem rachaduras roxas pela ilha, e delas saem esqueletos em ondas para levar a festa embora. Duas crianças da cidade, um menino e uma menina, pegam os blasters novos e defendem cada região até o guardião aparecer. Esqueleto derrotado não se machuca: ganha balões e volta voando para o Morro, acenando. Apagando as quatro lanternas, o caminho do cemitério se abre, e no fim todos descobrem que os esqueletos só queriam ser convidados.

- **Público:** crianças de 6 a 12 anos, e quem joga com elas.
- **Gênero:** tiro em terceira pessoa com defesa em ondas por região e exploração. Depois da história, a "Festa sem fim" (ondas sem fim no cemitério, com recorde e moedas para a lojinha).
- **Personagem:** o jogador escolhe entre o menino e a menina, e pode trocar a qualquer hora.
- **Controle é obrigatório:** tudo tem que funcionar no controle (menus inclusive), não só no teclado e mouse. Com controle há auxílio de mira e vibração.
- **Mundo:** uma ilha pequena, sem fases nem telas de carregamento. Cidade ao sul, floresta ao norte, Morro no meio.
- **Duração alvo:** 3 a 5 horas de história, mais coletáveis.
- **Inspirações de tom:** Plants vs. Zombies (monstros que fazem rir), Ratchet & Clank (armas divertidas), A Short Hike (ilha pequena e aconchegante).

## 2. Regras de tom

Valem para história, arte, som e código.

- **Ninguém morre.** Esqueleto derrotado fica zonzo, aparecem três balões coloridos amarrados nele e ele sobe acenando ("Tchau!") de volta para o Morro. Não volta mais naquela luta. No epílogo, todos os que foram de balão estão na festa. (Decisão do usuário em 2026-10-25: nada de desmontar e se levantar de novo.)
- **Esqueletos são engraçados, não assustadores:** batem os dentes, tropeçam nos próprios ossos, usam chapéu de festa roubado. Nada de olhos brilhando em vermelho, gritos ou escuridão.
- **Os aventureiros não morrem.** Sem energia, ficam tontos vendo estrelinhas e voltam no último ponto de retorno.
- **Blasters:** disparos coloridos com faísca e confete no impacto. Só se atira em esqueletos e alvos, nunca em pessoas.
- **Noite azul e cheia de vaga-lumes.** Mesmo o Morro é mais "festa de Halloween" do que sombrio.
- **Humor de criança:** trocadilhos de osso ("que dor de cotovelo!"), tombos e esqueletos educados demais ("Ossinhos, atacar! ...com licença.").

## 3. O mundo

**Ilha Cafuné.** Atravessar a pé de ponta a ponta leva de 3 a 4 minutos (algo perto de 400 x 500 m). O Morro aparece de qualquer ponto e serve de bússola.

```
                       MAR
  +----------------------------------------------+
  |                FLORESTA (norte)              |
  |   trilhas, rio, clareiras, casas de madeira  |
  |  ~~~~~~~~~~~~~~~~~~ rio ~~~~~~~~~~~~~~~~~~~~ |
  |              ^ MORRO (centro, alto)          |
  |                 casa dos esqueletos          |
  |                 CIDADE (sul)                 |
  |   praca e base da Guilda, ruas, parque, cais |
  +----------------------------------------------+
                       MAR
```

- **Cidade (sul):** montada com o KayKit City Builder Bits. A praça central abriga a base da Guilda e o palco da festa. Os nomes de ruas e lugares serão definidos quando os modelos chegarem, de acordo com o que o pacote oferece.
- **Floresta (norte):** montada com o KayKit Forest Nature Pack. Trilhas, rio, clareiras e uma clareira grande onde fica a árvore da festa.
- **Morro (centro):** o ponto mais alto da ilha, entre a cidade e a floresta, com a casa dos esqueletos no topo. Montado com pedras e árvores da floresta; o KayKit Halloween Bits (grátis) pode dar abóboras, lápides engraçadas e um mausoléu, se quisermos.
- **Escala:** o City Builder Bits foi feito para jogos de construir cidade vistos de cima. Os prédios podem precisar ser ampliados para combinar com os aventureiros. Isso se confirma no protótipo.

### 3.1 A ilha no jogo (já feita)

A ilha é a cena `scenes/ilha.tscn`, gerada uma vez por `tools/gerar_ilha.gd` e depois editável no editor da Godot. Medidas reais (−Z é norte, 1 unidade = 1 m, mar em y = −0,6):

| Lugar | Onde | Como é |
|---|---|---|
| Ilha | elipse de ~380 x 490 m com costa recortada | praia de areia em volta; terreno low-poly em grade de 4 m com cores por região |
| Cidade | sul, x de −60 a 60, z de 110 a 190 (terreno plano até a beira, mesmo no canto sudeste, onde antes a costa afundava o chão e as ruas flutuavam) | ruas do City Builder Bits em grade (4 x 3), prédios em volta dos quarteirões virados para a rua, carros, postes, lixeiras, caixa-d'água | As peças de rua ficam 4,5 cm afundadas: o asfalto do modelo está a 7 cm e a calçada a 10 cm, e o personagem pisa no terreno, a 0; assim o pé quase encosta no asfalto. Caixas e lixeiras soltas não caem em cima das ruas, e os postes de balão da comemoração não nascem na rua nem na água.
| Praça da festa | quarteirão central do sul (x −20 a 20, z 150 a 190; as ruas ocupam 5 m de cada lado, então o miolo livre vai de −15 a 15 e tudo da festa fica dentro dele) | palco vermelho e azul, arco amarelo, 8 balões em postes, bancos e árvores; o jogo começa aqui |
| Cais | sai da praia para o mar (z 206 a 255) | módulos de madeira do Animated Cute Fish Pack (Quaternius, CC0), pedido do usuário: dois `Dock_Long` e o `Dock_Wide` na ponta, a 0,75x, com estacas enfiadas na água e corda de corrimão; piso a 0,45 m (o piso do módulo fica 3,8 m acima do pé das estacas). Colisão: caixa no piso, paredes invisíveis no lugar da corda e uma rampa na areia. O pescador fica na ponta: a linha da vara (`fishing_rod_line`, com a boia e o anzol) é esticada até a água, a boia balança na superfície e o anzol fica embaixo |
| Praia do Cais | a oeste do cais (−30, 212) | areia aberta, sem enfeites: é onde acontece a defesa do prólogo (pedido do usuário: na praça, com a festa, a luta ficava confusa) |
| Sítio do Cafuné | campina a oeste do Morro, pasto em (−120, −6) com raio 11 m (até 2026-10-26 ficava em (−104, 52), ao lado da cidade; saiu de lá para a pista de skate) | cerca de madeira com porteira; estábulo de frente para o pasto, moinho, poço, bebedouros e fardos de feno (Medieval Hexagon). Dentro do pasto: dois cavalos (marrom e branco), vaca, burro e alpaca passeando e pastando. O casal de fazendeiros (Farmer_A com forcado, trabalhando no feno; Farmer_B perto do poço) mora aqui; antes atendiam a barraca de verduras da praça, que agora fica só com as verduras expostas |
| Bichos soltos | marcadores `Animais` | Quaternius, CC0 (`scripts/animal.gd`): passeiam perto de casa, param e pastam; veados, cervo e raposas fogem galopando quando o aventureiro chega a 7 m. Shiba na praça, husky na praia; dois veados perto da Clareira, cervo e raposas na mata. Ficam na camada dos moradores (tiro e esqueletos passam direto) |
| Peixes | marcadores `Cardumes` | peixes fofos do Animated Cute Fish Pack (`scripts/fish.gd`), 24 ao todo: dois cardumes no mar perto do cais e dois no rio (perto da ponte e a oeste), nadando em círculo logo abaixo da água; os do mar e o da ponte dão um saltinho fora d'água de vez em quando. Ficaram de fora os com dentes (tubarão, piranha, peixe-diabo, peixe-víbora) |
| Morro | centro, raio 90 m, 26 m de altura | dá para subir andando por qualquer lado; trilha de terra em espiral (2,5 voltas) até o topo plano, de 24 m de raio |
| Cemitério dos Ossinhos | topo do Morro (desde 2026-10-26, no lugar do castelinho) | peças do Halloween Bits: cerca em volta com o portão em arco (`arch_gate`) onde a trilha chega; as duas folhas do portão (`arch_gate_left` e `arch_gate_right`, com a origem na dobradiça) ficam fechadas até a cúpula cair e então abrem para dentro, e uma colisão invisível (`PortaoDoCemiterio`) sai junto, cripta no fundo (norte) com a lanterna central roxa flutuando em cima, caminho de pedra, túmulos nas laterais, abóboras sorridentes, velas, lanternas, espantalho, feno, baldes de doces na porta da cripta e pinheiros de outono por fora; o meio é um gramado livre para a luta final. Pedido do usuário; ficaram de fora caixões, ossos, caveiras e árvores secas, e o cemitério é de dia e colorido para seguir as regras de tom |
| Rio Preguiçoso | atravessa a ilha de leste a oeste em z ≈ −112 | 14 m de largura; cair nele faz "tchibum" e volta na bandeira sem perder coração |
| Ponte | x = 0, sobre o rio | ponte de pedra em arco do Medieval Hexagon (`building_bridge_A`), girada 30° (no pacote ela fica na diagonal do hexágono) e esticada para 6 x 32 m; colisão por malha com a escala aplicada nos pontos e rampas invisíveis nas pontas; é o único caminho para a mata |
| Mata | norte do rio | ~330 árvores, pedras, arbustos, trilhas de terra. Desde 2026-10-26 com as cores e formatos do Forest Nature Pack completo: verdes misturados (cores 1, 2 e 3), outono perto do Morro dos Ventos (5 e 6), cerejeiras perto da Clareira (7 e 8) e os formatos novos Tree 5, 6 e 7; as cores saem de um sorteio separado, então as posições continuaram as mesmas |
| Morrinhos de pedra | margem sul do rio | blocos de pedra com topo de grama do Forest completo (`Hill_*`), com colisão |
| Clareira da Jabuticabeira | (40, −180) | árvore gigante no meio |
| Bosque das Copas | (115, −160) | clareira redonda da mata, fechada por 9 árvores gigantes de várias cores, com arbustos floridos, pedras e um tronco caído; arena do desafio opcional do Guerreiro Planta (raio 12). Até 2026-10-26 era a Vila das Copas, com plataformas vermelhas, passarelas e molas; o usuário achou artificial demais para a floresta e as molas saíram |
| Morro dos Ventos | (−80, −162), 8 m | topo plano de 29 m de raio (a arena de 22 m e as 4 rachaduras inteiras no plano) e encosta suave até 58 m. Fica entre o rio e a costa: em (−95, −158) o lado do mar caía na praia e em (−88, −151) o lado sul encostava no rio |
| Lanternas | no centro das regiões Oeste, Leste, Ventos e Clareira | poste com esfera roxa e raio até a lanterna em cima da cripta do cemitério; acendem no fim do prólogo e apagam quando a região é vencida |
| Regiões de defesa | praia do cais (−30, 212), Oeste (−84, 140), Leste (84, 140), Clareira (24, −166), Ventos (−80, −162) | círculo de 22 m e 4 rachaduras; sem árvores, pedras nem arbustos num raio de 26 m |
| Cúpula do cemitério | topo do Morro, raio 25,5 m (cobre o topo inteiro) | some quando as quatro lanternas apagam; a bandeira TopoDoMorro fica na trilha logo antes do portão, do lado de fora |

**Marcadores editáveis** (`Marcadores` dentro da ilha): `Inicio` (onde o aventureiro começa e para onde olha), `PontosDeRetorno` (8 bandeiras: Praca, PeDoMorro, TopoDoMorro, EntradaDaMata, Clareira, MorroDosVentos, CidadeOeste, CidadeLeste; a primeira começa ativa), `Esqueletos` (14 soltos entre as regiões, cada um com o tipo na metadata `tipo`), `Municao` (10 caixas), `Regioes` (centro de cada defesa, com o raio na metadata `raio` e as 4 rachaduras como filhos) e `Moradores` (15, com `modelo`, `atividade`, `variante`, `item`, `falas`, `destino` e `altura` nos metadados; a rotação do marcador é para onde o morador olha). A festa fica em `Cidade/Praca/Festa`. Mover um marcador no editor muda o jogo, sem mexer em código.

**Esqueletos na ilha:** começam dormindo como pilha de ossos e se montam quando o aventureiro chega a 16 m (golpe de perto) ou 22 m (quem atira). Se o aventureiro se afasta mais de 45 m da casa deles, voltam para casa e deitam de novo. Derrotados, vão embora de balão e não voltam. Os das ondas saem das rachaduras (animação de sair do chão, 1,6x mais rápida) e perseguem o aventureiro por toda a região; se a onda é cancelada, afundam de volta.

**Regerar a ilha** (`godot --headless --path . -s res://tools/gerar_ilha.gd`) sobrescreve `scenes/ilha.tscn` e o terreno em `assets/terrain/`. Depois de mexer na ilha pelo editor, faça commit antes de regerar. `tools/foto_ilha.gd` tira fotos da ilha de cima e de alguns pontos, para conferir sem abrir o editor.

## 4. História

Estrutura escolhida pelo usuário em 2026-10-25 (opção C): a história é feita de **defesas em ondas por região**, com a ilha aberta entre elas; depois do final, abre a **"Festa sem fim"**, de ondas sem fim (antes chamada "Defender a festa").

### Premissa

Todo ano a ilha faz a Festa do Cafuné, com balões, banda, doces e lanternas. Os esqueletos que moram no Morro ouvem a música lá de cima, mas nunca são convidados: todo mundo se assusta só de olhar para eles. Este ano o Mestre Ossinho, líder dos esqueletos, decidiu: se não podem ir à festa, a festa vai até eles. Ele acende quatro Lanternas Mágicas, que abrem rachaduras roxas no chão, e por elas os esqueletos saem em ondas para levar a decoração para o cemitério do Morro.

### Prólogo: véspera da festa (praia do cais, tutorial)

1. O jogador escolhe o menino ou a menina na praça enfeitada.
2. O jogador nasce na praça da festa e o marcador aponta a praia ao lado do cais, onde se abrem as rachaduras roxas. **Onda 1:** 3 Minions (aprender a atirar). **Onda 2:** 4 Minions e 1 Rogue (aprender a desviar de flecha). No intervalo cai a primeira caixa de munição. A gente da praça torce de longe e comemora no fim.
3. O Mestre Ossinho aparece no céu sobre o Morro e acende as quatro lanternas: duas na cidade, duas na mata. Raios roxos ligam o cemitério do Morro às lanternas.
4. A praça fica segura e vira a base: bandeira de retorno e caixa de munição que sempre volta.

A ilha se abre. Objetivo: apagar as quatro lanternas.

### Como funciona uma defesa

- **Arena:** um círculo de uns 22 m em volta da lanterna, marcado no chão por um anel roxo. Entrar nele começa a defesa ("Os esqueletos vêm aí!").
- **Rachaduras:** 3 a 5 pontos em volta da arena; os esqueletos saem delas (animação de subir do chão).
- **Ondas:** 3 por região, cada uma maior que a anterior. A tela mostra "Onda 2 de 3 · faltam 5".
- **Intervalo:** uns 8 segundos entre ondas; cai uma caixa de munição e um coração no centro.
- **Guardião:** vem na última onda, com barra de vida no topo da tela.
- **Saiu do círculo ou ficou tonto:** a onda atual é cancelada (os esqueletos dela afundam de volta nas rachaduras) e recomeça quando você voltar. Ondas já vencidas continuam vencidas.
- **Vitória:** a lanterna apaga, as rachaduras fecham e a região vira festa (balões e bandeirinhas aparecem). A região fica segura, ganha uma bandeira de retorno e entrega a recompensa.
- **Entre regiões:** exploração tranquila, com poucos grupinhos de 2 ou 3 esqueletos soltos, que também vão embora de balão e não voltam.

### Ato 1: Cidade (em qualquer ordem)

**Desde 2026-10-26 (pedido do usuário) os guardiões não dão mais blaster:** dão moedas, e o Granulado, a Pipoqueira e o Pé-de-Moleque se compram na Lojinha de Blasters (seção 8). A Torre e o Guerreiro Planta continuam dando +1 coração, além das moedas.

| Região | Onda 1 | Onda 2 | Onda 3 | Guardião | Recompensa |
|---|---|---|---|---|---|
| Lanterna Oeste (perto da caixa-d'água) | 5 Minions | 4 Minions, 2 Warriors | 4 Minions, 1 Warrior | Ossão | 50 moedas |
| Lanterna Leste | 4 Minions, 1 Rogue | 3 Minions, 3 Rogues | 3 Minions, 2 Rogues | Mira-Torta | 50 moedas |

Fecho do ato: com as duas apagadas, as defesas da mata começam. A ponte não tem barreira (pedido do usuário): dá para passear na mata antes, mas as lanternas de lá só aceitam defesa depois das da cidade.

### Ato 2: Mata (em qualquer ordem)

| Região | Onda 1 | Onda 2 | Onda 3 | Guardião | Recompensa |
|---|---|---|---|---|---|
| Clareira da Jabuticabeira | 4 Minions, 1 Mage | 1 Golem, 2 Minions, 2 Mages, 1 Rogue | 2 Mages | Torre de Ossinhos | +1 coração máximo e 50 moedas |
| Morro dos Ventos | 5 Minions, 1 Warrior | 1 Golem, 1 Warrior, 2 Rogues, 1 Mage | 3 Minions | Minionzão | 50 moedas |

**Seta da ponte (corrigida em 2026-10-26, o usuário viu a seta da luta da mata parar na entrada da ponte):** do lado da cidade do rio o objetivo é "Atravesse a ponte para a mata" e a seta aponta o outro lado da ponte (perto da bandeira EntradaDaMata), não mais o começo dela (a seta sumia ao chegar e não aparecia de novo enquanto não se pisava na ponte). O lado do rio é medido pela curva do rio (`Story.south_of_river`), não por um z fixo: onde o rio desce, a margem da cidade passava do z da ponte e a seta já apontava a luta através da água. Passando o meio do rio, a seta aponta a luta mais perto.

Fecho do ato: com as quatro apagadas, a cúpula roxa do cemitério cai. Num bilhete deixado na última lanterna, um dos esqueletos escreveu que só queria dançar na festa.

### Ato 3: O cemitério do Morro

- Subida do Morro pela trilha em espiral.
- **Defesa final no cemitério:** 3 ondas com todos os tipos de esqueleto.
- **Chefe final: Mestre Ossinho**, esqueleto mago de coroa. Três fases: chama minions pelas rachaduras, se protege com bolhas mágicas que precisam ser estouradas, e por fim lança bolhas gigantes que se dividem.
- **Desfecho:** o Mestre Ossinho não vai de balão: senta no chão, tira a coroa e confessa que só queria ir à festa. As crianças entregam o convite.
- **No jogo (2026-10-26):** a defesa `cemiterio` fica no gramado do meio do cemitério (centro entre o portão e a cripta, raio 18, rachaduras nas diagonais a 10 m) e liga quando a cúpula cai. Antes era no pátio do castelinho, pequeno demais; o usuário pediu o cemitério com espaço amplo. Ondas: 4 Minions, 1 Rogue e 1 Mage; 2 Warriors, 2 Rogues e 2 Minions; 1 Golem, 1 Mage e o Mestre Ossinho. Vencida, começa o desfecho em cena (abaixo).
- **Desfecho em cena (`scripts/ending.gd`, ~15 s):** o controle e a interface somem e uma câmera de cena enquadra o Mestre sentado, a coroa no chão e o aventureiro na frente dele. Faixa "O Mestre Ossinho tirou a coroa..." / "Ninguém nunca convidou a gente para a festa."; o aventureiro diz "Toma! É o convite da festa!" e um presente voa até o colo do Mestre; ele responde "Um convite... para a gente?!", levanta e comemora; seis esqueletos saem do chão do outro lado, torcendo; faixa "Vocês entregaram o convite!". A foto do álbum é tirada ali. A tela escurece em "Na noite seguinte..." e o epílogo começa. O menu de pausa fica bloqueado durante a cena.

### Epílogo: a Festa do Cafuné

Todos os esqueletos que foram de balão voltam descendo de balão na praça, agora como convidados. **No jogo (2026-10-26):**
- **Noite:** céu azul-escuro com estrelas pintadas na cobertura do céu, a lua no lugar do sol (luz fraca e azulada, com o disco na frente do palco), luz ambiente lilás, brilho (glow) ligado, luz quente nos postes da cidade perto da praça e nas lanternas da festa, foco rosa no palco e fogos de artifício de 1 a 2 s (rojão com rastro, estouro colorido e um clarão que pinta a praça). Cordões de lâmpadas coloridas ligam os oito postes de balão da praça (ficam também de dia, no pós-jogo).
- **Convidados (descem de balão, um atrás do outro, e os balões estouram em confete ao pousar):** o Minionzão e quatro Minions dançando no meio da praça (não há dança no KayKit: alternam torcida, provocação dos esqueletos, pulinho e aceno, com giros); um Warrior tocando trompete com a banda no palco (no lugar do xilofone de costela, que não existe no pacote); dois Mages garçons andando entre as mesas com prato de doces e pizza; o Ossão com um hambúrguer perto da comida; um Rogue tomando sorvete; a Mira-Torta com a besta na barraca de tiro; a Torre de Ossinhos (quatro Minions empilhados balançando) ao lado do palco; e o Mestre Ossinho, sem coroa, sentado no banco com o vovô. Usam o mesmo script dos moradores (`model_path`, `model_scale`, `hide_meshes`).
- **Esqueletos da ilha:** os que dormiam pela ilha viram amigos no mesmo lugar (sentados ou acenando, com frases); acabou a luta livre.
- O aventureiro chega a sudeste do meio da praça, olhando para o palco; faixa "A Festa do Cafuné!" e objetivo "Aproveite a festa! Suba no palco para ver o álbum". A foto "A Festa do Cafuné" é tirada de um ângulo bonito alguns segundos depois.
- **Créditos (`scripts/credits.gd`):** subir no palco pausa o jogo e abre o "Álbum da Festa do Cafuné": cada foto da partida como polaroide com legenda (3,4 s cada; pular passa para a próxima, Start/Esc encerra), depois os créditos sobem (KayKit de Kay Lousberg, Kenney, Quaternius, sons feitos por código, Godot) e "Obrigado por jogar!".
- **Fotos do álbum:** tiradas sozinhas, sem a interface, 1,6 s depois de cada região vencida ("A primeira defesa, na praia do cais", "O Ossão foi embora de balão", "A Mira-Torta errou de novo", "A Torre de Ossinhos desmontou", "O Minionzão ficou tonto", "O Guerreiro Planta virou amigo da gente"), no desfecho e na festa. Ficam em 960x540 em `user://campanha_album/`.

### Depois dos créditos (pós-jogo)

A ilha volta para o dia e fica em festa: as lanternas mágicas viram lanternas de festa (cada uma de uma cor, sem o raio roxo), os convidados continuam na praça, os esqueletos da ilha são amigos e o Mestre Ossinho fica no cemitério chamando para a Festa sem fim. A barraca de tiro guarda os acertos na campanha. O Guerreiro Planta continua no Bosque das Copas para quem ainda não venceu.

### "Festa sem fim" (depois da história)

**Feita em 2026-10-26 (`scripts/endless_party.gd`).** A primeira versão do pós-jogo era o "Defender a festa" na praia (esqueletos que não atacavam tentando levar cinco presentes); o usuário não gostou ("ficar protegendo os 5 presentes ficou ruim") e escolheu as ondas de verdade no cemitério, a ideia original deste documento.
- No gramado do cemitério do Morro (a arena da luta final, raio 18), com o Mestre Ossinho, sem coroa, chamando ("É luta de brincadeira, mas vale de verdade!"). Ficar 1 s no círculo dourado do meio começa; o placar flutuando mostra o recorde.
- Os esqueletos lutam como na história, saindo de 8 rachaduras (as 4 da defesa final e mais 4 nos eixos, a 13 m, onde o chão é plano). Onda n: 3 + n esqueletos (até 14, no máximo 12 de pé ao mesmo tempo); Rogue a partir da 2ª, Mage da 3ª, Warrior da 4ª e Golem a cada 3 ondas a partir da 6ª.
- **A cada 5 ondas, um guardião** (com metade dos esqueletos): Ossão, Mira-Torta, Torre de Ossinhos, Minionzão e Guerreiro Planta, revezando; a cada volta pelos cinco eles vêm 30% mais fortes.
- Entre as ondas (6 s), munição e coração no centro. Cada onda vencida dá **5 + 2n moedas** (mais 30 na onda do guardião) e conta para o recorde.
- Ficar tonto acaba a festa ("Você aguentou N ondas", com "Novo recorde!" quando passa o anterior); sair para longe (60 m) também para. Os esqueletos que sobraram afundam e dá para começar de novo.

### Campanha salva e menu inicial

- **Salva sozinha** (`scripts/save_game.gd`, JSON em `user://campanha.json`; no Linux, `~/.local/share/godot/app_userdata/Ilha Cafuné/`): ao começar, a cada região vencida, recompensa pega, bandeira nova, troca de personagem, ao abrir a pausa e ao sair pelo menu. Guarda a etapa (antes, prologo, cidade, mata, cemiterio, festa, fim), as defesas vencidas, os blasters, os corações máximos, a bandeira, o personagem, recompensas ainda no chão, as fotos do álbum (arquivos em `user://campanha_album/`) e os recordes (Festa sem fim e acertos da barraca de tiro), as moedas, se a lojinha já foi visitada, os blasters comprados, o equipado em cada seta e as melhorias. Durante o desfecho não salva: quem sai ali volta para a defesa final.
- **Menu inicial:** "Ilha Cafuné", com "Continuar · <etapa>" (só com campanha salva), "Nova campanha" e "Sair do jogo". Continuar monta a ilha no ponto salvo: defesas vencidas em festa, lanternas certas, cúpula e portão, defesas da etapa ativas, e na festa ou no pós-jogo já entra de noite na praça ou com a brincadeira na praia.
- **Nova campanha** (no menu inicial e na pausa, pedido do usuário): pede confirmação ("Sim, começar do zero" / "Voltar") e apaga a campanha e as fotos. Pela pausa, a ilha recarrega do zero e vai direto para a escolha de personagem.
- Os testes automáticos nunca mexem na campanha de quem joga (qualquer argumento `--` desliga o salvamento; o teste de salvar usa `user://teste_campanha.json`).

### Mensagem

Não se julga ninguém pela aparência. Às vezes falta só um convite.

## 5. Progressão no mundo aberto

O jogo não tem fases. O progresso aparece no próprio mundo:

- **Raios das lanternas:** quatro raios roxos saem do cemitério do Morro e apontam as regiões que faltam. Apagam um a um.
- **Barreiras:** só a cúpula do cemitério (some depois das quatro lanternas). A barreira roxa da ponte saiu a pedido do usuário: a mata fica aberta desde o começo, mas as defesas de lá só começam depois das lanternas da cidade.
- **Regiões em festa:** cada região vencida ganha balões e bandeirinhas e fica sem esqueletos.
- **Blasters comprados aos poucos** (pedido do usuário; até 2026-10-26 vinham de presente dos guardiões): Paçoca desde o começo; os outros se compram na Lojinha de Blasters com as moedas dos guardiões (seção 8). Granadas desde o prólogo. Cada blaster tem sua seta no direcional (↑ Paçoca, → Granulado, ↓ Pipoqueira, ← Pé-de-Moleque) e sua tecla (1 a 4); no painel, cada blaster mostra uma cruzinha do direcional com o braço dele aceso (no controle) ou a tecla (no teclado). Apertar uma seta sem blaster mostra onde comprar ("Granulado: compre na Lojinha de Blasters, na beira da praia (40 moedas)"). Os blasters ganhos aparecem no painel como cartões menores conforme são desbloqueados (pedido do usuário).
- **Corações:** 5 no começo, +1 na Clareira.
- **Marcador na tela:** um losango roxo aponta o objetivo atual, com a distância em metros; o texto do objetivo aparece numa faixa quando muda e fica no menu de pausa.
- **Pontos de retorno:** bandeiras em cada região e no caminho.

Ideias para depois: coletáveis (estrelas escondidas, bilhetes dos esqueletos), esqueleto dourado (raro, foge, deixa prêmio), diamantes para melhorar blasters.

## 6. Personagens jogáveis

**Decisão do usuário (2026-10-25):** armadura medieval destoa da cidade. Os jogáveis são só **dois**: o **menino de boné amarelo** e a **menina de boné branco**, do pacote **"The Protagonists"** da KayKit Mystery Monthly Series 5. Os esqueletos continuam como estão.

| Personagem | Visual (do pacote) | Nome no jogo |
|---|---|---|
| Menino | boné amarelo, colete, mochila, roupa colorida de hoje | provisório: "Menino" |
| Menina | boné branco, óculos, mochila | provisório: "Menina" |

- **Pacote:** KayKit Mystery Monthly Series 5 (vendido no itch.io; licença CC0, como todo o KayKit). Traz 14 personagens; só usamos os dois Protagonists. Em 2026-10-25 o usuário trouxe a Coleção Completa do KayKit v6.1 (clone em `Projects/others/kaykit-complete-v6-1-assets`, com os arquivos no Git LFS; só os pacotes usados foram baixados com `git lfs pull --include`).
- **No jogo (desde 2026-10-25):** `assets/characters/protagonists/Protagonist_B.glb` é o menino e `Protagonist_A.glb` é a menina (a de óculos). Usam o mesmo `Rig_Medium` dos esqueletos, com os mesmos 23 ossos (só a ordem muda, e as animações acham os ossos pelo nome), então animações, encaixe do blaster e regiões de impacto valeram sem mudança. Antes, o Ranger e a Rogue do Adventurers grátis seguravam o lugar; eles saíram da build (`exclude_filter` do `export_presets.cfg`) e só ficam para as ferramentas de inspeção.
- **Escolher e trocar:** o jogo abre na tela "Escolha quem vai jogar". Depois, só pelo menu de pausa (Esc ou Tab / Start) > "Trocar de personagem" (decisão do usuário). Na primeira versão a diferença é só visual.
- **Nomes:** ainda por decidir.

### Moradores (feitos em 2026-10-26)

Personagens das Mystery Monthly do KayKit (Coleção Completa v6.1), todos no mesmo `Rig_Medium` do aventureiro, em `assets/characters/moradores/` (texturas alternativas em `texturas/`). Script: `scripts/townsperson.gd`. Escolha do usuário: "gente na cidade e na festa"; ficaram de fora quem tem arma de verdade (Sobrevivente, Boneco de Ação) e os duendes de Natal.

| Morador | Modelo | Onde e fazendo o quê |
|---|---|---|
| Banda (2) | Soldadinho de Brinquedo, com trompete | no palco da praça, tocando de verdade (pedido do usuário em 2026-10-26): o trompete fica na boca, preso à cabeça, com os braços erguidos até ele na pose de mira de duas mãos; o urso cruza o violão na barriga (preso ao peito, com o braço indo para a mão esquerda, na pose `Holding_C`) e faz a palhetada. O movimento é do `scripts/musician_motion.gd` (um `SkeletonModifier3D` por cima da pose: tronco e cabeça marcando o tempo a 112 bpm, inclinação nas notas longas, antebraço da palhetada). A banda não para de tocar nas comemorações. Fotos: `--banda-captura` |
| Fazendeiro e fazendeira | Farmer_A / Farmer_B | barraca de verduras da praça (trabalhando / parada) |
| Palhaço | Clown, com cachorrinho de balão | no pódio do cantinho do palhaço |
| Plateia (3) | crianças de fantasia de dinossauro e garota mágica (cores diferentes) | sentadas no chão vendo o palhaço |
| Dançarinas (2) | dinossauro e garota mágica | na frente do palco, torcendo |
| Vovô | Lorekeeper, com cajado | sentado num banco da praça; conta do Morro e dá a dica das lanternas |
| Garota mágica | com varinha | no outro banco |
| Motoristas (2) | Driver (duas texturas) | andando de um lado para o outro na calçada da rua norte |
| Trilheiro | Hiker | ao pé do Morro, falando da trilha |
| Urso da banda | Animatronic (versão normal), com violão | no palco, entre os soldadinhos |
| Bruxa | Witch | barraca de poções no noroeste da praça (bancada, caldeirão, cesto de cogumelos, vassoura): "Poção de groselha! Deixa a língua azul!" |
| Fantasiados | Super-herói, Patrulheiro espacial, Homem das cavernas | super-herói torcendo na barraca de tiro, astronauta perto do trenzinho, homem das cavernas na mesa da pizza |
| Lenhador | Werewolf (só a forma humana), com machado | na margem sul do rio, perto da ponte: parte um tronco caído ao lado do toco da árvore que derrubou, com pilhas de toras. O golpe do KayKit é de cima para baixo, por isso o tronco fica deitado; o machado vem com a lâmina para cima no osso da mão e é girado 180° em volta do cabo (`item_rot` no marcador) |
| Pescador | Hiker (outra textura), com vara de pesca | na ponta do cais, com caixa de pesca e balde |

- **Atividades:** parado, sentado no banco, sentado no chão, torcendo, trabalhando, andando (vai e volta entre dois pontos), tocando, cortando (lenha) e pescando. Animações do KayKit Character Animations (bibliotecas `geral`, `mov`, `festa` e `ferramentas`).

### Diversões (feitas em 2026-10-26)

- **Barraca de tiro ao alvo** (`scripts/shooting_gallery.gd`, marcador `Diversao/TiroAoAlvo` no canto sudoeste da praça): quatro alvos de pé do Prototype Bits que caem para trás quando acertados e voltam sozinhos em 2,5 s, o boneco de treino do Avian Swordsman no meio (balança e mostra o dano; cabeça vale o dobro) e o placar "TIRO AO ALVO / Acertos" flutuando em cima. Serve de treino de tiro. Os alvos só bloqueiam o caminho pela base, para o tiro chegar na região do alvo.
- **Perto do aventureiro:** quem está de pé vira para ele e acena, e o balão de fala mostra a próxima frase (uma a cada 16 s). As falas são curtas, com dicas e humor, e o vovô adianta o final ("Será que alguém já convidou os esqueletos?").
- **Nas ondas:** quem está até 14 m além do círculo de uma defesa em andamento torce ("Vai!", "Mira na cabeça!"). Ao vencer, comemora com confete. Cada região vencida da cidade e da mata ganha uma mesa com comida e três convidados festejando (`PARTY_GUESTS` no `story.gd`).
- **Colisão:** camada própria (`moradores`, a 5): o aventureiro esbarra, mas tiros, granadas, flechas, câmera e esqueletos passam direto. Ninguém atira nos moradores, e os esqueletos não ligam para eles.

## 7. Esqueletos e chefes

Os quatro esqueletos da versão grátis do KayKit Skeletons, mais variações de tamanho, cor e chapéu.

| Esqueleto | Papel | Comportamento (o que já está no jogo em **negrito**) |
|---|---|---|
| Minion | o mais comum, vem em bando | **chega perto e dá um soco; 5 de vida** |
| Warrior | resistente | **machado e escudo; tiro no corpo de frente é bloqueado ("bloqueou!"), a não ser quando ele ergue o machado; acertar a cabeça ou pelas costas; 8 de vida** |
| Rogue | à distância | **besta; para a uns 12 m e atira flecha de ventosa reta, que dá para desviar andando de lado**; 4 de vida; se esconder atrás de carros e árvores fica para depois |
| Mage | apoio | **cajado; lança bolha mágica lenta que persegue de leve e estoura com um tiro ("plof!")**; 4 de vida; chamar minions fica para depois |
| Golem de Ossos | pesado, nas ondas da mata | **o Skeleton_Golem do Skeletons completo (esqueleto grande, `Rig_Large`), 3,6 m; lento, 16 de vida; bate os punhos no chão (1,1 s depois do "!") e solta uma onda que se pula; quem está bem na frente leva o golpe; granada quase não empurra** |
| Esqueleto dourado | raro | variação dourada de qualquer um; foge e deixa muitos diamantes (ainda não feito) |

**Regras de combate que valem para todos (já no jogo):** antes de cada golpe aparece um "!" amarelo sobre a cabeça; levar tiro interrompe o ataque; cada golpe tira 1 coração; quando o aventureiro fica tonto, os esqueletos param de atacar e comemoram; quando ele volta na bandeira, os que estavam acordados voltam para os lugares de origem, para ninguém reaparecer cercado; derrotado, o esqueleto vai embora de balão e não volta.

Guardiões (todos montados com os esqueletos grátis, ampliados e com acessórios). Cada um aparece na última onda da sua região e vai embora de balão quando derrotado (um balão gigante):

| Guardião | Região | Base | Como é a luta |
|---|---|---|---|
| Ossão | Lanterna Oeste | Warrior 2,6x maior, escudo grande | salta e bate no chão, soltando uma onda que se pula; machadada de perto; o escudo bloqueia tiro no corpo pela frente (cabeça e costas valem); na metade da vida chama 2 Minions e com um quarto chama mais 2. 56 de vida (eram 40), anda mais rápido e salta com mais frequência |
| Mira-Torta | Lanterna Leste | Rogue 2,3x maior | pula de um lado para outro da arena; leque de 5 flechas; chuva de flechas com círculos de aviso no chão (sair do círculo antes de cair); 44 de vida (eram 32), pausa menor entre os ataques e chuva com 5 círculos (7 abaixo da metade) |
| Torre de Ossinhos | Clareira | 5 Minions empilhados | a torre anda e o de cima joga bolhas que estouram com tiro; cada Minion acertado o bastante sai de balão e os de cima descem; com 2 ou menos, a torre pula e solta uma onda; 6 de vida por andar, 30 no total (eram 20), bolhas mais frequentes |
| Minionzão | Morro dos Ventos | Minion 3x maior | investida em linha reta (uma faixa vermelha no chão avisa o caminho); depois fica tonto uns segundos e leva dano em dobro; soco de perto; 50 de vida (eram 36), investida mais frequente e com aviso um pouco mais curto, tonto por menos tempo |
| Mestre Ossinho | cemitério do Morro | Necromancer do Skeletons completo (já vem de coroa), 2x maior, cajado do Mage; 48 de vida | mantém distância de 7 a 12 m. Fase 1 (até 2/3 da vida): bolhas mágicas e dois minions pelas bordas a cada 10 s. Fase 2: escudo de seis bolhas girando (tiro e granada estouram; enquanto houver bolha, nada passa); sem bolhas fica tonto 5 s com dano em dobro e o escudo volta. Fase 3 (abaixo de 1/3): bolhas gigantes e lentas que, estouradas com tiro, viram três pequenas. Derrotado, senta no chão, tira a coroa (cai no chão na frente dele) e diz "Eu só queria ir à festa..." |
| Guerreiro Planta (opcional) | Bosque das Copas | PlantWarrior do Mystery Monthly Series 6 (não é esqueleto: é o guardião da mata), 1,7x, lança, escudo de folha e arco; 40 de vida | brota do chão quando o aventureiro entra no Bosque. Escudo de folha segura tiro no corpo pela frente (cabeça e costas valem). Três flechas em leque com aviso; investida com a lança (faixa verde no chão mostra o caminho) e depois fica ofegante e sem escudo. Vencido, aplaude e diz "Você é amigo da mata! Pode voltar quando quiser."; recompensa +1 coração. Não conta para a história (região `vila` ativa desde que a mata abre) |

**Opção paga barata:** a versão Extra do Skeletons traz o Skeleton Golem e o Necromancer, que dariam um chefe e um Mestre Ossinho com visual próprio. A página mostra dois preços (US$ 3,97 e US$ 7,95).

## 8. Blasters, itens e pacotes de arte

### Blasters

O KayKit não tem armas de fogo nem blasters em nenhum pacote (conferido em 2026-10-25). Os blasters vêm do **Kenney Blaster Kit** (CC0, grátis), que tem estilo low-poly parecido. Os nomes de doces continuam:

**No jogo hoje** (todos liberados desde o começo; ganhar um por vez fica para a história). Os números ficam em `scripts/weapons.gd`, um bloco por arma:

| Tecla | Blaster | Modelo | Mãos | Pente | Estoque inicial / máximo | Recarga | Jeito |
|---|---|---|---|---|---|---|---|
| 1 | Paçoca (pistola) | `blaster-a` | 1 | 12 | infinito | 1,0 s | tiro único e preciso, 1 de dano |
| 2 | Granulado (rajada) | `blaster-j` | 2 | 30 | 60 / 150 | 1,6 s | segura o gatilho, 11 tiros por segundo, 0,5 de dano, pouco espalhado |
| 3 | Pipoqueira (escopeta) | `blaster-l` | 2 | 6 | 12 / 36 | 1,8 s | 7 projéteis de 0,6 num leque de 5,5°, alcance de 28 m |
| 4 | Pé-de-Moleque (precisão) | `blaster-e` | 2 | 5 | 10 / 25 | 2,0 s | luneta ao mirar (aproxima e diminui a sensibilidade), 3 de dano, um tiro na cabeça derrota qualquer esqueleto |
| G / RB | Brigadeiro (granada) | `grenade-a` | — | — | começa com 2, máximo 3 | — | arremesso em arco, explode em confete depois de 1,4 s, raio de 5,5 m, 6 de dano no centro e 2 na borda nos esqueletos, 7 a 2 nos chefes (medido da borda do corpo), o escudo não segura, estoura bolhas; com o escudo de bolhas do Mestre, só estoura as bolhas. **Ajuste de 2026-10-26** (o usuário achou o dano baixo): antes eram 3 de dano, raio de 5 m, e a granada nem acertava os chefes |
| F / R3 | Pirulitão (corpo a corpo) | `lollipop_pink` (Halloween Bits, 1,7x) | — | — | infinito | — | pedido do usuário em 2026-10-26: golpe de lado (`Melee_1H_Attack_Slice_Horizontal` só no tronco, 1,6x mais rápido), o pirulito aparece na mão e o blaster some por 0,55 s; acerta 0,22 s depois quem estiver numa esfera de 1,3 m a 1,5 m na frente, uma vez cada, no corpo (3 de dano; o escudo do guerreiro segura pela frente, como no tiro), e estoura bolhas mágicas perto; interrompe a recarga; um golpe a cada 0,6 s. Também no botão do meio do mouse |

### Lojinha de Blasters e moedas (2026-10-26, pedido do usuário)

- **Campanha salva antes das moedas** (versão 1 do salvamento): ao continuar, ganha as moedas dos guardiões já vencidos, menos o preço dos blasters da história que já tem (naquela versão eles vieram de presente), com a faixa "Moedas dos guardiões: N!". O salvamento do usuário (história completa, com os 3 blasters) volta com 200 moedas.
- **Moedas:** cada guardião da história dá 50 (Ossão, Mira-Torta, Torre, Minionzão e o Guerreiro Planta, que é opcional) e o Mestre Ossinho dá 100. Até o fim da mata são 200 moedas (250 com o Planta). Os três blasters da história custam 40, 50 e 60 (150): dá para comprar os três e sobrar, ou pular algum e juntar para um melhor (por exemplo, Pé-de-Moleque + Bananada = 210, com o Planta). Depois da história, a Festa sem fim dá 5 + 2n por onda, mais 30 por guardião (uma partida de 10 ondas rende uns 220). O contador fica embaixo dos corações (aparece depois da primeira moeda).
- **Primeira moeda:** faixa "Você ganhou moedas!" e uma **seta dourada em forma de moeda** ("Lojinha · N m"), separada do losango roxo do objetivo, leva até a barraca. Some depois da primeira visita (`Story.shop_target`).
- **Barraca** (`scripts/shop.gd`): na beira da praia, entre a rua da praça e a areia, a leste do cais (12, 199,5): balcão com três blasters em exposição, toldo listrado de rosa e branco, placa "LOJINHA DE BLASTERS", caixote do Blaster Kit e o vendedor (o astronauta do Mystery Monthly). Parar meio segundo no tapete dourado na frente do balcão abre o menu (o jogo pausa); para abrir de novo, sair do tapete e voltar.
- **Menu para criança** (`scripts/shop_menu.gd`, refeito em 2026-10-26: o usuário achou o primeiro "muito textual"): cinco colunas com etiqueta colorida (Pistola, Metralhadora, Escopeta, Rifle e Extras), três cartões em cada uma. O cartão tem a miniatura colorida do blaster (`assets/ui/loja/`, geradas por `tools/gerar_miniaturas.gd`), o nome e o preço com uma moedinha; o que já é seu mostra "é seu", o equipado "em uso", e o que ainda não dá para comprar fica apagado. Abre com o item mais barato que ainda não é seu marcado.
- **Prévia:** escolher um cartão abre o blaster girando (SubViewport), a etiqueta do tipo, o **DANO** em número grande ("por tiro"; nas escopetas, a soma dos grãos), barras de 5 pedaços de Força, Rapidez, Alcance e Balas, em que seta ele fica, e os botões "Comprar N" (ou "Usar este" / "Em uso") e "Voltar". Faltando moedas, já avisa "Faltam N moedas". B / Esc volta da prévia para os cartões.
- **Encaixes:** continuam quatro setas (e as teclas 1 a 4); cada seta tem um blaster equipado (`Player.equipped`). Comprar equipa na seta e põe na mão; dá para voltar para outro a qualquer hora. A caixa de munição dá um pente de reserva de cada blaster equipado com estoque limitado.

| Seta | Blaster | Modelo | Preço | Jeito |
|---|---|---|---|---|
| ↑ (1) | Paçoca | `blaster-a` | de graça | a pistola de sempre: 12 balas de 1, estoque infinito |
| ↑ (1) | Jujuba | `blaster-k` | 60 | pistola rapidinha: 16 balas, 0,9 de dano, quase sem pausa; estoque infinito |
| ↑ (1) | Cocada | `blaster-c` | 130 | pistola pesada: 6 tiros de 2,4; estoque infinito |
| → (2) | Granulado | `blaster-j` | 40 | a primeira metralhadora: 30 balas de 0,5 |
| → (2) | Beijinho | `blaster-q` | 90 | metralhadora turbo: 45 balas de 0,35, a mais rápida |
| → (2) | Bananada | `blaster-d` | 150 | metralhadora forte e certeira: 24 balas de 0,9 |
| ↓ (3) | Pipoqueira | `blaster-l` | 50 | a primeira escopeta: 7 grãos de 0,6 |
| ↓ (3) | Canjica | `blaster-g` | 100 | escopeta de leque largo: 11 grãos de 0,5, alcance curto |
| ↓ (3) | Rapadura | `blaster-h` | 160 | cano duplo: 2 tiros de 8 grãos de 0,8, recarga rápida |
| ← (4) | Pé-de-Moleque | `blaster-e` | 60 | o primeiro rifle: luneta, 5 tiros de 3 |
| ← (4) | Suspiro | `blaster-p` | 110 | rifle semiautomático: 8 tiros de 2 com luneta |
| ← (4) | Bombom | `blaster-f` | 180 | superprecisão: 3 tiros de 6, luneta forte |
| extra | +1 Brigadeiro | — | 70 | cabem 4 granadas |
| extra | +1 Coração | — | 250 | um coração a mais para sempre |

O Blaster Kit tem 18 blasters (`blaster-a` a `blaster-r`) e 2 granadas; o jogo usa 12. O encaixe na mão dos novos foi medido nas malhas (cabo: o ponto mais baixo da metade de trás; boca: a ponta da frente) e conferido em `tools/foto_blasters.gd`; no Suspiro e no Bombom o cabo foi puxado para o punho atrás do pente. As silhuetas do painel saem de `tools/gerar_icones.gd`.

**Regras de munição (decisão do usuário: estoque limitado):**
- **Painel de armas** (`scripts/weapon_hud.gd`, inspirado numa referência de HUD de jogo de tiro enviada pelo usuário): no canto de baixo à direita, painéis escuros translúcidos inclinados. O grande mostra a arma na mão: ícone de balas, número do encaixe, pente grande em laranja sobre o estoque em cinza (∞ na Paçoca) e a silhueta branca da arma. Em cima, uma fileira de cartões menores, um para cada outro blaster já ganho, na ordem do direcional, com silhueta, pente/estoque e o botão que puxa aquele blaster: no controle, uma cruzinha do direcional com o braço daquela arma aceso em laranja; no teclado, a tecla do número (a fonte padrão da Godot não tem os glifos ↑→↓←, por isso o botão é desenhado). O cartão aparece quando o blaster é ganho, e o botão do blaster recém-ganho pisca em amarelo com um anel por uns 3 s. Cartão de blaster sem nenhuma munição fica apagado com o número em vermelho. À esquerda, as granadas com o número. O pente fica amarelo no último quarto e vermelho zerado; ao trocar de arma o conteúdo desliza e acende; ao atirar o número dá um pulinho; recarregando, a silhueta apaga, aparece "RECARREGANDO" e uma barra azul enche embaixo. As silhuetas são geradas por `tools/gerar_icones.gd` em `assets/ui/icones/`.
- Pente vazio recarrega sozinho (com a animação de recarga de uma ou duas mãos do KayKit e um anel azul na mira). Dá para recarregar antes de zerar com R ou X. Durante a recarga não atira; trocar de blaster cancela a recarga.
- Sem estoque, o gatilho faz "tic" e aparece "Sem munição! Procure uma caixa ou troque de blaster".
- **A Paçoca tem estoque infinito de propósito**, como rede de segurança: a criança nunca fica sem ter com o que atirar.
- **Caixa de munição** (caixote do Blaster Kit com um pente em cima): devolve 30 do Granulado, 6 da Pipoqueira, 5 do Pé-de-Moleque e 1 granada, até o máximo. Com tudo cheio, fica no chão.
  - Na ilha há 10 caixas fixas (marcadores `Marcadores/Municao`), que voltam 45 s depois de pegas.
  - Esqueleto derrotado deixa cair uma caixa em 50% das vezes, e sempre que a munição limitada está abaixo de 25%; essa some depois de 30 s.

### Itens

Diamantes (moeda), corações (energia), estrelas (coletável), bandeiras (checkpoint): todos do KayKit Platformer Pack. Potes de vaga-lume, bilhetes e Lanternas Mágicas: montados com peças dos pacotes ou feitos com formas simples na Godot.

**No jogo hoje:** o coração que cai é o `heart_red` do Platformer Pack, e a bandeira de retorno é a `flag_A`, azul quando inativa e amarela quando ativa (copiadas para `assets/props/platformer/<cor>/`; o pacote guarda cada cor numa pasta, todas com a mesma textura). A `star_red` e a `star_yellow` também foram copiadas, para coletáveis futuros. Os corações da tela são desenhados por código, e as estrelinhas de tonto são geradas por código (sempre de frente para a câmera). As armas dos esqueletos (machado, escudo, besta, cajado) vêm do próprio pacote Skeletons e encaixam no `handslot` sem ajuste.

### Pacotes

| Pacote | Autor | Versão | Tamanho | Uso |
|---|---|---|---|---|
| Adventurers | KayKit | grátis 2.0 | 12 MB | substitutos dos jogáveis até 2026-10-25; hoje só nas ferramentas (baixado) |
| Mystery Monthly Series 5 | KayKit | 1.1, da Coleção Completa v6.1 | 1,7 MB (só os Protagonists) | os dois jogáveis ("The Protagonists") (baixado) |
| Skeletons, Holiday Bits, Restaurant Bits | KayKit | completos, da Coleção Completa v6.1 | 13 + 8 + 5 MB | Golem e Necromancer (o Mestre Ossinho), em `assets/characters/skeletons/`; enfeites e comida da festa em `assets/props/festa/` (`doces/`, `comida/`, `circo/`) |
| Halloween Bits, Forest Nature Pack, Medieval Hexagon | KayKit | completos, da Coleção Completa v6.1 | 1,1 + 5,6 + 0,1 MB (só os usados) | cemitério do Morro (`assets/props/cemiterio/`); árvores e arbustos nas cores 2, 3, 5, 6, 7 e 8 (`assets/env/forest/corN/`), formatos Tree 5, 6 e 7 e morrinhos `Hill_*`; ponte de pedra (`assets/props/ponte/`) |
| Prototype Bits, RPG Tools Bits | KayKit | completos, da Coleção Completa v6.1 | poucos KB cada | alvos da barraca de tiro (`assets/props/tiro/`), vara e caixa de pesca (`assets/props/pesca/`) |
| Ultimate Animated Animal Pack, Animated Cute Fish Pack | Quaternius (quaternius.com, pastas do Google Drive) | CC0 | 65 MB brutos em `vendor/quaternius/` | baixados em 2026-10-26 com autorização do usuário: 10 animais em glTF com andar, galope, comer e parado (`assets/animais/`), 17 peixes em FBX com nado e pulo fora d'água (`assets/peixes/`) e os módulos de cais (`assets/props/cais_peixes/`). O KayKit não tem animais além dos cavalos de tabuleiro do Medieval Hexagon, que saíram. O Farm Animal Pack (porco, ovelha, lhama, pug) também foi baixado, mas saiu: o usuário não gostou do visual nem do comportamento (só tinham animação parada) |
| Mystery Monthly (mais personagens) | KayKit | 1.1, da Coleção Completa v6.1 | ~2 MB | Animatronic, Witch, Superhero, Space Ranger, Caveman, Werewolf (humano) em `assets/characters/moradores/`; Plant Warrior em `assets/characters/guardioes/` com as armas em `assets/weapons/planta/`; boneco de treino do Avian Swordsman |
| Mystery Monthly Series 4, 5 e 6 | KayKit | 1.1, da Coleção Completa v6.1 | 3,3 MB (só os usados) | moradores: Palhaço, Motorista, Fantasia de Monstro (Series 4); Trilheiro (Series 5); Fazendeiros, Soldadinho, Vovô (Lorekeeper), Garota Mágica (Series 6); objetos de mão em `assets/props/moradores/` |
| Skeletons | KayKit | grátis 1.1 | 7,7 MB | inimigos e chefes (baixado) |
| City Builder Bits | KayKit | grátis 1.0 | 4,6 MB | cidade (baixado) |
| Forest Nature Pack | KayKit | grátis 1.0 | 6,1 MB | floresta e Morro (baixado) |
| Blaster Kit | Kenney | 2.1 | 1,7 MB | blasters: 18 modelos (`blaster-a` a `blaster-r`), granadas, miras, alvos e projéteis de espuma (baixado) |
| Car Kit, City Kit Roads, Mini Skate, Watercraft Kit | Kenney (kenney.nl, CC0) | os de 2026 no site | 4,8 + 2,9 + 2,1 + 1,9 MB | baixados em 2026-10-26 com autorização do usuário, zips em `vendor/_downloads/kenney-20261026/` e extraídos em `vendor/kenney-*`. Usados: 5 karts, cones, caixa e pneu (`assets/carros/`); pedaços de estrada com e sem mureta, faixa, poste e placa (`assets/pista/`); 24 peças de skate e o skate (`assets/skate/`); barcos, navios, boias e o arco quadriculado de chegada (`assets/barcos/`) |
| Character Animations | KayKit | grátis 1.1 | 14 MB | 161 animações para o `Rig_Medium` e o `Rig_Large`, incluindo tiro, mira e recarga de uma e duas mãos, e animações próprias de esqueleto (baixado) |
| Platformer Pack | KayKit | grátis 1.0 | 22 MB | coração, bandeiras de retorno, estrelas; depois diamantes (baixado) |

Todos são CC0: uso comercial livre, sem atribuição obrigatória. O KayKit pede só para não revender os modelos sem alteração.

## 9. Notas técnicas na Godot

- **Esqueleto compartilhado (conferido nos arquivos):** aventureiros e esqueletos usam o mesmo esqueleto, `Rig_Medium`, com os mesmos nomes de ossos (`root`, `hips`, `spine`, `chest`, `head`, `upperarm.l/r`, `lowerarm.l/r`, `wrist.l/r`, `hand.l/r`, `handslot.l/r`, pernas e pés). Trocar de aventureiro é só trocar o modelo; animações, encaixe de arma e regiões de impacto continuam valendo.
- **Modelos em peças:** cada personagem vem dividido em malhas separadas (cabeça, corpo, braços, pernas, capa, elmo). Isso facilita trocar acessórios.
- **Animações:** os modelos não trazem animação embutida; elas vêm em arquivos `.glb` separados por categoria, em `vendor/kaykit-character-animations/.../Animations/gltf/Rig_Medium/`. As que importam para o jogo:

  | Arquivo | Animações úteis |
  |---|---|
  | `Rig_Medium_CombatRanged` | `Ranged_1H_Aiming`, `Ranged_1H_Shoot`, `Ranged_1H_Shooting`, `Ranged_1H_Reload` (pistola); as mesmas em `Ranged_2H_*` (escopeta e fuzil); `Ranged_Magic_*` (Mestre Ossinho) |
  | `Rig_Medium_MovementBasic` | `Walking_A/B/C`, `Running_A/B`, `Jump_Start`, `Jump_Idle`, `Jump_Land` |
  | `Rig_Medium_MovementAdvanced` | `Running_HoldingRifle`, `Running_Strafe_Left/Right`, `Walking_Backwards`, `Dodge_Forward/Backward/Left/Right` (esquiva) |
  | `Rig_Medium_General` | `Idle_A/B`, `Hit_A/B` (levar golpe), `Death_A/B` (ficar tonto), `Interact`, `PickUp`, `Throw` (granada Brigadeiro) |
  | `Rig_Medium_Special` | `Skeletons_Awaken_Floor` (esqueleto se montando do chão), `Skeletons_Idle`, `Skeletons_Walking`, `Skeletons_Taunt`, `Skeletons_Spawn_Ground` |
  | `Rig_Medium_Simulation` | `Cheering`, `Waving`, `Sit_Chair_*` (festa do epílogo) |

  Não há andar de lado lento nem correr de costas; a mira fica numa camada só do tronco, por cima da locomoção.
- **Blaster na mão:** os ossos `handslot.r` e `handslot.l` existem justamente para segurar objetos; o blaster vai num `BoneAttachment3D` no `handslot.r`, com marcador de boca do cano.
- **Mira:** pose de mira parada só no tronco no `AnimationTree`, para correr e atirar ao mesmo tempo. As animações de mira do KayKit (`Ranged_1H_Aiming`, `Ranged_2H_Aiming`) levantam o braço, seguram e abaixam no fim; repetidas, o braço sobe e desce sem parar. Por isso o jogo congela um instante delas (`AnimUtil.add_pose`: 0,6 s na de uma mão, 0,8 s na de duas).
- **Tiro:** sem animação de corpo (a do KayKit também levanta e abaixa o braço e reiniciava a cada disparo, fazendo cabeça e mãos repetirem o mesmo movimento). O coice é procedural, num nó `Coice` entre o osso da mão e o blaster: a boca sobe e a arma recua e volta, com força por arma (`coice` em `weapons.gd`). O teste `--armas` mede que cabeça e mão ficam firmes mirando e atirando.
- **Regiões de impacto:** cabeça e tronco dos esqueletos, mais pontos fracos dos chefes (costas do Ossão; cada andar da Torre de Ossinhos tem cabeça e corpo com vida própria).
- **Esqueleto indo embora de balão:** na derrota, três bolas do Platformer Pack (esticadas) com cordinhas aparecem sobre a cabeça e enchem; o esqueleto toca `Waving`, mostra "Tchau!" e sobe sem colisão, derivando para o Morro, até sumir em confete (uns 7 s). Sinal `gone` quando sai.
- **Escala:** 1 unidade = 1 metro; ampliar prédios da cidade se ficarem pequenos perto dos personagens.
- **Exportação:** a Godot gera `.exe` para Windows a partir do Mac. Para isso precisa baixar os modelos de exportação (export templates) da mesma versão da Godot, um pacote grande, na ordem de 1 GB. Também gera o app para macOS.

### 9.1 Fatia técnica

**Rodar o jogo** (da pasta `ilha-cafune`):

```bash
godot --path .
```

**Abrir no editor:**

```bash
godot -e --path .
```

**Testes automáticos:**
- `godot --headless --path . -- --smoke` atira num esqueleto sem abrir janela e imprime os estados.
- `godot --headless --path . -- --controle` joga só com eventos de controle simulados e confere 22 pontos (escolha inicial, analógicos, L3 correndo, pulo, mira, auxílio de mira, tiro, direcional e Y trocando de blaster, X, RB, R3 com o Pirulitão, Back, pausa com Start, trocar de personagem pela pausa, B e Start fechando a pausa); termina com "CONTROLE OK".
- `godot --headless --path . -- --combate` deixa os esqueletos atacarem de verdade e confere 13 pontos (soco, flecha e bolha acertam; invulnerabilidade; tiro estoura a bolha; tonto; comemoração; volta na bandeira com vida cheia; troca de bandeira; coração no chão; coração que cai); termina com "COMBATE OK". Leva cerca de 1 minuto.
- `godot --headless --path . -- --som` confere que os 20 efeitos carregam, que a música repete e que cada evento do jogo dispara o som certo (11 pontos); termina com "SOM OK". O teste não ouve nada: o `Sfx` anota o nome de cada som tocado quando `Sfx.logging` está ligado.
- `godot --headless --path . -- --ilha` confere a ilha (10 pontos): aventureiro no chão da praça, 18 esqueletos dormindo, bandeiras, acordar só quem está perto, voltar para casa, subir a encosta do Morro, atravessar a ponte, tchibum no rio e bandeira do topo; termina com "ILHA OK".
- `godot --headless --path . -- --historia` joga a história com ondas curtas e confere 32 pontos: só a Paçoca no começo; prólogo (começa na praça apontando a praia do cais, rachaduras, moradores da praça torcendo na onda e comemorando no fim, intervalo com munição e coração, onda cancelada ao se afastar e recomeçada ao voltar, lanternas acesas); Lanterna Oeste (Ossão com barra, tiro na cabeça, onda de choque que acerta no chão e passa por baixo de quem pula, Minions na metade da vida, lanterna apagada com 50 moedas e a seta da lojinha, convidados festejando, Granulado comprado na lojinha, Ossão indo de balão); Lanterna Leste (ficar tonto cancela a onda, Mira-Torta com chuva de flechas e leque de 5, defesas da mata começam, Pipoqueira comprada com as moedas); atravessar a ponte. Termina com "HISTORIA OK". Leva uns 3 minutos.
- `godot --headless --path . -- --mata` pula direto para a mata (cidade vencida, com Granulado e Pipoqueira) e confere 19 pontos (com o portão do cemitério abrindo e a seta da ponte): Golem de Ossos na segunda onda da Clareira (16 de vida, a pancada solta onda); Torre de Ossinhos com 5 andares, tiro na cabeça do andar de baixo, andar vencido indo de balão e os de cima descendo, bolha do de cima, pulo com onda quando sobram 2, coração de recompensa (vida máxima 6); Minionzão com a faixa da investida, acerto de quem fica no caminho, tonto com dano em dobro; cúpula caindo, 100 moedas da mata comprando o Pé-de-Moleque e chegar ao cemitério começando a defesa final. Termina com "MATA OK". Leva uns 2 minutos.
- `godot --path . -- --historia-captura` tira 12 fotos da história (`h01` a `h12`).
- `godot --headless --path . -- --cemiterio` parte do atalho com a cúpula caída e confere 15 pontos: defesa ativa, entrar no cemitério começa a defesa, Mestre Ossinho na última onda com barra, dois minions chamados, bolha, tiro na cabeça, escudo de 6 bolhas, golpe bloqueado com escudo, tiro que estoura bolha do escudo, tonto com dano em dobro, escudo some na fase 3, bolha gigante que vira três, senta e tira a coroa sem balão, defesa vencida começando o desfecho em cena. Termina com "CEMITERIO OK".
- `godot --headless --path . -- --final` vence a defesa final e confere 12 pontos do fim: desfecho com câmera de cena, sem controle e sem interface; esqueletos saindo do chão; noite seguinte na praça; foto do desfecho; 13 convidados chegando de balão; esqueletos da ilha viram amigos; todos pousam e a interface volta; Mestre sem coroa no banco com o vovô; foto da festa e objetivo no palco; subir no palco abre os créditos; pós-jogo de dia com lanternas de festa e a brincadeira na praia. Termina com "FINAL OK".
- `godot --headless --path . -- --festa-sem-fim` pula para o pós-jogo e confere 7 pontos da Festa sem fim: no cemitério com o Mestre e 8 rachaduras, o círculo começa a onda 1 com esqueletos de verdade, onda vencida dá moedas, recorde, munição e coração, onda 2 maior com Rogue, guardião na onda 5, tonto acaba com recorde e dá para recomeçar. Termina com "FESTA-SEM-FIM OK".
- `godot --headless --path . -- --atividades` confere 26 pontos das atividades extras: barcos; 5 karts vazios nas vagas, cada um de uma cor; aviso para dirigir perto de um; B / E entra e já dirige com o aventureiro da cintura para cima no banco; a câmera gira e volta; sai da vaga; entrar pela LARGADA começa a corrida; três voltas com recorde e moedas; descer na pista leva o aventureiro para fora e o carrinho para a vaga; entrar em outro carrinho; descer pela ilha deixa o carro lá; a 30 m ele fica e a mais de 50 m volta; cair no mar; pista de skate perto da cidade; aviso para pegar o skate; pegar; o pé desce até o chão no impulso e o skate anda; câmera livre no skate; marca SESSÃO; half-pipe; pontos; tombo; fim da sessão; descer deixa o skate no chão; longe, volta para a pista. Termina com "ATIVIDADES OK". `godot --path . -- --veiculos-captura` tira as vagas vazias e karts com a menina e com o menino no banco (`v01` a `v07`) e 8 quadros do impulso no skate de lado (`v10` a `v17`). Antes desses pontos, a primeira versão desta lista checava: B / E entra na largada com a câmera do kart; acelera para o norte; a mureta segura; três voltas pelas marcas dão tempo, recorde e moedas; B / E sai e volta no box; B / E sobe no skate e começa a sessão; no half-pipe o skate sobe a rampa e volta; giro 360 vale pontos; tombo não vale; fim da sessão com recorde e moedas; B / E desce. Termina com "ATIVIDADES OK". `godot --path . -- --atividades-captura` tira as fotos `a01` a `a13` (pista de kart de cima, largada e curva, pista de skate de cima, de lado e o half-pipe, barcos no cais, os 3 navios, o kart andando e na curva, o aviso do skate, o skate no ar e no half-pipe, a pista de skate com a cidade e a fazenda nova). `godot --path . -- --mapa-captura` tira a ilha inteira de cima com marcas a cada 50 m.
- `godot --headless --path . -- --loja` confere 14 pontos da lojinha: sem seta antes da primeira moeda, contador e seta dourada depois, tapete abre o menu e apaga a seta, sem moedas não compra, comprar a Jujuba (desconta, equipa e vai para a mão), usar a Paçoca de volta, o Granulado da história também se compra, +1 Brigadeiro, melhoria não se compra duas vezes, prévia com o blaster girando, tipo, dano e barras, voltar da prévia, Jujuba atirando, caixa de munição com o blaster comprado, o que vai para o salvamento. Termina com "LOJA OK". `godot --path . -- --loja-captura` tira 8 fotos (`l01` a `l08`: barraca, seta, cartões, prévias do Granulado e do Bombom, compra, cartões depois e o Granulado na mão).
- `godot --headless --path . -- --salvar` confere 8 pontos da campanha salva, recarregando a cena entre as fases: começar salva o prólogo; vencer a praia salva etapa, defesa, personagem e bandeira; menu inicial com Continuar; continuar na cidade com blasters, corações e recordes; Nova campanha na pausa com confirmação apagando tudo; continuar uma campanha salva na festa. Termina com "SALVAR OK".
- `godot --path . -- --banda-captura` tira 6 fotos da banda tocando (`b01` a `b06`, com um esqueleto de trompete do epílogo junto); `godot --path . -- --pirulito-captura` tira 3 do golpe do Pirulitão (`g01` a `g03`); `godot --path . --resolution 2400x900 -s res://tools/foto_musicos.gd` monta a folha de encaixe dos instrumentos.
- `godot --path . -- --final-captura` tira 14 fotos do fim (`f01_desfecho_convite` a `f14_festa_sem_fim_onda`, nomes diferentes dos da `--festa-captura`): convite, amigos do cemitério, "Na noite seguinte...", chegada na festa, praça à noite, palco com o esqueleto do trompete, Mestre e vovô, Torre, Mira-Torta, fogos e lua, álbum nos créditos, pós-jogo e a Festa sem fim (parada e com uma onda).
- `godot --path . -- --cemiterio-captura` tira 7 fotos da defesa final (`c01` a `c07`), com a câmera livre.
- `godot --path . -- --paisagem-captura` tira 27 fotos da paisagem sem interface (`p01` a `p28`), incluindo cais, pescador, pasto, veados, raposa, peixes e cachorro; cemitério de cima, cripta, túmulos, ponte de lado e de cima, mata da Clareira e dos Ventos, morrinhos do rio, cerejeiras da praça, praia do cais, cais de madeira, lenhador, Morro dos Ventos, portão fechado e aberto, pasto.
- `godot --headless --path . -- --extras` confere 16 pontos das diversões: bichos soltos passeando, peixes nadando, veado fugindo do aventureiro, andar pelo cais até a ponta; barraca com 4 alvos, boneco e placar; tiro de verdade no alvo marca ponto e derruba; o alvo volta; boneco mostra o dano; os 7 moradores novos; Guerreiro Planta aparece ao entrar no Bosque das Copas; escudo segura o corpo pela frente e a cabeça passa; leque de 3 flechas; sem escudo depois da investida; vencido aplaude e fica; +1 coração sem mexer na história. Termina com "EXTRAS OK".
- `godot --path . -- --extras-captura` tira 11 fotos (`x01` a `x12`, sem a `x09`): barraca de tiro, bruxa, banda com o urso, fantasiados, lenhador, pescador, Bosque das Copas, Guerreiro Planta.
- `godot --path . -- --festa-captura` tira 9 fotos da festa e dos moradores sem a interface (`f01` a `f08`, mais `f03b` da plateia do palhaço): praça, palco, palhaço, barraca, mesas, vovô falando, motorista na calçada e trilheiro.
- `godot --path . -- --mata-captura` tira 8 fotos da mata (`m00a`/`m00b`: Golem chegando e batendo no chão; `m01` a `m06`: Torre, andar indo de balão, faixa do Minionzão, Minionzão tonto, cúpula caindo, chegada ao cemitério).
- `godot --path . -- --ilha-captura` tira 8 fotos jogando na ilha (praça, esqueleto dormindo e acordando, trilha do Morro, cemitério, ponte, clareira, tchibum).
- `godot --headless --path . -- --armas` confere 27 pontos dos blasters: pente, recarga automática e com R, não atirar recarregando, troca com modelo novo na mão, estoque, sem munição, caixa (e caixa que fica no chão), escopeta, luneta, granada, caixa que cai com munição no fim, mira e cabeça firmes, coice, e o Pirulitão (aparece na mão, tira 3 de quem está na frente, espera entre golpes, devolve o blaster, estoura bolha); termina com "ARMAS OK". O teste de controle também confere X (recarregar), Y (trocar de blaster) e RB (granada), e o da ilha confere as 10 caixas.
- Os testes `--smoke`, `--controle`, `--combate`, `--som`, `--armas` e `--capture` rodam na **arena plana** (o mapa antigo, previsível), com esqueletos já acordados; o jogo normal e os modos `--ilha` abrem a ilha.
- Os modos `--smoke`, `--controle` e `--capture` ligam `god_mode` no jogador, para o tonto não travar o teste.
- Para rodar os testes, use um limite de tempo (`perl -e 'alarm 200; exec @ARGV' godot ...`): se um script tiver erro de digitação, a Godot fica parada em vez de sair.
- `godot --path . -- --capture` abre a janela, roda uma sequência e salva capturas em `tools/capturas/` (fora do git).

**Build para Linux e a Steam do PC com Bazzite** (feito em 2026-10-25):

- Os modelos de exportação da Godot 4.7.2 ficam em `~/Library/Application Support/Godot/export_templates/4.7.2.stable/` (pacote oficial `Godot_v4.7.2-stable_export_templates.tpz`, 1,28 GB, conferido pelo SHA-512 publicado). A predefinição "Linux" está em `export_presets.cfg`: x86_64, um executável só com o jogo embutido, sem `tools/` e `docs/`.
- `godot --headless --path . --export-release "Linux" build/linux/IlhaCafune.x86_64` gera o executável (uns 85 MB). `build/` tem `.gdignore`, para a Godot não importar o que sai ali.
- No PC (Bazzite, `bazzite.local`, usuário `usario`, SSH ligado com `ujust toggle-ssh` e a chave do Mac autorizada), o jogo fica em `~/Games/IlhaCafune/`, com `ilha-cafune.desktop` e `icone.png`. Ele entrou na Steam como jogo de fora da loja pelo `steamos-add-to-steam` do próprio Bazzite, rodando com o ambiente da sessão gráfica (`DISPLAY=:0`, `WAYLAND_DISPLAY=wayland-0`, `XDG_RUNTIME_DIR=/run/user/1000`); o nome vem do `.desktop`. Roda nativo, sem Proton. Para atualizar, basta copiar o executável novo por cima.
- **Regra do usuário (2026-10-26):** não refazer nem reenviar as imagens da Steam ou de apresentação (capas, fundo da página, logo, ícone e fotos de divulgação) quando o jogo mudar. Só quando ele pedir.
- **Arte da Steam:** `godot --path . -- --arte-steam` monta uma cena posada na campina ao pé do Morro (os dois aventureiros, esqueletos descendo e outros indo de balão, castelinho sem cúpula ao fundo; a arte que está na Steam ainda mostra o castelinho antigo, e só é refeita quando o usuário pedir) e fotografa sem interface, com câmeras em SubViewport, em `build/arte_steam/`. Depois `python3 tools/arte_steam.py` faz o logo (Arial Rounded Bold, contorno roxo, três balões) e as capas em `build/arte_steam/steam/`. Na Steam, a arte de um atalho vai em `userdata/<conta>/config/grid/` com o appid do atalho: `<appid>p.png` (capa vertical 600 x 900), `<appid>.png` (horizontal 920 x 430), `<appid>_hero.png` (fundo 3840 x 1240) e `<appid>_logo.png`.

**Controles.** A tela de jogo não mostra mais a lista de comandos nem o nome do personagem (pedido do usuário): os comandos ficam em Pausa > Comandos, e trocam sozinhos conforme o aparelho em uso. Com um menu aberto o jogo fica pausado.

| Ação | Teclado e mouse | Controle (Xbox / PlayStation) |
|---|---|---|
| Andar | WASD ou setas | analógico esquerdo |
| Correr | Shift (segurando) | L3 (liga; desliga ao parar de andar ou mirar) |
| Olhar | mouse | analógico direito |
| Pular | espaço | A / X |
| Mirar | botão direito | LT ou LB / L2 ou L1 |
| Atirar | botão esquerdo | RT / R2 |
| Recarregar | R | X / quadrado |
| Granada | G | RB / R1 |
| Pirulitão (corpo a corpo) | F ou botão do meio | R3 / R3 (apertar o analógico direito) |
| Entrar e sair do kart ou do skate | E | B / círculo |
| Escolher blaster | 1 Paçoca, 2 Granulado, 3 Pipoqueira, 4 Pé-de-Moleque (ou rodinha do mouse) | direcional: ↑ Paçoca, → Granulado, ↓ Pipoqueira, ← Pé-de-Moleque (Y passa para o próximo) |
| Pausa (continuar, trocar de personagem, comandos, sair) | Esc ou Tab | Start / Options |
| Confirmar e voltar no menu | Enter e Esc | A e B / X e círculo |
| Regiões de impacto | F3 | Back / Share |

**Auxílio de mira (só no controle e mirando):** um alvo a até 7° do centro da mira freia o giro do analógico pela metade e puxa a mira de leve para o corpo do esqueleto. Logo que aperta o gatilho de mira o puxão é mais forte por 0,25 s. A cabeça (dano em dobro) fica por conta de quem mira. Os valores ficam no grupo "Controle" do `player.gd` (`aim_assist_angle_deg`, `aim_assist_pull`, `aim_assist_snap`, `stick_speed`). A vibração é curta no tiro e mais forte no acerto.

**Detalhe da Godot 4.7:** as ações de menu `ui_accept` e `ui_cancel` não vêm ligadas aos botões A e B do controle; o `main.gd` liga.

**Código** (`scripts/`):

| Arquivo | O que faz |
|---|---|
| `main.gd` | abre a ilha (lendo os marcadores) ou, nos testes, a arena plana; cria jogador, esqueletos e bandeiras; interface (corações, clarão de golpe, escurecer do tonto); tchibum na água; queda de coração e os modos de teste |
| `player.gd` | câmera no ombro com SpringArm3D, movimento, `AnimationTree` (locomoção 2D, chão/ar, mira e tiro só no tronco, golpe recebido, normal/tonto), blaster no `handslot.r`, tiro por raio a partir do centro da tela, corações, invulnerabilidade piscando, empurrão, estrelinhas e volta na bandeira |
| `skeleton_enemy.gd` | tipos em `TYPES` (distância, aviso, intervalo, armas); perseguir, preparar com "!", golpear ou disparar, esperar, levar golpe, ir embora de balão e comemorar; escudo do Warrior; regiões de impacto em `BoneAttachment3D` |
| `projectile.gd` | flecha de ventosa e bolha mágica (que também é alvo) |
| `checkpoint.gd` | bandeira de ponto de retorno (ativa num raio de 4 m) |
| `heart_pickup.gd` | coração que devolve vida |
| `hurtbox.gd` | região de impacto (Area3D na camada 4) com multiplicador de dano |
| `sfx.gd` | toca efeitos (2D para o aventureiro e a interface, 3D com posição para esqueletos, flechas e bolhas) e a música em loop; cria os canais de áudio "Musica" (−9 dB) e "Efeitos" |
| `anim_util.gd` | carrega as bibliotecas de animação do KayKit (esqueleto médio e, para o Golem, o grande) e marca as que repetem |
| `townsperson.gd` | morador: atividade, aceno, balão de fala, torcida nas ondas e comemoração; instrumentos da banda (`INSTRUMENTS`) |
| `musician_motion.gd` | movimento de tocar trompete ou violão por cima da pose (gira ossos em eixos do modelo) |
| `shooting_gallery.gd` | barraca de tiro ao alvo (alvos e boneco de treino) |
| `boss_planta.gd` | o Guerreiro Planta, desafio opcional do Bosque das Copas |
| `fx.gd` | confete, poeira, rastro do tiro, clarão, onda da granada, texto flutuante e saída de balão (`balloon_away`, usada pelos esqueletos e pelos andares da Torre) |
| `endless_party.gd` | a Festa sem fim do pós-jogo (ondas que crescem, guardião a cada 5, moedas e recorde) |
| `shop.gd`, `shop_menu.gd` | a Lojinha de Blasters (barraca, tapete, vendedor) e o menu de compras |
| `ending.gd`, `credits.gd`, `save_game.gd` | desfecho, festa à noite e pós-jogo; créditos com o álbum; campanha salva |
| `weapon_hud.gd` | painel de armas inclinado (arma atual, cartões dos outros blasters ganhos com o botão do direcional ou a tecla, granadas, recarga) |
| `story.gd` | a história: regiões e ondas (`REGIONS`), lanternas, cúpula, portão do cemitério, recompensas, região em festa, objetivo atual |
| `defense.gd` | uma defesa em ondas: círculo, rachaduras, ondas, intervalo, cancelar e recomeçar, guardião na última onda |
| `boss.gd` | base dos guardiões: chegada pela rachadura, vida, aviso, onda de choque, círculos de perigo, saída de balão gigante |
| `boss_ossao.gd`, `boss_mira_torta.gd` | os guardiões da cidade |
| `boss_torre.gd`, `boss_minionzao.gd` | os guardiões da mata (a Torre tem vida por andar; o Minionzão tem investida e fica tonto) |
| `boss_mestre.gd` | o Mestre Ossinho: três fases, escudo de bolhas (`ShieldBubble`), bolha gigante que se divide (`GiantBubble`) e o desfecho sentado sem a coroa |
| `reward_pickup.gd` | recompensa de região (blaster novo ou +1 coração) |
| `boss_bar.gd`, `objective_marker.gd` | barra de vida do guardião e losango do objetivo |
| `weapons.gd` | os 4 blasters, a granada e o Pirulitão (pente, estoque, recarga, dano, espalhamento, luneta, modelo e encaixe) e o que a caixa de munição devolve |
| `grenade.gd` | granada Brigadeiro: arco, quique, explosão em área |
| `ammo_pickup.gd` | caixa de munição (fixa com retorno ou caída de esqueleto) |

`tools/weapon_axes.gd` mostra para onde aponta o osso da mão na pose de mira (o eixo X dele é a frente). No Blaster Kit o cano fica na ponta −Z de todos os modelos (`tools/foto_blasters_pontas.gd` mostra as pontas), então a rotação no osso é (0, −90, 0); `tools/foto_blasters.gd` mostra cada blaster de lado com a boca (amarelo) e o cabo (azul). `tools/inspect.gd` imprime a hierarquia importada.

**Som:** todos os sons são gerados por `tools/gerar_sons.py` (só biblioteca padrão do Python, 2,5 s para gerar tudo): `python3 tools/gerar_sons.py` reescreve `assets/audio/sfx/*.wav` e `assets/audio/musica/tema.wav`, e a Godot reimporta sozinha. São sons de desenho animado, sem estampido realista:

| Evento | Som |
|---|---|
| tiro do blaster | `tiro` ("piu" descendo) |
| acerto no corpo / na cabeça | `acerto` ("tic") / `acerto_cabeca` ("dim-dim") |
| esqueleto vai embora de balão / acorda do chão | `balao` (borracha enchendo e "tu-ru" de despedida) / `remontar` (toc-toc acelerando e "plim") |
| aviso "!" antes do golpe | `alerta` (baixinho, porque toca muito) |
| golpe de perto / flecha / bolha | `golpe_ar` ("fuuu") / `flecha` ("fiu") / `bolha` ("blub") |
| flecha batendo / bolha estourando | `ventosa` ("ploc") / `estouro` ("pop") |
| escudo bloqueando | `escudo` ("clang") |
| aventureiro leva golpe / fica tonto / reaparece | `bonk` / `tonto` (apito descendo e passarinhos) / `reaparecer` |
| bandeira ativada / coração recolhido / pulo | `bandeira` (dó-mi-sol-dó) / `coracao` / `pulo` |
| caiu na água | `splash` ("tchibum" com gotinhas) |
| Granulado / Pipoqueira / Pé-de-Moleque | `granulado` ("pi" curto) / `pipoqueira` (pipoca estourando) / `pe_de_moleque` ("vuuum" grave) |
| recarga / sem munição / troca de blaster | `recarga` ("clic-clac") / `sem_municao` ("tic") / `troca_arma` |
| arremesso / granada explodindo / caixa de munição | `arremesso` / `granada` ("pof" com brilho de confete) / `municao` (tilintar) |
| menu | `ui_mover` / `ui_ok` |
| música | `tema`: 8 compassos em dó maior a 112 bpm, 17 s, emendando sem corte |

Se quiser sons gravados em vez de sintetizados, os pacotes de áudio grátis (CC0) do Kenney servem; é só trocar os WAV mantendo os nomes.

**Ainda não tem:** ajuste de volume pelo jogador, exportação para `.exe` e otimização para computador fraco (a ilha tem centenas de árvores e milhares de tufos de grama; no Mac M4 roda leve, mas não foi medido em outra máquina). O aventureiro, os esqueletos e a interface ainda são montados por código; só a ilha é cena editável. O controle foi testado com controle físico no Mac (vibração aprovada); o ciclo de combate, o som e os blasters ainda só foram testados pelos testes automáticos e capturas (o som não foi ouvido por ninguém ainda).

### Atividades extras (2026-10-26, pedido do usuário)

Feitas com os pacotes do Kenney (Car Kit, City Kit Roads, Mini Skate e Watercraft Kit, todos CC0). Kart e skate usam o botão novo **interagir**: B no controle, E no teclado (entra e sai). Os dois dão moedas para a lojinha.

**Ajuste depois do primeiro teste do usuário (2026-10-26, "não consegui correr nos karts nem andar de skate"):** o B só funcionava em cima do tapete dourado (a uns 8 m dos karts estacionados) e só na entrada do skate, e o único aviso era uma placa no ar. Agora o B funciona a até 15 m do box (karts estacionados incluídos) ou em cima da pista de kart, e na entrada ou em qualquer lugar dentro da pista de skate; aparece um aviso fixo embaixo na tela ("Aperte B para correr de kart" / "Aperte E ..." no teclado) e as placas "PISTA DE KART" e "PISTA DE SKATE" ficaram maiores, mais altas e visíveis a até 120 m. A pista de skate foi para perto da cidade (pedido do usuário) e a fazenda foi para o lugar dela.

- **Barcos no mar** (`scripts/sea_traffic.gd`, sem colisão, é paisagem): 10 barcos ancorados perto da costa (pesqueiros, a remo, veleiros, rebocador, lancha), balançando na água; 6 têm um pescador de vara. Boias perto do cais. Três navios (galeão, transatlântico e cargueiro) dão a volta na ilha bem devagar, a uns 450 m, no horizonte.
- **Pista de kart** (gerada por `tools/gerar_ilha.gd`, na campina a leste do Morro, centro (125, 15)): oval de 48 x 80 m (uns 200 m por volta) com peças de estrada de 8 m; o pedaço com mureta do City Kit Roads é só a mureta, então cada pedaço leva o asfalto e a mureta por cima, com colisão no formato da peça. O pedaço 6 da reta oeste, de frente para o box, não tem a mureta de fora (a peça do pacote traz as duas muretas juntas, então ali vai só o asfalto e uma mureta de dentro feita à parte): é a **entrada da pista**, com faixa dourada e a placa "LARGADA". Arco quadriculado de chegada logo ao norte, postes de luz, cones nas curvas e o box ao lado com 5 vagas (marcadores `Diversao/Vagas`), pneus e caixa. A área fica sem árvores, pedras e grama (tiradas depois do sorteio, então o resto da ilha não muda).
- **Veículos do box** (`scripts/kart.gd`, `scripts/kart_race.gd`; refeitos depois do segundo teste do usuário): cinco karts, estacionados **vazios** nas vagas (o piloto alienígena do kart é uma malha separada, escondida): Morango (vermelho), Mirtilo (azul), Hortelã (verde), Uva (roxo) e Limão (amarelo). São o mesmo modelo pintado (cor multiplicando a textura da carroceria), todos a 17 m/s. Os dois carros de corrida do pacote (o Fórmula `race` e o Foguete `race-future`) entraram e saíram: o usuário preferiu só karts. Chegar a 3,4 m de um e apertar B / E **entra e já sai dirigindo** de onde ele está. **O aventureiro aparece no banco da cintura para cima** (uma cópia do modelo dele com pernas e mochila escondidas, na pose `Holding_A`, de quem segura o volante, com o respirar dela; a cintura fica na altura do banco). Tentativas que não agradaram: só a cabeça (num esqueleto parado na pose de T, com falhas e parecendo flutuar) e um capacete montado por código. As rodas giram com a velocidade e as da frente esterçam; o corpo inclina nas curvas. Frente / RT acelera, trás / LT freia e dá ré, esquerda e direita viram. Bater de frente em parede perde velocidade e faz "bonk". Dá para passear pela ilha inteira (as defesas não começam com o aventureiro dentro do veículo, e ele não leva golpe).
- **Câmera** (pedido do usuário): no veículo e no skate, o analógico direito (ou o mouse) gira a câmera em volta; 1,5 s depois de soltar, ela volta devagar para trás.
- **Corrida**: entrar na pista pela LARGADA, vindo de fora, põe o veículo na largada (logo ao sul do arco, virado para o norte), com contagem 3, 2, 1, "Já!" e **3 voltas contra o relógio**; cada volta só conta passando pelas 3 marcas do meio das retas (sem atalho), e a chegada é no arco. Na chegada: tempo, recorde (salvo) e **15 moedas, mais 10 com recorde novo**; depois continua dirigindo (andar na pista não começa outra corrida; para correr de novo, sair e entrar pela LARGADA). Descer no meio da corrida cancela.
- **Descer** (B / E): **dentro da pista**, o aventureiro vai para fora dela (no box) e o veículo volta para a vaga; **pela ilha**, o veículo fica onde parou, o aventureiro desce do lado, e o veículo **volta sozinho para a vaga quando o aventureiro se afasta 50 m** (com confete). Cair no mar com o veículo: ele volta para a vaga e o aventureiro faz o "tchibum" de sempre.
- A colisão do veículo é uma cápsula deitada (uma caixa enganchava nas emendas das peças). Estacionado, ele fica na camada do mundo (o aventureiro esbarra); dirigindo, bate em parede, mureta, outros veículos e moradores.
- **Pista de skate** (gerada, ao lado da cidade, a noroeste, centro (−98, 66), uns 40 m da esquina da cidade, com a entrada virada para as ruas; antes ficava na campina a oeste do Morro, onde agora está a fazenda): 40 x 40 m de concreto com cerca e entrada no sul, half-pipe de 4 m de altura e 20 m de comprimento (dois quarter-pipes de frente), duas rampas de pulo, caixote, corrimão, escada com corrimão e uma rampa longa; bancos do lado de fora. Peças de 1 m do Mini Skate ampliadas 5x, com colisão no formato delas.
- **Skate** (`Player.start_skating`, `scripts/skate_park.gd`, `scripts/skate_rider.gd`; refeito depois do segundo teste do usuário): o skate fica no chão na entrada da pista. Chegar perto (ou estar dentro da pista com ele lá) e apertar B / E **pega o skate** (some do chão e aparece debaixo dos pés) e **dá para andar pela ilha inteira**. Descer (B / E) deixa o skate no chão onde parou; **longe dele (50 m), ele volta para a entrada da pista** (com confete). Cair no mar ou ficar tonto também manda o skate de volta. Andar para a frente dá impulso, para trás freia, esquerda e direita viram; a ladeira puxa (no half-pipe vai e volta sozinho), rampas de até 76° viram chão e o aventureiro inclina junto com a rampa. Pular (A / espaço) faz o ollie; no ar, esquerda e direita giram. Saindo pela borda do half-pipe, sobe reto e volta para a rampa. Pousar atravessado é tombo ("Caiu!").
- **Perna empurrando** (pedido do usuário; o KayKit não tem animação de skate): `SkateRider`, um `SkeletonModifier3D` por cima da animação parada. Os quadris baixam (joelhos dobrados), o pé esquerdo fica firme na tábua e, ao dar impulso, o direito desce para o chão ao lado do skate, arrasta para trás e volta para a tábua (ciclo de 0,75 s); os pés são encaixados com conta de perna de duas partes (coxa e canela), joelho dobrando para a frente, e ficam retos. O skate só ganha velocidade enquanto o pé está no chão: uns 4 empurrões até a velocidade máxima, e perdendo um pouco de embalo ele empurra de novo. No ar, os dois pés ficam na tábua e o corpo encolhe. (O modificador aplica a pose e depois a desfaz; quem quiser medir o pé de fora usa `SkateRider.right_foot_drop`.)
- **Sessão de pontos**: passar de skate pela marca dourada "SESSÃO" dentro da pista começa **60 s** em que cada pulo pousado vale 200 pontos por segundo no ar mais 100 por meia volta ("Giro 360" = 400 com 1 s no ar); sair de perto da pista cancela. No fim, recorde salvo e **1 moeda a cada 100 pontos (até 25)**, e continua no skate. A mira e o painel de armas somem enquanto se anda.

## 10. Decisões em aberto


- **Título:** "Ilha Cafuné" é provisório.
- **Nomes do menino e da menina:** ainda por decidir.
- **Habilidades por classe:** na primeira versão a escolha é só visual.
- **Animação de tiro:** resolvida no papel, pelo KayKit Character Animations; falta baixar e conferir na Godot.
