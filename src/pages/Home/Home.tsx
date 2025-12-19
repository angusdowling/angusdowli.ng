import styles from "./Home.module.css";

export function Home() {
  return (
    <section className={styles.hero}>
      <p className={styles.manifesto}>
        Born in Melbourne,
        <br />
        Australia.
        <br />
        I believe in beauty,
        <br />
        emotion, connection.
        <br />
        The best design
        <br />
        is invisible —
        <br />
        technology that serves,
        <br />
        simplifies,
        <br />
        then disappears.
        <br />
        Still figuring out
        <br />
        the rest.
      </p>
    </section>
  );
}

