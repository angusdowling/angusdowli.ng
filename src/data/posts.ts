export interface Post {
  slug: string;
  title: string;
  date: string;
  /** Short description for listing pages */
  summary: string;
}

export const posts: Post[] = [
  {
    slug: "on-confidence",
    title: "On Confidence",
    date: "2025-01-01",
    summary: "Thoughts on confidence.",
  },
];

export function getPostBySlug(slug: string): Post | undefined {
  return posts.find((post) => post.slug === slug);
}
