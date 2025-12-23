import { useEffect, useRef, useCallback } from "react";

interface Position {
  x: number;
  y: number;
}

interface SmoothMouseOptions {
  smoothing?: number;
  flipY?: boolean;
  scaleToDpr?: boolean;
  /** Resolution scale to match canvas (0.5 = half res, 1.0 = full) */
  resolutionScale?: number;
  /** Canvas ref for accurate position calculation relative to canvas bounds */
  canvasRef?: React.RefObject<HTMLCanvasElement | null>;
}

export function useSmoothMouse(options: SmoothMouseOptions = {}) {
  const {
    smoothing = 16,
    flipY = true,
    scaleToDpr = true,
    resolutionScale = 1.0,
    canvasRef,
  } = options;

  const targetRef = useRef<Position>({ x: 0, y: 0 });
  const currentRef = useRef<Position>({ x: 0, y: 0 });

  useEffect(() => {
    const canvas = canvasRef?.current;

    const getCanvasMousePos = (clientX: number, clientY: number) => {
      const dpr = scaleToDpr
        ? Math.min(window.devicePixelRatio, 2) * resolutionScale
        : 1;

      if (canvas) {
        const rect = canvas.getBoundingClientRect();
        // Calculate position relative to the canvas element
        const x = ((clientX - rect.left) / rect.width) * canvas.width;
        const y = flipY
          ? ((rect.bottom - clientY) / rect.height) * canvas.height
          : ((clientY - rect.top) / rect.height) * canvas.height;
        return { x, y };
      } else {
        // Fallback to window-based calculation
        const x = clientX * dpr;
        const y = flipY ? (window.innerHeight - clientY) * dpr : clientY * dpr;
        return { x, y };
      }
    };

    // Initialize to center
    const centerX = canvas
      ? canvas.width / 2
      : (window.innerWidth / 2) *
        (scaleToDpr
          ? Math.min(window.devicePixelRatio, 2) * resolutionScale
          : 1);
    const centerY = canvas
      ? canvas.height / 2
      : (window.innerHeight / 2) *
        (scaleToDpr
          ? Math.min(window.devicePixelRatio, 2) * resolutionScale
          : 1);

    targetRef.current = { x: centerX, y: centerY };
    currentRef.current = { x: centerX, y: centerY };

    const handleMouseMove = (e: MouseEvent) => {
      const pos = getCanvasMousePos(e.clientX, e.clientY);
      targetRef.current.x = pos.x;
      targetRef.current.y = pos.y;
    };

    window.addEventListener("mousemove", handleMouseMove);
    return () => window.removeEventListener("mousemove", handleMouseMove);
  }, [flipY, scaleToDpr, resolutionScale, canvasRef]);

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
