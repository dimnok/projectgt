import { describe, expect, it } from "vitest";

import { getSmoothSvgPath } from "@/lib/chart/smooth-path";

describe("getSmoothSvgPath", () => {
  it("без точек путь пустой", () => {
    expect(getSmoothSvgPath([])).toBe("");
  });

  it("одна точка — только начало пути", () => {
    expect(getSmoothSvgPath([{ x: 10, y: 20 }])).toBe("M 10 20");
  });

  it("кривая начинается в первой точке и проходит через последнюю", () => {
    const path = getSmoothSvgPath([
      { x: 0, y: 100 },
      { x: 50, y: 40 },
      { x: 100, y: 70 },
    ]);

    expect(path.startsWith("M 0.0 100.0")).toBe(true);
    expect(path.endsWith("C 70.0 34.0, 90.0 64.0, 100.0 70.0")).toBe(true);
  });

  it("замыкание по линии превращает кривую в контур области", () => {
    const path = getSmoothSvgPath(
      [
        { x: 0, y: 100 },
        { x: 50, y: 40 },
      ],
      100
    );

    expect(path.endsWith("L 50.0 100.0 L 0.0 100.0 Z")).toBe(true);
  });
});
