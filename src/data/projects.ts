export interface Project {
  slug: string;
  title: string;
  role: string;
  company: string;
  year: number;
  shaderIndex: number;
  /** Short description for listing pages */
  summary: string;
}

export const featuredProjects: Project[] = [
  {
    slug: "video-rendering-platform",
    title: "Video Rendering Platform",
    role: "Software Engineer",
    company: "Plus Also",
    year: 2025,
    shaderIndex: 1,
    summary:
      "A distributed rendering system for generating thousands of personalized video variants from After Effects templates.",
  },
  {
    slug: "content-intelligence",
    title: "Content Intelligence",
    role: "Software Engineer",
    company: "Plus Also",
    year: 2025,
    shaderIndex: 2,
    summary:
      "A CAD processor that extracts product images and metadata from catalog PDFs with accurate color conversion.",
  },
  {
    slug: "creative-automation-pipeline",
    title: "Creative Automation Pipeline",
    role: "Software Engineer",
    company: "Plus Also",
    year: 2025,
    shaderIndex: 3,
    summary:
      "Figma and InDesign plugins that generate hundreds of localized, personalized variants from a single template.",
  },
  {
    slug: "enterprise-dam-architecture",
    title: "Enterprise DAM Architecture",
    role: "Solution Architect",
    company: "Plus Also",
    year: 2025,
    shaderIndex: 4,
    summary:
      "Solution architecture for a unified digital asset management platform serving a multi-brand retail group.",
  },
  {
    slug: "move-platform",
    title: "MOVE Platform",
    role: "Software Engineer",
    company: "Howatson+Co",
    year: 2024,
    shaderIndex: 5,
    summary:
      "The industry platform for Australia's Out-of-Home advertising, connecting media buyers and site owners.",
  },
  {
    slug: "retail-data-pipelines",
    title: "Retail Data Pipelines",
    role: "Software Engineer",
    company: "Plus Also",
    year: 2025,
    shaderIndex: 6,
    summary:
      "Transformation systems that convert raw product catalogues into state-specific marketing assets.",
  },
];

export function getProjectBySlug(slug: string): Project | undefined {
  return featuredProjects.find((project) => project.slug === slug);
}
