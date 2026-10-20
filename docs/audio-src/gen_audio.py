"""Generates the game's chiptune music loop and extra sound effects.

Everything here is synthesized from scratch (square, triangle and noise waves),
so there are no outside audio files to license or credit.

Usage (from the project root, needs numpy and ffmpeg):
    python3 docs/audio-src/gen_audio.py
Writes .ogg files into assets/music/ and assets/sfx/UISFX/.
"""

import os
import subprocess
import tempfile
import wave

import numpy as np

SAMPLE_RATE = 44100
MUSIC_DIR = "assets/music"
SFX_DIR = "assets/sfx/UISFX"


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

BPM = 124
BEAT = 60.0 / BPM
BAR = BEAT * 4

# One chord per bar (root note, chord notes). C - Am - F - G, then a variation.
CHORDS = [
    (48, [60, 64, 67]), (45, [57, 60, 64]), (41, [57, 60, 65]), (43, [55, 59, 62]),
    (48, [60, 64, 67]), (45, [57, 60, 64]), (41, [57, 60, 65]), (43, [55, 59, 62]),
    (41, [57, 60, 65]), (43, [55, 59, 62]), (40, [55, 59, 64]), (45, [57, 60, 64]),
    (41, [57, 60, 65]), (43, [55, 59, 62]), (48, [60, 64, 67]), (43, [55, 59, 62]),
]

# Melody as (bar, beat, midi note, length in beats). None = rest.
MELODY = [
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


def make_music():
    length = BAR * len(CHORDS)
    track = np.zeros(int(length * SAMPLE_RATE) + SAMPLE_RATE)  # spare second, folded back below

    for bar, (root, chord) in enumerate(CHORDS):
        bar_start = bar * BAR
        # Bass: root and fifth, walking on the off-beats.
        for beat, note in enumerate([root, root + 7, root + 12, root + 7]):
            add_at(track, envelope(triangle_wave(midi_to_hz(note), BEAT * 0.9)), bar_start + beat * BEAT, 0.35)
        # Chords: short soft stabs on the off-beats.
        for beat in [0.5, 1.5, 2.5, 3.5]:
            for note in chord:
                stab = decay(envelope(square_wave(midi_to_hz(note), BEAT * 0.4, duty=0.5)), 12)
                add_at(track, stab, bar_start + beat * BEAT, 0.05)
        # Drums: kick on 1 and 3, hi-hat on every off-beat.
        for beat in [0, 2]:
            kick_t = np.arange(int(0.15 * SAMPLE_RATE)) / SAMPLE_RATE
            kick = np.sin(2 * np.pi * (60 + 90 * np.exp(-kick_t * 30)) * kick_t) * np.exp(-kick_t * 25)
            add_at(track, kick, bar_start + beat * BEAT, 0.5)
        for beat in [0.5, 1.5, 2.5, 3.5]:
            hat = decay(noise(0.05, seed=bar * 10 + int(beat * 2)), 80)
            add_at(track, hat, bar_start + beat * BEAT, 0.08)

    for bar, beat, note, beats in MELODY:
        lead = envelope(square_wave(midi_to_hz(note), beats * BEAT * 0.92, duty=0.25), release=0.03)
        add_at(track, decay(lead, 2.0), bar * BAR + beat * BEAT, 0.16)

    # Fold anything that rang past the end back onto the start, so the loop is seamless.
    loop_samples = int(length * SAMPLE_RATE)
    overflow = track[loop_samples:]
    track = track[:loop_samples]
    track[: len(overflow)] += overflow
    save_ogg(track, os.path.join(MUSIC_DIR, "hotel_lobby_loop.ogg"))


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


if __name__ == "__main__":
    make_music()
    make_ui_click()
    make_text_blip()
    make_arpeggio([72, 76, 79, 84], 0.07, 0.35, os.path.join(SFX_DIR, "delivery_complete.ogg"))
    make_arpeggio([60, 64, 67, 72, 76, 79, 84], 0.09, 0.9, os.path.join(SFX_DIR, "win_jingle.ogg"), duty=0.5)
    make_lose_jingle()
