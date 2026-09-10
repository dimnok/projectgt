"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { addWorkHour, type AddWorkHourDraft } from "@/features/works/api/add-work-hour";
import { addWorkItems, type AddWorkItemDraft } from "@/features/works/api/add-work-items";
import {
  createWorkMaterial,
  getWorkMaterialContext,
  type CreateWorkMaterialInput,
} from "@/features/works/api/create-work-material";
import { deleteWorkHour } from "@/features/works/api/delete-work-hour";
import { deleteWorkItem } from "@/features/works/api/delete-work-item";
import {
  getObjectEstimatesForWorks,
  getObjectFloors,
  getObjectSections,
} from "@/features/works/api/get-work-item-catalog";
import { getWorkMembership } from "@/features/works/api/get-work-membership";
import {
  updateWorkHour,
  type UpdateWorkHourDraft,
} from "@/features/works/api/update-work-hour";
import {
  updateWorkItem,
  type UpdateWorkItemDraft,
} from "@/features/works/api/update-work-item";
import { updateWorkItemQuantity } from "@/features/works/api/update-work-item-quantity";
import {
  updateWorkHoursBulk,
} from "@/features/works/api/update-work-hours-bulk";
import type { WorkHourBulkUpdate } from "@/features/works/utils/work-hours-mass-edit";

export function useWorkMembership() {
  return useQuery({
    queryKey: ["works", "membership"],
    queryFn: getWorkMembership,
  });
}

export function useWorkItemCatalog(objectId: string | null, enabled: boolean) {
  const sectionsQuery = useQuery({
    queryKey: ["works", "object-sections", objectId],
    queryFn: () => getObjectSections(objectId!),
    enabled: Boolean(objectId) && enabled,
  });
  const floorsQuery = useQuery({
    queryKey: ["works", "object-floors", objectId],
    queryFn: () => getObjectFloors(objectId!),
    enabled: Boolean(objectId) && enabled,
  });
  const estimatesQuery = useQuery({
    queryKey: ["works", "object-estimates", objectId],
    queryFn: () => getObjectEstimatesForWorks(objectId!),
    enabled: Boolean(objectId) && enabled,
  });

  return { sectionsQuery, floorsQuery, estimatesQuery };
}

function useInvalidateWorks(workId: string) {
  const queryClient = useQueryClient();

  return async () => {
    await queryClient.invalidateQueries({ queryKey: ["works"] });
    await queryClient.invalidateQueries({
      queryKey: ["works", "items", workId],
    });
    await queryClient.invalidateQueries({
      queryKey: ["works", "hours", workId],
    });
    await queryClient.invalidateQueries({ queryKey: ["work-journal"] });
  };
}

export function useUpdateWorkItemQuantity(workId: string) {
  const invalidate = useInvalidateWorks(workId);

  return useMutation({
    mutationFn: ({ itemId, quantity }: { itemId: string; quantity: number }) =>
      updateWorkItemQuantity(itemId, quantity),
    onSuccess: async () => {
      await invalidate();
    },
  });
}

export function useDeleteWorkItem(workId: string) {
  const invalidate = useInvalidateWorks(workId);

  return useMutation({
    mutationFn: (itemId: string) => deleteWorkItem(itemId),
    onSuccess: async () => {
      await invalidate();
    },
  });
}

export function useWorkMaterialContext(
  objectId: string | null,
  system: string | null,
  subsystem: string | null,
  enabled: boolean
) {
  return useQuery({
    queryKey: ["works", "material-context", objectId, system, subsystem],
    queryFn: () => getWorkMaterialContext(objectId!, system!, subsystem!),
    enabled:
      Boolean(objectId && system && subsystem) && enabled,
  });
}

export function useCreateWorkMaterial(objectId: string) {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (input: CreateWorkMaterialInput) => createWorkMaterial(input),
    onSuccess: async () => {
      await queryClient.invalidateQueries({
        queryKey: ["works", "object-estimates", objectId],
      });
      await queryClient.invalidateQueries({
        queryKey: ["works", "material-context", objectId],
      });
      await queryClient.invalidateQueries({ queryKey: ["estimates"] });
    },
  });
}

export function useAddWorkItems(workId: string) {
  const invalidate = useInvalidateWorks(workId);

  return useMutation({
    mutationFn: (drafts: AddWorkItemDraft[]) => addWorkItems(workId, drafts),
    onSuccess: async () => {
      await invalidate();
    },
  });
}

export function useUpdateWorkItem(workId: string) {
  const invalidate = useInvalidateWorks(workId);

  return useMutation({
    mutationFn: (draft: UpdateWorkItemDraft) => updateWorkItem(draft),
    onSuccess: async () => {
      await invalidate();
    },
  });
}

export function useAddWorkHour(workId: string) {
  const invalidate = useInvalidateWorks(workId);

  return useMutation({
    mutationFn: (draft: AddWorkHourDraft) => addWorkHour(workId, draft),
    onSuccess: async () => {
      await invalidate();
    },
  });
}

export function useUpdateWorkHour(workId: string) {
  const invalidate = useInvalidateWorks(workId);

  return useMutation({
    mutationFn: (draft: UpdateWorkHourDraft) => updateWorkHour(draft),
    onSuccess: async () => {
      await invalidate();
    },
  });
}

export function useUpdateWorkHoursBulk(workId: string) {
  const invalidate = useInvalidateWorks(workId);

  return useMutation({
    mutationFn: (updates: WorkHourBulkUpdate[]) =>
      updateWorkHoursBulk(workId, updates),
    onSuccess: async () => {
      await invalidate();
    },
  });
}

export function useDeleteWorkHour(workId: string) {
  const invalidate = useInvalidateWorks(workId);

  return useMutation({
    mutationFn: (hourId: string) => deleteWorkHour(hourId),
    onSuccess: async () => {
      await invalidate();
    },
  });
}
