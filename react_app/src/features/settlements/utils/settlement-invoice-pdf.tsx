import { readFileSync } from "node:fs";
import path from "node:path";

import {
  Document,
  Font,
  Page,
  StyleSheet,
  Text,
  View,
  renderToBuffer,
} from "@react-pdf/renderer";
import { PDFDocument } from "pdf-lib";

import { moneyNumericWithUnitsRu, moneyToWordsRu } from "@/features/settlements/utils/money-to-words";
import {
  formatCurrency,
  formatQuantity,
  formatRuDate,
} from "@/features/settlements/utils/settlement.utils";

/** Данные счёта для PDF (шапка и суммы). */
export type SettlementInvoiceOperation = {
  invoiceNumber: string;
  invoiceDate: string;
  operationType: "act" | "advance" | "other";
  actNumber: string | null;
  note: string | null;
  purpose: string | null;
  contractNumber: string;
  objectName: string;
  contractorName: string;
  amount: number;
  vatRate: number | null;
  vatAmount: number;
  totalToPay: number;
  advanceRetention: number;
  warrantyRetention: number;
};

/** Реквизиты продавца (компания) для PDF. */
export type SettlementInvoiceCompany = {
  nameFull: string;
  legalAddress: string | null;
  inn: string | null;
  kpp: string | null;
  phone: string | null;
  email: string | null;
  directorName: string | null;
  chiefAccountantName: string | null;
};

/** Банковский счёт компании для PDF. */
export type SettlementInvoiceBankAccount = {
  bankName: string;
  bik: string | null;
  corrAccount: string | null;
  accountNumber: string;
};

/** Реквизиты покупателя (контрагент) для PDF. */
export type SettlementInvoiceContractor = {
  fullName: string;
  legalAddress: string;
  inn: string;
  kpp: string | null;
  phone: string;
  email: string;
};

/** Всё, что нужно, чтобы собрать PDF счёта на оплату. */
export type SettlementInvoicePdfInput = {
  operation: SettlementInvoiceOperation;
  company: SettlementInvoiceCompany;
  bankAccount: SettlementInvoiceBankAccount;
  contractor: SettlementInvoiceContractor;
};

let fontsRegistered = false;

/** Подключает шрифты Inter один раз на процесс. */
function registerFonts() {
  if (fontsRegistered) {
    return;
  }
  const dir = path.join(process.cwd(), "public", "fonts");
  const regular = readFileSync(path.join(dir, "Inter-Regular.ttf")).toString(
    "base64"
  );
  const bold = readFileSync(path.join(dir, "Inter-Bold.ttf")).toString("base64");

  Font.register({
    family: "Inter",
    fonts: [
      { src: `data:font/ttf;base64,${regular}`, fontWeight: "normal" },
      { src: `data:font/ttf;base64,${bold}`, fontWeight: "bold" },
    ],
  });
  fontsRegistered = true;
}

/** Стили PDF-документа счёта. */
const styles = StyleSheet.create({
  page: {
    fontFamily: "Inter",
    fontSize: 9,
    color: "#000000",
    paddingHorizontal: 28,
    paddingVertical: 24,
  },
  table: {
    borderWidth: 0.5,
    borderColor: "#000000",
  },
  row: { flexDirection: "row" },
  cell: {
    padding: 4,
    borderRightWidth: 0.5,
    borderBottomWidth: 0.5,
    borderColor: "#000000",
  },
  cellLast: { borderRightWidth: 0 },
  cellLabel: { fontWeight: "bold" },
  headerCell: { backgroundColor: "#E0E0E0", fontWeight: "bold" },
  bankPurpose: {
    padding: 4,
    borderTopWidth: 0.5,
    borderColor: "#000000",
  },
  purposeHint: { fontSize: 6 },
  title: {
    fontSize: 13,
    fontWeight: "bold",
    textAlign: "center",
    marginTop: 16,
    marginBottom: 14,
  },
  partyRow: { flexDirection: "row", marginBottom: 6 },
  partyLabel: { width: 72, fontWeight: "bold" },
  partyValue: { flex: 1 },
  itemsTable: {
    borderWidth: 0.5,
    borderColor: "#000000",
    marginTop: 12,
  },
  totals: { marginTop: 8, alignItems: "flex-end" },
  totalRow: { flexDirection: "row", marginBottom: 2 },
  totalLabel: { marginRight: 12 },
  bold: { fontWeight: "bold" },
  summaryBlock: { marginTop: 12 },
  summaryLine: { marginBottom: 6 },
  rule: { height: 1.5, backgroundColor: "#000000", marginTop: 6 },
  signatures: { marginTop: 28 },
  signatureRow: { flexDirection: "row", alignItems: "flex-end", marginBottom: 20 },
  signatureRole: { width: 72, fontSize: 8 },
  signatureField: {
    width: 140,
    height: 12,
    borderBottomWidth: 0.5,
    borderColor: "#000000",
  },
  signatureName: { marginLeft: 8, fontSize: 8 },
});

/** Сумма без символа рубля — в PDF валюта подписывается словами. */
function cleanCurrency(value: number): string {
  return formatCurrency(value).replace(/₽/g, "").trim();
}

/** Телефон в виде `+7 999 123-45-67`; нераспознанный номер возвращается как есть. */
function formatPhoneRu(value: string): string {
  const digits = value.replace(/\D/g, "");
  const normalized =
    digits.length === 11 && digits.startsWith("8") ? `7${digits.slice(1)}` : digits;
  if (normalized.length !== 11) {
    return value;
  }
  return `+7 ${normalized.slice(1, 4)} ${normalized.slice(4, 7)}-${normalized.slice(
    7,
    9
  )}-${normalized.slice(9, 11)}`;
}

/** Склеивает непустые части строки через запятую. */
function joinParts(parts: Array<string | null | undefined>): string {
  return parts
    .map((part) => part?.trim() ?? "")
    .filter((part) => part !== "")
    .join(", ");
}

/** Наименование позиции: примечание, иначе формулировка по типу счёта. */
function lineItemName(input: SettlementInvoicePdfInput): string {
  const { operation } = input;
  const note = operation.note?.trim();
  if (note) {
    return note;
  }

  const contract = operation.contractNumber.trim();
  const contractPart = contract ? ` по договору № ${contract}` : "";

  switch (operation.operationType) {
    case "act":
      return joinParts([
        `Выполнение работ${contractPart}`,
        operation.actNumber ? `(акт № ${operation.actNumber})` : null,
        operation.objectName ? `объект: ${operation.objectName}` : null,
      ]);
    case "advance":
      return `Авансовый платёж${contractPart}`;
    default: {
      const purpose = operation.purpose?.trim();
      return purpose || `Услуги${contractPart}`;
    }
  }
}

/** Основание платежа — договор. */
function basisText(input: SettlementInvoicePdfInput): string {
  const contract = input.operation.contractNumber.trim();
  return contract ? `Договор № ${contract}` : "—";
}

/** Назначение платежа для банковских реквизитов, с НДС при его наличии. */
function paymentPurposeText(input: SettlementInvoicePdfInput): string {
  const { operation } = input;
  const base = `Оплата по счету № ${operation.invoiceNumber} от ${formatRuDate(
    operation.invoiceDate
  )}`;
  const hasVat = operation.vatRate !== null && operation.vatRate > 0;
  if (hasVat && operation.vatAmount > 0) {
    return `${base}. В том числе НДС(${formatQuantity(
      operation.vatRate as number
    )}%) ${cleanCurrency(operation.vatAmount)} руб.`;
  }
  return base;
}

/** Строка продавца: название, адрес, ИНН, КПП, телефон, почта. */
function sellerLine(company: SettlementInvoiceCompany): string {
  return joinParts([
    company.nameFull,
    company.legalAddress,
    company.inn ? `ИНН ${company.inn}` : null,
    company.kpp ? `КПП ${company.kpp}` : null,
    company.phone ? `тел. ${formatPhoneRu(company.phone)}` : null,
    company.email ? `e-mail: ${company.email}` : null,
  ]);
}

/** Строка покупателя: название, адрес, ИНН, КПП, телефон, почта. */
function buyerLine(contractor: SettlementInvoiceContractor): string {
  return joinParts([
    contractor.fullName,
    contractor.legalAddress,
    contractor.inn ? `ИНН ${contractor.inn}` : null,
    contractor.kpp ? `КПП ${contractor.kpp}` : null,
    contractor.phone ? `тел. ${formatPhoneRu(contractor.phone)}` : null,
    contractor.email ? `e-mail: ${contractor.email}` : null,
  ]);
}

/** Разметка PDF «Счёт на оплату» (одна страница). */
function SettlementInvoiceDocument({
  input,
}: {
  input: SettlementInvoicePdfInput;
}) {
  const { operation, company, bankAccount, contractor } = input;
  const invoiceDate = formatRuDate(operation.invoiceDate);
  const hasVat = operation.vatRate !== null && operation.vatRate > 0;
  const lineAmount = operation.amount + operation.vatAmount;

  let wordsLine = moneyToWordsRu(operation.totalToPay);
  if (hasVat && operation.vatRate) {
    wordsLine += `, в том числе НДС(${formatQuantity(
      operation.vatRate
    )}%) ${moneyToWordsRu(operation.vatAmount, false)}`;
  }

  return (
    <Document>
      <Page size="A4" style={styles.page}>
        {/* Банковские реквизиты */}
        <View style={styles.table}>
          <View style={styles.row}>
            <Text style={[styles.cell, styles.cellLabel, { flex: 1.1 }]}>
              Банк получателя
            </Text>
            <Text style={[styles.cell, { flex: 2.4 }]}>
              {bankAccount.bankName}
            </Text>
            <Text style={[styles.cell, styles.cellLabel, { flex: 1.1 }]}>
              БИК
            </Text>
            <Text style={[styles.cell, styles.cellLast, { flex: 2.4 }]}>
              {bankAccount.bik ?? "—"}
            </Text>
          </View>
          <View style={styles.row}>
            <Text style={[styles.cell, styles.cellLabel, { flex: 1.1 }]}>
              Корр. счёт
            </Text>
            <Text style={[styles.cell, { flex: 2.4 }]}>
              {bankAccount.corrAccount ?? "—"}
            </Text>
            <Text style={[styles.cell, styles.cellLabel, { flex: 1.1 }]}>
              Сч. №
            </Text>
            <Text style={[styles.cell, styles.cellLast, { flex: 2.4 }]}>
              {bankAccount.accountNumber}
            </Text>
          </View>
          <View style={styles.row}>
            <Text style={[styles.cell, styles.cellLabel, { flex: 1.1 }]}>
              ИНН
            </Text>
            <Text style={[styles.cell, { flex: 2.4 }]}>{company.inn ?? "—"}</Text>
            <Text style={[styles.cell, styles.cellLabel, { flex: 1.1 }]}>
              КПП
            </Text>
            <Text style={[styles.cell, styles.cellLast, { flex: 2.4 }]}>
              {company.kpp ?? "—"}
            </Text>
          </View>
          <View style={styles.row}>
            <Text style={[styles.cell, styles.cellLabel, { flex: 1.1 }]}>
              Получатель
            </Text>
            <Text style={[styles.cell, styles.bold, styles.cellLast, { flex: 5.9 }]}>
              {company.nameFull}
            </Text>
          </View>
          <View style={styles.bankPurpose}>
            <Text>{paymentPurposeText(input)}</Text>
            <Text style={styles.purposeHint}>Назначение платежа</Text>
          </View>
        </View>

        <Text style={styles.title}>
          Счёт на оплату № {operation.invoiceNumber} от {invoiceDate}
        </Text>

        <View style={styles.partyRow}>
          <Text style={styles.partyLabel}>Поставщик:</Text>
          <Text style={styles.partyValue}>{sellerLine(company)}</Text>
        </View>
        <View style={styles.partyRow}>
          <Text style={styles.partyLabel}>Покупатель:</Text>
          <Text style={styles.partyValue}>{buyerLine(contractor)}</Text>
        </View>
        <View style={styles.partyRow}>
          <Text style={styles.partyLabel}>Основание:</Text>
          <Text style={styles.partyValue}>{basisText(input)}</Text>
        </View>

        {/* Таблица позиций */}
        <View style={styles.itemsTable}>
          <View style={styles.row}>
            <Text style={[styles.cell, styles.headerCell, { flex: 0.5, textAlign: "center" }]}>
              №
            </Text>
            <Text style={[styles.cell, styles.headerCell, { flex: 4.5 }]}>
              Наименование
            </Text>
            <Text style={[styles.cell, styles.headerCell, { flex: 1, textAlign: "center" }]}>
              Ед.
            </Text>
            <Text style={[styles.cell, styles.headerCell, { flex: 0.8, textAlign: "center" }]}>
              Кол-во
            </Text>
            <Text style={[styles.cell, styles.headerCell, { flex: 1.2, textAlign: "right" }]}>
              Цена
            </Text>
            <Text style={[styles.cell, styles.headerCell, styles.cellLast, { flex: 1.2, textAlign: "right" }]}>
              Сумма
            </Text>
          </View>
          <View style={styles.row}>
            <Text style={[styles.cell, { flex: 0.5, textAlign: "center" }]}>1</Text>
            <Text style={[styles.cell, { flex: 4.5 }]}>{lineItemName(input)}</Text>
            <Text style={[styles.cell, { flex: 1, textAlign: "center" }]}>усл.</Text>
            <Text style={[styles.cell, { flex: 0.8, textAlign: "center" }]}>1</Text>
            <Text style={[styles.cell, { flex: 1.2, textAlign: "right" }]}>
              {cleanCurrency(lineAmount)}
            </Text>
            <Text style={[styles.cell, styles.cellLast, { flex: 1.2, textAlign: "right" }]}>
              {cleanCurrency(lineAmount)}
            </Text>
          </View>
        </View>

        {/* Итоги */}
        <View style={styles.totals}>
          <View style={styles.totalRow}>
            <Text style={styles.totalLabel}>Итого:</Text>
            <Text>{cleanCurrency(lineAmount)}</Text>
          </View>
          {hasVat ? (
            <View style={styles.totalRow}>
              <Text style={styles.totalLabel}>
                НДС {formatQuantity(operation.vatRate as number)}%:
              </Text>
              <Text>{cleanCurrency(operation.vatAmount)}</Text>
            </View>
          ) : null}
          {operation.advanceRetention > 0 ? (
            <View style={styles.totalRow}>
              <Text style={styles.totalLabel}>Удержание аванса:</Text>
              <Text>- {cleanCurrency(operation.advanceRetention)}</Text>
            </View>
          ) : null}
          {operation.warrantyRetention > 0 ? (
            <View style={styles.totalRow}>
              <Text style={styles.totalLabel}>Гарантийное удержание:</Text>
              <Text>- {cleanCurrency(operation.warrantyRetention)}</Text>
            </View>
          ) : null}
          <View style={styles.totalRow}>
            <Text style={[styles.totalLabel, styles.bold]}>Всего к оплате:</Text>
            <Text style={styles.bold}>{cleanCurrency(operation.totalToPay)}</Text>
          </View>
        </View>

        {/* Сумма прописью */}
        <View style={styles.summaryBlock}>
          <Text style={styles.summaryLine}>
            Всего наименований 1, на сумму {moneyNumericWithUnitsRu(operation.totalToPay)}
          </Text>
          <Text style={[styles.summaryLine, styles.bold]}>{wordsLine}.</Text>
          <View style={styles.rule} />
        </View>

        {/* Подписи */}
        <View style={styles.signatures}>
          <View style={styles.signatureRow}>
            <Text style={styles.signatureRole}>Руководитель</Text>
            <View style={styles.signatureField} />
            <Text style={styles.signatureName}>
              {company.directorName?.trim() || " "}
            </Text>
          </View>
          <View style={styles.signatureRow}>
            <Text style={styles.signatureRole}>Бухгалтер</Text>
            <View style={styles.signatureField} />
            <Text style={styles.signatureName}>
              {company.chiefAccountantName?.trim() || " "}
            </Text>
          </View>
        </View>
      </Page>
    </Document>
  );
}

/** Формирует PDF счёта на оплату и возвращает байты. */
export async function buildSettlementInvoicePdf(
  input: SettlementInvoicePdfInput
): Promise<Uint8Array> {
  registerFonts();

  const buffer = await renderToBuffer(<SettlementInvoiceDocument input={input} />);

  // Метаданные документа.
  const pdf = await PDFDocument.load(buffer);
  pdf.setTitle(
    `Счёт на оплату № ${input.operation.invoiceNumber} от ${formatRuDate(
      input.operation.invoiceDate
    )}`
  );
  pdf.setProducer("Стройка PRO");
  pdf.setCreator("Стройка PRO");
  return pdf.save();
}
