"use client";

import {
  ChevronRightIcon,
  FileTextIcon,
  FolderIcon,
  HardDriveIcon,
} from "lucide-react";
import { toast } from "sonner";

import { Badge } from "@/components/ui/badge";
import type { GtDiskFolder } from "@/features/gt-disk/data/gt-disk-structure";
import { cn } from "@/lib/utils";

type GtDiskFolderListProps = {
  folders: GtDiskFolder[];
  density?: "desktop" | "mobile";
};

export function notifyGtDiskStub(fileName?: string) {
  toast.message(
    fileName
      ? `«${fileName}» пока нельзя открыть — это макет ГТ Диска.`
      : "Загрузка и открытие файлов появятся позже. Сейчас показана только структура."
  );
}

export function GtDiskFolderList({
  folders,
  density = "desktop",
}: GtDiskFolderListProps) {
  const isMobile = density === "mobile";

  return (
    <ul className={cn("flex flex-col", isMobile ? "gap-2" : "gap-1")}>
      {folders.map((folder) => (
        <li key={folder.id}>
          <div
            className={cn(
              "rounded-xl border border-border/70 bg-muted/20",
              isMobile ? "px-3 py-2.5" : "px-3 py-2"
            )}
          >
            <div className="flex items-start gap-2.5">
              <FolderIcon className="mt-0.5 size-4 shrink-0 text-muted-foreground" />
              <div className="min-w-0 flex-1">
                <p className="text-sm font-medium">{folder.name}</p>
                <p className="text-xs text-muted-foreground">{folder.hint}</p>
              </div>
            </div>
            {folder.sampleFiles.length > 0 ? (
              <ul className="mt-2 flex flex-col gap-1 pl-6">
                {folder.sampleFiles.map((fileName) => (
                  <li key={fileName}>
                    <button
                      type="button"
                      onClick={() => notifyGtDiskStub(fileName)}
                      className="flex w-full min-w-0 items-center gap-2 rounded-lg px-1.5 py-1 text-left text-xs text-foreground/80 hover:bg-muted"
                    >
                      <FileTextIcon className="size-3.5 shrink-0 text-muted-foreground" />
                      <span className="min-w-0 truncate">{fileName}</span>
                      <ChevronRightIcon className="ml-auto size-3.5 shrink-0 text-muted-foreground" />
                    </button>
                  </li>
                ))}
              </ul>
            ) : (
              <p className="mt-1.5 pl-6 text-xs text-muted-foreground">
                Пока пусто
              </p>
            )}
          </div>
        </li>
      ))}
    </ul>
  );
}

export function GtDiskStubBadge() {
  return (
    <Badge variant="outline" className="gap-1.5 font-normal">
      <HardDriveIcon className="size-3.5 text-muted-foreground" />
      Макет
    </Badge>
  );
}
