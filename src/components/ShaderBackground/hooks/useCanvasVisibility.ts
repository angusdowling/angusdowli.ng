import { useState, useEffect, RefObject } from "react";

interface UseCanvasVisibilityOptions {
  /** Threshold for intersection (0-1). Default 0.01 = 1% visible */
  threshold?: number;
  /** Root margin to start/stop animation slightly before/after visibility */
  rootMargin?: string;
}

export function useCanvasVisibility(
  canvasRef: RefObject<HTMLCanvasElement | null>,
  options: UseCanvasVisibilityOptions = {}
) {
  const { threshold = 0.01, rootMargin = "50px" } = options;
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0];
        setIsVisible(entry.isIntersecting);
      },
      {
        threshold,
        rootMargin, // Start animation slightly before canvas enters viewport
      }
    );

    observer.observe(canvas);
    return () => observer.disconnect();
  }, [canvasRef, threshold, rootMargin]);

  return isVisible;
}
