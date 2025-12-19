import { Link, NavLink } from "react-router-dom";
import { Github, Linkedin } from "lucide-react";
import { ShaderBackground } from "./components/ShaderBackground";
import { AnimatedRoutes } from "./components/AnimatedRoutes";
import styles from "./App.module.css";

function App() {
  return (
    <>
      <ShaderBackground />
      <main className={styles.app}>
        <header className={styles.header}>
          <h1 className={styles.title}>
            <Link to="/">Angus Dowling</Link>
          </h1>

          <nav>
            <ul className={styles.navList}>
              <li>
                <NavLink
                  to="/work"
                  className={({ isActive }) => (isActive ? styles.active : "")}
                >
                  Work
                </NavLink>
              </li>
              {/* <li>
                <NavLink to="/notes" className={({ isActive }) => (isActive ? styles.active : "")}>Notes</NavLink>
              </li> */}
              <li>
                <NavLink
                  to="/contact"
                  className={({ isActive }) => (isActive ? styles.active : "")}
                >
                  Contact
                </NavLink>
              </li>
              <li>
                <a href="/resume.pdf" target="_blank" rel="noopener noreferrer">
                  Resume
                </a>
              </li>
            </ul>
          </nav>
        </header>

        <div className={styles.content}>
          <div className={styles.border}></div>

          <div className={styles.routes}>
            <AnimatedRoutes />
          </div>
        </div>
        <footer className={styles.footer}>
          <p className={styles.footerItem}>
            Software Engineer <br /> based in Australia
          </p>
          <div className={styles.footerItem}>
            <ul className={styles.socialList}>
              <li>
                <a
                  href="https://github.com/angusdowling"
                  aria-label="GitHub"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <Github size={20} strokeWidth={1} />
                </a>
              </li>
              <li>
                <a
                  href="https://www.linkedin.com/in/angus-dowling/"
                  aria-label="LinkedIn"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <Linkedin size={20} strokeWidth={1} />
                </a>
              </li>
            </ul>
          </div>
        </footer>
      </main>
    </>
  );
}

export default App;
