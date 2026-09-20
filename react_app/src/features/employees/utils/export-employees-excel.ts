import type { Employee } from "@/features/employees/types/employee.types";
import { employeeEmploymentLabel } from "@/features/employees/utils/employee-employment";
import { employeeStatusLabel } from "@/features/employees/utils/employee-status";
import {
  employeeFullName,
  formatRuDate,
  objectNamesLabel,
} from "@/features/employees/utils/employee.utils";
import { formatPhone } from "@/lib/utils/phone";

const FONT_FAMILY = "Calibri";

const borderThin = {
  top: { style: "thin" as const, color: { argb: "FFD0D7DE" } },
  left: { style: "thin" as const, color: { argb: "FFD0D7DE" } },
  bottom: { style: "thin" as const, color: { argb: "FFD0D7DE" } },
  right: { style: "thin" as const, color: { argb: "FFD0D7DE" } },
};

const HEADERS = [
  "ФИО",
  "Должность",
  "Статус",
  "Вид трудоустройства",
  "Дата приёма",
  "Объекты",
  "Телефон",
  "Дата рождения",
  "Место рождения",
  "Гражданство",
  "Размер одежды",
  "Размер обуви",
  "Рост",
  "Паспорт (серия и номер)",
  "Кем выдан",
  "Дата выдачи",
  "Код подразделения",
  "Адрес регистрации",
  "ИНН",
  "СНИЛС",
  "КИГ",
  "Номер патента",
] as const;

const COLUMN_WIDTHS = [
  28, 18, 14, 18, 12, 32, 18, 12, 20, 14, 14, 12, 10, 20, 28, 12, 14, 36, 14,
  16, 16, 18,
];

export type ExportEmployeesExcelOptions = {
  employees: Employee[];
  objectNamesById: Map<string, string>;
};

function todayIsoDate(): string {
  const now = new Date();
  const year = now.getFullYear();
  const month = String(now.getMonth() + 1).padStart(2, "0");
  const day = String(now.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

function passportLabel(employee: Employee): string {
  return `${employee.passportSeries} ${employee.passportNumber}`.trim();
}

function downloadWorkbook(buffer: ArrayBuffer, fileName: string) {
  const blob = new Blob([buffer], {
    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  });
  const url = window.URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = fileName;
  document.body.appendChild(anchor);
  anchor.click();
  document.body.removeChild(anchor);
  window.URL.revokeObjectURL(url);
}

/**
 * Builds and downloads an Excel file with the visible employee list.
 * Rates and trip allowances are not included.
 */
export async function exportEmployeesToExcel({
  employees,
  objectNamesById,
}: ExportEmployeesExcelOptions): Promise<void> {
  if (employees.length === 0) {
    throw new Error("Нет сотрудников для выгрузки");
  }

  const ExcelJS = await import("exceljs");
  const workbook = new ExcelJS.Workbook();
  workbook.creator = "ProjectGT";
  workbook.created = new Date();

  const sheet = workbook.addWorksheet("Сотрудники", {
    views: [{ state: "frozen", ySplit: 1 }],
  });

  sheet.columns = COLUMN_WIDTHS.map((width) => ({ width }));

  const headerRow = sheet.addRow([...HEADERS]);
  headerRow.font = { bold: true, size: 11, name: FONT_FAMILY, color: { argb: "FF1F2328" } };
  headerRow.alignment = { horizontal: "center", vertical: "middle", wrapText: true };
  headerRow.height = 28;
  headerRow.eachCell((cell) => {
    cell.border = borderThin;
    cell.fill = {
      type: "pattern",
      pattern: "solid",
      fgColor: { argb: "FFF2F2F2" },
    };
  });

  for (const employee of employees) {
    const row = sheet.addRow([
      employeeFullName(employee),
      employee.position,
      employeeStatusLabel(employee.status),
      employeeEmploymentLabel(employee.employmentType),
      formatRuDate(employee.employmentDate),
      objectNamesLabel(employee.objectIds, objectNamesById),
      formatPhone(employee.phone) || employee.phone,
      formatRuDate(employee.birthDate),
      employee.birthPlace,
      employee.citizenship,
      employee.clothingSize,
      employee.shoeSize,
      employee.height,
      passportLabel(employee),
      employee.passportIssuedBy,
      formatRuDate(employee.passportIssueDate),
      employee.passportDepartmentCode,
      employee.registrationAddress,
      employee.inn,
      employee.snils,
      employee.kig,
      employee.patentNumber,
    ]);
    row.font = { name: FONT_FAMILY, size: 11, color: { argb: "FF24292F" } };
    row.alignment = { vertical: "middle", wrapText: true };
    row.eachCell((cell) => {
      cell.border = borderThin;
    });
  }

  const buffer = await workbook.xlsx.writeBuffer();
  downloadWorkbook(
    buffer as ArrayBuffer,
    `Сотрудники_${formatRuDate(todayIsoDate())}.xlsx`
  );
}
