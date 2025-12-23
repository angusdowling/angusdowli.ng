import { Link } from "react-router-dom";
import { posts } from "../../data";
import styles from "./Notes.module.css";

export function Notes() {
  if (posts.length === 0) {
    return (
      <div className={styles.container}>
        <p className={styles.empty}>Coming soon...</p>
      </div>
    );
  }

  return (
    <div className={styles.container}>
      <ul className={styles.list}>
        {posts.map((post) => (
          <li key={post.slug} className={styles.item}>
            <Link to={`/notes/${post.slug}`} className={styles.link}>
              <p className={styles.title}>{post.title}</p>
            </Link>
          </li>
        ))}
      </ul>
    </div>
  );
}
