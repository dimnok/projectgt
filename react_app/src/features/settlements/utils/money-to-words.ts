/** Склонение по числу: forms = [1, 2..4, 5..]. */
function pluralize(n: number, forms: [string, string, string]): string {
  const mod100 = n % 100;
  if (mod100 >= 11 && mod100 <= 14) {
    return forms[2];
  }
  switch (n % 10) {
    case 1:
      return forms[0];
    case 2:
    case 3:
    case 4:
      return forms[1];
    default:
      return forms[2];
  }
}

/** Разряды числительных: единицы, десятки-подростки, десятки, сотни. */
const UNITS_MALE = [
  "",
  "один",
  "два",
  "три",
  "четыре",
  "пять",
  "шесть",
  "семь",
  "восемь",
  "девять",
];
const UNITS_FEMALE = [
  "",
  "одна",
  "две",
  "три",
  "четыре",
  "пять",
  "шесть",
  "семь",
  "восемь",
  "девять",
];
const TEENS = [
  "десять",
  "одиннадцать",
  "двенадцать",
  "тринадцать",
  "четырнадцать",
  "пятнадцать",
  "шестнадцать",
  "семнадцать",
  "восемнадцать",
  "девятнадцать",
];
const TENS = [
  "",
  "",
  "двадцать",
  "тридцать",
  "сорок",
  "пятьдесят",
  "шестьдесят",
  "семьдесят",
  "восемьдесят",
  "девяносто",
];
const HUNDREDS = [
  "",
  "сто",
  "двести",
  "триста",
  "четыреста",
  "пятьсот",
  "шестьсот",
  "семьсот",
  "восемьсот",
  "девятьсот",
];

/** Трёхзначная группа прописью; `female` — женский род (тысячи). */
function triplet(value: number, female: boolean): string {
  if (value === 0) {
    return "";
  }
  const h = Math.floor(value / 100);
  const t = Math.floor((value % 100) / 10);
  const u = value % 10;
  const parts: string[] = [];
  if (h > 0) parts.push(HUNDREDS[h]);
  if (t === 1) {
    parts.push(TEENS[u]);
  } else {
    if (t > 1) parts.push(TENS[t]);
    if (u > 0) parts.push((female ? UNITS_FEMALE : UNITS_MALE)[u]);
  }
  return parts.join(" ");
}

/** Целое число прописью с разрядами до миллиардов. */
function numberToWords(n: number): string {
  if (n === 0) {
    return "ноль";
  }

  const groups: string[] = [];
  let rest = n;

  const billions = Math.floor(rest / 1_000_000_000);
  rest %= 1_000_000_000;
  if (billions > 0) {
    groups.push(
      `${triplet(billions, false)} ${pluralize(billions, [
        "миллиард",
        "миллиарда",
        "миллиардов",
      ])}`
    );
  }

  const millions = Math.floor(rest / 1_000_000);
  rest %= 1_000_000;
  if (millions > 0) {
    groups.push(
      `${triplet(millions, false)} ${pluralize(millions, [
        "миллион",
        "миллиона",
        "миллионов",
      ])}`
    );
  }

  const thousands = Math.floor(rest / 1000);
  rest %= 1000;
  if (thousands > 0) {
    groups.push(
      `${triplet(thousands, true)} ${pluralize(thousands, [
        "тысяча",
        "тысячи",
        "тысяч",
      ])}`
    );
  }

  if (rest > 0) {
    groups.push(triplet(rest, false));
  }

  return groups.join(" ").trim();
}

/** Первая буква — заглавная. */
function capitalize(value: string): string {
  if (!value) {
    return value;
  }
  return value.charAt(0).toUpperCase() + value.slice(1);
}

/** Делит сумму на рубли и копейки, отбрасывая знак. */
function splitMoney(amount: number): { rubles: number; kopecks: number } {
  const abs = Math.abs(amount);
  const rubles = Math.trunc(abs);
  const kopecks = Math.round(abs * 100) % 100;
  return { rubles, kopecks };
}

/**
 * Денежная сумма прописью: «Одна тысяча двести тридцать четыре рубля 56 копеек».
 *
 * Совпадает с приложением (Flutter `moneyToWordsRu`).
 */
export function moneyToWordsRu(amount: number, capitalizeValue = true): string {
  const negative = amount < 0;
  const { rubles, kopecks } = splitMoney(amount);

  const words = numberToWords(rubles);
  const rublesText = capitalizeValue ? capitalize(words) : words;
  const rublesUnit = pluralize(rubles, ["рубль", "рубля", "рублей"]);
  const kopecksUnit = pluralize(kopecks, ["копейка", "копейки", "копеек"]);
  const kopecksText = String(kopecks).padStart(2, "0");

  const result = `${rublesText} ${rublesUnit} ${kopecksText} ${kopecksUnit}`;
  return negative ? `Минус ${result}` : result;
}

/** Числовая сумма с единицами: «4 979 304 рубля 23 копейки». */
export function moneyNumericWithUnitsRu(amount: number): string {
  const negative = amount < 0;
  const { rubles, kopecks } = splitMoney(amount);
  const rublesText = new Intl.NumberFormat("ru-RU").format(rubles);
  const rublesUnit = pluralize(rubles, ["рубль", "рубля", "рублей"]);
  const kopecksUnit = pluralize(kopecks, ["копейка", "копейки", "копеек"]);
  const kopecksText = String(kopecks).padStart(2, "0");

  const result = `${rublesText} ${rublesUnit} ${kopecksText} ${kopecksUnit}`;
  return negative ? `Минус ${result}` : result;
}
