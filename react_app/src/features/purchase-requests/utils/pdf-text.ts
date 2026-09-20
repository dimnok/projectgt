/**
 * Текст PDF целиком — вход для распознавания счёта.
 *
 * Разбор делаем в браузере: на устройстве пользователя это доли секунды,
 * а в среде серверной функции тяжёлый PDF-парсер работает непредсказуемо
 * долго. На сервер уходит уже текст — функция остаётся лёгкой и быстрой.
 */
export async function extractPdfText(file: File): Promise<string> {
  // Библиотека грузится только когда её действительно вызвали.
  const pdfjs = await import("pdfjs-dist");
  pdfjs.GlobalWorkerOptions.workerSrc = new URL(
    "pdfjs-dist/build/pdf.worker.min.mjs",
    import.meta.url
  ).toString();

  const data = new Uint8Array(await file.arrayBuffer());
  const document = await pdfjs.getDocument({
    data,
    isEvalSupported: false,
  }).promise;

  try {
    const pages: string[] = [];
    for (let pageNumber = 1; pageNumber <= document.numPages; pageNumber += 1) {
      const page = await document.getPage(pageNumber);
      const content = await page.getTextContent();
      pages.push(
        content.items
          .map((item) => ("str" in item ? item.str : ""))
          .join(" ")
      );
    }
    return pages.join("\n");
  } finally {
    await document.destroy();
  }
}

/** Ниже этого порога считаем, что текстового слоя в файле нет (скан или фото). */
export const MIN_INVOICE_TEXT_LENGTH = 120;
