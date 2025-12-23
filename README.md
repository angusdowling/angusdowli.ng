# angusdowli.ng

Personal portfolio website featuring an interactive WebGL shader background with morphing 3D shapes and a responsive dot grid.

## Tech Stack

- **React 18** with TypeScript
- **Vite** for build tooling
- **React Router** for client-side routing
- **Framer Motion** for page transitions
- **WebGL 2.0** for shader-based visuals
- **react-markdown** for rendering markdown content
- **Lucide React** for icons
- **CSS Modules** with design tokens
- **Cloudflare Pages** for deployment

## Getting Started

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## Project Structure

```
src/
├── components/           # Reusable components
│   ├── AnimatedRoutes/   # Page transition wrapper
│   ├── Markdown/         # Markdown renderer component
│   └── ShaderBackground/ # WebGL shader canvas
│       ├── hooks/        # WebGL-specific hooks
│       └── shaders/      # GLSL vertex/fragment shaders
│
├── content/              # Markdown content files
│   ├── notes/            # Blog/notes content
│   └── work/             # Case study content
│
├── context/              # React context providers
│   └── ShaderContext     # Shader state management
│
├── data/                 # Static data definitions
│   ├── posts.ts          # Notes/posts data
│   └── projects.ts       # Project metadata
│
├── layouts/              # Layout components
│   └── RootLayout/       # Main app shell (header, footer, frame)
│
├── pages/                # Route pages
│   ├── CaseStudy/        # Individual project case study
│   ├── Home/             # Landing page
│   ├── Note/             # Individual note page
│   ├── Notes/            # Notes listing
│   ├── NotFound/         # 404 page
│   └── Work/             # Work/projects listing
│
├── styles/
│   └── global.css        # Design tokens & base styles
│
└── main.tsx              # App entry point
```

## Architecture

### Design Tokens

CSS custom properties defined in `global.css` for consistent styling:

```css
:root {
  --color-surface: #fff;
  --font-size-base: 16px;
  --space-md: 24px;
  --transition-base: 300ms ease;
}
```

### Component Pattern

Each component is co-located with its styles and exports:

```
ComponentName/
├── ComponentName.tsx
├── ComponentName.module.css
└── index.ts
```

### WebGL Shader

The background shader features:

- Morphing 3D shapes (pyramid → sphere → cube → octahedron → torus)
- Interactive dot grid with mouse repulsion
- Animated "A" letter pattern
- Grain/stipple texture effect

Custom hooks handle WebGL concerns:

- `useWebGLProgram` - Shader compilation and program linking
- `useAnimationFrame` - Render loop with delta time
- `useSmoothMouse` - Interpolated mouse position
- `useCanvasResize` - DPR-aware canvas sizing
- `useCanvasVisibility` - Pause rendering when not visible

## Scripts

| Command           | Description                          |
| ----------------- | ------------------------------------ |
| `npm run dev`     | Start dev server at localhost:5173   |
| `npm run build`   | Type-check and build for production  |
| `npm run preview` | Preview production build locally     |
| `npm run lint`    | Run ESLint                           |
| `npm run deploy`  | Build and deploy to Cloudflare Pages |

## License

MIT
