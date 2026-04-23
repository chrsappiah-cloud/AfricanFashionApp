#!/usr/bin/env python3
from __future__ import annotations

import gc
from pathlib import Path

import torch
from diffusers import AutoPipelineForText2Image
from PIL import Image


MODEL_ID = "stabilityai/sd-turbo"
ROOT = Path("/Applications/AfricanFashionApp")
ASSETS_DIR = ROOT / "AfricanFashionApp" / "Assets.xcassets"
APP_ICON_DIR = ASSETS_DIR / "AppIcon.appiconset"
LAUNCH_DIR = ASSETS_DIR / "LaunchImage.imageset"


def get_device() -> tuple[str, torch.dtype]:
    if torch.backends.mps.is_available():
        return "mps", torch.float16
    return "cpu", torch.float32


def make_pipeline(device: str, dtype: torch.dtype):
    pipe = AutoPipelineForText2Image.from_pretrained(
        MODEL_ID,
        torch_dtype=dtype,
        safety_checker=None,
    )
    pipe = pipe.to(device)
    pipe.enable_attention_slicing()
    pipe.set_progress_bar_config(disable=True)
    return pipe


def generate_image(pipe, prompt: str, negative_prompt: str, seed: int):
    generator = torch.Generator(device=pipe.device).manual_seed(seed)
    return pipe(
        prompt=prompt,
        negative_prompt=negative_prompt,
        num_inference_steps=2,
        guidance_scale=0.0,
        width=1024,
        height=1024,
        generator=generator,
    ).images[0]


def main() -> None:
    APP_ICON_DIR.mkdir(parents=True, exist_ok=True)
    LAUNCH_DIR.mkdir(parents=True, exist_ok=True)

    device, dtype = get_device()
    pipe = make_pipeline(device, dtype)
    negative = "text, words, letters, watermark, logo text, blurry, low quality, noisy"

    prompts = {
        "AppIcon-1024.png": (
            "premium iOS app icon, stylized african compass emblem, charcoal background, "
            "rich gold geometric symbol, clean minimal luxury branding, centered, no text"
        ),
        "AppIcon-Dark-1024.png": (
            "dark mode iOS app icon, african compass symbol, matte black and bronze palette, "
            "simple centered emblem, minimal and elegant, no text"
        ),
        "AppIcon-Tinted-1024.png": (
            "monochrome iOS app icon glyph, bold african compass silhouette, high contrast, "
            "single-color emblem on dark neutral background, no text"
        ),
        "LaunchImage-2732.png": (
            "luxury fashion launch artwork, deep black to bronze gradient background, "
            "centered african compass emblem, subtle fabric texture, cinematic soft light, no text"
        ),
    }

    seeds = {
        "AppIcon-1024.png": 1201,
        "AppIcon-Dark-1024.png": 1202,
        "AppIcon-Tinted-1024.png": 1203,
        "LaunchImage-2732.png": 1204,
    }

    for filename, prompt in prompts.items():
        image = generate_image(
            pipe=pipe,
            prompt=prompt,
            negative_prompt=negative,
            seed=seeds[filename],
        )
        if filename == "LaunchImage-2732.png":
            image = image.resize((2732, 2732), resample=Image.Resampling.LANCZOS)
        if filename.startswith("AppIcon"):
            out_path = APP_ICON_DIR / filename
        else:
            out_path = LAUNCH_DIR / filename
        image.save(out_path, format="PNG")
        print(f"Generated {out_path}")
        gc.collect()


if __name__ == "__main__":
    main()
