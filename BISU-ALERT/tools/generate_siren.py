#!/usr/bin/env python3
"""
Generate the BISU-Alert School Emergency Alarm Bell.

    python tools/generate_siren.py   ->   assets/sounds/sos_siren.wav

Standard library only, so this runs on a bare Python install with no pip step.
Generates an authentic electric vibrating school alarm bell (like a 10-inch
school fire / emergency evacuation gong) with rapid clapper impacts (~11.5 strikes/sec)
and rich metallic resonant overtones.

The output is built to loop seamlessly with audioplayers ReleaseMode.loop.
"""

import math
import os
import wave

# -- Output format ----------------------------------------------------------
# 44.1 kHz / 16-bit mono.
SAMPLE_RATE = 44100
SAMPLE_WIDTH = 2  # bytes, i.e. 16-bit
CHANNELS = 1

# Bell strike frequency (strikes per second)
STRIKE_RATE = 11.5  # ~87ms per clapper strike
DURATION = 3.0      # Total loop duration in seconds

# Bell resonant modes: (frequency in Hz, relative amplitude, decay rate in s^-1)
# Derived from circular bell/gong acoustics
MODES = [
    (1050.0, 0.45, 12.0),
    (1520.0, 0.65, 16.0),
    (2180.0, 0.85, 20.0),
    (2740.0, 0.55, 25.0),
    (3480.0, 0.35, 30.0),
    (4350.0, 0.20, 35.0),
    (5800.0, 0.12, 45.0),
]

OUTPUT_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    os.pardir,
    "assets",
    "sounds",
    "sos_siren.wav",
)


def generate_school_bell_frames() -> bytes:
    """Render the school alarm bell as little-endian signed 16-bit PCM."""
    total_samples = int(SAMPLE_RATE * DURATION)
    samples = [0.0] * total_samples
    strike_interval = SAMPLE_RATE / STRIKE_RATE
    num_strikes = int(DURATION * STRIKE_RATE)

    # Wrap strike responses across the boundary so the loop point has zero seam
    strike_len = int(SAMPLE_RATE * 0.6)

    for s in range(num_strikes):
        strike_start = int(s * strike_interval)
        for i in range(strike_len):
            idx = (strike_start + i) % total_samples
            t = i / SAMPLE_RATE

            # Sharp metallic strike transient (clapper hit)
            transient = 0.0
            if i < int(SAMPLE_RATE * 0.005):
                env = 1.0 - (i / (SAMPLE_RATE * 0.005))
                transient = env * math.sin(2.0 * math.pi * 3800.0 * t) * 0.45

            # Modal harmonic ring
            modal_sum = 0.0
            for freq, amp, decay in MODES:
                # Slight metallic warble
                wobble = 1.0 + 0.003 * math.sin(2.0 * math.pi * 32.0 * t)
                modal_sum += amp * math.exp(-decay * t) * math.sin(2.0 * math.pi * freq * wobble * t)

            samples[idx] += transient + modal_sum * 0.35

    # Normalize to peak amplitude 0.90 to avoid any 16-bit clipping
    max_val = max(abs(x) for x in samples) if samples else 1.0
    if max_val > 0.0:
        samples = [x / max_val * 0.90 for x in samples]

    # Convert to 16-bit signed PCM
    out = bytearray()
    for x in samples:
        sample = int(round(max(-1.0, min(1.0, x)) * 32767))
        out += sample.to_bytes(2, byteorder="little", signed=True)

    return bytes(out)


def main() -> None:
    frames = generate_school_bell_frames()

    os.makedirs(os.path.dirname(OUTPUT_PATH), exist_ok=True)
    with wave.open(OUTPUT_PATH, "wb") as wav:
        wav.setnchannels(CHANNELS)
        wav.setsampwidth(SAMPLE_WIDTH)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(frames)

    frame_count = len(frames) // (SAMPLE_WIDTH * CHANNELS)
    print(
        "Wrote school alarm bell to {path}\n"
        "  {seconds:.2f} s, {rate} Hz, {bits}-bit, "
        "{channels} ch, {kib:.0f} KiB".format(
            path=os.path.normpath(OUTPUT_PATH),
            seconds=frame_count / SAMPLE_RATE,
            rate=SAMPLE_RATE,
            bits=SAMPLE_WIDTH * 8,
            channels=CHANNELS,
            kib=len(frames) / 1024,
        )
    )


if __name__ == "__main__":
    main()
