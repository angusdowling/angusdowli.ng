import { Link } from "react-router-dom";
import styles from "./NotFound.module.css";

export function NotFound() {
  return (
    <section className={styles.container}>
      <h2 className={styles.code}>404</h2>
      <p className={styles.message}>Page not found</p>
      <Link to="/" className={styles.link}>
        Back to home
      </Link>
    </section>
  );
}

