/**
 * Tax regimes for contractors. Labels match the company form
 * (`CompanyFormContent.taxationSystems`, 2026).
 * ПСН and НПД are added because a contractor can be an individual entrepreneur.
 */
export const TAXATION_SYSTEMS = [
  "ОСНО",
  "УСН «Доходы»",
  "УСН «Доходы минус расходы»",
  "АУСН «Доходы»",
  "АУСН «Доходы минус расходы»",
  "ЕСХН",
  "ПСН",
  "НПД",
] as const;

export type TaxationSystem = (typeof TAXATION_SYSTEMS)[number];

export const TAXATION_NONE_VALUE = "__none__";

export const TAXATION_SYSTEM_OPTIONS = [
  { value: TAXATION_NONE_VALUE, label: "Не указана" },
  ...TAXATION_SYSTEMS.map((value) => ({ value, label: value })),
];

export function isTaxationSystem(value: string): value is TaxationSystem {
  return (TAXATION_SYSTEMS as readonly string[]).includes(value);
}

export function taxationSelectItems(current: string) {
  if (!current || isTaxationSystem(current)) {
    return TAXATION_SYSTEM_OPTIONS;
  }
  return [
    { value: current, label: current },
    ...TAXATION_SYSTEM_OPTIONS,
  ];
}
