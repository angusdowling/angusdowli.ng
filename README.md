# angusdowli.ng

Personal website with a WebGL shader background.

## Development

```bash
# Install dependencies
npm install

# Start dev server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Deploy to Cloudflare Pages

### Option 1: GitHub Integration (Recommended)

1. Push this repo to GitHub
2. Go to [Cloudflare Pages Dashboard](https://dash.cloudflare.com/?to=/:account/pages)
3. Click "Create a project" → "Connect to Git"
4. Select your repository
5. Configure build settings:
   - **Framework preset**: Vite
   - **Build command**: `npm run build`
   - **Build output directory**: `dist`
6. Click "Save and Deploy"

### Option 2: Direct Upload via CLI

```bash
# Install Wrangler CLI
npm install -g wrangler

# Login to Cloudflare
wrangler login

# Build the project
npm run build

# Deploy to Cloudflare Pages
wrangler pages deploy dist --project-name=angusdowli-ng
```

## Shader

The background uses a WebGL port of a Shadertoy-style GLSL shader featuring:
- Perspective dotted wave-grid
- Interactive mouse gravity well effect (click and drag)
- Dynamic wave animation with lighting

