import { getRequiredClient } from "@/lib/supabase/client";
import { getActiveCompanyId } from "@/lib/supabase/company";
import type { Employee } from "@/features/employees/types/employee.types";

/**
 * Compresses and resizes an image file to max 1600px width/height
 * with 85% JPEG quality to optimize storage and upload speed.
 */
async function compressImageFile(
  file: File,
  maxSide = 1600,
  quality = 0.85
): Promise<{ blob: Blob; ext: string; mime: string }> {
  return new Promise((resolve) => {
    // If it's SVG, don't rasterize/compress
    if (file.type === "image/svg+xml") {
      resolve({ blob: file, ext: "svg", mime: file.type });
      return;
    }

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
          resolve({ blob: file, ext: "jpg", mime: file.type || "image/jpeg" });
          return;
        }

        ctx.drawImage(img, 0, 0, width, height);
        canvas.toBlob(
          (blob) => {
            if (blob) {
              resolve({ blob, ext: "jpg", mime: "image/jpeg" });
            } else {
              resolve({
                blob: file,
                ext: "jpg",
                mime: file.type || "image/jpeg",
              });
            }
          },
          "image/jpeg",
          quality
        );
      };
      img.onerror = () => {
        resolve({ blob: file, ext: "jpg", mime: file.type || "image/jpeg" });
      };
      img.src = event.target?.result as string;
    };
    reader.onerror = () => {
      resolve({ blob: file, ext: "jpg", mime: file.type || "image/jpeg" });
    };
    reader.readAsDataURL(file);
  });
}

/**
 * Uploads a new photo for an employee into the `employees` storage bucket
 * and updates the employee's `photo_url` in the database.
 */
export async function uploadEmployeePhoto(
  employee: Employee,
  file: File
): Promise<string> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  const { blob, ext, mime } = await compressImageFile(file);

  // 1. Delete previous photos from storage folder if any
  try {
    const { data: existingFiles } = await client.storage
      .from("employees")
      .list(employee.id);
    if (existingFiles && existingFiles.length > 0) {
      const paths = existingFiles
        .filter((f) => !f.name.startsWith("."))
        .map((f) => `${employee.id}/${f.name}`);
      if (paths.length > 0) {
        await client.storage.from("employees").remove(paths);
      }
    }
  } catch (err) {
    console.warn("Storage cleanup notice:", err);
  }

  // 2. Upload new photo
  const timestamp = Date.now();
  const filePath = `${employee.id}/avatar_${timestamp}.${ext}`;
  const { error: uploadError } = await client.storage
    .from("employees")
    .upload(filePath, blob, {
      contentType: mime,
      upsert: true,
    });

  if (uploadError) {
    throw new Error(`Ошибка загрузки фото: ${uploadError.message}`);
  }

  // 3. Get public URL with cache-buster parameter to ensure fresh display
  const { data: publicUrlData } = client.storage
    .from("employees")
    .getPublicUrl(filePath);
  const publicUrl = publicUrlData.publicUrl;

  // 4. Update employee record
  const { error: dbError } = await client
    .from("employees")
    .update({
      photo_url: publicUrl,
      updated_at: new Date().toISOString(),
    })
    .eq("id", employee.id)
    .eq("company_id", companyId);

  if (dbError) {
    throw new Error(`Ошибка сохранения фото: ${dbError.message}`);
  }

  return publicUrl;
}

/**
 * Removes the photo from storage and clears `photo_url` in the database.
 */
export async function deleteEmployeePhoto(employee: Employee): Promise<void> {
  const client = getRequiredClient();
  const companyId = await getActiveCompanyId();

  // 1. Delete files in employee's folder
  try {
    const { data: existingFiles } = await client.storage
      .from("employees")
      .list(employee.id);
    if (existingFiles && existingFiles.length > 0) {
      const paths = existingFiles
        .filter((f) => !f.name.startsWith("."))
        .map((f) => `${employee.id}/${f.name}`);
      if (paths.length > 0) {
        await client.storage.from("employees").remove(paths);
      }
    }
  } catch (err) {
    console.warn("Storage cleanup notice:", err);
  }

  // 2. Clear photo_url in DB
  const { error: dbError } = await client
    .from("employees")
    .update({
      photo_url: null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", employee.id)
    .eq("company_id", companyId);

  if (dbError) {
    throw new Error(`Ошибка удаления фото: ${dbError.message}`);
  }
}

/**
 * Downloads the employee's photo to the user's device.
 */
export async function downloadEmployeePhoto(
  photoUrl: string,
  employee: Employee
): Promise<void> {
  const fullName = [employee.lastName, employee.firstName, employee.middleName]
    .filter(Boolean)
    .join("_");
  const filename = `${fullName || "employee"}_photo.jpg`;

  try {
    const res = await fetch(photoUrl);
    if (!res.ok) throw new Error("Fetch failed");
    const blob = await res.blob();
    const blobUrl = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = blobUrl;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(blobUrl);
  } catch {
    // Fallback if cross-origin fetch is blocked
    const link = document.createElement("a");
    link.href = photoUrl;
    link.target = "_blank";
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }
}
