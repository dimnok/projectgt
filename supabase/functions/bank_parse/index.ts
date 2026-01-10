import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import xlsx from "npm:xlsx";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Access-Control-Allow-Headers": "authorization, content-type, apikey, x-client-info"
};

/**
 * Генерирует SHA-256 хеш для строки данных.
 */
async function generateHash(data: string): Promise<string> {
  const msgUint8 = new TextEncoder().encode(data);
  const hashBuffer = await crypto.subtle.digest("SHA-256", msgUint8);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

/**
 * Очищает номер счета от пробелов и других символов.
 */
function cleanAccountNumber(acc: string): string {
  return String(acc || "").replace(/[^\d]/g, "").trim();
}

/**
 * Приводит дату к формату dd.MM.yyyy
 */
function formatDate(date: any): string | null {
  if (!date) return null;
  
  if (date instanceof Date) {
    const d = date.getDate().toString().padStart(2, '0');
    const m = (date.getMonth() + 1).toString().padStart(2, '0');
    const y = date.getFullYear();
    return `${d}.${m}.${y}`;
  }
  
  return String(date).trim();
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: cors });
  }

  try {
    const { file, mapping, companyId, bankAccountId, targetInn, targetAccountNumber } = await req.json();
    if (!file) throw new Error("Missing file base64");

    const bin = atob(file);
    const bytes = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);

    const wb = xlsx.read(bytes, { type: "buffer", cellDates: true });
    const sheetName = wb.SheetNames[0];
    const ws = wb.Sheets[sheetName];
    if (!ws) throw new Error("Sheet not found");

    const dataStartRow = mapping?.startRow ?? 1;
    const data = xlsx.utils.sheet_to_json(ws, { header: 1, defval: null });

    // --- Оптимизированный скан заголовка (One-pass Header Scan) ---
    let foundInn: string | null = null;
    let foundAccount: string | null = null;
    const headerIndices = {};

    for (let i = 0; i < dataStartRow; i++) {
      const row = data[i] || [];
      const rowText = row.join(" ").toLowerCase();
      
      // 1. Поиск данных для валидации (только в строках ДО начала данных)
      if (i < dataStartRow - 1) {
        if (!foundInn && (rowText.includes("инн владельца") || rowText.includes("инн:"))) {
          const numbersOnly = rowText.replace(/[^\d]/g, "");
          const innMatch = numbersOnly.match(/\d{10,12}/);
          if (innMatch) foundInn = innMatch[0];
        }
        
        if (!foundAccount && (rowText.includes("выписка по счёту") || rowText.includes("счет №") || rowText.includes("счёт №") || rowText.includes("расчетный счет"))) {
          const numbersOnly = rowText.replace(/[^\d]/g, "");
          const accMatch = numbersOnly.match(/\d{20}/);
          if (accMatch) foundAccount = accMatch[0];
        }
      }

      // 2. Сбор индексов колонок для маппинга
      row.forEach((cell, idx) => {
        const val = String(cell || "").trim().toLowerCase();
        if (val) {
          if (!headerIndices[idx]) headerIndices[idx] = new Set();
          headerIndices[idx].add(val);
        }
      });
    }

    // --- Валидация ---
    if (targetInn) {
      if (!foundInn) throw new Error("В заголовке выписки не найден ИНН владельца. Проверка безопасности не пройдена.");
      if (targetInn !== foundInn) throw new Error(`Выписка принадлежит компании с ИНН ${foundInn}, а вы загружаете в компанию с ИНН ${targetInn}.`);
    }

    if (targetAccountNumber) {
      if (!foundAccount) throw new Error("В заголовке выписки не найден номер банковского счета. Проверка безопасности не пройдена.");
      const cleanTarget = cleanAccountNumber(targetAccountNumber);
      const cleanFound = cleanAccountNumber(foundAccount);
      if (cleanTarget !== cleanFound) {
        throw new Error(`Выписка по счету ...${cleanFound.slice(-4)}, а выбрана загрузка в счет ...${cleanTarget.slice(-4)}.`);
      }
    }

    // --- Маппинг колонок ---
    const findIndex = (name) => {
      if (!name) return -1;
      const lowerName = String(name).toLowerCase();
      for (const [idx, names] of Object.entries(headerIndices)) {
        if ((names as Set<string>).has(lowerName)) return parseInt(idx);
      }
      return -1;
    };

    const colMapping = mapping?.columnMapping || {};
    const indices = {};
    Object.keys(colMapping).forEach(key => {
      indices[key] = findIndex(colMapping[key]);
    });

    const isNonEmpty = (val) => {
      if (val == null) return false;
      const s = String(val).trim();
      return s !== '' && s !== '0' && s !== '0,00' && s !== '0.00';
    };

    // --- Параллельная обработка строк (Promise-based Hashing) ---
    const rowPromises = [];

    for (let i = dataStartRow - 1; i < data.length; i++) {
      const row = data[i];
      if (!row || row.length === 0) continue;

      const getValue = (key) => {
        const idx = indices[key];
        return (idx !== undefined && idx !== -1) ? row[idx] : null;
      };

      const dateVal = getValue('date');
      let amount = null;
      let type = 'expense';

      const creditRaw = getValue('amount_credit');
      const debitRaw = getValue('amount_debit');
      const amtRaw = getValue('amount');

      if (isNonEmpty(creditRaw)) {
        amount = creditRaw;
        type = 'income';
      } else if (isNonEmpty(debitRaw)) {
        amount = debitRaw;
        type = 'expense';
      } else if (amtRaw != null) {
        amount = amtRaw;
        const typeRaw = getValue('type')?.toString().toLowerCase() || '';
        if (typeRaw.includes('приход') || typeRaw.includes('доход') || typeRaw === '+') {
          type = 'income';
        }
      }

      if (dateVal == null && amount == null) continue;

      const contractorName = getValue('contractor_name');
      const contractorInn = getValue('contractor_inn');
      const comment = getValue('comment');
      const transactionNumber = getValue('transaction_number');
      const formattedDate = formatDate(dateVal);

      // Формируем задачу на хеширование
      const hashString = [
        companyId || 'no_company',
        bankAccountId || 'no_account',
        formattedDate || 'no_date',
        String(amount || 0),
        type,
        String(contractorInn || 'no_inn').trim(),
        String(transactionNumber || 'no_number').trim(),
        String(comment || 'no_comment').trim(),
      ].join('|');

      const processRow = async () => ({
        date: formattedDate,
        amount: amount,
        type: type,
        contractor_name: contractorName,
        contractor_inn: contractorInn,
        comment: comment,
        transaction_number: transactionNumber,
        operation_hash: await generateHash(hashString),
      });

      rowPromises.push(processRow());
    }

    const items = await Promise.all(rowPromises);

    return new Response(JSON.stringify({ items }), {
      headers: { ...cors, "Content-Type": "application/json" }
    });

  } catch (e) {
    return new Response(JSON.stringify({ error: String(e?.message ?? e) }), {
      status: 400,
      headers: { ...cors, "Content-Type": "application/json" }
    });
  }
});
