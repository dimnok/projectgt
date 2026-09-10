"use client";

import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";

import { createObject } from "@/features/objects/api/create-object";
import { deleteObject } from "@/features/objects/api/delete-object";
import { getObjects } from "@/features/objects/api/get-objects";
import { updateObject } from "@/features/objects/api/update-object";
import type { ObjectDraft, SiteObject } from "@/features/objects/types/object.types";

const objectsQueryKey = ["objects"] as const;

export function useObjects() {
  return useQuery({
    queryKey: objectsQueryKey,
    queryFn: getObjects,
  });
}

export function useCreateObject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (draft: ObjectDraft) => createObject(draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: objectsQueryKey });
    },
  });
}

export function useUpdateObject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({
      object,
      draft,
    }: {
      object: SiteObject;
      draft: ObjectDraft;
    }) => updateObject(object, draft),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: objectsQueryKey });
    },
  });
}

export function useDeleteObject() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (id: string) => deleteObject(id),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: objectsQueryKey });
    },
  });
}
