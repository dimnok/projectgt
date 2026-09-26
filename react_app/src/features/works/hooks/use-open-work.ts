"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { closeWork } from "@/features/works/api/close-work";
import { deleteWork } from "@/features/works/api/delete-work";
import {
  getMyOpenWorkId,
  getOccupiedEmployeeIdsToday,
  getProfileObjectIds,
} from "@/features/works/api/get-open-work-context";
import {
  addWorkShiftPhotos,
  deleteWorkShiftPhotoAt,
  replaceWorkShiftPhotoAt,
} from "@/features/works/api/manage-work-photo";
import { openWork, type OpenWorkDraft } from "@/features/works/api/open-work";
import { reopenWork } from "@/features/works/api/reopen-work";
import type { WorkPhotoKind } from "@/features/works/api/upload-work-photo";
import type { Work } from "@/features/works/types/work.types";

export function useMyOpenWorkId() {
  return useQuery({
    queryKey: ["works", "my-open-id"],
    queryFn: getMyOpenWorkId,
  });
}

export function useProfileObjectIds() {
  return useQuery({
    queryKey: ["works", "profile-object-ids"],
    queryFn: getProfileObjectIds,
  });
}

export function useOccupiedEmployeeIdsToday() {
  return useQuery({
    queryKey: ["works", "occupied-employees-today"],
    queryFn: getOccupiedEmployeeIdsToday,
  });
}

export function useOpenWork() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: OpenWorkDraft) => openWork(draft),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["works"] });
    },
  });
}

/** Добавление фото смены: утро или вечер, до 4 с каждой стороны. */
export function useAddWorkShiftPhotos() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      work,
      files,
      kind,
    }: {
      work: Work;
      files: File[];
      kind: WorkPhotoKind;
    }) => addWorkShiftPhotos(work, files, kind),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["works"] });
    },
  });
}

/** Замена одного фото смены по порядковому номеру. */
export function useReplaceWorkShiftPhotoAt() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      work,
      file,
      kind,
      index,
    }: {
      work: Work;
      file: File;
      kind: WorkPhotoKind;
      index: number;
    }) => replaceWorkShiftPhotoAt(work, file, kind, index),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["works"] });
    },
  });
}

/** Удаление одного фото смены по порядковому номеру. */
export function useDeleteWorkShiftPhotoAt() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      work,
      kind,
      index,
    }: {
      work: Work;
      kind: WorkPhotoKind;
      index: number;
    }) => deleteWorkShiftPhotoAt(work, kind, index),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["works"] });
    },
  });
}

export function useCloseWork() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (workId: string) => closeWork(workId),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["works"] });
    },
  });
}

export function useReopenWork() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (workId: string) => reopenWork(workId),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["works"] });
    },
  });
}

export function useDeleteWork() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (workId: string) => deleteWork(workId),
    onSuccess: async () => {
      await queryClient.invalidateQueries({ queryKey: ["works"] });
    },
  });
}
