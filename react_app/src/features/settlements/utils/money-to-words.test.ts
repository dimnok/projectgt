import { describe, expect, it } from "vitest";

import {
  moneyNumericWithUnitsRu,
  moneyToWordsRu,
} from "@/features/settlements/utils/money-to-words";

function normalize(value: string): string {
  return value.replace(/\u00A0|\u202F/g, " ");
}

describe("moneyToWordsRu", () => {
  it("сумма прописью с копейками", () => {
    expect(moneyToWordsRu(1234.56)).toBe(
      "Одна тысяча двести тридцать четыре рубля 56 копеек"
    );
  });

  it("ноль рублей", () => {
    expect(moneyToWordsRu(0)).toBe("Ноль рублей 00 копеек");
  });

  it("миллион", () => {
    expect(moneyToWordsRu(1_000_000)).toBe("Один миллион рублей 00 копеек");
  });

  it("склонение рубля и копейки", () => {
    expect(moneyToWordsRu(21.05)).toBe("Двадцать один рубль 05 копеек");
  });

  it("отрицательная сумма", () => {
    expect(moneyToWordsRu(-5)).toBe("Минус Пять рублей 00 копеек");
  });

  it("без заглавной буквы по флагу", () => {
    expect(moneyToWordsRu(5, false)).toBe("пять рублей 00 копеек");
  });
});

describe("moneyNumericWithUnitsRu", () => {
  it("числовая сумма с единицами", () => {
    expect(normalize(moneyNumericWithUnitsRu(4_979_304.23))).toBe(
      "4 979 304 рубля 23 копейки"
    );
  });
});
