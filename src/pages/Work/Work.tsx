import { Link } from "react-router-dom";
import { featuredProjects } from "../../data";
import styles from "./Work.module.css";

export function Work() {
  return (
    <div className={styles.container}>
      <ul className={styles.list}>
        {featuredProjects.map((project) => (
          <li key={project.title} className={styles.item}>
            <Link to={`/work/${project.slug}`} className={styles.link}>
              <p className={styles.title}>{project.title}</p>
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
