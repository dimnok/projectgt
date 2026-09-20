"use client";

import { useMemo, useState } from "react";
import { Building2Icon, ChevronRightIcon, LandmarkIcon } from "lucide-react";

import {
  MobileSheet,
  MobileSheetBody,
  MobileSheetChrome,
} from "@/components/shared/mobile-sheet-chrome";
import { EmptyState } from "@/components/shared/empty-state";
import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { Badge } from "@/components/ui/badge";
import {
  GT_DISK_COMPANY_FOLDERS,
  GT_DISK_LEAD,
  GT_DISK_OBJECT_FOLDERS,
  GT_DISK_RULES,
  GT_DISK_STUB_NOTE,
  GT_DISK_TITLE,
} from "@/features/gt-disk/data/gt-disk-structure";
import { GtDiskFolderList } from "@/features/gt-disk/ui/shared/gt-disk-folder-list";
import { ObjectStatusBadge } from "@/features/objects/ui/shared/object-status-badge";
import { useObjects } from "@/features/objects/hooks/use-objects";
import type { SiteObject } from "@/features/objects/types/object.types";
import { sortObjectsByName } from "@/features/objects/utils/object.utils";
import { usePermissions } from "@/hooks/use-permissions";
import { MobileAppBar } from "@/layouts/mobile/mobile-app-bar";

type OpenFolder =
  | { kind: "company" }
  | { kind: "object"; object: SiteObject }
  | null;

export function GtDiskMobile() {
  const { can } = usePermissions();
  const canReadObjects = can("objects", "read");
  const { data, isLoading, isError, error } = useObjects({
    enabled: canReadObjects,
  });
  const [infoOpen, setInfoOpen] = useState(false);
  const [openFolder, setOpenFolder] = useState<OpenFolder>(null);

  const objects = useMemo(() => sortObjectsByName(data ?? []), [data]);

  if (canReadObjects && isLoading) {
    return <Loading />;
  }

  if (canReadObjects && isError) {
    return (
      <ErrorState
        message={error instanceof Error ? error.message : "Неизвестная ошибка"}
      />
    );
  }

  const folderTitle =
    openFolder?.kind === "company"
      ? "Документы компании"
      : openFolder?.kind === "object"
        ? openFolder.object.name
        : "";

  return (
    <div
      data-fill-viewport
      className="-m-4 flex h-full min-h-0 min-w-0 flex-1 flex-col overflow-hidden bg-background"
    >
      <MobileAppBar title={GT_DISK_TITLE} />

      <div className="min-h-0 flex-1 overflow-y-auto overscroll-contain px-4 pb-6 pt-3">
        <button
          type="button"
          onClick={() => setInfoOpen(true)}
          className="mb-3 w-full rounded-2xl border bg-muted/40 px-4 py-3 text-left"
        >
          <div className="flex items-center justify-between gap-2">
            <p className="text-sm font-medium">Что это за диск</p>
            <Badge variant="outline" className="font-normal">
              Макет
            </Badge>
          </div>
          <p className="mt-1 line-clamp-2 text-xs text-muted-foreground">
            {GT_DISK_LEAD}
          </p>
        </button>

        <p className="mb-2 px-1 text-xs font-medium uppercase tracking-wide text-muted-foreground">
          Папки
        </p>

        <button
          type="button"
          onClick={() => setOpenFolder({ kind: "company" })}
          className="mb-2 flex w-full items-center gap-3 rounded-2xl border bg-card px-3 py-3 text-left"
        >
          <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-muted">
            <LandmarkIcon className="size-4" />
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-sm font-medium">Документы компании</p>
            <p className="text-xs text-muted-foreground">Общие файлы фирмы</p>
          </div>
          <ChevronRightIcon className="size-4 shrink-0 text-muted-foreground" />
        </button>

        {objects.length === 0 ? (
          <EmptyState
            title="Объектов нет"
            description="Папки площадок появятся вместе с объектами."
            icon={Building2Icon}
          />
        ) : (
          <ul className="flex flex-col gap-2">
            {objects.map((object) => (
              <li key={object.id}>
                <button
                  type="button"
                  onClick={() => setOpenFolder({ kind: "object", object })}
                  className="flex w-full items-center gap-3 rounded-2xl border bg-card px-3 py-3 text-left"
                >
                  <div className="flex size-10 shrink-0 items-center justify-center rounded-xl bg-muted">
                    <Building2Icon className="size-4" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <p className="text-sm font-medium">{object.name}</p>
                      <ObjectStatusBadge status={object.status} />
                    </div>
                    <p className="mt-0.5 truncate text-xs text-muted-foreground">
                      {object.address || "Адрес не указан"}
                    </p>
                  </div>
                  <ChevronRightIcon className="size-4 shrink-0 text-muted-foreground" />
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>

      <MobileSheet open={infoOpen} onOpenChange={setInfoOpen}>
        <MobileSheetChrome
          title={GT_DISK_TITLE}
          description={GT_DISK_LEAD}
          confirmLabel="Понятно"
          confirmShowLabelWhenEnabled
          onConfirm={() => setInfoOpen(false)}
        />
        <MobileSheetBody>
          <p className="text-sm leading-relaxed text-muted-foreground">
            {GT_DISK_LEAD}
          </p>
          <ol className="flex list-decimal flex-col gap-2.5 pl-4 text-sm text-muted-foreground">
            {GT_DISK_RULES.map((rule) => (
              <li key={rule} className="pl-1 leading-relaxed">
                {rule}
              </li>
            ))}
          </ol>
          <p className="text-xs text-muted-foreground">{GT_DISK_STUB_NOTE}</p>
        </MobileSheetBody>
      </MobileSheet>

      <MobileSheet
        open={openFolder !== null}
        onOpenChange={(open) => {
          if (!open) {
            setOpenFolder(null);
          }
        }}
      >
        <MobileSheetChrome
          title={folderTitle || "Папка"}
          description="Разделы файлов объекта"
          confirmLabel="Закрыть"
          confirmShowLabelWhenEnabled
          onConfirm={() => setOpenFolder(null)}
        />
        <MobileSheetBody>
          <GtDiskFolderList
            folders={
              openFolder?.kind === "company"
                ? GT_DISK_COMPANY_FOLDERS
                : GT_DISK_OBJECT_FOLDERS
            }
            density="mobile"
          />
          <p className="text-xs text-muted-foreground">{GT_DISK_STUB_NOTE}</p>
        </MobileSheetBody>
      </MobileSheet>
    </div>
  );
}
