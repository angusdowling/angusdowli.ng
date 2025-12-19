import { Link, NavLink } from "react-router-dom";
import { Github, Linkedin } from "lucide-react";
import { ShaderBackground, AnimatedRoutes } from "../../components";
import styles from "./RootLayout.module.css";

const NAV_ITEMS = [
  { label: "Work", to: "/work" },
  // { label: "Notes", to: "/notes" },
  { label: "Contact", to: "/contact" },
  { label: "Résumé", to: "/resume.pdf", external: true },
];

const SOCIAL_LINKS = [
  { label: "GitHub", href: "https://github.com/angusdowling", icon: Github },
  {
    label: "LinkedIn",
    href: "https://www.linkedin.com/in/angus-dowling/",
    icon: Linkedin,
  },
];

export function RootLayout() {
  return (
    <>
      <ShaderBackground />
      <div className={styles.layout}>
        <header className={styles.header}>
          <h1 className={styles.title}>
            <Link to="/">Angus Dowling</Link>
          </h1>

          <nav>
            <ul className={styles.nav}>
              {NAV_ITEMS.map(({ label, to, external }) => (
                <li key={to}>
                  {external ? (
                    <a
                      href={to}
                      target="_blank"
                      rel="noopener noreferrer"
                      className={styles.navLink}
                    >
                      {label}
                    </a>
                  ) : (
                    <NavLink
                      to={to}
                      className={({ isActive }) =>
                        `${styles.navLink} ${
                          isActive ? styles.navLinkActive : ""
                        }`
                      }
                    >
                      {label}
                    </NavLink>
                  )}
                </li>
              ))}
            </ul>
          </nav>
        </header>

        <main className={styles.main}>
          <div className={styles.frame} />
          <div className={styles.content}>
            <AnimatedRoutes />
          </div>
        </main>

        <footer className={styles.footer}>
          <p className={styles.footerText}>
            Software Engineer <br /> based in Australia
          </p>
          <ul className={styles.socialLinks}>
            {SOCIAL_LINKS.map(({ label, href, icon: Icon }) => (
              <li key={href}>
                <a
                  href={href}
                  aria-label={label}
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  <Icon size={20} strokeWidth={1} />
                </a>
              </li>
            ))}
          </ul>
        </footer>
      </div>
    </>
  );
}
