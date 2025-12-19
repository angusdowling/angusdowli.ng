import { useState } from "react";
import styles from "./Work.module.css";

const projects = [
  {
    title: "Plus Also",
    role: "Software Engineer",
    company: "Plus Also",
    year: 2025,
    blurb:
      "Developed the full platform stack: design-to-production plugins for Figma and InDesign with AI-powered layout matching, a Cloudflare-based distributed video rendering system with Apple Silicon nodes, and content intelligence tools for automated catalogue processing and multi-tenant campaign management.",
  },
  {
    title: "BWS",
    role: "Software Engineer",
    company: "Plus Also",
    year: 2025,
    blurb:
      "Built ETL pipelines to transform product catalogue spreadsheets into production-ready marketing assets, including jurisdiction-based product mapping across Australian states and AI-powered layout generation for retail catalogues.",
  },
  {
    title: "Myer",
    role: "Software Engineer",
    company: "Plus Also",
    year: 2025,
    blurb:
      "Developed a suite of ETL pipelines for catalogue, campaign, EDM, and eCommerce workflows, transforming marketing briefs into Figma-ready assets with live product API integration, hierarchical data processing, and automated module generation.",
  },
  {
    title: "Dan Murphy's",
    role: "Software Engineer",
    company: "Plus Also",
    year: 2025,
    blurb:
      "Built a multi-state catalogue transformation system with dynamic pricing logic across australian jurisdictions, handling product categorisation, dinkus/badge generation, and automated contents page creation.",
  },
  {
    title: "Endevour Group",
    role: "Solution Architect",
    company: "Plus Also",
    year: 2025,
    blurb:
      "Led solution design for a unified DAM consolidating Dan Murphy's, BWS, ALH, Pinnacle, and Langtons into Adobe Experience Manager, integrating Workfront, Indigo, and PIM with automated ABAC compliance workflows and Brand Portal distribution across 350+ venues.",
  },
  {
    title: "Outdoor Media Association",
    role: "Software Engineer",
    company: "Howatson+Co",
    year: 2024,
    blurb:
      "Developed MOVE 2.0, Australia's Out-of-Home advertising platform connecting media buyers and owners, featuring campaign planning, inventory package management, and geographic site mapping across the national OOH network.",
  },
  {
    title: "TABCORP",
    role: "Solution Architect",
    company: "Howatson+Co",
    year: 2024,
    blurb:
      "Developed AEM Cloud infrastructure for TAB's betting platform, featuring reusable content components for promotions, navigation, and betting features, plus custom App Builder tools for content preview and bulk asset management",
  },
  {
    title: "Colonial First State",
    role: "Software Engineer",
    company: "Howatson+Co",
    year: 2023,
    blurb:
      "Built Colonial First State's AEM Cloud website with a 50+ component library, including card systems, carousels, hero banners, and form modules. It features TypeScript/Storybook frontend development and Java Sling Models with legacy site migration support.",
  },
  {
    title: "Noun",
    role: "Software Engineer",
    company: "Howatson+Co",
    year: 2023,
    blurb:
      "Built a Next.js portfolio site for Noun interior design studio featuring a JSON-driven CMS, dynamic color theming with scroll-based palette rotation, Cloudflare video delivery, and responsive project showcases with smooth scrolling.",
  },
  {
    title: "Catholic Healthcare",
    role: "Software Engineer",
    company: "Howatson+Co",
    year: 2023,
    blurb:
      "Built the location-based service finder for Catholic Healthcare's Optimizely website, enabling users to search aged care facilities by location, service type, and availability with Vue.js/TypeScript frontend and .NET backend integration.",
  },
  {
    title: "Australian Computer Society",
    role: "Software Engineer",
    company: "Howatson+Co",
    year: 2022,
    blurb:
      "Developed AEM frontend components for the Australian Computer Society website, featuring HTL/Sightly templates with Storybook integration, TypeScript modules, and styling for events, membership, and skills assessment workflows.",
  },
  {
    title: "Howatson+Co",
    role: "Software Engineer",
    company: "Howatson+Co",
    year: 2022,
    blurb:
      "Developed a Next.js portfolio website for Howatson+Co showcasing agency work with video reels, project galleries, custom cursor interactions, and headless WordPress CMS integration.",
  },
  {
    title: "CHE Proximity",
    role: "Software Engineer",
    company: "CHE Proximity",
    year: 2022,
    blurb:
      "Developed the CHE Proximity website featuring horizontal scrolling work showcases, intersection observer animations, dynamic theme toggling, and AWS Lambda functions for generating countdown timer GIFs.",
  },
  {
    title: "ANZ Banking Group",
    role: "Software Engineer",
    company: "CHE Proximity",
    year: 2022,
    blurb:
      "Built AEM SPA components for ANZ New Zealand's banking website using React, featuring server-side rendering via Adobe I/O Runtime, branch locator with Google Maps, featured rates displays, and Funnelback search integration.",
  },
  {
    title: "Tourism Queensland",
    role: "Software Engineer",
    company: "CHE Proximity",
    year: 2021,
    blurb:
      "Built AEM components for queensland.com, Tourism Queensland's official destination platform showcasing travel experiences, attractions, and events across the state.",
  },
];

export function Work() {
  const [activeProject, setActiveProject] = useState<string | null>(null);

  const handleClick = (title: string) => {
    setActiveProject(activeProject === title ? null : title);
  };

  return (
    <ul
      className={`${styles.list} ${activeProject ? styles.listHasActive : ""}`}
    >
      {projects.map((project) => {
        const isActive = activeProject === project.title;
        return (
          <li
            key={project.title}
            className={`${styles.item} ${isActive ? styles.itemActive : ""}`}
          >
            <button onClick={() => handleClick(project.title)}>
              <p className={styles.title}>{project.title}</p>
            </button>
            <div
              className={`${styles.description} ${
                isActive ? styles.descriptionVisible : ""
              }`}
            >
              <p className={styles.meta}>
                {project.role}, {project.company}, {project.year}
              </p>
              <p>{project.blurb}</p>
            </div>
          </li>
        );
      })}
    </ul>
  );
}
