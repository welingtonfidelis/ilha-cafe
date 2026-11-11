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

    # Pancada no chão do guardião: estrondo grave e curto, com chacoalhar de terra.
    thud = envelope(osc(90, 32, 0.7, "sine"), 0.002, 0.25)
    rumble = envelope(lowpass(noise(0.8), 500), 0.01, 0.3)
    sfx("pancada", mix(0.9, (thud, 0, 1.0), (rumble, 0.02, 0.7)), -2)

    # Tchibum (caiu na água): chuá de ruído grave, um "blop" descendo e gotinhas.
    splash = envelope(lowpass(noise(0.6), 1800), 0.01, 0.18)
    blop = envelope(osc(500, 140, 0.25, "sine"), 0.003, 0.08)
    drops = [(envelope(osc(f, f * 1.3, 0.05, "sine"), 0.001, 0.015), t, 0.35) for f, t in [(1400, 0.25), (1800, 0.33), (1200, 0.42), (2000, 0.5)]]
    sfx("splash", mix(0.7, (splash, 0, 0.9), (blop, 0.02, 0.8), *drops), -4)

    # Interface: mover o foco e confirmar.
    sfx("ui_mover", envelope(osc(900, 900, 0.04, "tri"), 0.001, 0.012), -12)
    sfx("ui_ok", mix(0.16, (envelope(osc(880, 880, 0.08, "tri"), 0.001, 0.03), 0, 0.8), (envelope(osc(1320, 1320, 0.1, "tri"), 0.001, 0.04), 0.05, 0.8)), -8)


# --- Faísca (Parte 2) ------------------------------------------------------

def am(sig, rate, depth):
    """Tremolo: o volume sobe e desce `rate` vezes por segundo (profundidade 0 a 1)."""
    return [x * (1.0 - depth * (0.5 + 0.5 * math.cos(2 * math.pi * rate * i / SR))) for i, x in enumerate(sig)]


def sweep_lowpass(sig, f0, f1):
    """Passa-baixa cujo corte vai de f0 a f1 ao longo do som (ar girando, motor subindo)."""
    out = [0.0] * len(sig)
    y = 0.0
    n = max(len(sig) - 1, 1)
    for i, x in enumerate(sig):
        cutoff = f0 * (f1 / f0) ** (i / n)
        rc = 1.0 / (2 * math.pi * cutoff)
        alpha = (1.0 / SR) / (rc + 1.0 / SR)
        y += alpha * (x - y)
        out[i] = y
    return out


def sfx_loop(name, sig, peak_db=-3.0):
    """Som que repete sem emenda: sem o esmaecer das bordas (o tamanho tem de fechar ciclos inteiros)."""
    save(f"sfx/{name}.wav", normalize(sig, peak_db))


def make_faisca():
    """Sons do Faísca: robozinho de desenho (servo, bipes, "boing"), pedido do usuário em 2026-10-29:
    "faltam sons novos pro faisca lutando, voando, etc". Têm semente própria para não mudar os outros."""
    random.seed(7)
    air = lambda dur, lo, hi: lowpass(highpass(noise(dur), lo), hi)
    beep = lambda f, d, shape="square": lowpass(envelope(osc(f, f, d, shape), 0.002, d * 0.7, 0.5, 0.02), 4500)

    # Soco: "fup" de ar curtinho e um "zip" de servo. Soco forte: ar mais grave e um "vrum".
    zip_ = lowpass(envelope(osc(600, 950, 0.06, "square"), 0.002, 0.03), 3000)
    sfx("faisca_soco", mix(0.16, (envelope(air(0.14, 800, 3200), 0.02, 0.04), 0, 0.9), (zip_, 0, 0.25)), -9)
    vrum = lowpass(envelope(osc(230, 110, 0.18, "saw"), 0.003, 0.07), 1200)
    sfx("faisca_soco_forte", mix(0.26, (envelope(air(0.22, 400, 2400), 0.03, 0.07), 0, 0.9), (vrum, 0.02, 0.6), (zip_, 0, 0.25)), -6)

    # Acertou: "pof" macio com um "tin" de mão de robô.
    pof = envelope(osc(320, 110, 0.09, "sine"), 0.001, 0.035)
    tin = envelope(mix(0.1, (osc(2400, 2400, 0.1), 0, 1.0), (osc(3610, 3610, 0.1), 0, 0.4)), 0.001, 0.03)
    sfx("faisca_acerto", mix(0.12, (pof, 0, 1.0), (tin, 0, 0.35), (envelope(highpass(noise(0.02), 2500), 0.001, 0.006), 0, 0.4)), -5)

    # Bolota apanhando: "ui!" de borracha. Bolota estourando: "pop" com brilho subindo.
    sfx("bolota_ai", envelope(osc(650, 1150, 0.16, "tri", vibrato=0.06, vib_rate=30), 0.005, 0.07), -10)
    glitter = [(envelope(osc(f, f, 0.15, "sine"), 0.002, 0.05), t, 0.35) for f, t in [(1760, 0.05), (2349, 0.1), (2960, 0.15), (3520, 0.2)]]
    pop = mix(0.1, (envelope(osc(1300, 450, 0.07), 0.001, 0.018), 0, 1.0), (envelope(highpass(noise(0.04), 3000), 0.001, 0.01), 0, 0.5))
    sfx("bolota_estoura", mix(0.45, (pop, 0, 1.0), *glitter), -5)

    # Giro no ar: ar rodando (o corte do filtro sobe) com um assobio subindo.
    swirl = am(sweep_lowpass(highpass(noise(0.42), 300), 700, 3800), 14, 0.6)
    sfx("faisca_giro", mix(0.45, (envelope(swirl, 0.05, 0.3, 0.3, 0.06), 0, 1.0), (envelope(osc(500, 1100, 0.4, "tri"), 0.04, 0.25), 0, 0.15)), -7)

    # Carregando o giro forte: motor subindo e tremendo cada vez mais rápido, e um "plim" de pronto.
    n = n_samples(0.5)
    motor = [math.sin(2 * math.pi * (120 * (i / SR) + 480 * (i / SR) ** 2)) for i in range(n)]
    motor = [x * (0.7 + 0.3 * math.sin(2 * math.pi * (8 + 40 * i / n) * i / SR)) for i, x in enumerate(motor)]
    whine = lowpass(osc(240, 1300, 0.5, "saw"), 2500)
    ready = envelope(mix(0.2, (osc(1568, 1568, 0.2), 0, 1.0), (osc(2349, 2349, 0.2), 0, 0.4)), 0.002, 0.06)
    sfx("faisca_carga", mix(0.68, (envelope(motor, 0.05, 1.0, 1.0), 0, 0.6), (envelope(whine, 0.05, 1.0, 1.0), 0, 0.15), (ready, 0.48, 0.6)), -8)

    # Pião (giro forte): "vush-vush" de hélice por 1 s, com zumbido de motor.
    blades = am(lowpass(highpass(noise(1.0), 250), 2600), 11, 0.85)
    hum = lowpass(osc(160, 200, 1.0, "saw"), 700)
    sfx("faisca_piao", envelope(mix(1.0, (blades, 0, 1.0), (hum, 0, 0.35)), 0.03, 1.0, 1.0, 0.15), -5)

    # Pisão: "boing" descendo e a pancadinha embaixo.
    sfx("faisca_pisao", mix(0.25, (envelope(osc(620, 210, 0.16, "tri"), 0.002, 0.06), 0, 0.7), (envelope(osc(160, 55, 0.18, "sine"), 0.001, 0.06), 0.03, 1.0)), -4)

    # Agarrar: "tchup" e a bolota reclamando ("iiih" subindo).
    sfx("faisca_agarra", mix(0.3, (envelope(osc(450, 950, 0.05, "sine"), 0.001, 0.02), 0, 1.0),
                            (envelope(osc(900, 1500, 0.22, "tri", vibrato=0.05, vib_rate=24), 0.01, 0.12), 0.05, 0.5)), -6)
    # Arremesso: ar forte e a bolota voando com um "uiii" descendo.
    sfx("faisca_arremesso", mix(0.5, (envelope(air(0.25, 500, 3000), 0.03, 0.08), 0, 0.9),
                               (envelope(osc(1700, 650, 0.45, "sine", vibrato=0.04, vib_rate=18), 0.01, 0.25), 0.04, 0.35)), -5)

    # Pulo: "bwip" de robô. Pouso: "toc" macio.
    sfx("faisca_pulo", mix(0.14, (lowpass(envelope(osc(320, 760, 0.1, "square"), 0.002, 0.05), 3500), 0, 0.6), (envelope(osc(260, 520, 0.12, "sine"), 0.002, 0.06), 0, 0.6)), -11)
    sfx("faisca_pouso", mix(0.1, (envelope(osc(210, 90, 0.08, "sine"), 0.001, 0.025), 0, 1.0), (envelope(highpass(noise(0.015), 3000), 0.001, 0.004), 0, 0.3)), -13)

    # Laser dos pés: "zing" ao ligar e um zumbido com brilho que repete enquanto flutua (1 s fecha ciclos
    # inteiros de 110, 220, 880 e 30 Hz, então emenda sem estalo).
    sfx("faisca_laser_liga", mix(0.2, (envelope(osc(900, 1900, 0.13, "sine"), 0.002, 0.06), 0, 0.8), (envelope(highpass(noise(0.1), 4000), 0.002, 0.03), 0, 0.3)), -9)
    n = n_samples(1.0)
    loop = []
    for i in range(n):
        t = i / SR
        x = 0.45 * math.sin(2 * math.pi * 110 * t) + 0.25 * math.sin(2 * math.pi * 220 * t)
        x += 0.22 * math.sin(2 * math.pi * 880 * t) * (0.5 + 0.5 * math.sin(2 * math.pi * 30 * t))
        x += 0.08 * math.sin(2 * math.pi * 1760 * t) * (0.5 + 0.5 * math.sin(2 * math.pi * 7 * t))
        loop.append(x)
    sfx_loop("faisca_laser", loop, -14)

    # Mola: "boiiing" de desenho.
    sfx("faisca_mola", envelope(osc(170, 640, 0.55, "sine", vibrato=0.08, vib_rate=17), 0.003, 0.25), -6)

    # Machucou: bipe de "ô-ou" descendo. Sem corações: curto (estalos elétricos e um apito caindo).
    sfx("faisca_dor", mix(0.32, (beep(880, 0.11), 0, 0.8), (beep(587, 0.17), 0.12, 0.8)), -8)
    crackle = [x if random.random() < 0.18 else 0.0 for x in highpass(noise(0.7), 1500)]
    sfx("faisca_curto", mix(0.9, (envelope(crackle, 0.002, 0.35), 0, 0.7),
                           (envelope(osc(1300, 160, 0.8, "square", vibrato=0.05, vib_rate=11), 0.005, 0.5), 0.05, 0.3)), -6)

    # Estrelinha: "plim" brilhante. Vaga-lume achado: arpejo mágico com tremidinha.
    sfx("estrelinha", mix(0.3, (envelope(mix(0.25, (osc(1319, 1319, 0.25), 0, 1.0), (osc(2637, 2637, 0.25), 0, 0.3)), 0.002, 0.06), 0, 0.8),
                         (envelope(mix(0.25, (osc(1976, 1976, 0.25), 0, 1.0), (osc(3951, 3951, 0.25), 0, 0.2)), 0.002, 0.08), 0.05, 0.8)), -9)
    twinkle = [(am(envelope(osc(midi(m), midi(m), 0.4, "sine"), 0.005, 0.18), 18, 0.4), i * 0.08, 0.6) for i, m in enumerate([84, 88, 91, 96, 100])]
    sfx("vaga_lume", mix(0.85, *twinkle), -6)

    # Dancinha: 4 s a 120 batidas por minuto, como a dança do Robo (bumbo, palma, baixo e bipes de robô).
    beat = 0.5
    parts = []
    for b in range(8):
        parts.append((envelope(osc(140, 45, 0.15, "sine"), 0.001, 0.05), b * beat, 0.9))
        if b % 2 == 1:
            parts.append((envelope(highpass(noise(0.12), 1200), 0.001, 0.04), b * beat, 0.35))
        bass_note = [45, 45, 48, 50][b % 4]
        parts.append((lowpass(envelope(osc(midi(bass_note), midi(bass_note), 0.4, "saw"), 0.005, 0.18), 900), b * beat, 0.35))
    for k, m in enumerate([76, None, 79, 76, 81, 79, 76, None, 76, None, 79, 81, 84, 81, 79, 76]):
        if m:
            parts.append((beep(midi(m), 0.18), k * beat / 2, 0.22))
    sfx("faisca_danca", mix(4.1, *parts), -7)


def make_neve():
    """Sons da 3-1 Pico Gelado (2026-10-30): o sino que a bola de neve toca e o gelo que racha (o cubo do pinguim
    derretendo, a cachoeira congelando, a porta do cume)."""
    random.seed(31)
    # Sino: parciais fora da série harmônica (o "dlém" de sino), cada uma caindo num tempo, e a batida do badalo.
    f = midi(79)
    parts = [(envelope(osc(f * r, f * r, 1.6, "sine"), 0.002, d), 0, g) for r, d, g in
             [(1.0, 0.9, 0.9), (2.0, 0.6, 0.45), (2.76, 0.4, 0.35), (5.4, 0.2, 0.2), (8.93, 0.1, 0.12)]]
    parts.append((envelope(highpass(noise(0.02), 3000), 0.001, 0.008), 0, 0.3))
    sfx("sino", mix(1.6, *parts), -6)
    # Gelo: estalos agudos espalhados e um brilho de cristal descendo.
    crack = [x if random.random() < 0.12 else 0.0 for x in highpass(noise(0.45), 2500)]
    tinkle = [(envelope(osc(midi(m), midi(m), 0.3, "sine"), 0.002, 0.1), i * 0.05, 0.35) for i, m in enumerate([100, 96, 93, 88])]
    sfx("gelo", mix(0.55, (envelope(crack, 0.002, 0.18), 0, 0.8), *tinkle), -8)


def make_fabrica():
    """Sons da 3-2 Fábrica de Blocos (2026-10-31): o martelinho de apito, o tique-taque dos blocos-pisca e o pistão."""
    random.seed(32)
    # Martelinho de apito: a pancada surda embaixo e o "piu-piu" do apito de plástico (dois chiados agudos que sobem).
    thud = envelope(osc(150, 48, 0.22, "sine"), 0.001, 0.07)
    knock = envelope(lowpass(noise(0.08), 1800), 0.001, 0.025)
    piu = [(envelope(osc(1900, 2700, 0.09, "tri", vibrato=0.04, vib_rate=40), 0.004, 0.05, 0.4, 0.02), t, 0.3) for t in (0.02, 0.13)]
    sfx("martelo", mix(0.34, (thud, 0, 1.0), (knock, 0, 0.5), *piu), -4)
    # Tique: o clique seco de relógio de fábrica (madeira e metal), curtinho.
    clic = envelope(highpass(noise(0.03), 2000), 0.0005, 0.008)
    tok = envelope(osc(1250, 1180, 0.05, "sine"), 0.001, 0.015)
    sfx("tique", mix(0.06, (clic, 0, 0.8), (tok, 0, 0.6)), -12)
    # Pistão: o chiado do ar subindo e o "tchunc" do fim.
    chiado = sweep_lowpass(envelope(highpass(noise(0.7), 900), 0.03, 0.5, 0.3, 0.15), 2500, 6000)
    tchunc = envelope(osc(220, 90, 0.15, "square"), 0.001, 0.05)
    sfx("pistao", mix(0.85, (chiado, 0, 0.45), (lowpass(tchunc, 1200), 0.62, 0.9)), -6)


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


def make_faisquinhas():
    """Sons dos Faisquinhas (2026-11-11, item 1 e 2 da lista do Faísca): o "piu-piu!" de robozinho que o Faisquinha
    preso dá para chamar o Faísca (dois bipes subindo, o segundo com uma tremidinha) e o resgate (a bolha já estoura
    com o "estouro"; aqui é o "ê!" de festa: arpejo rápido subindo, com brilho no fim)."""
    random.seed(41)
    chirp = lambda f0, f1, d: lowpass(envelope(osc(f0, f1, d, "tri", vibrato=0.02, vib_rate=30), 0.003, d * 0.6, 0.3, 0.02), 6000)
    sfx("faisquinha_chama", mix(0.36, (chirp(1500, 2100, 0.09), 0, 0.9), (am(chirp(1700, 2800, 0.16), 24, 0.5), 0.13, 0.9)), -7)
    notas = [72, 76, 79, 84, 88]
    parts = [(lowpass(envelope(osc(midi(m), midi(m), 0.16, "square"), 0.002, 0.1, 0.3, 0.02), 4000), i * 0.06, 0.35)
             for i, m in enumerate(notas)]
    parts += [(am(envelope(osc(midi(m), midi(m), 0.5, "sine"), 0.004, 0.3), 16, 0.35), 0.3 + i * 0.05, 0.5)
              for i, m in enumerate([96, 100, 103])]
    sfx("faisquinha_salvo", mix(0.95, *parts), -6)


def make_brindes():
    """Sons das moedas e da Máquina de Brindes (2026-11-11, item 4 da lista do Faísca): a moeda é um "plim-plim" de
    metal (duas notas subindo, com o brilho da parcial aguda); a máquina é a catraca da manivela (estalinhos) e o
    "vrum" do motorzinho subindo, até o "tum" da cápsula caindo."""
    random.seed(44)
    def plim(f, d):
        return mix(d, (envelope(osc(f, f, d, "sine"), 0.001, d * 0.5), 0, 0.8), (envelope(osc(f * 2.76, f * 2.76, d, "sine"), 0.001, d * 0.2), 0, 0.3))
    sfx("moeda", mix(0.3, (plim(midi(88), 0.12), 0, 0.8), (plim(midi(95), 0.22), 0.07, 0.9)), -8)
    clics = [(envelope(highpass(noise(0.02), 2500), 0.0005, 0.008), 0.05 + k * 0.07, 0.5) for k in range(10)]
    motor = sweep_lowpass(envelope(osc(90, 220, 0.8, "saw"), 0.05, 0.5, 0.4, 0.1), 600, 1800)
    tum = envelope(osc(160, 60, 0.2, "sine"), 0.001, 0.08)
    sfx("maquina", mix(1.05, *clics, (motor, 0.0, 0.35), (tum, 0.85, 0.9)), -6)


def make_mundo():
    """Sons do mundo que reage (2026-11-11, item 6 da lista do Faísca): o farfalhar do mato (chiado filtrado que
    sobe e desce, com estalinhos de folha), a caixa de madeira quebrando (o "créc" surdo e as tábuas batendo), o pote
    de barro quebrando (o "plec" seco e os caquinhos tilintando), o presente abrindo (papel rasgando e um brilho de
    sininho subindo) e o passinho na poça (dois "ploc" de gota)."""
    random.seed(61)
    chiado = am(sweep_lowpass(envelope(highpass(noise(0.32), 700), 0.03, 0.2, 0.25, 0.08), 1800, 4200), 22, 0.4)
    folhas = [(envelope(highpass(noise(0.012), 3000), 0.0005, 0.005), random.uniform(0.02, 0.24), 0.3) for _ in range(5)]
    sfx("mato", mix(0.34, (chiado, 0, 0.8), *folhas), -10)
    crec = envelope(lowpass(noise(0.16), 1400), 0.001, 0.06)
    tum = envelope(osc(140, 70, 0.18, "sine"), 0.001, 0.07)
    tabuas = [(envelope(lowpass(osc(f, f * 0.8, 0.09, "tri"), 1600), 0.001, 0.04), t, 0.5)
              for f, t in [(420, 0.07), (330, 0.13), (510, 0.19), (380, 0.26)]]
    sfx("caixa_quebra", mix(0.42, (crec, 0, 0.9), (tum, 0, 0.8), *tabuas), -4)
    plec = envelope(highpass(noise(0.05), 1200), 0.0005, 0.02)
    caquinhos = [(envelope(osc(f, f, 0.12, "sine"), 0.001, 0.05), t, 0.35)
                 for f, t in [(2300, 0.05), (3100, 0.09), (2700, 0.14), (3600, 0.2), (2500, 0.26)]]
    sfx("pote_quebra", mix(0.4, (plec, 0, 1.0), (envelope(osc(260, 180, 0.08, "sine"), 0.001, 0.03), 0, 0.6), *caquinhos), -5)
    rasgo = am(envelope(highpass(noise(0.22), 1500), 0.005, 0.15, 0.3, 0.05), 45, 0.6)
    brilho = [(envelope(osc(midi(m), midi(m), 0.3, "sine"), 0.002, 0.15), 0.12 + i * 0.05, 0.4) for i, m in enumerate([84, 88, 91, 96])]
    sfx("presente_abre", mix(0.55, (rasgo, 0, 0.7), *brilho), -6)
    ploc = lambda f: envelope(osc(f, f * 2.2, 0.06, "sine"), 0.001, 0.03)
    sfx("poca", mix(0.16, (ploc(500), 0, 0.8), (ploc(700), 0.06, 0.5), (envelope(highpass(noise(0.04), 2500), 0.001, 0.015), 0, 0.3)), -12)


# --- música do Faísca por mundo (item 7 da lista do Faísca, 2026-11-11) ------------------
#
# Uma bandinha feita aqui (marimba, cavaquinho, caixinha de música, sininho, flauta, metais, quadrada, baixo, pizzicato,
# pad e bateria macia com palmas, chocalho, guizos e bloquinho) e uma notação curta: a melodia é uma lista de
# "nota:tempos" ("A4:.5", "-:1" é pausa) e os acordes, um nome por compasso ("F", "Dm", "F#m", "E"). Cada faixa repete
# sem emenda (o que passa do fim volta para o começo). As vinhetas não repetem.

_NOTAS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
_cache_notas = {}


def nota_midi(nome):
    """'F#5' -> 78; 'Bb4' -> 70."""
    base = _NOTAS[nome[0]]
    resto = nome[1:]
    while resto and resto[0] in "#b":
        base += 1 if resto[0] == "#" else -1
        resto = resto[1:]
    return 12 * (int(resto) + 1) + base


def acorde(nome, oitava=4):
    """Tríade fechada em volta do dó central: 'Dm' -> [62, 65, 69] (com oitava 4)."""
    menor = nome.endswith("m")
    raiz = nome[:-1] if menor else nome
    r = nota_midi(raiz + str(oitava))
    if r > 12 * (oitava + 1) + 7:
        r -= 12
    return [r, r + (3 if menor else 4), r + 7]


def instrumento(nome, m, dur):
    """Uma nota do instrumento `nome` (midi `m`, `dur` segundos), guardada para reaproveitar."""
    chave = (nome, m, round(dur, 3))
    if chave in _cache_notas:
        return _cache_notas[chave]
    f = midi(m)
    if nome == "marimba":
        d = dur + 0.25
        sig = mix(d, (envelope(osc(f, f, d, "sine"), 0.002, 0.22), 0, 0.85), (envelope(osc(f * 3.93, f * 3.93, 0.12, "sine"), 0.001, 0.025), 0, 0.3),
                  (envelope(osc(f * 2, f * 2, d, "sine"), 0.002, 0.08), 0, 0.2))
    elif nome == "cavaquinho":
        d = dur + 0.15
        sig = mix(d, (lowpass(envelope(osc(f, f, d, "tri"), 0.002, 0.16), 3500), 0, 0.8), (envelope(osc(f * 2, f * 2, d, "sine"), 0.001, 0.06), 0, 0.3))
    elif nome == "caixinha":
        d = dur + 0.6
        sig = mix(d, (envelope(osc(f, f, d, "sine"), 0.001, 0.55), 0, 0.8), (envelope(osc(f * 3, f * 3, d, "sine"), 0.001, 0.14), 0, 0.3),
                  (envelope(osc(f * 5.4, f * 5.4, 0.2, "sine"), 0.001, 0.04), 0, 0.15))
    elif nome == "sino":
        d = dur + 0.9
        sig = mix(d, (envelope(osc(f, f, d, "sine"), 0.001, 0.7), 0, 0.8), (envelope(osc(f * 2.76, f * 2.76, d, "sine"), 0.001, 0.22), 0, 0.3),
                  (envelope(osc(f * 5.4, f * 5.4, 0.3, "sine"), 0.001, 0.06), 0, 0.12))
    elif nome == "flauta":
        d = dur + 0.08
        corpo = mix(d, (osc(f, f, d, "sine", vibrato=0.006, vib_rate=5.0), 0, 0.85), (osc(f, f, d, "tri"), 0, 0.12))
        sopro = envelope(highpass(noise(0.08), 2500), 0.01, 0.04)
        sig = mix(d, (envelope(corpo, 0.04, 0.4, 0.75, 0.08), 0, 1.0), (sopro, 0, 0.06))
    elif nome == "metais":
        d = dur + 0.1
        corpo = lowpass(mix(d, (osc(f, f, d, "saw", vibrato=0.004, vib_rate=5.5), 0, 0.6), (osc(f, f, d, "sine"), 0, 0.5)), 2200)
        sig = envelope(corpo, 0.03, 0.5, 0.8, 0.1)
    elif nome == "quadrada":
        d = dur + 0.05
        sig = envelope(lowpass(osc(f, f, d, "square"), 2600), 0.004, 0.25, 0.5, 0.05)
    elif nome == "baixo":
        d = dur
        sig = envelope(lowpass(osc(f, f, d, "tri"), 900), 0.005, 0.3, 0.45, 0.05)
    elif nome == "pizz":
        d = dur + 0.1
        sig = envelope(lowpass(osc(f, f, d, "tri"), 1200), 0.002, 0.12)
    elif nome == "pad":
        d = dur + 0.3
        sig = lowpass(mix(d, (osc(f, f, d, "tri"), 0, 0.4), (osc(f * 1.004, f * 1.004, d, "sine"), 0, 0.4)), 1600)
        sig = envelope(sig, 0.3, 1.0, 0.85, 0.3)
    else:
        raise ValueError(nome)
    _cache_notas[chave] = sig
    return sig


def bateria(nome):
    """Uma batida da bateria macia."""
    chave = ("bateria", nome)
    if chave in _cache_notas:
        return _cache_notas[chave]
    if nome == "bumbo":
        sig = envelope(osc(150, 45, 0.18, "sine"), 0.001, 0.07)
    elif nome == "caixa":
        sig = envelope(mix(0.16, (highpass(noise(0.16), 900), 0, 0.7), (osc(220, 180, 0.16), 0, 0.3)), 0.001, 0.05)
    elif nome == "palma":
        estalo = lambda: envelope(lowpass(highpass(noise(0.05), 1000), 3200), 0.001, 0.012)
        sig = mix(0.12, (estalo(), 0, 0.6), (estalo(), 0.011, 0.6), (estalo(), 0.022, 0.9))
    elif nome == "chimbal":
        sig = envelope(highpass(noise(0.05), 6500), 0.001, 0.012)
    elif nome == "chocalho":
        sig = envelope(highpass(noise(0.07), 4500), 0.012, 0.025)
    elif nome == "guizos":
        tinidos = [(envelope(osc(fq, fq, 0.15, "sine"), 0.001, 0.05), random.uniform(0, 0.02), 0.2) for fq in (5200, 6100, 7300, 8200)]
        sig = mix(0.16, (envelope(highpass(noise(0.1), 5000), 0.002, 0.03), 0, 0.5), *tinidos)
    elif nome == "bloquinho":
        sig = mix(0.06, (envelope(osc(900, 880, 0.06), 0.001, 0.015), 0, 0.7), (envelope(osc(1350, 1320, 0.06), 0.001, 0.01), 0, 0.4))
    elif nome == "tambor":
        sig = envelope(osc(210, 120, 0.28, "sine"), 0.002, 0.12)
    elif nome == "timpano":
        sig = envelope(mix(0.8, (osc(98, 92, 0.8, "sine"), 0, 0.9), (lowpass(noise(0.8), 300), 0, 0.3)), 0.004, 0.3)
    elif nome == "prato":
        sig = envelope(highpass(noise(1.6), 3500), 0.002, 0.6)
    elif nome == "brilho":
        sig = mix(0.9, *[(envelope(osc(midi(m), midi(m), 0.4, "sine"), 0.001, 0.15), k * 0.06, 0.4) for k, m in enumerate([96, 100, 103, 108])])
    else:
        raise ValueError(nome)
    _cache_notas[chave] = sig
    return sig


class Faixa:
    """Uma música: `compassos` de 4 tempos a `bpm`. Com `repete`, o que passa do fim volta para o começo."""

    def __init__(self, bpm, compassos, repete=True, cauda=0.0):
        self.tempo = 60.0 / bpm
        self.beats = compassos * 4
        self.repete = repete
        self.n = n_samples(self.beats * self.tempo + (0.0 if repete else cauda))
        self.out = [0.0] * self.n

    def por(self, sig, beat, g):
        s = n_samples(beat * self.tempo)
        out = self.out
        n = self.n
        if self.repete:
            for i, x in enumerate(sig):
                out[(s + i) % n] += x * g
        else:
            for i, x in enumerate(sig[: max(n - s, 0)]):
                out[s + i] += x * g

    def melodia(self, instr, texto, g, comeco=0.0, oitava=0):
        b = comeco
        for parte in texto.split():
            nome, tempos = parte.split(":")
            t = float(tempos)
            if nome != "-":
                self.por(instrumento(instr, nota_midi(nome) + 12 * oitava, t * self.tempo), b, g)
            b += t

    def acordes(self, instr, nomes, ritmo, g, oitava=4):
        """`ritmo`: lista de (tempo no compasso, duração em tempos, quais notas do acorde: 'todas', 0, 1, 2 ou 'oitava')."""
        for c, nome in enumerate(nomes):
            notas = acorde(nome, oitava)
            for b, d, quais in ritmo:
                if quais == "todas":
                    escolhidas = notas
                elif quais == "oitava":
                    escolhidas = [notas[0] + 12]
                else:
                    escolhidas = [notas[quais]]
                for m in escolhidas:
                    self.por(instrumento(instr, m, d * self.tempo), c * 4 + b, g / (len(escolhidas) ** 0.5))

    def baixo(self, instr, nomes, ritmo, g, oitava=3):
        """`ritmo`: (tempo, duração, 'raiz' | 'quinta' | 'oitava'). Na oitava 3 a raiz fica entre sol#2 e sol3 (de 104 a
        196 Hz): mais grave que isso some na caixinha de som da TV."""
        for c, nome in enumerate(nomes):
            r = acorde(nome, oitava)[0]
            for b, d, qual in ritmo:
                m = r + {"raiz": 0, "quinta": 7, "oitava": 12}[qual]
                self.por(instrumento(instr, m, d * self.tempo), c * 4 + b, g)

    def batida(self, nome, tempos_no_compasso, g, compassos=None):
        for c in (compassos if compassos is not None else range(self.beats // 4)):
            for b in tempos_no_compasso:
                self.por(bateria(nome), c * 4 + b, g)

    def salvar(self, nome, pico=-6.0):
        save(f"musica/{nome}.wav", normalize(lowpass(self.out, 10000), pico) if self.repete else fade_edges(normalize(self.out, pico), 30))


def make_momentos():
    """Sons dos momentos especiais das fases (item 9 da lista do Faísca, 2026-11-11). O "rolar" é o ronco da Bolota
    gigante descendo a Ponte Fofa: um rumor grave que repete sem emenda (o tamanho fecha os ciclos), com uns
    "tum" de quique. A "enchente" é a água correndo na cozinha alagando da 2-1."""
    random.seed(90)
    dur = 1.0
    ronco = sweep_lowpass(noise(dur), 180, 260)
    ronco = am(ronco, 6, 0.35)
    tum = [(envelope(osc(70, 50, 0.18, "sine"), 0.002, 0.07), t, 0.5) for t in (0.0, 0.5)]
    sfx_loop("rolar", mix(dur, (ronco, 0, 1.0), *tum), -4)
    # A enchente da 2-1 (a cozinha alagando): a água correndo, um chiado no meio do agudo que balança devagar, com
    # bolhinhas (assobios curtos subindo) espalhadas. Repete sem emenda, como o "rolar".
    dur = 2.0
    agua = lowpass(highpass(noise(dur), 500), 2600)
    agua = am(agua, 1.5, 0.3)
    fundo = am(sweep_lowpass(noise(dur), 220, 320), 0.5, 0.2)
    bolhas = [(envelope(osc(random.uniform(500, 900), random.uniform(1100, 1700), 0.07, "sine"), 0.003, 0.05), random.uniform(0.0, dur - 0.1), 0.22) for _ in range(14)]
    sfx_loop("enchente", mix(dur, (agua, 0, 0.7), (fundo, 0, 0.8), *bolhas), -5)


def make_musica_faisca():
    """Os temas do Faísca (item 7 da lista do Faísca, 2026-11-11): um por mundo, o do farol e o dos chefes, e as duas
    vinhetas (o Faisquinha resgatado e a Estrela Grande)."""
    random.seed(70)
    oito = [0, .5, 1, 1.5, 2, 2.5, 3, 3.5]

    # Mundo 1, Ilhas Fofas (1-1 e 1-2): fá maior, saltitante, marimba na melodia, cavaquinho no contratempo, palmas.
    f = Faixa(124, 16)
    acordes = ["F", "C", "Dm", "Bb", "F", "C", "Bb", "C", "Dm", "Bb", "F", "C", "Dm", "Bb", "C", "C"]
    f.melodia("marimba", "A4:.5 C5:.5 F5:1 E5:.5 D5:.5 C5:1  G4:.5 C5:.5 E5:1 D5:.5 C5:.5 G4:1  "
              "A4:.5 D5:.5 F5:1 E5:.5 F5:.5 A5:1  G5:1.5 F5:.5 D5:2  "
              "A4:.5 C5:.5 F5:1 G5:.5 A5:.5 F5:1  E5:.5 G5:.5 C6:1 Bb5:.5 G5:.5 E5:1  "
              "D5:.5 F5:.5 Bb5:1 A5:.5 G5:.5 F5:1  E5:1 G5:1 C5:2  "
              "D5:1 -:.5 F5:.5 A5:1 G5:1  F5:1 -:.5 D5:.5 F5:1 Bb4:1  C5:.5 D5:.5 F5:.5 A5:.5 C6:1 A5:1  G5:2 E5:1 C5:1  "
              "D5:.5 E5:.5 F5:.5 A5:.5 D6:1 C6:1  Bb5:.5 A5:.5 G5:.5 F5:.5 D5:2  E5:.5 F5:.5 G5:.5 A5:.5 Bb5:1 G5:1  "
              "C6:1 Bb5:.5 G5:.5 E5:1 C5:1", 0.34)
    f.melodia("sino", "-:32 D6:4 D6:4 C6:4 C6:4 F6:4 D6:4 E6:4 C6:4", 0.1)
    f.acordes("cavaquinho", acordes, [(.5, .4, "todas"), (1.5, .4, "todas"), (2.5, .4, "todas"), (3.5, .4, "todas")], 0.16)
    f.baixo("baixo", acordes, [(0, 1.4, "raiz"), (1.5, .5, "raiz"), (2, 1.4, "quinta"), (3.5, .5, "oitava")], 0.3)
    f.batida("bumbo", [0, 2], 0.42)
    f.batida("palma", [1, 3], 0.2)
    f.batida("chocalho", oito, 0.06)
    f.salvar("mundo_1")

    # Mundo 2, Doces e Brinquedos (2-1, 2-2 e 2-3): sol maior, de brinquedo de corda: caixinha de música picadinha,
    # "oompa" no pizzicato, bloquinho no contratempo.
    f = Faixa(132, 16)
    acordes = ["G", "Em", "C", "D", "G", "Em", "C", "D", "C", "D", "Bm", "Em", "Am", "D", "G", "D"]
    f.melodia("caixinha", "G5:.5 -:.5 B5:.5 -:.5 D6:.5 B5:.5 G5:1  E5:.5 -:.5 G5:.5 -:.5 B5:.5 G5:.5 E5:1  "
              "C5:.5 E5:.5 G5:.5 C6:.5 B5:.5 A5:.5 G5:1  A5:.5 F#5:.5 D5:.5 F#5:.5 A5:2  "
              "B5:.5 -:.5 D6:.5 -:.5 G6:.5 F#6:.5 E6:.5 D6:.5  E6:.5 D6:.5 B5:.5 G5:.5 E5:1 G5:1  "
              "C6:.5 B5:.5 A5:.5 G5:.5 E5:.5 G5:.5 C6:1  D6:1 F#5:.5 A5:.5 D5:2  "
              "E5:.5 G5:.5 C6:.5 G5:.5 E6:1 D6:1  F#5:.5 A5:.5 D6:.5 A5:.5 F#6:1 E6:1  D6:.5 B5:.5 F#5:.5 B5:.5 D6:1 B5:1  "
              "G5:.5 B5:.5 E6:.5 B5:.5 G5:2  A5:.5 C6:.5 E6:.5 C6:.5 A5:1 C6:1  F#6:.5 E6:.5 D6:.5 C6:.5 A5:1 F#5:1  "
              "G5:.5 B5:.5 D6:.5 G6:.5 -:1 D6:1  C6:.5 B5:.5 A5:.5 F#5:.5 D5:1 -:1", 0.36)
    f.acordes("sino", acordes, [(1, .4, "todas"), (3, .4, "todas")], 0.12, oitava=5)
    f.baixo("pizz", acordes, [(0, .5, "raiz"), (1, .5, "quinta"), (2, .5, "raiz"), (3, .5, "quinta")], 0.36)
    f.batida("bumbo", [0, 2], 0.36)
    f.batida("palma", [1, 3], 0.14)
    f.batida("bloquinho", [.5, 1.5, 2.5, 3.5], 0.12)
    f.salvar("mundo_2")

    # Mundo 3, Frio e Vento (3-1 e 3-2): ré maior, mais calmo, sininho na melodia, flauta no fundo, guizos de trenó.
    f = Faixa(108, 16)
    acordes = ["D", "Bm", "G", "A", "D", "Bm", "G", "A", "G", "A", "F#m", "Bm", "G", "A", "D", "A"]
    f.melodia("sino", "F#5:1 A5:1 D6:1.5 C#6:.5  B5:1 F#5:1 D5:2  G5:1 B5:1 D6:1 E6:1  C#6:1.5 B5:.5 A5:2  "
              "F#5:.5 G5:.5 A5:1 D6:1 F#6:1  E6:1 D6:.5 C#6:.5 B5:2  B5:.5 C#6:.5 D6:1 G6:1 F#6:.5 E6:.5  E6:2 C#6:1 A5:1  "
              "D6:1.5 B5:.5 G5:2  E6:1.5 C#6:.5 A5:2  F#6:1 E6:.5 C#6:.5 A5:1 C#6:1  D6:2 B5:2  "
              "G5:.5 B5:.5 D6:.5 G6:.5 F#6:1 E6:1  E6:.5 F#6:.5 E6:.5 C#6:.5 A5:2  D6:1 F#6:1 A6:1 F#6:1  E6:2 C#6:1 A5:1", 0.3)
    f.acordes("flauta", acordes, [(0, 3.9, "todas")], 0.09)
    f.acordes("caixinha", acordes, [(0, 1, 0), (1, 1, 1), (2, 1, 2), (3, 1, "oitava")], 0.07, oitava=4)
    f.baixo("baixo", acordes, [(0, 2, "raiz"), (2, 2, "quinta")], 0.28)
    f.batida("bumbo", [0], 0.32)
    f.batida("guizos", oito, 0.09)
    f.batida("guizos", [0, 1, 2, 3], 0.08)
    f.salvar("mundo_3")

    # O farol (o hub): dó maior, devagar, de ninar: caixinha em arpejo, pad e flauta, sem bateria.
    f = Faixa(88, 8)
    acordes = ["C", "Am", "F", "G", "C", "Em", "F", "G"]
    f.melodia("flauta", "E5:1.5 D5:.5 C5:1 G5:1  A5:1.5 G5:.5 E5:2  F5:1 A5:1 C6:1 A5:1  G5:3 -:1  "
              "E5:1 G5:1 C6:1.5 B5:.5  B5:1.5 G5:.5 E5:2  A5:1 G5:1 F5:1 A5:1  G5:2 D5:1 B4:1", 0.3)
    f.acordes("caixinha", acordes, [(0, .5, 0), (.5, .5, 1), (1, .5, 2), (1.5, .5, "oitava"), (2, .5, 2), (2.5, .5, 1), (3, .5, 0), (3.5, .5, 1)],
              0.1, oitava=5)
    f.acordes("pad", acordes, [(0, 4, "todas")], 0.1)
    f.baixo("baixo", acordes, [(0, 3.8, "raiz")], 0.2)
    f.salvar("farol")

    # Os chefes: lá menor, agitado sem assustar: baixo em colcheias, a quadrada na melodia, tambores no fim.
    f = Faixa(144, 8)
    acordes = ["Am", "F", "C", "G", "Am", "F", "G", "E"]
    f.melodia("quadrada", "A4:.5 C5:.5 E5:.5 A5:.5 G5:.5 E5:.5 C5:.5 E5:.5  F5:1 A5:.5 F5:.5 C6:1 A5:1  "
              "G5:.5 E5:.5 C5:.5 E5:.5 G5:1 C6:1  B5:1 D6:.5 B5:.5 G5:2  "
              "A5:.5 A5:.5 C6:.5 A5:.5 E6:1 D6:1  C6:.5 A5:.5 F5:.5 A5:.5 C6:1 F6:1  "
              "E6:.5 D6:.5 B5:.5 G5:.5 D6:1 B5:1  G#5:1 B5:1 E6:1 G#5:1", 0.22)
    f.acordes("metais", acordes, [(0, 1.5, "todas"), (2.5, 1, "todas")], 0.08)
    f.baixo("baixo", acordes, [(b, .45, "raiz" if k % 2 == 0 else "oitava") for k, b in enumerate(oito)], 0.3)
    f.batida("bumbo", [0, 1, 2, 3], 0.4)
    f.batida("palma", [1, 3], 0.2)
    f.batida("chimbal", oito, 0.08)
    f.batida("tambor", [2, 2.5, 3, 3.5], 0.3, compassos=[7])
    f.salvar("chefe")

    # Vinheta do Faisquinha resgatado: arpejo subindo no sininho e na marimba, o acorde e o brilho.
    f = Faixa(150, 1, repete=False, cauda=1.6)
    f.melodia("sino", "G5:.25 C6:.25 E6:.25 G6:.25 E6:.5 G6:.5 C7:2", 0.4)
    f.melodia("marimba", "G4:.25 C5:.25 E5:.25 G5:.25 E5:.5 G5:.5 C6:2", 0.3)
    f.acordes("pad", ["C"], [(2, 2, "todas")], 0.2, oitava=4)
    f.por(bateria("brilho"), 2.0, 0.5)
    f.salvar("vinheta_faisquinha", -4.0)

    # Vinheta da Estrela Grande: a fanfarra dos metais com o tímpano, o acorde grande, o prato e o brilho.
    f = Faixa(120, 2, repete=False, cauda=2.4)
    f.melodia("metais", "G4:.5 G4:.25 G4:.25 C5:1 E5:.5 E5:.25 E5:.25 G5:1 C6:3", 0.32)
    f.melodia("sino", "-:4 C6:1 E6:1 G6:1 C7:1", 0.18)
    f.acordes("metais", ["C"], [(4, 3, "todas")], 0.2, oitava=4)
    for b in (0, 2, 4):
        f.por(bateria("timpano"), b, 0.45)
    f.por(bateria("prato"), 4, 0.3)
    f.por(bateria("brilho"), 4.5, 0.4)
    f.salvar("vinheta_estrela", -4.0)


if __name__ == "__main__":
    import sys
    # Com nomes (python3 tools/gerar_sons.py faisquinhas), gera só esses grupos e não mexe nos outros arquivos.
    grupos = {"sfx": make_sfx, "musica": make_music, "faisca": make_faisca, "neve": make_neve, "fabrica": make_fabrica,
              "faisquinhas": make_faisquinhas, "brindes": make_brindes, "mundo": make_mundo,
              "musica_faisca": make_musica_faisca, "momentos": make_momentos}
    for nome in (sys.argv[1:] or list(grupos)):
        grupos[nome]()
