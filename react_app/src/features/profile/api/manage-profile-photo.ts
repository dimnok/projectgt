import { getRequiredClient } from "@/lib/supabase/client";
import { compressImageFile } from "@/features/profile/utils/compress-image";

const AVATARS_BUCKET = "avatars";

function profileFolder(userId: string) {
  return `profiles/${userId}`;
}

async function removeExistingAvatars(userId: string) {
  const client = getRequiredClient();
  const folder = profileFolder(userId);

  const { data: existingFiles } = await client.storage
    .from(AVATARS_BUCKET)
    .list(folder);

  if (!existingFiles || existingFiles.length === 0) {
    return;
  }

  const paths = existingFiles
    .filter((file) => !file.name.startsWith("."))
    .map((file) => `${folder}/${file.name}`);

  if (paths.length > 0) {
    await client.storage.from(AVATARS_BUCKET).remove(paths);
  }
}

async function requireUserId() {
  const client = getRequiredClient();
  const {
    data: { user },
    error,
  } = await client.auth.getUser();

  if (error || !user) {
    throw new Error("Нужно войти в аккаунт");
  }

  return { client, userId: user.id };
}

/**
 * Uploads a profile photo to Storage bucket `avatars` (`profiles/{userId}/`)
 * and writes `photo_url` on the profile row.
 */
export async function uploadProfilePhoto(file: File): Promise<string> {
  const { client, userId } = await requireUserId();
  const { blob, ext, mime } = await compressImageFile(file);

  try {
    await removeExistingAvatars(userId);
  } catch {
    // Cleanup is best-effort; upload still proceeds.
  }

  const timestamp = Date.now();
  const filePath = `${profileFolder(userId)}/avatar_${timestamp}.${ext}`;
  const { error: uploadError } = await client.storage
    .from(AVATARS_BUCKET)
    .upload(filePath, blob, {
      contentType: mime,
      upsert: true,
    });

  if (uploadError) {
    throw new Error(`Ошибка загрузки фото: ${uploadError.message}`);
  }

  const { data: publicUrlData } = client.storage
    .from(AVATARS_BUCKET)
    .getPublicUrl(filePath);
  const publicUrl = `${publicUrlData.publicUrl}?t=${timestamp}`;

  const { error: dbError } = await client
    .from("profiles")
    .update({
      photo_url: publicUrl,
      updated_at: new Date().toISOString(),
    })
    .eq("id", userId);

  if (dbError) {
    throw new Error(`Ошибка сохранения фото: ${dbError.message}`);
  }

  return publicUrl;
}

/**
 * Removes profile photos from Storage and clears `photo_url`.
 */
export async function deleteProfilePhoto(): Promise<void> {
  const { client, userId } = await requireUserId();

  try {
    await removeExistingAvatars(userId);
  } catch {
    // Storage cleanup is best-effort.
  }

  const { error } = await client
    .from("profiles")
    .update({
      photo_url: null,
      updated_at: new Date().toISOString(),
    })
    .eq("id", userId);

  if (error) {
    throw new Error(`Ошибка удаления фото: ${error.message}`);
  }
}
