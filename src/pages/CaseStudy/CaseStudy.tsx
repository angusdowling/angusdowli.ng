import { useEffect } from "react";
import { useParams, Link, Navigate } from "react-router-dom";
import { ArrowLeft } from "lucide-react";
import { useShader } from "../../context";
import { getProjectBySlug, getProjectContent } from "../../data";
import { Markdown } from "../../components";
import styles from "./CaseStudy.module.css";

export function CaseStudy() {
  const { slug } = useParams<{ slug: string }>();
  const { selectProject, clearProject } = useShader();

  const project = slug ? getProjectBySlug(slug) : undefined;
  const content = slug ? getProjectContent(slug) : undefined;

  useEffect(() => {
    if (project?.shaderIndex) {
      selectProject(project.shaderIndex);
    }

    return () => {
      clearProject();
    };
  }, [project, selectProject, clearProject]);

  if (!project) {
    return <Navigate to="/work" replace />;
  }

  return (
    <div className={styles.container}>
      <Link to="/work" className={styles.backLink}>
        <ArrowLeft size={16} strokeWidth={1.5} />
        <span>Back to Work</span>
      </Link>

      <article className={styles.article}>
        {content ? (
          <Markdown content={content} />
        ) : (
          <>
            <header className={styles.header}>
              <h1 className={styles.title}>{project.title}</h1>
              <p className={styles.meta}>
                {project.role}, {project.company}, {project.year}
              </p>
            </header>
            <div className={styles.content}>
              <p>{project.summary}</p>
            </div>
          </>
        )}
      </article>
    </div>
  );
}
