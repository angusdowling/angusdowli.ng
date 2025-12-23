import { useLayoutEffect } from "react";
import { useLocation, Routes, Route } from "react-router-dom";
import { AnimatePresence, motion, animate } from "framer-motion";
import { Home, Work, CaseStudy, Notes, Note, NotFound } from "../../pages";
import styles from "./AnimatedRoutes.module.css";

export function AnimatedRoutes() {
  const location = useLocation();

  // Scroll to top with easing when route changes
  useLayoutEffect(() => {
    const scrollY = window.scrollY;
    if (scrollY > 0) {
      animate(scrollY, 0, {
        duration: 0.4,
        ease: [0.4, 0, 0.2, 1],
        onUpdate: (value) => window.scrollTo(0, value),
      });
    }
  }, [location.pathname]);

  return (
    <AnimatePresence mode="wait">
      <motion.div
        key={location.pathname}
        className={styles.page}
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        transition={{ duration: 0.3 }}
      >
        <Routes location={location}>
          <Route path="/" element={<Home />} />
          <Route path="/work" element={<Work />} />
          <Route path="/work/:slug" element={<CaseStudy />} />
          <Route path="/notes" element={<Notes />} />
          <Route path="/notes/:slug" element={<Note />} />
          <Route path="*" element={<NotFound />} />
        </Routes>
      </motion.div>
    </AnimatePresence>
  );
}
