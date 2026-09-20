"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import {
  deleteSettlementFile,
  downloadSettlementFile,
  getSettlementFiles,
  uploadSettlementFile,
} from "@/features/settlements/api/settlement-files";
import type { SettlementFile } from "@/features/settlements/types/settlement.types";
import { saveBlobAsFile } from "@/features/settlements/utils/download";

/** Ключ кэша вложений по счёту. */
export function settlementFilesQueryKey(settlementOperationId: string) {
  return ["settlement-files", settlementOperationId] as const;
}

/** Файлы по счёту. */
export function useSettlementFiles(
  settlementOperationId: string | null,
  enabled = true
) {
  return useQuery({
    queryKey: settlementFilesQueryKey(settlementOperationId ?? "none"),
    queryFn: () => getSettlementFiles(settlementOperationId as string),
    enabled: Boolean(settlementOperationId) && enabled,
  });
}

/** Прикрепляет файл к счёту. */
export function useUploadSettlementFile(settlementOperationId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: {
      file: File;
      name: string;
      description?: string | null;
    }) =>
      uploadSettlementFile({
        settlementOperationId,
        file: input.file,
        name: input.name,
        description: input.description,
      }),
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: settlementFilesQueryKey(settlementOperationId),
      });
    },
  });
}

/** Удаляет вложение счёта (запись и объект в Storage). */
export function useDeleteSettlementFile(settlementOperationId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (file: Pick<SettlementFile, "id" | "filePath">) =>
      deleteSettlementFile(file.id, file.filePath),
    onSuccess: () => {
      void queryClient.invalidateQueries({
        queryKey: settlementFilesQueryKey(settlementOperationId),
      });
    },
  });
}

/** Скачивает файл и сохраняет на устройство пользователя. */
export async function downloadSettlementFileForUser(
  file: SettlementFile
): Promise<void> {
  saveBlobAsFile(await downloadSettlementFile(file.filePath), file.name);
}
