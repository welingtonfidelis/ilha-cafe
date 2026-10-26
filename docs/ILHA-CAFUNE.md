# Ilha Cafuné — documentação única

Versão do documento: 2026-10-25 (elenco trocado para o KayKit)
Jogo: **Ilha Cafuné** (título provisório): tiro em terceira pessoa infantil, num mundo aberto pequeno.
Motor: Godot 4.7 (3D), com exportação para Windows (`.exe`) e macOS.
Arte: **só pacotes prontos e CC0**, quase tudo do KayKit (Kay Lousberg). Os blasters vêm do Kenney, porque o KayKit não tem armas de fogo. Lista completa na seção 8.

**Estado atual: história completa até o Mestre Ossinho, com festa e moradores (2026-10-26).** Projeto Godot 4.7.2 na raiz desta pasta, versionado em git (branch `main`, publicado em github.com/welingtonfidelis/ilha-cafe, público). Pedidos do usuário em 2026-10-26 depois de testar: luta do prólogo na praia do cais, cais de madeira, cavalos, correr (Shift / L3), lenhador partindo tronco, bandeira com raio maior, chefes mais difíceis (menos o Mestre Ossinho, que estava bom), Morro dos Ventos com topo plano e o portão do cemitério que abre. O jogo abre na ilha de verdade (`scenes/ilha.tscn`, seção 3.1). Já dá para jogar o prólogo na praça, as duas defesas da cidade (Ossão e Mira-Torta), atravessar a ponte e as duas da mata (Torre de Ossinhos e Minionzão), ganhando o Granulado, a Pipoqueira, +1 coração e o Pé-de-Moleque, até a cúpula do cemitério cair. A praça tem a festa montada (palco com banda e o urso do violão, mesas de comida e doces, presentes, barraca dos fazendeiros, barraca de poções da bruxa, barraca de tiro ao alvo e o cantinho do palhaço) e 22 moradores na festa e pela ilha (inclusive lenhador e pescador) que falam, torcem nas ondas e comemoram; cada região vencida ganha convidados e uma mesa de festa. O Golem de Ossos aparece nas ondas da mata, e o Bosque das Copas tem o desafio opcional do Guerreiro Planta. Com a cúpula caída, a defesa final no meio do cemitério do Morro traz 3 ondas e o Mestre Ossinho (o Necromancer do KayKit) em três fases; derrotado, ele senta, tira a coroa e as crianças entregam o convite. Faltam o epílogo na praça e o modo "Defender a festa". Aventureiro escolhível, câmera em terceira pessoa, 4 blasters com pente, recarga e estoque limitado, granada e caixas de munição, controle com auxílio de mira; esqueletos com armas que atacam cada um do seu jeito, vida em corações, tonto com estrelinhas, pontos de retorno e coração que cai (modelos do Platformer Pack); 30 efeitos sonoros e música de fundo gerados por síntese. Pacotes brutos em `vendor/` (fora do git e com `.gdignore`), só os arquivos usados copiados para `assets/`. Como rodar e o que falta: seção 9.1.

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
- **Gênero:** tiro em terceira pessoa com defesa em ondas por região e exploração. Depois da história, o modo "Defender a festa" (ondas sem fim na praça, com recorde).
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
| Cais | sai da praça para o mar (z 206 a 254) | de madeira: piso de tábuas do Dungeon Pack (`floor_wood_large`), corrimão de cerca de madeira do Medieval Hexagon nas duas beiras (a cerca do pacote fica 1 m fora da origem, porque é a borda de um hexágono: `FENCE_OFFSET`) e toras fincadas na água; colisão por uma caixa invisível. Na ponta, atravessado, o cais do Medieval Hexagon (`building_docks_blue` 4x: tábuas sobre estacas, corrimão para o mar, barril, caixote e bandeira azul), pedido do usuário. O pescador fica nele: a linha da vara (`fishing_rod_line`, com a boia e o anzol) é esticada até a água, a boia balança na superfície e o anzol fica embaixo |
| Praia do Cais | a oeste do cais (−30, 212) | areia aberta, sem enfeites: é onde acontece a defesa do prólogo (pedido do usuário: na praça, com a festa, a luta ficava confusa) |
| Pasto | a oeste da cidade (−104, 52), raio 11 m | cerca de madeira com porteira e 4 cavalos pastando (`scripts/horse.gd`; os cavalos do Medieval Hexagon são peças inteiras, sem esqueleto: pastar é inclinar o corpo e virar devagar). São os únicos animais da coleção (não há peixes nem pássaros) |
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
| Barreira da ponte | cabeceira sul da ponte | parede roxa translúcida com colisão; some quando as duas lanternas da cidade apagam |
| Cúpula do cemitério | topo do Morro, raio 25,5 m (cobre o topo inteiro) | some quando as quatro lanternas apagam; a bandeira TopoDoMorro fica na trilha logo antes do portão, do lado de fora |

**Marcadores editáveis** (`Marcadores` dentro da ilha): `Inicio` (onde o aventureiro começa e para onde olha), `PontosDeRetorno` (8 bandeiras: Praca, PeDoMorro, TopoDoMorro, EntradaDaMata, Clareira, MorroDosVentos, CidadeOeste, CidadeLeste; a primeira começa ativa), `Esqueletos` (14 soltos entre as regiões, cada um com o tipo na metadata `tipo`), `Municao` (10 caixas), `Regioes` (centro de cada defesa, com o raio na metadata `raio` e as 4 rachaduras como filhos) e `Moradores` (15, com `modelo`, `atividade`, `variante`, `item`, `falas`, `destino` e `altura` nos metadados; a rotação do marcador é para onde o morador olha). A festa fica em `Cidade/Praca/Festa`. Mover um marcador no editor muda o jogo, sem mexer em código.

**Esqueletos na ilha:** começam dormindo como pilha de ossos e se montam quando o aventureiro chega a 16 m (golpe de perto) ou 22 m (quem atira). Se o aventureiro se afasta mais de 45 m da casa deles, voltam para casa e deitam de novo. Derrotados, vão embora de balão e não voltam. Os das ondas saem das rachaduras (animação de sair do chão, 1,6x mais rápida) e perseguem o aventureiro por toda a região; se a onda é cancelada, afundam de volta.

**Regerar a ilha** (`godot --headless --path . -s res://tools/gerar_ilha.gd`) sobrescreve `scenes/ilha.tscn` e o terreno em `assets/terrain/`. Depois de mexer na ilha pelo editor, faça commit antes de regerar. `tools/foto_ilha.gd` tira fotos da ilha de cima e de alguns pontos, para conferir sem abrir o editor.

## 4. História

Estrutura escolhida pelo usuário em 2026-10-25 (opção C): a história é feita de **defesas em ondas por região**, com a ilha aberta entre elas; depois do final, abre o modo **"Defender a festa"**, de ondas sem fim.

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

| Região | Onda 1 | Onda 2 | Onda 3 | Guardião | Recompensa |
|---|---|---|---|---|---|
| Lanterna Oeste (perto da caixa-d'água) | 5 Minions | 4 Minions, 2 Warriors | 4 Minions, 1 Warrior | Ossão | blaster Granulado |
| Lanterna Leste | 4 Minions, 1 Rogue | 3 Minions, 3 Rogues | 3 Minions, 2 Rogues | Mira-Torta | blaster Pipoqueira |

Fecho do ato: com as duas apagadas, a barreira roxa da ponte some e a mata se abre.

### Ato 2: Mata (em qualquer ordem)

| Região | Onda 1 | Onda 2 | Onda 3 | Guardião | Recompensa |
|---|---|---|---|---|---|
| Clareira da Jabuticabeira | 4 Minions, 1 Mage | 1 Golem, 2 Minions, 2 Mages, 1 Rogue | 2 Mages | Torre de Ossinhos | +1 coração máximo |
| Morro dos Ventos | 5 Minions, 1 Warrior | 1 Golem, 1 Warrior, 2 Rogues, 1 Mage | 3 Minions | Minionzão | blaster Pé-de-Moleque |

Fecho do ato: com as quatro apagadas, a cúpula roxa do cemitério cai. Num bilhete deixado na última lanterna, um dos esqueletos escreveu que só queria dançar na festa.

### Ato 3: O cemitério do Morro

- Subida do Morro pela trilha em espiral.
- **Defesa final no cemitério:** 3 ondas com todos os tipos de esqueleto.
- **Chefe final: Mestre Ossinho**, esqueleto mago de coroa. Três fases: chama minions pelas rachaduras, se protege com bolhas mágicas que precisam ser estouradas, e por fim lança bolhas gigantes que se dividem.
- **Desfecho:** o Mestre Ossinho não vai de balão: senta no chão, tira a coroa e confessa que só queria ir à festa. As crianças entregam o convite.
- **No jogo (2026-10-26):** a defesa `cemiterio` fica no gramado do meio do cemitério (centro entre o portão e a cripta, raio 18, rachaduras nas diagonais a 10 m) e liga quando a cúpula cai. Antes era no pátio do castelinho, pequeno demais; o usuário pediu o cemitério com espaço amplo. Ondas: 4 Minions, 1 Rogue e 1 Mage; 2 Warriors, 2 Rogues e 2 Minions; 1 Golem, 1 Mage e o Mestre Ossinho. Vencida, aparecem as faixas "O Mestre Ossinho tirou a coroa..." e "Vocês entregaram o convite!", os moradores comemoram e o objetivo vira "Explore a ilha à vontade!". O epílogo na praça ainda não foi feito.

### Epílogo: a Festa do Cafuné

Todos os esqueletos que foram de balão voltam descendo de balão na praça, agora como convidados: tocam na banda (xilofone de costela), dançam e servem doces. Os créditos passam como um álbum de fotos da festa. Ao fim, abre o modo "Defender a festa".

### Modo "Defender a festa" (depois da história)

- Na praça, com o palco e a decoração. Rachaduras em volta.
- Ondas sem fim, cada vez maiores; a cada 5 ondas vem um guardião (revezando os quatro).
- Todos os blasters liberados; caixas de munição e corações entre as ondas.
- Contador de ondas e recorde salvo no computador.
- Como a partida termina: decisão em aberto (seção 10).

### Mensagem

Não se julga ninguém pela aparência. Às vezes falta só um convite.

## 5. Progressão no mundo aberto

O jogo não tem fases. O progresso aparece no próprio mundo:

- **Raios das lanternas:** quatro raios roxos saem do cemitério do Morro e apontam as regiões que faltam. Apagam um a um.
- **Barreiras:** a barreira da ponte (some depois das duas lanternas da cidade) e a cúpula do cemitério (some depois das quatro).
- **Regiões em festa:** cada região vencida ganha balões e bandeirinhas e fica sem esqueletos.
- **Blasters ganhos aos poucos** (pedido do usuário): Paçoca desde o começo; Granulado (Oeste), Pipoqueira (Leste) e Pé-de-Moleque (Morro dos Ventos). Granadas desde o prólogo. Cada blaster tem sua seta no direcional (↑ Paçoca, → Granulado, ↓ Pipoqueira, ← Pé-de-Moleque) e sua tecla (1 a 4); no painel, cada blaster mostra uma cruzinha do direcional com o braço dele aceso (no controle) ou a tecla (no teclado). Apertar um que ainda não ganhou mostra onde ele é ganho ("Granulado: você ganha ao apagar a Lanterna Oeste"). Os blasters ganhos aparecem no painel como cartões menores conforme são desbloqueados (pedido do usuário).
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
| Banda (2) | Soldadinho de Brinquedo, com trompete | no palco da praça, tocando |
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
| G / RB | Brigadeiro (granada) | `grenade-a` | — | — | começa com 2, máximo 3 | — | arremesso em arco, explode em confete depois de 1,4 s, raio de 5 m, até 3 de dano, o escudo não segura, estoura bolhas |

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
| Mystery Monthly (mais personagens) | KayKit | 1.1, da Coleção Completa v6.1 | ~2 MB | Animatronic, Witch, Superhero, Space Ranger, Caveman, Werewolf (humano) em `assets/characters/moradores/`; Plant Warrior em `assets/characters/guardioes/` com as armas em `assets/weapons/planta/`; boneco de treino do Avian Swordsman |
| Mystery Monthly Series 4, 5 e 6 | KayKit | 1.1, da Coleção Completa v6.1 | 3,3 MB (só os usados) | moradores: Palhaço, Motorista, Fantasia de Monstro (Series 4); Trilheiro (Series 5); Fazendeiros, Soldadinho, Vovô (Lorekeeper), Garota Mágica (Series 6); objetos de mão em `assets/props/moradores/` |
| Skeletons | KayKit | grátis 1.1 | 7,7 MB | inimigos e chefes (baixado) |
| City Builder Bits | KayKit | grátis 1.0 | 4,6 MB | cidade (baixado) |
| Forest Nature Pack | KayKit | grátis 1.0 | 6,1 MB | floresta e Morro (baixado) |
| Blaster Kit | Kenney | 2.1 | 1,7 MB | blasters: 18 modelos (`blaster-a` a `blaster-r`), granadas, miras, alvos e projéteis de espuma (baixado) |
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
- `godot --headless --path . -- --controle` joga só com eventos de controle simulados e confere 21 pontos (escolha inicial, analógicos, L3 correndo, pulo, mira, auxílio de mira, tiro, direcional e Y trocando de blaster, X, RB, Back, pausa com Start, trocar de personagem pela pausa, B e Start fechando a pausa); termina com "CONTROLE OK".
- `godot --headless --path . -- --combate` deixa os esqueletos atacarem de verdade e confere 13 pontos (soco, flecha e bolha acertam; invulnerabilidade; tiro estoura a bolha; tonto; comemoração; volta na bandeira com vida cheia; troca de bandeira; coração no chão; coração que cai); termina com "COMBATE OK". Leva cerca de 1 minuto.
- `godot --headless --path . -- --som` confere que os 20 efeitos carregam, que a música repete e que cada evento do jogo dispara o som certo (11 pontos); termina com "SOM OK". O teste não ouve nada: o `Sfx` anota o nome de cada som tocado quando `Sfx.logging` está ligado.
- `godot --headless --path . -- --ilha` confere a ilha (10 pontos): aventureiro no chão da praça, 18 esqueletos dormindo, bandeiras, acordar só quem está perto, voltar para casa, subir a encosta do Morro, atravessar a ponte, tchibum no rio e bandeira do topo; termina com "ILHA OK".
- `godot --headless --path . -- --historia` joga a história com ondas curtas e confere 32 pontos: só a Paçoca no começo; prólogo (começa na praça apontando a praia do cais, rachaduras, moradores da praça torcendo na onda e comemorando no fim, intervalo com munição e coração, onda cancelada ao se afastar e recomeçada ao voltar, lanternas acesas); Lanterna Oeste (Ossão com barra, tiro na cabeça, onda de choque que acerta no chão e passa por baixo de quem pula, Minions na metade da vida, lanterna apagada, convidados festejando, recompensa Granulado, Ossão indo de balão); Lanterna Leste (ficar tonto cancela a onda, Mira-Torta com chuva de flechas e leque de 5, barreira da ponte some, Pipoqueira); atravessar a ponte. Termina com "HISTORIA OK". Leva uns 3 minutos.
- `godot --headless --path . -- --mata` pula direto para a mata (cidade vencida, com Granulado e Pipoqueira) e confere 18 pontos (com o portão do cemitério abrindo): Golem de Ossos na segunda onda da Clareira (16 de vida, a pancada solta onda); Torre de Ossinhos com 5 andares, tiro na cabeça do andar de baixo, andar vencido indo de balão e os de cima descendo, bolha do de cima, pulo com onda quando sobram 2, coração de recompensa (vida máxima 6); Minionzão com a faixa da investida, acerto de quem fica no caminho, tonto com dano em dobro; cúpula caindo, Pé-de-Moleque e chegar ao cemitério começando a defesa final. Termina com "MATA OK". Leva uns 2 minutos.
- `godot --path . -- --historia-captura` tira 12 fotos da história (`h01` a `h12`).
- `godot --headless --path . -- --cemiterio` parte do atalho com a cúpula caída e confere 15 pontos: defesa ativa, entrar no cemitério começa a defesa, Mestre Ossinho na última onda com barra, dois minions chamados, bolha, tiro na cabeça, escudo de 6 bolhas, golpe bloqueado com escudo, tiro que estoura bolha do escudo, tonto com dano em dobro, escudo some na fase 3, bolha gigante que vira três, senta e tira a coroa sem balão, defesa vencida com o fim da história. Termina com "CEMITERIO OK".
- `godot --path . -- --cemiterio-captura` tira 7 fotos da defesa final (`c01` a `c07`), com a câmera livre.
- `godot --path . -- --paisagem-captura` tira 15 fotos da paisagem sem interface (`p01` a `p16`): cemitério de cima, cripta, túmulos, ponte de lado e de cima, mata da Clareira e dos Ventos, morrinhos do rio, cerejeiras da praça, praia do cais, cais de madeira, lenhador, Morro dos Ventos, portão fechado e aberto, pasto.
- `godot --headless --path . -- --extras` confere 12 pontos das diversões: barraca com 4 alvos, boneco e placar; tiro de verdade no alvo marca ponto e derruba; o alvo volta; boneco mostra o dano; os 7 moradores novos; Guerreiro Planta aparece ao entrar no Bosque das Copas; escudo segura o corpo pela frente e a cabeça passa; leque de 3 flechas; sem escudo depois da investida; vencido aplaude e fica; +1 coração sem mexer na história. Termina com "EXTRAS OK".
- `godot --path . -- --extras-captura` tira 11 fotos (`x01` a `x12`, sem a `x09`): barraca de tiro, bruxa, banda com o urso, fantasiados, lenhador, pescador, Bosque das Copas, Guerreiro Planta.
- `godot --path . -- --festa-captura` tira 9 fotos da festa e dos moradores sem a interface (`f01` a `f08`, mais `f03b` da plateia do palhaço): praça, palco, palhaço, barraca, mesas, vovô falando, motorista na calçada e trilheiro.
- `godot --path . -- --mata-captura` tira 8 fotos da mata (`m00a`/`m00b`: Golem chegando e batendo no chão; `m01` a `m06`: Torre, andar indo de balão, faixa do Minionzão, Minionzão tonto, cúpula caindo, chegada ao cemitério).
- `godot --path . -- --ilha-captura` tira 8 fotos jogando na ilha (praça, esqueleto dormindo e acordando, trilha do Morro, cemitério, ponte, clareira, tchibum).
- `godot --headless --path . -- --armas` confere 17 pontos dos blasters: pente, recarga automática e com R, não atirar recarregando, troca com modelo novo na mão, estoque, sem munição, caixa (e caixa que fica no chão), escopeta, luneta, granada e caixa que cai com munição no fim; termina com "ARMAS OK". O teste de controle também confere X (recarregar), Y (trocar de blaster) e RB (granada), e o da ilha confere as 10 caixas.
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
| `townsperson.gd` | morador: atividade, aceno, balão de fala, torcida nas ondas e comemoração |
| `shooting_gallery.gd` | barraca de tiro ao alvo (alvos e boneco de treino) |
| `boss_planta.gd` | o Guerreiro Planta, desafio opcional do Bosque das Copas |
| `fx.gd` | confete, poeira, rastro do tiro, clarão, onda da granada, texto flutuante e saída de balão (`balloon_away`, usada pelos esqueletos e pelos andares da Torre) |
| `weapon_hud.gd` | painel de armas inclinado (arma atual, cartões dos outros blasters ganhos com o botão do direcional ou a tecla, granadas, recarga) |
| `story.gd` | a história: regiões e ondas (`REGIONS`), lanternas, barreira da ponte, cúpula, recompensas, região em festa, objetivo atual |
| `defense.gd` | uma defesa em ondas: círculo, rachaduras, ondas, intervalo, cancelar e recomeçar, guardião na última onda |
| `boss.gd` | base dos guardiões: chegada pela rachadura, vida, aviso, onda de choque, círculos de perigo, saída de balão gigante |
| `boss_ossao.gd`, `boss_mira_torta.gd` | os guardiões da cidade |
| `boss_torre.gd`, `boss_minionzao.gd` | os guardiões da mata (a Torre tem vida por andar; o Minionzão tem investida e fica tonto) |
| `boss_mestre.gd` | o Mestre Ossinho: três fases, escudo de bolhas (`ShieldBubble`), bolha gigante que se divide (`GiantBubble`) e o desfecho sentado sem a coroa |
| `reward_pickup.gd` | recompensa de região (blaster novo ou +1 coração) |
| `boss_bar.gd`, `objective_marker.gd` | barra de vida do guardião e losango do objetivo |
| `weapons.gd` | os 4 blasters e a granada (pente, estoque, recarga, dano, espalhamento, luneta, modelo e encaixe) e o que a caixa de munição devolve |
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

**Ainda não tem:** epílogo, modo "Defender a festa", ajuste de volume pelo jogador, exportação para `.exe` e otimização para computador fraco (a ilha tem centenas de árvores e milhares de tufos de grama; no Mac M4 roda leve, mas não foi medido em outra máquina). O aventureiro, os esqueletos e a interface ainda são montados por código; só a ilha é cena editável. O controle foi testado com controle físico no Mac (vibração aprovada); o ciclo de combate, o som e os blasters ainda só foram testados pelos testes automáticos e capturas (o som não foi ouvido por ninguém ainda).

## 10. Decisões em aberto

- **Título:** "Ilha Cafuné" é provisório.
- **Nomes do menino e da menina:** ainda por decidir.
- **Fim de uma partida no "Defender a festa":** (a) os esqueletos tentam levar 5 enfeites do palco; derrubar o ladrão devolve o enfeite; perdeu os 5, acabou; ou (b) acaba quando o aventureiro fica tonto 3 vezes.
- **Habilidades por classe:** na primeira versão a escolha é só visual.
- **Epílogo:** os esqueletos voltam de balão para a festa na praça como convidados, banda com xilofone de costela, créditos como álbum de fotos; depois abre o "Defender a festa".
- **Animação de tiro:** resolvida no papel, pelo KayKit Character Animations; falta baixar e conferir na Godot.
