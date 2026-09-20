"use client";

import { FileTextIcon, ExternalLinkIcon, PencilIcon, PlusIcon, Trash2Icon } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import { Button, buttonVariants } from "@/components/ui/button";
import { Spinner } from "@/components/ui/spinner";
import { CompanyDocumentDeleteDialog } from "@/features/company/ui/shared/company-document-delete-dialog";
import { CompanyDocumentFormDialog } from "@/features/company/ui/shared/company-document-form-dialog";
import {
  useCompanyDocuments,
  useCreateCompanyDocument,
  useDeleteCompanyDocument,
  useUpdateCompanyDocument,
} from "@/features/company/hooks/use-company-documents";
import type { CompanyDocument, CompanyDocumentDraft } from "@/features/company/types/company.types";
import { formatDocumentDate } from "@/features/company/utils/company-document";

type CompanyDocumentsProps = {
  canEdit: boolean;
};

/** Документы компании (лицензии, СРО): список и операции. */
export function CompanyDocuments({ canEdit }: CompanyDocumentsProps) {
  const { data, isLoading, isError, error } = useCompanyDocuments();
  const createDocument = useCreateCompanyDocument();
  const updateDocument = useUpdateCompanyDocument();
  const deleteDocument = useDeleteCompanyDocument();

  const [editorDocument, setEditorDocument] = useState<
    CompanyDocument | null | undefined
  >(undefined);
  const [documentToDelete, setDocumentToDelete] =
    useState<CompanyDocument | null>(null);

  const documents = data ?? [];
  const isEditorOpen = editorDocument !== undefined;
  const isSaving = createDocument.isPending || updateDocument.isPending;

  function handleSubmit(draft: CompanyDocumentDraft) {
    if (editorDocument) {
      updateDocument.mutate(
        { id: editorDocument.id, draft },
        {
          onSuccess: () => {
            setEditorDocument(undefined);
            toast.success("Документ обновлён");
          },
          onError: (err) =>
            toast.error(
              err instanceof Error
                ? err.message
                : "Не удалось сохранить документ"
            ),
        }
      );
      return;
    }

    createDocument.mutate(draft, {
      onSuccess: () => {
        setEditorDocument(undefined);
        toast.success("Документ добавлен");
      },
      onError: (err) =>
        toast.error(
          err instanceof Error ? err.message : "Не удалось добавить документ"
        ),
    });
  }

  function handleDelete() {
    if (!documentToDelete) {
      return;
    }
    deleteDocument.mutate(documentToDelete.id, {
      onSuccess: () => {
        setDocumentToDelete(null);
        toast.success("Документ удалён");
      },
      onError: (err) =>
        toast.error(
          err instanceof Error ? err.message : "Не удалось удалить документ"
        ),
    });
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between gap-3">
        <div>
          <p className="text-sm font-medium">Лицензии и СРО</p>
          <p className="text-xs text-muted-foreground">
            {documents.length > 0
              ? `${documents.length} документ(а)`
              : "Документы не добавлены"}
          </p>
        </div>
        {canEdit ? (
          <Button
            type="button"
            size="sm"
            onClick={() => setEditorDocument(null)}
          >
            <PlusIcon data-icon="inline-start" />
            Добавить документ
          </Button>
        ) : null}
      </div>

      {isLoading ? (
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <Spinner /> Загрузка…
        </div>
      ) : isError ? (
        <p className="text-sm text-destructive">
          {error instanceof Error
            ? error.message
            : "Не удалось загрузить документы"}
        </p>
      ) : documents.length === 0 ? (
        <div className="rounded-lg border border-dashed p-4 text-sm text-muted-foreground">
          Документы не добавлены.
        </div>
      ) : (
        <div className="flex flex-col gap-2">
          {documents.map((document) => (
            <div
              key={document.id}
              className="flex items-center justify-between gap-3 rounded-lg border bg-card p-3"
            >
              <div className="flex min-w-0 items-center gap-3">
                <div className="flex size-9 shrink-0 items-center justify-center rounded-md bg-primary/10 text-primary">
                  <FileTextIcon className="size-4" />
                </div>
                <div className="min-w-0">
                  <p className="truncate text-sm font-medium">
                    {document.title}
                  </p>
                  <p className="truncate text-xs text-muted-foreground">
                    {document.type || "—"}
                    {document.number ? ` · № ${document.number}` : ""}
                    {` · до ${formatDocumentDate(document.expiryDate)}`}
                  </p>
                </div>
              </div>
              <div className="flex shrink-0 items-center gap-1">
                {document.fileUrl ? (
                  <a
                    href={document.fileUrl}
                    target="_blank"
                    rel="noreferrer"
                    aria-label="Открыть файл"
                    className={buttonVariants({
                      variant: "ghost",
                      size: "icon-sm",
                    })}
                  >
                    <ExternalLinkIcon />
                  </a>
                ) : (
                  <Badge variant="outline">без файла</Badge>
                )}
                {canEdit ? (
                  <>
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon-sm"
                      aria-label="Изменить документ"
                      onClick={() => setEditorDocument(document)}
                    >
                      <PencilIcon />
                    </Button>
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon-sm"
                      aria-label="Удалить документ"
                      onClick={() => setDocumentToDelete(document)}
                    >
                      <Trash2Icon />
                    </Button>
                  </>
                ) : null}
              </div>
            </div>
          ))}
        </div>
      )}

      <CompanyDocumentFormDialog
        open={isEditorOpen}
        document={editorDocument ?? null}
        isSaving={isSaving}
        onOpenChange={(open) => {
          if (!open) {
            setEditorDocument(undefined);
          }
        }}
        onSubmit={handleSubmit}
      />

      <CompanyDocumentDeleteDialog
        document={documentToDelete}
        isDeleting={deleteDocument.isPending}
        onOpenChange={(open) => {
          if (!open) {
            setDocumentToDelete(null);
          }
        }}
        onConfirm={handleDelete}
      />
    </div>
  );
}
