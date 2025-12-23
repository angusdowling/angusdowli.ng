// Import notes markdown files as raw strings
import onConfidence from "./on-confidence.md?raw";

export const postContent: Record<string, string> = {
  "on-confidence": onConfidence,
};

export function getPostContent(slug: string): string | undefined {
  return postContent[slug];
}

