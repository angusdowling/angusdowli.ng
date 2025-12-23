// Import markdown files as raw strings
import videoRenderingPlatform from "./video-rendering-platform.md?raw";
import contentIntelligence from "./content-intelligence.md?raw";
import creativeAutomationPipeline from "./creative-automation-pipeline.md?raw";
import enterpriseDamArchitecture from "./enterprise-dam-architecture.md?raw";
import movePlatform from "./move-platform.md?raw";
import retailDataPipelines from "./retail-data-pipelines.md?raw";

export const projectContent: Record<string, string> = {
  "video-rendering-platform": videoRenderingPlatform,
  "content-intelligence": contentIntelligence,
  "creative-automation-pipeline": creativeAutomationPipeline,
  "enterprise-dam-architecture": enterpriseDamArchitecture,
  "move-platform": movePlatform,
  "retail-data-pipelines": retailDataPipelines,
};

export function getProjectContent(slug: string): string | undefined {
  return projectContent[slug];
}

