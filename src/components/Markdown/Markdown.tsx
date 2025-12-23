import ReactMarkdown, { Components } from "react-markdown";
import remarkGfm from "remark-gfm";
import styles from "./Markdown.module.css";

interface MarkdownProps {
  content: string;
  className?: string;
}

function isExternalLink(href: string): boolean {
  if (!href) return false;
  if (href.startsWith("/") || href.startsWith("#")) return false;

  try {
    const url = new URL(href, window.location.origin);
    return !url.hostname.endsWith("angusdowli.ng");
  } catch {
    return false;
  }
}

const components: Components = {
  a: ({ href, children, ...props }) => {
    const external = isExternalLink(href || "");

    if (external) {
      return (
        <a href={href} target="_blank" rel="noopener noreferrer" {...props}>
          {children}
        </a>
      );
    }

    return (
      <a href={href} {...props}>
        {children}
      </a>
    );
  },
};

export function Markdown({ content, className = "" }: MarkdownProps) {
  return (
    <div className={`${styles.markdown} ${className}`}>
      <ReactMarkdown remarkPlugins={[remarkGfm]} components={components}>
        {content}
      </ReactMarkdown>
    </div>
  );
}
