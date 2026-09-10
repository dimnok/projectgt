"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { closeWork } from "@/features/works/api/close-work";
import { deleteWork } from "@/features/works/api/delete-work";
import {
  getMyOpenWorkId,
  getOccupiedEmployeeIdsToday,
  getProfileObjectIds,
} from "@/features/works/api/get-open-work-context";
import { openWork, type OpenWorkDraft } from "@/features/works/api/open-work";
import { reopenWork } from "@/features/works/api/reopen-work";
import { saveWorkEveningPhoto } from "@/features/works/api/save-work-evening-photo";
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

export function useSaveWorkEveningPhoto() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ work, file }: { work: Work; file: File }) =>
      saveWorkEveningPhoto(work, file),
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
