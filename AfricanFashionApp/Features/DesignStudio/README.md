# Design Studio

This feature implements the fashion-design workflow from the source brief:

- custom clothing concepts tailored to client preferences and body measurements
- trend prediction for likely popular colors, silhouettes, fabrics, trims, and commercial directions
- saved collection boards and PDF-ready tech-pack sections
- version-history revisions for generated looks

## Structure

- `Models/`: client profiles, garment briefs, trend signals, generated looks, SwiftData records, and tech-pack documents
- `Services/`: prompt composition, live trend/image API clients, fallback services, and tech-pack generation
- `ViewModels/`: async UI state for design generation, trend loading, and dashboard samples
- `Views/`: Studio dashboard, clients, generator, trend lab, board, cards, and tech-pack preview

## Backend Contract

The app calls a backend proxy rather than embedding an OpenAI key in the iOS binary.

Environment variables:

- `FASHION_TREND_API_URL`: override for the trend endpoint
- `FASHION_IMAGE_API_URL`: override for the image-generation endpoint
- `FASHION_AI_API_TOKEN`: optional bearer token for your backend proxy
- `FASHION_IMAGE_MODEL`: image model identifier forwarded to the backend, defaulting to `gpt-image-2`

Expected endpoints:

- `POST /v1/fashion/trends`
- `POST /v1/fashion/images`

The image endpoint receives an OpenAI-compatible payload with `model`, `prompt`, `size`, `quality`, and `output_format`, then returns `{ "image_url": "https://..." }` for rendering inside SwiftUI.

If the backend is unavailable, the app falls back to deterministic local trend signals and preview image URLs so the Studio remains usable offline.

## Collection Iteration

The Collection Board includes:

- `New Version`: duplicates a saved look into a new revision, increments `versionNumber`, and stores `parentLookID`
- `Tech Pack`: generates PDF-ready sections from the look, fit measurements, and saved trend evidence

This keeps prompt text, image URL, garment metadata, and iteration history together for design review.
