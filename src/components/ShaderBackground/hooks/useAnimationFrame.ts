import { useEffect, useRef } from "react";

interface FrameData {
  time: number;
  deltaTime: number;
}

type FrameCallback = (frame: FrameData) => void;

interface AnimationFrameOptions {
  debug?: boolean;
  logInterval?: number; // How many frames between logs (default: 60)
  paused?: boolean; // Pause the animation loop
}

export function useAnimationFrame(
  callback: FrameCallback,
  options: AnimationFrameOptions = {}
) {
  const { debug = false, logInterval = 60, paused = false } = options;

  const frameRef = useRef<number>(0);
  const startTimeRef = useRef(Date.now());
  const lastFrameRef = useRef(Date.now());
  const pausedTimeRef = useRef(0); // Accumulated paused time
  const pauseStartRef = useRef<number | null>(null);
  const callbackRef = useRef(callback);
  const fpsHistoryRef = useRef<number[]>([]);
  const frameTimesRef = useRef<number[]>([]);

  callbackRef.current = callback;

  useEffect(() => {
    if (paused) {
      // Track when we paused
      if (pauseStartRef.current === null) {
        pauseStartRef.current = Date.now();
      }
      cancelAnimationFrame(frameRef.current);
      return;
    }

    // Resume: accumulate paused duration
    if (pauseStartRef.current !== null) {
      pausedTimeRef.current += Date.now() - pauseStartRef.current;
      pauseStartRef.current = null;
      lastFrameRef.current = Date.now(); // Reset to avoid large deltaTime spike
    }

    const animate = () => {
      const now = Date.now();
      const deltaTime = (now - lastFrameRef.current) / 1000;
      // Subtract paused time from total elapsed time
      const time = (now - startTimeRef.current - pausedTimeRef.current) / 1000;
      lastFrameRef.current = now;

      // Performance tracking
      if (debug && deltaTime > 0) {
        const fps = 1 / deltaTime;
        const frameTimeMs = deltaTime * 1000;

        fpsHistoryRef.current.push(fps);
        frameTimesRef.current.push(frameTimeMs);

        if (fpsHistoryRef.current.length >= logInterval) {
          const avgFps =
            fpsHistoryRef.current.reduce((a, b) => a + b) /
            fpsHistoryRef.current.length;
          const minFps = Math.min(...fpsHistoryRef.current);
          const maxFps = Math.max(...fpsHistoryRef.current);
          const avgFrameTime =
            frameTimesRef.current.reduce((a, b) => a + b) /
            frameTimesRef.current.length;

          console.log(
            `[Shader] FPS: ${avgFps.toFixed(1)} (min: ${minFps.toFixed(
              1
            )}, max: ${maxFps.toFixed(1)}) | Frame: ${avgFrameTime.toFixed(
              2
            )}ms`
          );

          fpsHistoryRef.current = [];
          frameTimesRef.current = [];
        }
      }

      callbackRef.current({ time, deltaTime });
      frameRef.current = requestAnimationFrame(animate);
    };

    frameRef.current = requestAnimationFrame(animate);

    return () => cancelAnimationFrame(frameRef.current);
  }, [debug, logInterval, paused]);
}
