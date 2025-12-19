import { useEffect, useRef, useCallback } from "react";

interface Position {
  x: number;
  y: number;
}

interface SmoothMouseOptions {
  smoothing?: number;
  flipY?: boolean;
  scaleToDpr?: boolean;
}

export function useSmoothMouse(options: SmoothMouseOptions = {}) {
  const { smoothing = 16, flipY = true, scaleToDpr = true } = options;

  const targetRef = useRef<Position>({ x: 0, y: 0 });
  const currentRef = useRef<Position>({ x: 0, y: 0 });

  useEffect(() => {
    const dpr = scaleToDpr ? Math.min(window.devicePixelRatio, 2) : 1;
    const centerX = (window.innerWidth / 2) * dpr;
    const centerY = (window.innerHeight / 2) * dpr;

    targetRef.current = { x: centerX, y: centerY };
    currentRef.current = { x: centerX, y: centerY };

    const handleMouseMove = (e: MouseEvent) => {
      const dpr = scaleToDpr ? Math.min(window.devicePixelRatio, 2) : 1;
      targetRef.current.x = e.clientX * dpr;
      targetRef.current.y = flipY
        ? (window.innerHeight - e.clientY) * dpr
        : e.clientY * dpr;
    };

    window.addEventListener("mousemove", handleMouseMove);
    return () => window.removeEventListener("mousemove", handleMouseMove);
  }, [flipY, scaleToDpr]);

  const update = useCallback(
    (deltaTime: number) => {
      const factor = 1 - Math.exp(-smoothing * deltaTime);
      currentRef.current.x +=
        (targetRef.current.x - currentRef.current.x) * factor;
      currentRef.current.y +=
        (targetRef.current.y - currentRef.current.y) * factor;
      return currentRef.current;
    },
    [smoothing]
  );

  return { current: currentRef, target: targetRef, update };
}

