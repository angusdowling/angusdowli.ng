import { useParams, Link, Navigate } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import { getPostBySlug, getPostContent } from "../../data";
import { Markdown } from "../../components";
import styles from "./Note.module.css";

export function Note() {
  const { slug } = useParams<{ slug: string }>();

  const post = slug ? getPostBySlug(slug) : undefined;
  const content = slug ? getPostContent(slug) : undefined;

  if (!post) {
    return <Navigate to="/notes" replace />;
  }

  return (
    <div className={styles.container}>
      <Link to="/notes" className={styles.backLink}>
        <ArrowLeft size={16} strokeWidth={1.5} />
        <span>Back to Notes</span>
      </Link>

      <article className={styles.article}>
        {content ? (
          <Markdown content={content} />
        ) : (
          <>
            <header className={styles.header}>
              <h1 className={styles.title}>{post.title}</h1>
              <time className={styles.date}>{post.date}</time>
            </header>
            <div className={styles.content}>
              <p>{post.summary}</p>
            </div>
          </>
        )}
      </article>
    </div>
  );
}

