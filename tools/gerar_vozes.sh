#!/bin/bash
# Vozes dos momentos principais (item 13 da lista de melhorias): gera assets/audio/vozes/<id>.wav com a voz
# brasileira do Mac (Luciana), mono, 22 kHz. São provisórias: dá para trocar cada arquivo por uma gravação de
# verdade (com a voz da família, por exemplo) com o mesmo nome. Uso: bash tools/gerar_vozes.sh
cd "$(dirname "$0")/.."
OUT=assets/audio/vozes
mkdir -p "$OUT"
TMP=$(mktemp -d)
falar() {
  say -v Luciana -r 175 -o "$TMP/$1.aiff" "$2"
  afconvert -f WAVE -d LEI16@22050 -c 1 "$TMP/$1.aiff" "$OUT/$1.wav"
  echo "voz: $1"
}
falar prologo "Os esqueletos estão chegando! Vamos defender a festa!"
falar lanterna "Apagamos a lanterna!"
falar ossao "Cuidado! É o Ossão!"
falar mira_torta "Olha a Mira-Torta!"
falar torre "É a Torre de Ossinhos!"
falar minionzao "Nossa, que Minionzão enorme!"
falar planta "O Guerreiro Planta acordou!"
falar mestre "É o Mestre Ossinho!"
falar conseguimos "Conseguimos!"
falar convite "Toma! É o convite da festa!"
falar festa "Viva! A Festa do Cafuné!"
falar fisgou "Fisgou! Puxa, puxa!"
falar peixe_novo "Peixe novo!"
falar la_vou_eu "Lá vou eu!"
falar achei "Achei você!"
falar dourado "Olha! Um esqueleto dourado!"
falar figurinha "Figurinha nova!"
falar bilhete "Achei um bilhete!"
falar campeao "Campeão!"
falar tres_estrelas "Três estrelas!"
falar fim_de_ano "Feliz fim de ano!"
falar tonto "Ai, ai... fiquei tonto!"
rm -rf "$TMP"
