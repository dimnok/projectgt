export function formatCurrency(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    style: "currency",
    currency: "RUB",
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);
}

export function formatPurchaseRequestAmount(amount: number) {
  return amount > 0 ? formatCurrency(amount) : "—";
}

export function formatQuantity(value: number): string {
  return new Intl.NumberFormat("ru-RU", {
    maximumFractionDigits: 3,
  }).format(value);
}

/** «5 заявок», «1 заявка», «2 заявки» — склонение по числу. */
export function purchaseRequestCountLabel(count: number): string {
  const mod10 = count % 10;
  const mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 19) {
    return `${count} заявок`;
  }
  if (mod10 === 1) {
    return `${count} заявка`;
  }
  if (mod10 >= 2 && mod10 <= 4) {
    return `${count} заявки`;
  }
  return `${count} заявок`;
}

/** «5 шт × 116,00 ₽ = 580,00 ₽» — компактная строка позиции счёта. */
export function formatInvoiceItemAmounts(item: {
  quantity: number | null;
  unit: string | null;
  price: number | null;
  amount: number | null;
}): string {
  const quantity =
    item.quantity !== null
      ? `${formatQuantity(item.quantity)}${item.unit ? ` ${item.unit}` : ""}`
      : null;
  const price = item.price !== null ? formatCurrency(item.price) : null;
  const amount = item.amount !== null ? formatCurrency(item.amount) : null;

  if (quantity && price && amount) {
    return `${quantity} × ${price} = ${amount}`;
  }
  return [quantity, price, amount].filter(Boolean).join(" · ");
}

export function formatRuDate(value: string | null | undefined): string {
  if (!value) {
    return "—";
  }
  const clean = value.split("T")[0];
  const [year, month, day] = clean.split("-");
  if (!year || !month || !day) {
    return value;
  }
  return `${day}.${month}.${year}`;
}

export function formatRuDateTime(value: string | Date | null | undefined): string {
  if (!value) {
    return "—";
  }
  const date = typeof value === "string" ? new Date(value) : value;
  if (Number.isNaN(date.getTime())) {
    return String(value);
  }
  const day = String(date.getDate()).padStart(2, "0");
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const year = date.getFullYear();
  const hours = String(date.getHours()).padStart(2, "0");
  const minutes = String(date.getMinutes()).padStart(2, "0");
  return `${day}.${month}.${year} ${hours}:${minutes}`;
}
