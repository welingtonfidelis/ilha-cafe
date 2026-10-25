# Ilha Cafuné — documentação única

Versão do documento: 2026-10-25 (elenco trocado para o KayKit)
Jogo: **Ilha Cafuné** (título provisório): tiro em terceira pessoa infantil, num mundo aberto pequeno.
Motor: Godot 4.7 (3D), com exportação para Windows (`.exe`) e macOS.
Arte: **só pacotes prontos e CC0**, quase tudo do KayKit (Kay Lousberg). Os blasters vêm do Kenney, porque o KayKit não tem armas de fogo. Lista completa na seção 8.

**Estado atual: ilha jogável com 4 blasters e granada (2026-10-25).** Projeto Godot 4.7.2 na raiz desta pasta, versionado em git (branch `main`, sem remoto). O jogo abre na ilha de verdade (`scenes/ilha.tscn`, seção 3.1): cidade, Morro com castelinho, rio com ponte, mata, cais e 18 esqueletos que dormem até o aventureiro chegar perto. Aventureiro escolhível, câmera em terceira pessoa, 4 blasters com pente, recarga e estoque limitado, granada e caixas de munição, controle com auxílio de mira; esqueletos com armas que atacam cada um do seu jeito, vida em corações, tonto com estrelinhas, pontos de retorno e coração que cai (modelos do Platformer Pack); 30 efeitos sonoros e música de fundo gerados por síntese. Pacotes brutos em `vendor/` (fora do git e com `.gdignore`), só os arquivos usados copiados para `assets/`. Como rodar e o que falta: seção 9.1.

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

Na véspera da Festa do Cafuné, os esqueletos do Morro descem e levam tudo da festa. Duas crianças da cidade, um menino e uma menina, pegam os blasters novos e saem pela ilha recuperando o que foi roubado, desmontando esqueletos (que sempre se remontam) e apagando as quatro Lanternas Mágicas que fecham o caminho do Morro. No fim, descobre que os esqueletos só queriam ser convidados.

- **Público:** crianças de 6 a 12 anos, e quem joga com elas.
- **Gênero:** tiro em terceira pessoa com plataforma leve e exploração.
- **Personagem:** o jogador escolhe entre o menino e a menina, e pode trocar a qualquer hora.
- **Controle é obrigatório:** tudo tem que funcionar no controle (menus inclusive), não só no teclado e mouse. Com controle há auxílio de mira e vibração.
- **Mundo:** uma ilha pequena, sem fases nem telas de carregamento. Cidade ao sul, floresta ao norte, Morro no meio.
- **Duração alvo:** 3 a 5 horas de história, mais coletáveis.
- **Inspirações de tom:** Plants vs. Zombies (monstros que fazem rir), Ratchet & Clank (armas divertidas), A Short Hike (ilha pequena e aconchegante).

## 2. Regras de tom

Valem para história, arte, som e código.

- **Ninguém morre.** Esqueleto acertado desmonta: os ossos se espalham com um "plóc", a caveira quica resmungando e os ossos saem pulando de volta para o Morro. Eles se remontam lá; não é morte, é derrota de desenho animado.
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
| Cidade | sul, x de −60 a 60, z de 110 a 190 | ruas do City Builder Bits em grade (4 x 3), prédios em volta dos quarteirões virados para a rua, carros, postes, lixeiras, caixa-d'água |
| Praça da festa | quarteirão central do sul (x −20 a 20, z 150 a 190) | palco vermelho e azul, arco amarelo, 8 balões em postes, bancos e árvores; o jogo começa aqui |
| Cais | sai da praça para o mar (z 206 a 252) | passarela de tábuas |
| Morro | centro, raio 90 m, 26 m de altura | dá para subir andando por qualquer lado; trilha de terra em espiral (2,5 voltas) até o topo plano |
| Castelinho | topo do Morro | 4 torres com bandeiras, muros, portão para o sul e a lanterna central roxa |
| Rio Preguiçoso | atravessa a ilha de leste a oeste em z ≈ −112 | 14 m de largura; cair nele faz "tchibum" e volta na bandeira sem perder coração |
| Ponte | x = 0, sobre o rio | passarela de tábuas com corrimão; é o único caminho para a mata |
| Mata | norte do rio | ~330 árvores, pedras, arbustos, trilhas de terra |
| Clareira da Jabuticabeira | (40, −180) | árvore gigante no meio |
| Vila das Copas | (115, −160) | 3 plataformas de madeira sobre postes (chegar lá em cima fica para o pulo duplo) |
| Morro dos Ventos | (−115, −185), 14 m | morrinho a noroeste |
| Lanternas | 2 na cidade (leste e oeste), 1 no Morro dos Ventos, 1 na clareira | poste com esfera roxa e raio até o castelinho; por enquanto só visual |

**Marcadores editáveis** (`Marcadores` dentro da ilha): `Inicio` (onde o aventureiro começa e para onde olha), `PontosDeRetorno` (6 bandeiras: Praca, PeDoMorro, TopoDoMorro, EntradaDaMata, Clareira, MorroDosVentos; a primeira começa ativa) e `Esqueletos` (18, cada um com o tipo na metadata `tipo`). Mover um marcador no editor muda o jogo, sem mexer em código.

**Esqueletos na ilha:** começam dormindo como pilha de ossos e se montam quando o aventureiro chega a 16 m (golpe de perto) ou 22 m (quem atira). Se o aventureiro se afasta mais de 45 m da casa deles, voltam para casa e deitam de novo. Desmontados sem ninguém por perto, ficam dormindo ali mesmo.

**Regerar a ilha** (`godot --headless --path . -s res://tools/gerar_ilha.gd`) sobrescreve `scenes/ilha.tscn` e o terreno em `assets/terrain/`. Depois de mexer na ilha pelo editor, faça commit antes de regerar. `tools/foto_ilha.gd` tira fotos da ilha de cima e de alguns pontos, para conferir sem abrir o editor.

## 4. História

### Premissa

Todo ano a ilha faz a Festa do Cafuné, com balões, banda, doces e lanternas. Os esqueletos que moram no Morro ouvem a música lá de cima, mas nunca são convidados: todo mundo se assusta só de olhar para eles. Este ano o Mestre Ossinho, líder dos esqueletos, decidiu: se não podem ir à festa, a festa vai até eles. Os esqueletos descem e levam tudo para fazer a sua própria festa no Morro.

### Prólogo: véspera da festa (praça da cidade, tutorial)

1. O jogador escolhe seu aventureiro e ajuda a Guilda a montar a festa (andar, pular, interagir).
2. Ao anoitecer, os esqueletos descem do Morro e levam balões, instrumentos e doces. Os aventureiros tentam espadas e machados, mas os esqueletos se remontam na hora.
3. A Guilda abre a caixa de equipamentos novos: os blasters. Um disparo desmonta o esqueleto de vez, e ele volta pulando para o Morro (tutorial de tiro).
4. O Mestre Ossinho aparece no alto do Morro e acende quatro Lanternas Mágicas, duas na cidade e duas na floresta. Raios roxos ligam o Morro às lanternas e fecham o caminho até lá.

A ilha se abre. Objetivo: apagar as quatro lanternas.

### Ato 1: Cidade

Missões em qualquer ordem:

- **A banda sumiu:** recuperar os instrumentos espalhados pela cidade. A música da cidade vai ganhando instrumentos.
- **Doces da festa:** recuperar os doces que os esqueletos esconderam.
- **Botas de Mola:** a Guilda entrega o pulo duplo, que abre telhados e lugares altos.
- **Ossão** (chefe): esqueleto guerreiro gigante. Apaga a Lanterna 1.
- **Mira-Torta** (chefe, precisa do pulo duplo): esqueleta ladina gigante de besta. Apaga a Lanterna 2.

Fecho do ato: com as duas lanternas da cidade apagadas, a ponte para a floresta baixa.

### Ato 2: Floresta

Os esqueletos estão levando vaga-lumes em potes para iluminar a festa deles.

- **Potes de vaga-lume:** libertar os vaga-lumes. Cada leva liberta ilumina uma parte da floresta à noite.
- **Gancho:** a Guilda manda o gancho, que atravessa o rio e alcança galhos altos.
- **Torre de Ossinhos** (chefe): dezenas de esqueletos-minion empilhados numa torre que anda. Atirar na base faz a torre desabar. Apaga a Lanterna 3.
- **Minionzão** (chefe, precisa do gancho): minion gigante que se enrola e rola como bola de boliche. Apaga a Lanterna 4.
- **Bilhetes dos esqueletos:** 12 bilhetes espalhados pelas duas regiões mostram, aos poucos, que eles só queriam ser convidados.

Fecho do ato: as quatro lanternas apagam e o caminho do Morro se abre. Um dos aventureiros, lendo um bilhete: "Gente... e se eles só estiverem sozinhos?"

### Ato 3: O Morro

- **Subida do Morro**, usando pulo duplo e gancho, com os esqueletos tentando atrapalhar pela última vez.
- **Chefe final: Mestre Ossinho**, esqueleto mago de coroa. Três fases: chama ondas de minions, se protege com um escudo de ossos, e por fim monta uma criatura gigante com os ossos de todos (desmonta ao fim da luta).
- **Desfecho:** o Mestre Ossinho cai sentado numa pilha de ossos e balões e confessa que só queria ir à festa. A Guilda entrega o convite.

### Epílogo: a Festa do Cafuné

A festa acontece na praça com os esqueletos de convidados: tocam na banda (xilofone de costela), dançam e servem doces. Os créditos passam como um álbum de fotos da festa.

### Mensagem

Não se julga ninguém pela aparência. Às vezes falta só um convite.

## 5. Progressão no mundo aberto

O jogo não tem fases. O progresso aparece no próprio mundo:

- **Raios das lanternas:** quatro raios roxos saem do Morro e apontam os chefes. Apagam um a um.
- **Habilidades que abrem caminho:**

  | Habilidade | Quando | O que abre |
  |---|---|---|
  | Botas de Mola (pulo duplo) | Ato 1 | telhados e lugares altos da cidade, chefe Mira-Torta |
  | Gancho | Ato 2 | rio, galhos altos, chefe Minionzão, subida do Morro |

- **A ilha volta a ficar em festa:** cada missão concluída devolve algo visível (banda, balões, luzes, vaga-lumes).
- **Moeda e melhorias:** os esqueletos derrotados deixam cair diamantes (KayKit Platformer Pack), que compram melhorias de blaster na base da Guilda.
- **Pontos de retorno:** bandeiras de checkpoint (também do Platformer Pack).

Coletáveis: bilhetes dos esqueletos (12), potes de vaga-lume, estrelas escondidas e esqueletos dourados (raros, fogem e deixam muitos diamantes).

## 6. Personagens jogáveis

**Decisão do usuário (2026-10-25):** armadura medieval destoa da cidade. Os jogáveis são só **dois**: o **menino de boné amarelo** e a **menina de boné branco**, do pacote **"The Protagonists"** da KayKit Mystery Monthly Series 5. Os esqueletos continuam como estão.

| Personagem | Visual (do pacote) | Nome no jogo |
|---|---|---|
| Menino | boné amarelo, colete, mochila, roupa colorida de hoje | provisório: "Menino" |
| Menina | boné branco, óculos, mochila | provisório: "Menina" |

- **Pacote:** KayKit Mystery Monthly Series 5, **pago** (US$ 19,99; US$ 13,39 na promoção de Halloween de 2026), 42 MB, licença CC0. Traz 14 personagens; só usamos os dois Protagonists. O autor diz que são "tecnicamente idênticos" aos Adventurers, então devem usar o mesmo `Rig_Medium`: as animações, o encaixe do blaster e as regiões de impacto continuam valendo. Confirmar quando o pacote chegar.
- **Enquanto o pacote não chega:** o Ranger e a Rogue do Adventurers (grátis) seguram o lugar, sem capa, capuz e aljava (`HIDDEN_MESH_HINTS` no `player.gd`). Para trocar, basta mudar os caminhos em `CHARACTERS`, no `player.gd`.
- **Trocar:** menu (Tab / Start), Q/E ou direcional. Na primeira versão a diferença é só visual.
- **Nomes:** ainda por decidir.

**Moradores:** o pacote grátis não tem moradores comuns. Dá para criar alguns trocando as cores dos aventureiros (troca da textura de gradiente) e tirando as armas. Na história, os moradores estão escondidos de medo e só aparecem na festa do epílogo, o que pede poucos modelos.

## 7. Esqueletos e chefes

Os quatro esqueletos da versão grátis do KayKit Skeletons, mais variações de tamanho, cor e chapéu.

| Esqueleto | Papel | Comportamento (o que já está no jogo em **negrito**) |
|---|---|---|
| Minion | o mais comum, vem em bando | **chega perto e dá um soco; 3 de vida** |
| Warrior | resistente | **machado e escudo; tiro no corpo de frente é bloqueado ("bloqueou!"), a não ser quando ele ergue o machado; acertar a cabeça ou pelas costas; 5 de vida** |
| Rogue | à distância | **besta; para a uns 12 m e atira flecha de ventosa reta, que dá para desviar andando de lado**; se esconder atrás de carros e árvores fica para depois |
| Mage | apoio | **cajado; lança bolha mágica lenta que persegue de leve e estoura com um tiro ("plof!")**; chamar minions fica para depois |
| Esqueleto dourado | raro | variação dourada de qualquer um; foge e deixa muitos diamantes (ainda não feito) |

**Regras de combate que valem para todos (já no jogo):** antes de cada golpe aparece um "!" amarelo sobre a cabeça; levar tiro interrompe o ataque; cada golpe tira 1 coração; quando o aventureiro fica tonto, os esqueletos param de atacar e comemoram; quando ele volta na bandeira, todos voltam para os lugares de origem e acordam de novo, para ninguém reaparecer cercado.

Chefes (todos montados com os esqueletos grátis, ampliados e com acessórios):

| Chefe | Onde | Base | Como é a luta |
|---|---|---|---|
| Ossão | cidade | Warrior 3x maior | bate o escudo no chão (onda que se pula); ponto fraco nas costas |
| Mira-Torta | cidade, no alto | Rogue 2,5x maior | atira flechas de ventosa de cima dos prédios; chegar perto com o pulo duplo |
| Torre de Ossinhos | floresta | dezenas de Minions empilhados | a torre anda; acertar os da base derruba a torre |
| Minionzão | floresta | Minion 4x maior | enrola e rola como bola de boliche; desviar e acertar quando fica tonto |
| Mestre Ossinho | Morro | Mage com coroa | três fases (minions, escudo de ossos, criatura gigante de ossos) |

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
| 4 | Pé-de-Moleque (precisão) | `blaster-e` | 2 | 5 | 10 / 25 | 2,0 s | luneta ao mirar (aproxima e diminui a sensibilidade), 3 de dano, um tiro na cabeça desmonta qualquer esqueleto |
| G / RB | Brigadeiro (granada) | `grenade-a` | — | — | começa com 2, máximo 3 | — | arremesso em arco, explode em confete depois de 1,4 s, raio de 5 m, até 3 de dano, o escudo não segura, estoura bolhas |

**Regras de munição (decisão do usuário: estoque limitado):**
- O contador fica no canto de baixo à direita: nome do blaster, "pente / estoque" e as granadas como bolinhas. O número do pente fica amarelo no último quarto e vermelho zerado.
- Pente vazio recarrega sozinho (com a animação de recarga de uma ou duas mãos do KayKit e um anel azul na mira). Dá para recarregar antes de zerar com R ou X. Durante a recarga não atira; trocar de blaster cancela a recarga.
- Sem estoque, o gatilho faz "tic" e aparece "Sem munição! Procure uma caixa ou troque de blaster".
- **A Paçoca tem estoque infinito de propósito**, como rede de segurança: a criança nunca fica sem ter com o que atirar.
- **Caixa de munição** (caixote do Blaster Kit com um pente em cima): devolve 30 do Granulado, 6 da Pipoqueira, 5 do Pé-de-Moleque e 1 granada, até o máximo. Com tudo cheio, fica no chão.
  - Na ilha há 10 caixas fixas (marcadores `Marcadores/Municao`), que voltam 45 s depois de pegas.
  - Esqueleto desmontado deixa cair uma caixa em 50% das vezes, e sempre que a munição limitada está abaixo de 25%; essa some depois de 30 s.

### Itens

Diamantes (moeda), corações (energia), estrelas (coletável), bandeiras (checkpoint): todos do KayKit Platformer Pack. Potes de vaga-lume, bilhetes e Lanternas Mágicas: montados com peças dos pacotes ou feitos com formas simples na Godot.

**No jogo hoje:** o coração que cai é o `heart_red` do Platformer Pack, e a bandeira de retorno é a `flag_A`, azul quando inativa e amarela quando ativa (copiadas para `assets/props/platformer/<cor>/`; o pacote guarda cada cor numa pasta, todas com a mesma textura). A `star_red` e a `star_yellow` também foram copiadas, para coletáveis futuros. Os corações da tela são desenhados por código, e as estrelinhas de tonto são geradas por código (sempre de frente para a câmera). As armas dos esqueletos (machado, escudo, besta, cajado) vêm do próprio pacote Skeletons e encaixam no `handslot` sem ajuste.

### Pacotes

| Pacote | Autor | Versão | Tamanho | Uso |
|---|---|---|---|---|
| Adventurers | KayKit | grátis 2.0 | 12 MB | substitutos provisórios dos jogáveis (baixado) |
| Mystery Monthly Series 5 | KayKit | pago, US$ 13,39 na promoção | 42 MB | os dois jogáveis ("The Protagonists"); **falta o usuário comprar** |
| Skeletons | KayKit | grátis 1.1 | 7,7 MB | inimigos e chefes (baixado) |
| City Builder Bits | KayKit | grátis 1.0 | 4,6 MB | cidade (baixado) |
| Forest Nature Pack | KayKit | grátis 1.0 | 6,1 MB | floresta e Morro (baixado) |
| Blaster Kit | Kenney | 2.1 | 1,7 MB | blasters: 18 modelos (`blaster-a` a `blaster-r`), granadas, miras, alvos e projéteis de espuma (baixado) |
| Character Animations | KayKit | grátis 1.1 | 14 MB | 161 animações para o `Rig_Medium` e o `Rig_Large`, incluindo tiro, mira e recarga de uma e duas mãos, e animações próprias de esqueleto (baixado) |
| Platformer Pack | KayKit | grátis 1.0 | 22 MB | coração, bandeiras de retorno, estrelas; depois diamantes (baixado) |
| Halloween Bits | KayKit | grátis | 5,3 MB | enfeites do Morro (opcional) |

Todos são CC0: uso comercial livre, sem atribuição obrigatória. O KayKit pede só para não revender os modelos sem alteração.

## 9. Notas técnicas na Godot

- **Esqueleto compartilhado (conferido nos arquivos):** aventureiros e esqueletos usam o mesmo esqueleto, `Rig_Medium`, com os mesmos nomes de ossos (`root`, `hips`, `spine`, `chest`, `head`, `upperarm.l/r`, `lowerarm.l/r`, `wrist.l/r`, `hand.l/r`, `handslot.l/r`, pernas e pés). Trocar de aventureiro é só trocar o modelo; animações, encaixe de arma e regiões de impacto continuam valendo.
- **Modelos em peças:** cada personagem vem dividido em malhas separadas (cabeça, corpo, braços, pernas, capa, elmo). Isso facilita esqueleto desmontando e trocar acessórios.
- **Animações:** os modelos não trazem animação embutida; elas vêm em arquivos `.glb` separados por categoria, em `vendor/kaykit-character-animations/.../Animations/gltf/Rig_Medium/`. As que importam para o jogo:

  | Arquivo | Animações úteis |
  |---|---|
  | `Rig_Medium_CombatRanged` | `Ranged_1H_Aiming`, `Ranged_1H_Shoot`, `Ranged_1H_Shooting`, `Ranged_1H_Reload` (pistola); as mesmas em `Ranged_2H_*` (escopeta e fuzil); `Ranged_Magic_*` (Mestre Ossinho) |
  | `Rig_Medium_MovementBasic` | `Walking_A/B/C`, `Running_A/B`, `Jump_Start`, `Jump_Idle`, `Jump_Land` |
  | `Rig_Medium_MovementAdvanced` | `Running_HoldingRifle`, `Running_Strafe_Left/Right`, `Walking_Backwards`, `Dodge_Forward/Backward/Left/Right` (esquiva) |
  | `Rig_Medium_General` | `Idle_A/B`, `Hit_A/B` (levar golpe), `Death_A/B` (ficar tonto), `Interact`, `PickUp`, `Throw` (granada Brigadeiro) |
  | `Rig_Medium_Special` | `Skeletons_Awaken_Floor` (esqueleto se montando do chão), `Skeletons_Death_Resurrect` (desmonta e se remonta), `Skeletons_Idle`, `Skeletons_Walking`, `Skeletons_Taunt`, `Skeletons_Spawn_Ground` |
  | `Rig_Medium_Simulation` | `Cheering`, `Waving`, `Sit_Chair_*` (festa do epílogo) |

  Não há andar de lado lento nem correr de costas; a mira fica numa camada só do tronco, por cima da locomoção.
- **Blaster na mão:** os ossos `handslot.r` e `handslot.l` existem justamente para segurar objetos; o blaster vai num `BoneAttachment3D` no `handslot.r`, com marcador de boca do cano.
- **Mira:** camada de tiro só no tronco no `AnimationTree`, para correr e atirar ao mesmo tempo.
- **Regiões de impacto:** cabeça e tronco dos esqueletos, mais pontos fracos dos chefes (costas do Ossão, base da Torre de Ossinhos).
- **Esqueleto desmontando:** na derrota, o modelo é trocado pelas partes soltas com física. Os esqueletos KayKit vêm em peças (cabeça, mandíbula, olhos, corpo, braços, pernas, capa), conferido nos arquivos.
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
- `godot --headless --path . -- --controle` joga só com eventos de controle simulados e confere 14 comandos (menu, analógicos, pulo, mira, auxílio de mira, tiro, troca de aventureiro, Back e Start); termina com "CONTROLE OK".
- `godot --headless --path . -- --combate` deixa os esqueletos atacarem de verdade e confere 13 pontos (soco, flecha e bolha acertam; invulnerabilidade; tiro estoura a bolha; tonto; comemoração; volta na bandeira com vida cheia; troca de bandeira; coração no chão; coração que cai); termina com "COMBATE OK". Leva cerca de 1 minuto.
- `godot --headless --path . -- --som` confere que os 20 efeitos carregam, que a música repete e que cada evento do jogo dispara o som certo (11 pontos); termina com "SOM OK". O teste não ouve nada: o `Sfx` anota o nome de cada som tocado quando `Sfx.logging` está ligado.
- `godot --headless --path . -- --ilha` confere a ilha (10 pontos): aventureiro no chão da praça, 18 esqueletos dormindo, bandeiras, acordar só quem está perto, voltar para casa, subir a encosta do Morro, atravessar a ponte, tchibum no rio e bandeira do topo; termina com "ILHA OK".
- `godot --path . -- --ilha-captura` tira 8 fotos jogando na ilha (praça, esqueleto dormindo e acordando, trilha do Morro, castelinho, ponte, clareira, tchibum).
- `godot --headless --path . -- --armas` confere 17 pontos dos blasters: pente, recarga automática e com R, não atirar recarregando, troca com modelo novo na mão, estoque, sem munição, caixa (e caixa que fica no chão), escopeta, luneta, granada e caixa que cai com munição no fim; termina com "ARMAS OK". O teste de controle também confere X (recarregar), Y (trocar de blaster) e RB (granada), e o da ilha confere as 10 caixas.
- Os testes `--smoke`, `--controle`, `--combate`, `--som`, `--armas` e `--capture` rodam na **arena plana** (o mapa antigo, previsível), com esqueletos já acordados; o jogo normal e os modos `--ilha` abrem a ilha.
- Os modos `--smoke`, `--controle` e `--capture` ligam `god_mode` no jogador, para o tonto não travar o teste.
- Para rodar os testes, use um limite de tempo (`perl -e 'alarm 200; exec @ARGV' godot ...`): se um script tiver erro de digitação, a Godot fica parada em vez de sair.
- `godot --path . -- --capture` abre a janela, roda uma sequência e salva capturas em `tools/capturas/` (fora do git).

**Controles** (as dicas na tela trocam sozinhas conforme o aparelho em uso):

| Ação | Teclado e mouse | Controle (Xbox / PlayStation) |
|---|---|---|
| Andar | WASD ou setas | analógico esquerdo |
| Olhar | mouse | analógico direito |
| Pular | espaço | A / X |
| Mirar | botão direito | LT ou LB / L2 ou L1 |
| Atirar | botão esquerdo | RT / R2 |
| Recarregar | R | X / quadrado |
| Granada | G | RB / R1 |
| Trocar de blaster | 1 a 4 ou rodinha do mouse | Y / triângulo |
| Trocar de aventureiro | Q e E | direcional ← e → |
| Menu de aventureiros | Tab | Start / Options |
| Confirmar e voltar no menu | Enter e Esc | A e B / X e círculo |
| Regiões de impacto | F3 | Back / Share |
| Soltar o mouse | Esc | — |

**Auxílio de mira (só no controle e mirando):** um alvo a até 7° do centro da mira freia o giro do analógico pela metade e puxa a mira de leve para o corpo do esqueleto. Logo que aperta o gatilho de mira o puxão é mais forte por 0,25 s. A cabeça (dano em dobro) fica por conta de quem mira. Os valores ficam no grupo "Controle" do `player.gd` (`aim_assist_angle_deg`, `aim_assist_pull`, `aim_assist_snap`, `stick_speed`). A vibração é curta no tiro e mais forte no acerto.

**Detalhe da Godot 4.7:** as ações de menu `ui_accept` e `ui_cancel` não vêm ligadas aos botões A e B do controle; o `main.gd` liga.

**Código** (`scripts/`):

| Arquivo | O que faz |
|---|---|
| `main.gd` | abre a ilha (lendo os marcadores) ou, nos testes, a arena plana; cria jogador, esqueletos e bandeiras; interface (corações, clarão de golpe, escurecer do tonto); tchibum na água; queda de coração e os modos de teste |
| `player.gd` | câmera no ombro com SpringArm3D, movimento, `AnimationTree` (locomoção 2D, chão/ar, mira e tiro só no tronco, golpe recebido, normal/tonto), blaster no `handslot.r`, tiro por raio a partir do centro da tela, corações, invulnerabilidade piscando, empurrão, estrelinhas e volta na bandeira |
| `skeleton_enemy.gd` | tipos em `TYPES` (distância, aviso, intervalo, armas); perseguir, preparar com "!", golpear ou disparar, esperar, levar golpe, desmontar, remontar e comemorar; escudo do Warrior; regiões de impacto em `BoneAttachment3D` |
| `projectile.gd` | flecha de ventosa e bolha mágica (que também é alvo) |
| `checkpoint.gd` | bandeira de ponto de retorno |
| `heart_pickup.gd` | coração que devolve vida |
| `hurtbox.gd` | região de impacto (Area3D na camada 4) com multiplicador de dano |
| `sfx.gd` | toca efeitos (2D para o aventureiro e a interface, 3D com posição para esqueletos, flechas e bolhas) e a música em loop; cria os canais de áudio "Musica" (−9 dB) e "Efeitos" |
| `anim_util.gd` | carrega as bibliotecas de animação do KayKit e marca as que repetem |
| `fx.gd` | confete, poeira, rastro do tiro, clarão, onda da granada e texto flutuante |
| `weapons.gd` | os 4 blasters e a granada (pente, estoque, recarga, dano, espalhamento, luneta, modelo e encaixe) e o que a caixa de munição devolve |
| `grenade.gd` | granada Brigadeiro: arco, quique, explosão em área |
| `ammo_pickup.gd` | caixa de munição (fixa com retorno ou caída de esqueleto) |

`tools/weapon_axes.gd` mostra para onde aponta o osso da mão na pose de mira (o eixo X dele é a frente). No Blaster Kit o cano fica na ponta −Z de todos os modelos (`tools/foto_blasters_pontas.gd` mostra as pontas), então a rotação no osso é (0, −90, 0); `tools/foto_blasters.gd` mostra cada blaster de lado com a boca (amarelo) e o cabo (azul). `tools/inspect.gd` imprime a hierarquia importada.

**Som:** todos os sons são gerados por `tools/gerar_sons.py` (só biblioteca padrão do Python, 2,5 s para gerar tudo): `python3 tools/gerar_sons.py` reescreve `assets/audio/sfx/*.wav` e `assets/audio/musica/tema.wav`, e a Godot reimporta sozinha. São sons de desenho animado, sem estampido realista:

| Evento | Som |
|---|---|
| tiro do blaster | `tiro` ("piu" descendo) |
| acerto no corpo / na cabeça | `acerto` ("tic") / `acerto_cabeca` ("dim-dim") |
| esqueleto desmonta / se remonta | `ossos` (toc-toc de madeira e "boing") / `remontar` (toc-toc acelerando e "plim") |
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

**Ainda não tem:** história (missões, lanternas funcionando, chefes, ponte que baixa), pulo duplo e gancho, ganhar os blasters aos poucos, ajuste de volume pelo jogador, exportação para `.exe` e otimização para computador fraco (a ilha tem centenas de árvores e milhares de tufos de grama; no Mac M4 roda leve, mas não foi medido em outra máquina). O aventureiro, os esqueletos e a interface ainda são montados por código; só a ilha é cena editável. O controle foi testado com controle físico no Mac (vibração aprovada); o ciclo de combate, o som e os blasters ainda só foram testados pelos testes automáticos e capturas (o som não foi ouvido por ninguém ainda).

## 10. Decisões em aberto

- **Título:** "Ilha Cafuné" é provisório.
- **Nomes do menino e da menina:** ainda por decidir.
- **Habilidades por classe:** na primeira versão a escolha é só visual.
- **Skeletons Extra (pago):** Golem e Necromancer melhorariam os chefes e o Mestre Ossinho.
- **Animação de tiro:** resolvida no papel, pelo KayKit Character Animations; falta baixar e conferir na Godot.
