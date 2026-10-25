# Ilha Cafuné — documentação única

Versão do documento: 2026-10-25 (elenco trocado para o KayKit)
Jogo: **Ilha Cafuné** (título provisório): tiro em terceira pessoa infantil, num mundo aberto pequeno.
Motor: Godot 4.7 (3D), com exportação para Windows (`.exe`) e macOS.
Arte: **só pacotes prontos e CC0**, quase tudo do KayKit (Kay Lousberg). Os blasters vêm do Kenney, porque o KayKit não tem armas de fogo. Lista completa na seção 8.

**Estado atual: fatia técnica jogável (2026-10-25).** Projeto Godot 4.7.2 na raiz desta pasta, com aventureiro escolhível, câmera em terceira pessoa, andar, correr, pular, mirar e atirar com blaster, e esqueletos que perseguem, levam tiro por região (cabeça vale o dobro), desmontam e se remontam. Pacotes brutos em `vendor/` (com `.gdignore`), só os arquivos usados copiados para `assets/`. Como rodar e o que falta: seção 9.1.

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

Na véspera da Festa do Cafuné, os esqueletos do Morro descem e levam tudo da festa. A Guilda dos Aventureiros pega os blasters novos e sai pela ilha recuperando o que foi roubado, desmontando esqueletos (que sempre se remontam) e apagando as quatro Lanternas Mágicas que fecham o caminho do Morro. No fim, descobre que os esqueletos só queriam ser convidados.

- **Público:** crianças de 6 a 12 anos, e quem joga com elas.
- **Gênero:** tiro em terceira pessoa com plataforma leve e exploração.
- **Personagem:** o jogador escolhe um dos cinco aventureiros e pode trocar na base da Guilda.
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

Os cinco aventureiros da versão grátis do KayKit Adventurers. O jogador escolhe um no começo e pode trocar na base da Guilda. Na primeira versão a diferença é só visual; habilidade especial por classe fica para depois.

Todos usam blasters. A arma original de cada um vai pendurada nas costas, como enfeite.

| Personagem | Pacote | Arma original (vai nas costas) | Personalidade sugerida |
|---|---|---|---|
| Knight (Cavaleiro) | Adventurers, grátis | espada e escudo; elmo com viseira | certinho, protetor, fala como herói de livro |
| Barbarian (Bárbaro) | Adventurers, grátis | machado; chapéu de urso | grandalhão de coração mole, adora doce |
| Rogue (Ladino) | Adventurers, grátis; variante com capuz | — | rápido, brincalhão, faz piada de tudo |
| Mage (Mago) | Adventurers, grátis | cajado e livro | estudioso, explica tudo, um pouco medroso |
| Ranger (Patrulheiro) | Adventurers, grátis | arco, flechas e aljava | calmo, conhece a floresta como ninguém |

Os nomes e gêneros dos personagens ficam para quando virmos os modelos.

**Moradores:** o pacote grátis não tem moradores comuns. Dá para criar alguns trocando as cores dos aventureiros (troca da textura de gradiente) e tirando as armas. Na história, os moradores estão escondidos de medo e só aparecem na festa do epílogo, o que pede poucos modelos.

## 7. Esqueletos e chefes

Os quatro esqueletos da versão grátis do KayKit Skeletons, mais variações de tamanho, cor e chapéu.

| Esqueleto | Papel | Comportamento |
|---|---|---|
| Minion | o mais comum, vem em bando | corre e dá trombada; frágil |
| Warrior | resistente | escudo na frente; acertar quando ele ergue o machado ou pelas costas |
| Rogue | à distância | atira com besta (flecha de ventosa), se esconde atrás de carros e árvores |
| Mage | apoio | lança bolhas mágicas lentas e chama minions |
| Esqueleto dourado | raro | variação dourada de qualquer um; foge e deixa muitos diamantes |

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

| Blaster | Tipo | No jogo |
|---|---|---|
| Paçoca | pistola, inicial | tiro único preciso; munição infinita |
| Pipoqueira | escopeta | espalha a curta distância |
| Granulado | rajada | tiro rápido, dano baixo |
| Pé-de-Moleque | precisão | tiro carregado de longe; acerta pontos fracos |
| Brigadeiro | granada | explode em confete, em área |

Quais modelos do Blaster Kit viram cada um se decide quando o pacote for baixado.

### Itens

Diamantes (moeda), corações (energia), estrelas (coletável), bandeiras (checkpoint): todos do KayKit Platformer Pack. Potes de vaga-lume, bilhetes e Lanternas Mágicas: montados com peças dos pacotes ou feitos com formas simples na Godot.

### Pacotes

| Pacote | Autor | Versão | Tamanho | Uso |
|---|---|---|---|---|
| Adventurers | KayKit | grátis 2.0 | 12 MB | personagens jogáveis (baixado) |
| Skeletons | KayKit | grátis 1.1 | 7,7 MB | inimigos e chefes (baixado) |
| City Builder Bits | KayKit | grátis 1.0 | 4,6 MB | cidade (baixado) |
| Forest Nature Pack | KayKit | grátis 1.0 | 6,1 MB | floresta e Morro (baixado) |
| Blaster Kit | Kenney | 2.1 | 1,7 MB | blasters: 18 modelos (`blaster-a` a `blaster-r`), granadas, miras, alvos e projéteis de espuma (baixado) |
| Character Animations | KayKit | grátis 1.1 | 14 MB | 161 animações para o `Rig_Medium` e o `Rig_Large`, incluindo tiro, mira e recarga de uma e duas mãos, e animações próprias de esqueleto (baixado) |
| Platformer Pack | KayKit | grátis | 22 MB | moeda, corações, checkpoints (depois) |
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
- `godot --path . -- --capture` abre a janela, roda uma sequência e salva capturas em `tools/capturas/` (fora do git).

**Controles** (as dicas na tela trocam sozinhas conforme o aparelho em uso):

| Ação | Teclado e mouse | Controle (Xbox / PlayStation) |
|---|---|---|
| Andar | WASD ou setas | analógico esquerdo |
| Olhar | mouse | analógico direito |
| Pular | espaço | A / X |
| Mirar | botão direito | LT ou LB / L2 ou L1 |
| Atirar | botão esquerdo | RT ou RB / R2 ou R1 |
| Trocar de aventureiro | Q e E, ou 1 a 6 | direcional ← e → |
| Menu de aventureiros | Tab | Start / Options |
| Confirmar e voltar no menu | Enter e Esc | A e B / X e círculo |
| Regiões de impacto | F3 | Back / Share |
| Soltar o mouse | Esc | — |

**Auxílio de mira (só no controle e mirando):** um alvo a até 7° do centro da mira freia o giro do analógico pela metade e puxa a mira de leve para o corpo do esqueleto. Logo que aperta o gatilho de mira o puxão é mais forte por 0,25 s. A cabeça (dano em dobro) fica por conta de quem mira. Os valores ficam no grupo "Controle" do `player.gd` (`aim_assist_angle_deg`, `aim_assist_pull`, `aim_assist_snap`, `stick_speed`). A vibração é curta no tiro e mais forte no acerto.

**Detalhe da Godot 4.7:** as ações de menu `ui_accept` e `ui_cancel` não vêm ligadas aos botões A e B do controle; o `main.gd` liga.

**Código** (`scripts/`):

| Arquivo | O que faz |
|---|---|
| `main.gd` | monta o mundo (chão, cidade ampliada 5x, floresta 1,8x), jogador, esqueletos, interface e os modos `--smoke` e `--capture` |
| `player.gd` | câmera no ombro com SpringArm3D, movimento, `AnimationTree` (locomoção 2D, chão/ar, mira e tiro só no tronco), blaster no `handslot.r`, tiro por raio a partir do centro da tela |
| `skeleton_enemy.gd` | perseguir, provocar, levar golpe, desmontar (`Skeletons_Death`) e remontar (`Skeletons_Death_Resurrect`); regiões de impacto em `BoneAttachment3D` |
| `hurtbox.gd` | região de impacto (Area3D na camada 4) com multiplicador de dano |
| `anim_util.gd` | carrega as bibliotecas de animação do KayKit e marca as que repetem |
| `fx.gd` | confete, poeira, rastro do tiro, clarão e texto flutuante |

`tools/weapon_axes.gd` calcula a rotação do blaster a partir da pose de mira (resultado: 90° em Y, posição `(0.12, 0.1, 0)`), e `tools/inspect.gd` imprime a hierarquia importada.

**Ainda não tem:** esqueleto atacando e vida do jogador, som, mapa da ilha de verdade, outros blasters, cenas editáveis no editor (tudo é montado por código em `main.gd`) e exportação para `.exe`. O controle só foi testado com eventos simulados; falta um teste com controle físico.

## 10. Decisões em aberto

- **Título:** "Ilha Cafuné" é provisório.
- **Nomes e gêneros dos aventureiros:** decidir depois de ver os modelos.
- **Habilidades por classe:** na primeira versão a escolha é só visual.
- **Skeletons Extra (pago):** Golem e Necromancer melhorariam os chefes e o Mestre Ossinho.
- **Animação de tiro:** resolvida no papel, pelo KayKit Character Animations; falta baixar e conferir na Godot.
