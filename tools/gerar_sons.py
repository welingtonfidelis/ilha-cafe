"""Gera os efeitos sonoros e a música de fundo do Ilha Cafuné por síntese (só biblioteca padrão).

Uso (da pasta do projeto):  python3 tools/gerar_sons.py
Saída: assets/audio/sfx/*.wav e assets/audio/musica/tema.wav (44,1 kHz, mono, 16 bits).

Os sons são de propósito "de desenho animado": nada de estampido realista.
Para ajustar um som, mude a função dele e rode de novo; a Godot reimporta sozinha.
"""

import math
import os
import random
import struct
import wave

SR = 44100
ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "audio")
random.seed(42)


# --- blocos básicos ---------------------------------------------------------

def n_samples(sec):
    return int(SR * sec)


def osc(f0, f1, dur, shape="sine", curve="exp", vibrato=0.0, vib_rate=6.0):
    """Oscilador com glissando de f0 para f1."""
    n = n_samples(dur)
    out = [0.0] * n
    phase = 0.0
    for i in range(n):
        t = i / max(n - 1, 1)
        f = f0 * (f1 / f0) ** t if curve == "exp" else f0 + (f1 - f0) * t
        if vibrato:
            f *= 1.0 + vibrato * math.sin(2 * math.pi * vib_rate * i / SR)
        phase += f / SR
        p = phase % 1.0
        if shape == "sine":
            v = math.sin(2 * math.pi * p)
        elif shape == "tri":
            v = 4.0 * abs(p - 0.5) - 1.0
        elif shape == "square":
            v = 0.7 if p < 0.5 else -0.7
        else:  # saw
            v = 2.0 * p - 1.0
        out[i] = v
    return out


def noise(dur):
    return [random.uniform(-1.0, 1.0) for _ in range(n_samples(dur))]


def envelope(sig, attack=0.005, decay=0.15, sustain=0.0, release=0.0):
    """Ataque linear e queda exponencial até `sustain`; release linear no fim."""
    n = len(sig)
    a = max(n_samples(attack), 1)
    r = n_samples(release)
    out = [0.0] * n
    for i in range(n):
        t = i / SR
        if i < a:
            g = i / a
        else:
            g = sustain + (1.0 - sustain) * math.exp(-(t - attack) / max(decay, 1e-4))
        if r and i > n - r:
            g *= (n - i) / r
        out[i] = sig[i] * g
    return out


def lowpass(sig, cutoff):
    rc = 1.0 / (2 * math.pi * cutoff)
    alpha = (1.0 / SR) / (rc + 1.0 / SR)
    out = [0.0] * len(sig)
    y = 0.0
    for i, x in enumerate(sig):
        y += alpha * (x - y)
        out[i] = y
    return out


def highpass(sig, cutoff):
    low = lowpass(sig, cutoff)
    return [x - l for x, l in zip(sig, low)]


def gain(sig, g):
    return [x * g for x in sig]


def mix(length_sec, *parts):
    """parts: (sinal, início_em_segundos, ganho)."""
    out = [0.0] * n_samples(length_sec)
    for sig, start, g in parts:
        s = n_samples(start)
        for i, x in enumerate(sig):
            j = s + i
            if j < len(out):
                out[j] += x * g
    return out


def normalize(sig, peak_db=-3.0):
    peak = max((abs(x) for x in sig), default=0.0)
    if peak == 0:
        return sig
    target = 10 ** (peak_db / 20.0)
    return [x * target / peak for x in sig]


def fade_edges(sig, ms=4):
    n = min(n_samples(ms / 1000.0), len(sig) // 2)
    out = list(sig)
    for i in range(n):
        out[i] *= i / n
        out[-1 - i] *= i / n
    return out


def save(rel_path, sig):
    path = os.path.join(ROOT, rel_path)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1.0, min(1.0, x)) * 32767)) for x in sig))
    peak = max(abs(x) for x in sig)
    print(f"{rel_path:32s} {len(sig) / SR:5.2f} s  pico {20 * math.log10(max(peak, 1e-9)):6.1f} dB")


def sfx(name, sig, peak_db=-3.0):
    save(f"sfx/{name}.wav", fade_edges(normalize(sig, peak_db)))


def midi(note):
    return 440.0 * 2 ** ((note - 69) / 12.0)


# --- efeitos ----------------------------------------------------------------

def make_sfx():
    # Blaster: "piu" descendo, com um sopro de ruído no começo.
    pew = envelope(osc(1500, 380, 0.16, "square"), 0.002, 0.06)
    puff = envelope(highpass(noise(0.05), 2500), 0.001, 0.015)
    sfx("tiro", lowpass(mix(0.17, (pew, 0, 0.8), (puff, 0, 0.5)), 7000), -4)

    # Acerto no corpo: "tic" curtinho. Na cabeça: "dim-dim" brilhante.
    sfx("acerto", envelope(osc(1800, 1500, 0.06, "sine"), 0.001, 0.02), -8)
    ding = lambda f: envelope(mix(0.3, (osc(f, f, 0.3), 0, 1.0), (osc(f * 2.01, f * 2.01, 0.3), 0, 0.3)), 0.002, 0.08)
    sfx("acerto_cabeca", mix(0.4, (ding(1568), 0, 0.8), (ding(2093), 0.07, 0.8)), -5)

    # Balão: borracha enchendo (chiado subindo com tremidinha) e um "tu-ru" alegre de despedida.
    squeak = envelope(osc(260, 820, 0.4, "tri", vibrato=0.05, vib_rate=26), 0.02, 0.3, 0.4, 0.05)
    note = lambda m, d: envelope(mix(d, (osc(midi(m), midi(m), d, "sine"), 0, 1.0), (osc(midi(m) * 2, midi(m) * 2, d), 0, 0.2)), 0.004, d * 0.6)
    sfx("balao", mix(1.0, (squeak, 0, 0.6), (note(79, 0.22), 0.45, 0.7), (note(76, 0.32), 0.62, 0.7)), -5)

    # Esqueleto acordando do chão: "toc-toc" acelerando e um "plim" subindo.
    rise = []
    t = 0.0
    step = 0.12
    for _ in range(9):  # passo encolhendo: os "toc" vão ficando mais juntos
        f = 800 + t * 900
        rise.append((envelope(osc(f, f, 0.04, "tri"), 0.001, 0.01), t, 0.7))
        t += step
        step = max(step * 0.82, 0.035)
    plim = envelope(osc(700, 1400, 0.25, "sine"), 0.003, 0.1)
    sfx("remontar", mix(1.0, *rise, (plim, 0.72, 0.7)), -7)

    # Aviso "!": um "tlim" suave (vai tocar muito, então fica baixinho).
    sfx("alerta", envelope(mix(0.2, (osc(1320, 1320, 0.2), 0, 1.0), (osc(1980, 1980, 0.2), 0, 0.3)), 0.003, 0.05), -12)

    # Golpe de perto: "fuuu" de ar.
    whoosh = noise(0.28)
    whoosh = lowpass(highpass(whoosh, 500), 2500)
    sfx("golpe_ar", envelope(whoosh, 0.12, 0.06), -6)

    # Escudo do guerreiro bloqueando: "clang" com parciais metálicos.
    clang = mix(0.6, *[(osc(f, f, 0.6), 0, a) for f, a in [(523, 1.0), (1312, 0.6), (2290, 0.4), (3350, 0.25)]])
    sfx("escudo", envelope(clang, 0.001, 0.12), -6)

    # Flecha de ventosa saindo: "fiu" fino. Batendo: "ploc" de ventosa.
    sfx("flecha", envelope(lowpass(highpass(noise(0.18), 1800), 6000), 0.005, 0.05), -7)
    sfx("ventosa", envelope(osc(900, 300, 0.09, "sine"), 0.001, 0.03), -5)

    # Bolha mágica saindo ("blub" ondulado) e estourando ("pop").
    sfx("bolha", envelope(osc(300, 900, 0.35, "sine", vibrato=0.12, vib_rate=14), 0.02, 0.15), -7)
    sfx("estouro", mix(0.12, (envelope(osc(1200, 500, 0.06), 0.001, 0.015), 0, 1.0), (envelope(highpass(noise(0.04), 3000), 0.001, 0.01), 0, 0.5)), -5)

    # Aventureiro levando golpe: "bonk" (pancada grave e tom caindo).
    thump = envelope(osc(180, 60, 0.18, "sine"), 0.001, 0.06)
    fall = envelope(osc(700, 350, 0.18, "tri"), 0.002, 0.07)
    sfx("bonk", mix(0.22, (thump, 0, 1.0), (fall, 0.01, 0.5)), -3)

    # Tonto: apito descendo com "uó-uó" e passarinhos (dois piados no fim).
    slide = envelope(osc(1100, 260, 0.9, "sine", vibrato=0.06, vib_rate=7), 0.01, 0.6, 0.3, 0.1)
    tweet = lambda: envelope(osc(3000, 3600, 0.07, "sine"), 0.002, 0.03)
    sfx("tonto", mix(1.4, (slide, 0, 0.8), (tweet(), 0.95, 0.4), (tweet(), 1.12, 0.4), (tweet(), 1.25, 0.35)), -4)

    # Bandeira ativada: arpejo maior subindo (dó-mi-sol-dó).
    notes = [72, 76, 79, 84]
    parts = [(envelope(mix(0.35, (osc(midi(m), midi(m), 0.35, "tri"), 0, 1.0), (osc(midi(m) * 2, midi(m) * 2, 0.35), 0, 0.25)), 0.003, 0.12), i * 0.09, 0.7) for i, m in enumerate(notes)]
    sfx("bandeira", mix(0.75, *parts), -4)

    # Coração recolhido: brilho de duas notas subindo.
    sparkle = [(envelope(osc(midi(m), midi(m), 0.25, "sine"), 0.002, 0.08), i * 0.07, 0.8) for i, m in enumerate([84, 91])]
    sfx("coracao", mix(0.4, *sparkle), -5)

    # Pulo: "boing" curtinho subindo.
    sfx("pulo", envelope(osc(260, 620, 0.14, "sine"), 0.003, 0.08), -9)

    # Reaparecer na bandeira: brilho subindo devagar.
    shimmer = mix(0.7, *[(envelope(osc(midi(m), midi(m), 0.3, "sine"), 0.01, 0.1), i * 0.08, 0.5) for i, m in enumerate([72, 79, 84, 88, 91])])
    sfx("reaparecer", shimmer, -6)

    # Blasters: Granulado (rajada, "pi" curtinho e agudo), Pipoqueira (pipoca estourando em leque)
    # e Pé-de-Moleque (tiro de precisão, "vuuum" grave com cauda).
    sfx("granulado", envelope(osc(1900, 900, 0.07, "square"), 0.001, 0.025), -7)
    pops = [(envelope(mix(0.06, (osc(f, f * 0.6, 0.06, "tri"), 0, 0.8), (highpass(noise(0.03), 2000), 0, 0.5)), 0.001, 0.015), t, random.uniform(0.6, 1.0))
            for f, t in [(900, 0.0), (1200, 0.015), (750, 0.03), (1050, 0.045), (1350, 0.06), (850, 0.08)]]
    thump = envelope(osc(160, 70, 0.12, "sine"), 0.001, 0.05)
    sfx("pipoqueira", mix(0.22, (thump, 0, 0.9), *pops), -3)
    zap = envelope(osc(700, 140, 0.45, "saw"), 0.002, 0.12)
    sfx("pe_de_moleque", lowpass(mix(0.5, (zap, 0, 0.7), (envelope(osc(2400, 600, 0.12, "sine"), 0.001, 0.04), 0, 0.5)), 5000), -3)

    # Recarga: "clic-clac" (tira o pente, põe o pente). Sem munição: "tic" seco.
    click = lambda f: envelope(mix(0.05, (osc(f, f * 0.7, 0.05, "square"), 0, 0.6), (highpass(noise(0.03), 3000), 0, 0.6)), 0.001, 0.01)
    sfx("recarga", mix(0.6, (click(1400), 0.0, 0.9), (click(900), 0.38, 1.0), (click(1600), 0.46, 0.7)), -6)
    sfx("sem_municao", click(2200), -12)

    # Troca de blaster: deslizar metálico rápido. Arremesso: "fuu" curtinho.
    sfx("troca_arma", mix(0.2, (envelope(lowpass(highpass(noise(0.12), 2500), 7000), 0.02, 0.04), 0, 0.6), (click(1200), 0.11, 0.8)), -8)
    sfx("arremesso", envelope(lowpass(highpass(noise(0.2), 700), 3000), 0.06, 0.05), -8)

    # Granada Brigadeiro: "pof" grave de desenho com brilho de confete por cima.
    boom = envelope(lowpass(noise(0.8), 900), 0.004, 0.22)
    bass = envelope(osc(120, 40, 0.5, "sine"), 0.002, 0.18)
    glitter = [(envelope(osc(f, f, 0.12, "sine"), 0.002, 0.04), t, 0.25) for f, t in [(2637, 0.1), (3136, 0.16), (3520, 0.22), (2794, 0.3), (3951, 0.36)]]
    sfx("granada", mix(0.9, (boom, 0, 0.9), (bass, 0, 0.9), *glitter), -2)

    # Caixa de munição recolhida: tilintar metálico subindo.
    ting = lambda f: envelope(mix(0.25, (osc(f, f, 0.25), 0, 1.0), (osc(f * 2.76, f * 2.76, 0.25), 0, 0.3)), 0.002, 0.07)
    sfx("municao", mix(0.45, (ting(1046), 0, 0.7), (ting(1318), 0.06, 0.7), (ting(1568), 0.12, 0.7)), -6)

    # Tchibum (caiu na água): chuá de ruído grave, um "blop" descendo e gotinhas.
    splash = envelope(lowpass(noise(0.6), 1800), 0.01, 0.18)
    blop = envelope(osc(500, 140, 0.25, "sine"), 0.003, 0.08)
    drops = [(envelope(osc(f, f * 1.3, 0.05, "sine"), 0.001, 0.015), t, 0.35) for f, t in [(1400, 0.25), (1800, 0.33), (1200, 0.42), (2000, 0.5)]]
    sfx("splash", mix(0.7, (splash, 0, 0.9), (blop, 0.02, 0.8), *drops), -4)

    # Interface: mover o foco e confirmar.
    sfx("ui_mover", envelope(osc(900, 900, 0.04, "tri"), 0.001, 0.012), -12)
    sfx("ui_ok", mix(0.16, (envelope(osc(880, 880, 0.08, "tri"), 0.001, 0.03), 0, 0.8), (envelope(osc(1320, 1320, 0.1, "tri"), 0.001, 0.04), 0.05, 0.8)), -8)


# --- música -----------------------------------------------------------------

def make_music():
    """Tema alegre em dó maior, 8 compassos que emendam sem corte (loop)."""
    bpm = 112
    beat = 60.0 / bpm
    total_beats = 32
    length = total_beats * beat
    n = n_samples(length)
    out = [0.0] * n

    def place(sig, start_beat, g):
        s = n_samples(start_beat * beat)
        for i, x in enumerate(sig):
            out[(s + i) % n] += x * g  # o que passa do fim volta para o começo: loop sem emenda

    chords = [[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62]] * 2  # C Am F G, duas vezes
    bass = [48, 45, 41, 43] * 2

    melody = [
        (0, .5, 76), (.5, .5, 79), (1, 1, 81), (2, .5, 79), (2.5, .5, 76), (3, 1, 72),
        (4, .5, 74), (4.5, .5, 76), (5, 1, 72), (6, 1.5, 69), (7.5, .5, 72),
        (8, .5, 77), (8.5, .5, 76), (9, 1, 74), (10, .5, 72), (10.5, .5, 74), (11, 1, 76),
        (12, 1, 79), (13, .5, 77), (13.5, .5, 76), (14, 2, 74),
        (16, .5, 76), (16.5, .5, 79), (17, 1, 84), (18, .5, 83), (18.5, .5, 81), (19, 1, 79),
        (20, .5, 81), (20.5, .5, 79), (21, 1, 76), (22, 1, 72), (23, 1, 74),
        (24, .5, 77), (24.5, .5, 81), (25, 1, 79), (26, .5, 77), (26.5, .5, 76), (27, 1, 74),
        (28, 1, 71), (29, 1, 74), (30, 2, 72),
    ]
    for start, dur, note in melody:
        f = midi(note)
        voice = mix(dur * beat + 0.15, (osc(f, f, dur * beat + 0.15, "sine", vibrato=0.004, vib_rate=5.5), 0, 0.8),
                    (osc(f, f, dur * beat + 0.15, "tri"), 0, 0.25))
        place(envelope(voice, 0.012, 0.35, 0.55, 0.08), start, 0.32)

    for bar in range(8):
        chord = chords[bar]
        # Arpejo em colcheias, bem baixinho.
        for k in range(8):
            note = chord[k % 3] + (12 if k >= 4 else 0)
            f = midi(note)
            place(envelope(osc(f, f, 0.3, "tri"), 0.004, 0.12), bar * 4 + k * 0.5, 0.09)
        # Baixo nos tempos 1 e 3.
        for b in (0, 2):
            f = midi(bass[bar])
            place(envelope(osc(f, f, beat * 0.95, "tri"), 0.006, 0.4, 0.4, 0.05), bar * 4 + b, 0.3)
        # Bateria macia: bumbo em 1 e 3, caixa em 2 e 4, chimbal em colcheias.
        for b in (0, 2):
            place(envelope(osc(150, 45, 0.16, "sine"), 0.001, 0.06), bar * 4 + b, 0.45)
        for b in (1, 3):
            snare = mix(0.15, (highpass(noise(0.15), 800), 0, 0.7), (osc(220, 180, 0.15), 0, 0.3))
            place(envelope(snare, 0.001, 0.05), bar * 4 + b, 0.16)
        for k in range(8):
            place(envelope(highpass(noise(0.04), 6000), 0.001, 0.012), bar * 4 + k * 0.5, 0.05)

    save("musica/tema.wav", normalize(lowpass(out, 9000), -6.0))


if __name__ == "__main__":
    make_sfx()
    make_music()
