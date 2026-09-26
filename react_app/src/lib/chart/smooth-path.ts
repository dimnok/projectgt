/** Точка кривой в координатах SVG. */
export type SmoothPathPoint = {
  x: number;
  y: number;
};

/** Натяжение кривой: чем больше, тем сильнее изгиб между точками. */
const TENSION = 0.2;

/**
 * Плавная кривая по точкам (кубические Безье).
 *
 * Кривая проходит через все точки, а не сглаживает их «по среднему» —
 * значения на графике остаются настоящими.
 *
 * При `closeToY` кривая замыкается по этой линии: получается контур для
 * заливки области под графиком.
 */
export function getSmoothSvgPath(
  points: SmoothPathPoint[],
  closeToY?: number
): string {
  if (points.length === 0) {
    return "";
  }
  if (points.length === 1) {
    return `M ${points[0].x} ${points[0].y}`;
  }

  let path = `M ${points[0].x.toFixed(1)} ${points[0].y.toFixed(1)}`;

  for (let index = 0; index < points.length - 1; index += 1) {
    const previous = points[index === 0 ? 0 : index - 1];
    const current = points[index];
    const next = points[index + 1];
    const afterNext = points[index + 2] ?? next;

    const control1x = current.x + (next.x - previous.x) * TENSION;
    const control1y = current.y + (next.y - previous.y) * TENSION;
    const control2x = next.x - (afterNext.x - current.x) * TENSION;
    const control2y = next.y - (afterNext.y - current.y) * TENSION;

    path += ` C ${control1x.toFixed(1)} ${control1y.toFixed(1)}, ${control2x.toFixed(1)} ${control2y.toFixed(1)}, ${next.x.toFixed(1)} ${next.y.toFixed(1)}`;
  }

  if (closeToY !== undefined) {
    const last = points[points.length - 1];
    const first = points[0];
    path += ` L ${last.x.toFixed(1)} ${closeToY.toFixed(1)} L ${first.x.toFixed(1)} ${closeToY.toFixed(1)} Z`;
  }

  return path;
}
