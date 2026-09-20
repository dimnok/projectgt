"use client";

import { useMemo, useState } from "react";
import { toast } from "sonner";

import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { ObjectsFilters } from "@/features/objects/ui/desktop/objects-filters";
import { ObjectsList } from "@/features/objects/ui/desktop/objects-list";
import { ObjectsSummary } from "@/features/objects/ui/desktop/objects-summary";
import { ObjectDeleteDialog } from "@/features/objects/ui/shared/object-delete-dialog";
import { ObjectFormDialog } from "@/features/objects/ui/shared/object-form-dialog";
import { useObjectFilters } from "@/features/objects/hooks/use-object-filters";
import {
  useCreateObject,
  useDeleteObject,
  useObjects,
  useUpdateObject,
} from "@/features/objects/hooks/use-objects";
import type { ObjectDraft, SiteObject } from "@/features/objects/types/object.types";
import {
  filterObjects,
  sortObjectsByName,
} from "@/features/objects/utils/object.utils";
import { usePermissions } from "@/hooks/use-permissions";
import { useAppSearch, AppSearchField } from "@/layouts/desktop/app-search";

export function ObjectsDesktop() {
  const { data, isLoading, isError, error } = useObjects();
  const { status, setStatus } = useObjectFilters();
  const { query } = useAppSearch();
  const { can } = usePermissions();
  const createObject = useCreateObject();
  const updateObject = useUpdateObject();
  const deleteObject = useDeleteObject();

  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [editorObject, setEditorObject] = useState<SiteObject | null | undefined>(
    undefined
  );
  const [objectToDelete, setObjectToDelete] = useState<SiteObject | null>(null);

  const objects = useMemo(
    () =>
      sortObjectsByName(
        filterObjects(data ?? [], { search: query, status })
      ),
    [data, query, status]
  );
  const isEditorOpen = editorObject !== undefined;

  function handleCreate(draft: ObjectDraft) {
    createObject.mutate(draft, {
      onSuccess: (created) => {
        setExpandedId(created.id);
        setEditorObject(undefined);
        toast.success("Объект создан");
      },
      onError: () => toast.error("Не удалось создать объект"),
    });
  }

  function handleUpdate(draft: ObjectDraft) {
    if (!editorObject) {
      return;
    }
    updateObject.mutate(
      { object: editorObject, draft },
      {
        onSuccess: (updated) => {
          setExpandedId(updated.id);
          setEditorObject(undefined);
          toast.success("Изменения сохранены");
        },
        onError: () => toast.error("Не удалось сохранить объект"),
      }
    );
  }

  function handleDelete() {
    if (!objectToDelete) {
      return;
    }
    deleteObject.mutate(objectToDelete.id, {
      onSuccess: () => {
        setObjectToDelete(null);
        setExpandedId((current) =>
          current === objectToDelete.id ? null : current
        );
        toast.success("Объект удалён");
      },
      onError: () => toast.error("Не удалось удалить объект"),
    });
  }

  if (isLoading) {
    return <Loading />;
  }

  if (isError) {
    return (
      <ErrorState
        message={error instanceof Error ? error.message : "Неизвестная ошибка"}
      />
    );
  }

  return (
    <>
      <div className="grid min-w-0 w-full flex-1 grid-cols-1 content-start items-start gap-3 lg:grid-cols-[minmax(0,1fr)_var(--content-aside-width)] lg:gap-6">
        <div className="min-w-0 w-full lg:order-1">
          {objects.length === 0 ? (
            <EmptyState
              title="Объектов нет"
              description="Добавьте объект или измените фильтры."
            />
          ) : (
            <ObjectsList
              objects={objects}
              expandedId={expandedId}
              canUpdate={can("objects", "update")}
              canDelete={can("objects", "delete")}
              onExpandedChange={(id, open) => {
                setExpandedId(open ? id : null);
              }}
              onEdit={setEditorObject}
              onDelete={setObjectToDelete}
            />
          )}
        </div>
        <aside className="order-first flex min-w-0 w-full flex-col gap-3 lg:sticky lg:top-0 lg:order-2 lg:gap-6 lg:self-start">
          <div className="flex min-w-0 flex-col gap-2">
            <AppSearchField
              variant="aside"
              placeholder="Поиск по названию, адресу..."
              aria-label="Поиск по объектам"
            />
            <ObjectsFilters
              status={status}
              onStatusChange={setStatus}
              canCreate={can("objects", "create")}
              onCreate={() => setEditorObject(null)}
            />
          </div>
          <ObjectsSummary objects={data ?? []} />
        </aside>
      </div>
      <ObjectFormDialog
        open={isEditorOpen}
        object={editorObject}
        isSaving={createObject.isPending || updateObject.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setEditorObject(undefined);
          }
        }}
        onSubmit={editorObject ? handleUpdate : handleCreate}
      />
      <ObjectDeleteDialog
        object={objectToDelete}
        isDeleting={deleteObject.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setObjectToDelete(null);
          }
        }}
        onConfirm={handleDelete}
      />
    </>
  );
}
