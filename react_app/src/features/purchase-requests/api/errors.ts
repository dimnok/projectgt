/** Ответ Supabase с ошибкой превращаем в исключение: его ловит интерфейс. */
export function throwIfError(error: { message: string } | null) {
  if (error) {
    throw new Error(error.message);
  }
}

/** Хранилище файлов счетов. Путь файла всегда начинается с компании. */
export const PURCHASE_REQUESTS_BUCKET = "purchase_requests";

/** Набор полей заявки вместе с названием объекта. */
export const REQUEST_SELECT = "*, objects:object_id(name)";
