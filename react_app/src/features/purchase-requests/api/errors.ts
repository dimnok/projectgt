export function throwIfError(error: { message: string } | null) {
  if (error) {
    throw new Error(error.message);
  }
}

export const PURCHASE_REQUESTS_BUCKET = "purchase_requests";
export const REQUEST_SELECT = "*, objects:object_id(name)";
