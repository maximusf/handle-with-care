"""Generates the game's chiptune music loop and extra sound effects.

Everything here is synthesized from scratch (square, triangle and noise waves),
so there are no outside audio files to license or credit.

Usage (from the project root, needs numpy and ffmpeg):
    python3 docs/audio-src/gen_audio.py
Writes .ogg files into assets/music/ and assets/sfx/ (UISFX, PlayerSFX, PackageSFX).
"""

import os
import subprocess
import tempfile
import wave

import numpy as np

SAMPLE_RATE = 44100
MUSIC_DIR = "assets/music"
SFX_DIR = "assets/sfx/UISFX"
PLAYER_SFX_DIR = "assets/sfx/PlayerSFX"
PACKAGE_SFX_DIR = "assets/sfx/PackageSFX"


# ---------------------------------------------------------------- waves

def midi_to_hz(note):
    return 440.0 * 2 ** ((note - 69) / 12)


def square_wave(freq, seconds, duty=0.25):
    t = np.arange(int(seconds * SAMPLE_RATE)) / SAMPLE_RATE
    return np.where((t * freq) % 1.0 < duty, 1.0, -1.0)


def triangle_wave(freq, seconds):
    t = np.arange(int(seconds * SAMPLE_RATE)) / SAMPLE_RATE
    return 2.0 * np.abs(2.0 * ((t * freq) % 1.0) - 1.0) - 1.0


def noise(seconds, seed=0):
    rng = np.random.default_rng(seed)
    return rng.uniform(-1.0, 1.0, int(seconds * SAMPLE_RATE))


def envelope(samples, attack=0.005, release=0.04):
    """Fade in and out so notes don't click."""
    count = len(samples)
    env = np.ones(count)
    attack_len = min(int(attack * SAMPLE_RATE), count)
    release_len = min(int(release * SAMPLE_RATE), count)
    if attack_len:
        env[:attack_len] = np.linspace(0, 1, attack_len)
    if release_len:
        env[-release_len:] *= np.linspace(1, 0, release_len)
    return samples * env


def decay(samples, speed):
    """Plucky volume drop-off, speed = how fast it fades."""
    t = np.arange(len(samples)) / SAMPLE_RATE
    return samples * np.exp(-t * speed)


def soften(samples, width):
    """Simple low-pass filter (moving average). Bigger width = duller, more muffled."""
    kernel = np.ones(width) / width
    return np.convolve(samples, kernel, mode="same")


def sweep(start_hz, end_hz, seconds, duty=0.5):
    """Square wave whose pitch slides from start_hz to end_hz."""
    count = int(seconds * SAMPLE_RATE)
    freqs = np.linspace(start_hz, end_hz, count)
    phase = np.cumsum(freqs) / SAMPLE_RATE
    return np.where(phase % 1.0 < duty, 1.0, -1.0)


def thump(start_hz, end_hz, seconds, speed):
    """Low sine 'boom' that drops in pitch, like a kick drum."""
    t = np.arange(int(seconds * SAMPLE_RATE)) / SAMPLE_RATE
    freqs = end_hz + (start_hz - end_hz) * np.exp(-t * speed)
    phase = np.cumsum(freqs) / SAMPLE_RATE
    return np.sin(2 * np.pi * phase) * np.exp(-t * speed * 0.6)


def add_at(track, samples, start_seconds, volume):
    start = int(start_seconds * SAMPLE_RATE)
    end = min(start + len(samples), len(track))
    track[start:end] += samples[: end - start] * volume


def save_ogg(samples, path):
    peak = np.max(np.abs(samples))
    if peak > 0:
        samples = samples / peak * 0.9
    pcm = (samples * 32767).astype(np.int16)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav_path = tmp.name
    with wave.open(wav_path, "wb") as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        wav_file.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-c:a", "libvorbis", "-q:a", "5", path], check=True)
    os.remove(wav_path)
    print("wrote", path, f"{len(samples) / SAMPLE_RATE:.2f}s")


# ---------------------------------------------------------------- music
# Chords: one per bar, as (bass root note, chord notes) in MIDI numbers (60 = middle C).
# Melody: (bar, beat, MIDI note, length in beats).

# Level music: bouncy hotel-lobby loop. C - Am - F - G, then a variation.
LEVEL_BPM = 124
LEVEL_CHORDS = [
    (48, [60, 64, 67]), (45, [57, 60, 64]), (41, [57, 60, 65]), (43, [55, 59, 62]),
    (48, [60, 64, 67]), (45, [57, 60, 64]), (41, [57, 60, 65]), (43, [55, 59, 62]),
    (41, [57, 60, 65]), (43, [55, 59, 62]), (40, [55, 59, 64]), (45, [57, 60, 64]),
    (41, [57, 60, 65]), (43, [55, 59, 62]), (48, [60, 64, 67]), (43, [55, 59, 62]),
]
LEVEL_MELODY = [
    # A: bouncy hook
    (0, 0, 72, 0.5), (0, 0.5, 76, 0.5), (0, 1, 79, 1), (0, 2.5, 76, 0.5), (0, 3, 74, 1),
    (1, 0, 72, 0.5), (1, 0.5, 69, 0.5), (1, 1, 72, 1.5), (1, 3, 76, 1),
    (2, 0, 77, 0.5), (2, 0.5, 76, 0.5), (2, 1, 74, 1), (2, 2, 72, 1), (2, 3, 69, 1),
    (3, 0, 71, 1.5), (3, 1.5, 74, 0.5), (3, 2, 79, 2),
    (4, 0, 72, 0.5), (4, 0.5, 76, 0.5), (4, 1, 79, 1), (4, 2.5, 81, 0.5), (4, 3, 79, 1),
    (5, 0, 76, 0.5), (5, 0.5, 72, 0.5), (5, 1, 76, 1.5), (5, 3, 79, 1),
    (6, 0, 81, 1), (6, 1, 79, 0.5), (6, 1.5, 77, 0.5), (6, 2, 76, 1), (6, 3, 74, 1),
    (7, 0, 74, 1), (7, 1, 76, 0.5), (7, 1.5, 74, 0.5), (7, 2, 72, 2),
    # B: answering phrase, a little higher
    (8, 0, 81, 1), (8, 1, 77, 1), (8, 2, 81, 0.5), (8, 2.5, 84, 1.5),
    (9, 0, 83, 1), (9, 1, 79, 1), (9, 2, 74, 2),
    (10, 0, 79, 0.5), (10, 0.5, 83, 0.5), (10, 1, 86, 1), (10, 2, 83, 1), (10, 3, 79, 1),
    (11, 0, 81, 1.5), (11, 1.5, 76, 0.5), (11, 2, 72, 2),
    (12, 0, 77, 0.5), (12, 0.5, 81, 0.5), (12, 1, 84, 1), (12, 2, 81, 1), (12, 3, 77, 1),
    (13, 0, 79, 1), (13, 1, 83, 1), (13, 2, 86, 2),
    (14, 0, 84, 0.5), (14, 0.5, 79, 0.5), (14, 1, 76, 1), (14, 2, 72, 1), (14, 3, 76, 1),
    (15, 0, 74, 1), (15, 1, 71, 1), (15, 2, 67, 1), (15, 3, 71, 1),
]

# Title music: calmer and slower, gently arpeggiated, no drums. Cmaj7 - Am7 - Fmaj7 - G.
TITLE_BPM = 92
TITLE_CHORDS = [
    (48, [60, 64, 67, 71]), (45, [57, 60, 64, 67]), (41, [57, 60, 64, 65]), (43, [55, 59, 62, 65]),
    (48, [60, 64, 67, 71]), (45, [57, 60, 64, 67]), (41, [57, 60, 64, 65]), (43, [55, 59, 62, 67]),
    (41, [57, 60, 64, 65]), (40, [55, 59, 64, 67]), (45, [57, 60, 64, 67]), (38, [57, 60, 62, 65]),
    (41, [57, 60, 64, 65]), (43, [55, 59, 62, 65]), (48, [60, 64, 67, 71]), (43, [55, 59, 62, 67]),
]
TITLE_MELODY = [
    (0, 0, 76, 1.5), (0, 1.5, 74, 0.5), (0, 2, 72, 2),
    (1, 0, 76, 1), (1, 1, 79, 1), (1, 2, 76, 2),
    (2, 0, 77, 1.5), (2, 1.5, 76, 0.5), (2, 2, 72, 1), (2, 3, 69, 1),
    (3, 0, 71, 3), (3, 3, 74, 1),
    (4, 0, 76, 1.5), (4, 1.5, 74, 0.5), (4, 2, 72, 2),
    (5, 0, 76, 1), (5, 1, 79, 1), (5, 2, 84, 2),
    (6, 0, 81, 1.5), (6, 1.5, 79, 0.5), (6, 2, 77, 1), (6, 3, 76, 1),
    (7, 0, 74, 4),
    (8, 0, 72, 1), (8, 1, 77, 1), (8, 2, 81, 2),
    (9, 0, 79, 1.5), (9, 1.5, 76, 0.5), (9, 2, 71, 2),
    (10, 0, 72, 1), (10, 1, 76, 1), (10, 2, 79, 1), (10, 3, 76, 1),
    (11, 0, 77, 3), (11, 3, 74, 1),
    (12, 0, 72, 1), (12, 1, 77, 1), (12, 2, 81, 1.5), (12, 3.5, 79, 0.5),
    (13, 0, 79, 2), (13, 2, 77, 1), (13, 3, 74, 1),
    (14, 0, 76, 4),
    (15, 0, 74, 2), (15, 2, 71, 2),
]


def make_song(path, bpm, chords, melody, calm):
    """Builds a seamless loop. calm=True: soft arpeggios and a triangle lead, no drums."""
    beat = 60.0 / bpm
    bar = beat * 4
    length = bar * len(chords)
    track = np.zeros(int(length * SAMPLE_RATE) + 2 * SAMPLE_RATE)  # spare room, folded back below

    for bar_number, (root, chord) in enumerate(chords):
        bar_start = bar_number * bar
        if calm:
            # Bass: long root notes on beats 1 and 3.
            for beat_number in [0, 2]:
                bass = envelope(triangle_wave(midi_to_hz(root), beat * 1.9), release=0.2)
                add_at(track, bass, bar_start + beat_number * beat, 0.35)
            # Chords: broken up into a gentle eighth-note arpeggio.
            pattern = chord + chord[-2:0:-1]
            for step in range(8):
                note = pattern[step % len(pattern)] + 12
                pluck = decay(envelope(triangle_wave(midi_to_hz(note), beat * 0.9)), 4)
                add_at(track, pluck, bar_start + step * beat / 2, 0.10)
        else:
            # Bass: root and fifth, walking on each beat.
            for beat_number, note in enumerate([root, root + 7, root + 12, root + 7]):
                add_at(track, envelope(triangle_wave(midi_to_hz(note), beat * 0.9)), bar_start + beat_number * beat, 0.35)
            # Chords: short soft stabs on the off-beats.
            for off_beat in [0.5, 1.5, 2.5, 3.5]:
                for note in chord:
                    stab = decay(envelope(square_wave(midi_to_hz(note), beat * 0.4, duty=0.5)), 12)
                    add_at(track, stab, bar_start + off_beat * beat, 0.05)
            # Drums: kick on 1 and 3, hi-hat on every off-beat.
            for beat_number in [0, 2]:
                kick_t = np.arange(int(0.15 * SAMPLE_RATE)) / SAMPLE_RATE
                kick = np.sin(2 * np.pi * (60 + 90 * np.exp(-kick_t * 30)) * kick_t) * np.exp(-kick_t * 25)
                add_at(track, kick, bar_start + beat_number * beat, 0.5)
            for off_beat in [0.5, 1.5, 2.5, 3.5]:
                hat = decay(noise(0.05, seed=bar_number * 10 + int(off_beat * 2)), 80)
                add_at(track, hat, bar_start + off_beat * beat, 0.08)

    for bar_number, beat_number, note, beats in melody:
        if calm:
            lead = decay(envelope(triangle_wave(midi_to_hz(note), beats * beat * 0.95), release=0.1), 0.8)
            add_at(track, lead, bar_number * bar + beat_number * beat, 0.22)
        else:
            lead = decay(envelope(square_wave(midi_to_hz(note), beats * beat * 0.92, duty=0.25), release=0.03), 2.0)
            add_at(track, lead, bar_number * bar + beat_number * beat, 0.16)

    # Fold anything that rang past the end back onto the start, so the loop is seamless.
    loop_samples = int(length * SAMPLE_RATE)
    overflow = track[loop_samples:]
    track = track[:loop_samples]
    track[: len(overflow)] += overflow
    save_ogg(track, path)


# ---------------------------------------------------------------- sound effects

def make_ui_click():
    t = np.arange(int(0.05 * SAMPLE_RATE)) / SAMPLE_RATE
    freq = 1100 - 500 * (t / t[-1])
    click = np.where((np.cumsum(freq) / SAMPLE_RATE) % 1.0 < 0.5, 1.0, -1.0)
    save_ogg(envelope(decay(click, 40), release=0.01), os.path.join(SFX_DIR, "ui_click.ogg"))


def make_text_blip():
    blip = envelope(square_wave(midi_to_hz(81), 0.035, duty=0.5), release=0.01)
    save_ogg(blip, os.path.join(SFX_DIR, "text_blip.ogg"))


def make_arpeggio(notes, step, hold, path, duty=0.25):
    total = step * (len(notes) - 1) + hold
    track = np.zeros(int(total * SAMPLE_RATE) + 1)
    for i, note in enumerate(notes):
        length = hold if i == len(notes) - 1 else step * 1.5
        tone = decay(envelope(square_wave(midi_to_hz(note), length, duty)), 3.0)
        add_at(track, tone, i * step, 0.5)
    save_ogg(envelope(track, release=0.08), path)


def make_lose_jingle():
    notes = [67, 66, 65, 64]
    step = 0.32
    track = np.zeros(int((step * 3 + 1.2) * SAMPLE_RATE))
    for i, note in enumerate(notes):
        length = 1.2 if i == 3 else step * 1.1
        t = np.arange(int(length * SAMPLE_RATE)) / SAMPLE_RATE
        wobble = 1 + 0.012 * np.sin(2 * np.pi * 6 * t) * (i == 3)  # sad vibrato on the last note
        phase = np.cumsum(midi_to_hz(note) * wobble) / SAMPLE_RATE
        tone = np.where(phase % 1.0 < 0.5, 1.0, -1.0)
        add_at(track, decay(envelope(tone), 1.5), i * step, 0.5)
    save_ogg(envelope(track, release=0.2), os.path.join(SFX_DIR, "lose_jingle.ogg"))


# ---------------------------------------------------------------- gameplay sound effects
# Replacements for the old placeholder sounds, so every sound in the game is original.

def make_footstep():
    tap = decay(soften(noise(0.08, seed=1), 12), 60) * 0.6 + thump(140, 80, 0.08, 40) * 0.6
    save_ogg(envelope(tap, attack=0.001, release=0.01), os.path.join(PLAYER_SFX_DIR, "footstep.ogg"))


def make_jump():
    hop = decay(envelope(sweep(260, 620, 0.16, duty=0.5), release=0.03), 6)
    save_ogg(hop, os.path.join(PLAYER_SFX_DIR, "jump.ogg"))


def make_kick():
    boom = thump(220, 55, 0.25, 22)
    snap = decay(soften(noise(0.05, seed=2), 3), 90)
    track = np.zeros(int(0.25 * SAMPLE_RATE))
    add_at(track, boom, 0, 0.9)
    add_at(track, snap, 0, 0.5)
    save_ogg(envelope(track, attack=0.001, release=0.03), os.path.join(PLAYER_SFX_DIR, "kick.ogg"))


def make_charge_tick():
    # The game replays this at higher pitches as the kick charges, so keep it short and plain.
    tick = decay(envelope(square_wave(midi_to_hz(64), 0.12, duty=0.5), release=0.03), 10)
    save_ogg(tick, os.path.join(PLAYER_SFX_DIR, "charge_tick.ogg"))


def make_whoosh_loop():
    # Loops while a package flies, so it has no fade in or out; the volume gently swells instead.
    seconds = 1.0
    t = np.arange(int(seconds * SAMPLE_RATE)) / SAMPLE_RATE
    air = soften(noise(seconds, seed=3), 40)
    swell = 0.7 + 0.3 * np.sin(2 * np.pi * 2 * t)  # two swells per loop, so the loop point matches
    rush = air * swell
    # Blend the end into the start so the loop point has no click.
    blend = int(0.05 * SAMPLE_RATE)
    fade = np.linspace(0, 1, blend)
    rush[:blend] = rush[:blend] * fade + rush[-blend:] * (1 - fade)
    save_ogg(rush[:-blend], os.path.join(PACKAGE_SFX_DIR, "whoosh_loop.ogg"))


def make_land():
    box = thump(120, 60, 0.15, 30) * 0.8 + decay(soften(noise(0.15, seed=4), 20), 50) * 0.5
    save_ogg(envelope(box, attack=0.001, release=0.02), os.path.join(PACKAGE_SFX_DIR, "land.ogg"))


def make_package_break():
    track = np.zeros(int(0.7 * SAMPLE_RATE))
    add_at(track, thump(160, 45, 0.3, 15), 0, 0.8)
    # A few crunchy bursts of noise, like cardboard tearing, then rattling debris.
    for i, start in enumerate([0.0, 0.05, 0.11, 0.2]):
        crunch = decay(soften(noise(0.12, seed=10 + i), 4), 35)
        add_at(track, crunch, start, 0.5 - i * 0.08)
    for i, start in enumerate([0.3, 0.38, 0.47, 0.55]):
        rattle = decay(soften(noise(0.04, seed=20 + i), 2), 120)
        add_at(track, rattle, start, 0.18)
    save_ogg(envelope(track, attack=0.001, release=0.08), os.path.join(PACKAGE_SFX_DIR, "package_break.ogg"))


if __name__ == "__main__":
    make_song(os.path.join(MUSIC_DIR, "hotel_lobby_loop.ogg"), LEVEL_BPM, LEVEL_CHORDS, LEVEL_MELODY, calm=False)
    make_song(os.path.join(MUSIC_DIR, "title_theme_loop.ogg"), TITLE_BPM, TITLE_CHORDS, TITLE_MELODY, calm=True)
    make_ui_click()
    make_text_blip()
    make_arpeggio([72, 76, 79, 84], 0.07, 0.35, os.path.join(SFX_DIR, "delivery_complete.ogg"))
    make_arpeggio([60, 64, 67, 72, 76, 79, 84], 0.09, 0.9, os.path.join(SFX_DIR, "win_jingle.ogg"), duty=0.5)
    make_lose_jingle()
    make_footstep()
    make_jump()
    make_kick()
    make_charge_tick()
    make_whoosh_loop()
    make_land()
    make_package_break()
