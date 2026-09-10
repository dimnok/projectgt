import { getRequiredClient } from "@/lib/supabase/client";
import { parseLocalDate } from "@/features/works/utils/work.utils";

async function compressImageFile(
  file: File,
  maxSide = 1600,
  quality = 0.85
): Promise<{ blob: Blob; mime: string }> {
  if (file.type === "image/svg+xml") {
    return { blob: file, mime: file.type };
  }

  return new Promise((resolve) => {
    const reader = new FileReader();
    reader.onload = (event) => {
      const img = new Image();
      img.onload = () => {
        let width = img.naturalWidth || img.width;
        let height = img.naturalHeight || img.height;
        if (width > maxSide || height > maxSide) {
          if (width >= height) {
            height = Math.round((height * maxSide) / width);
            width = maxSide;
          } else {
            width = Math.round((width * maxSide) / height);
            height = maxSide;
          }
        }
        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext("2d");
        if (!ctx) {
          resolve({ blob: file, mime: file.type || "image/jpeg" });
          return;
        }
        ctx.drawImage(img, 0, 0, width, height);
        canvas.toBlob(
          (blob) => {
            resolve({
              blob: blob ?? file,
              mime: blob ? "image/jpeg" : file.type || "image/jpeg",
            });
          },
          "image/jpeg",
          quality
        );
      };
      img.onerror = () => {
        resolve({ blob: file, mime: file.type || "image/jpeg" });
      };
      img.src = event.target?.result as string;
    };
    reader.onerror = () => {
      resolve({ blob: file, mime: file.type || "image/jpeg" });
    };
    reader.readAsDataURL(file);
  });
}

function pad(value: number): string {
  return String(value).padStart(2, "0");
}

export type WorkPhotoKind = "morning" | "evening";

/**
 * Uploads a shift photo to bucket `works`.
 * Path matches Flutter PhotoService: `{objectId}/{dd-MM-yyyy}/{timestamp}_{kind}.jpg`.
 */
export async function uploadWorkShiftPhoto(
  objectId: string,
  file: File,
  kind: WorkPhotoKind,
  workDate?: string
): Promise<string> {
  if (!objectId) {
    throw new Error("Не выбран объект");
  }

  const client = getRequiredClient();
  const { blob, mime } = await compressImageFile(file);
  const now = new Date();
  const folderDate = workDate ? parseLocalDate(workDate) : now;
  const dateFolder = `${pad(folderDate.getDate())}-${pad(folderDate.getMonth() + 1)}-${folderDate.getFullYear()}`;
  const stamp = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}_${pad(now.getHours())}-${pad(now.getMinutes())}-${pad(now.getSeconds())}`;
  const filePath = `${objectId}/${dateFolder}/${stamp}_${kind}.jpg`;

  const { error } = await client.storage.from("works").upload(filePath, blob, {
    contentType: mime,
    upsert: true,
  });

  if (error) {
    throw new Error(`Не удалось загрузить фото: ${error.message}`);
  }

  const { data } = client.storage.from("works").getPublicUrl(filePath);
  if (!data.publicUrl) {
    throw new Error("Не удалось получить ссылку на фото");
  }
  return data.publicUrl;
}

export async function uploadWorkMorningPhoto(
  objectId: string,
  file: File
): Promise<string> {
  return uploadWorkShiftPhoto(objectId, file, "morning");
}
