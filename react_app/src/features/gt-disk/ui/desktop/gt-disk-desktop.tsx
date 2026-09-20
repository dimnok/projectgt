"use client";

import { useMemo, useState, type ReactNode } from "react";
import {
  ChevronLeftIcon,
  ChevronRightIcon,
  HardDriveIcon,
  LandmarkIcon,
  SearchIcon,
} from "lucide-react";
import { toast } from "sonner";

import { ErrorState } from "@/components/shared/error-state";
import { Loading } from "@/components/shared/loading";
import { Button } from "@/components/ui/button";
import {
  InputGroup,
  InputGroupAddon,
  InputGroupInput,
} from "@/components/ui/input-group";
import { Separator } from "@/components/ui/separator";
import {
  buildGtDiskRoot,
  getGtDiskNodeAt,
  gtDiskCrumbs,
  splitGtDiskChildren,
  GT_DISK_LEAD,
  GT_DISK_TITLE,
  type GtDiskNode,
} from "@/features/gt-disk/data/gt-disk-structure";
import {
  GtDiskFileGlyph,
  GtDiskFolderGlyph,
} from "@/features/gt-disk/ui/desktop/gt-disk-glyphs";
import { useObjects } from "@/features/objects/hooks/use-objects";
import { sortObjectsByName } from "@/features/objects/utils/object.utils";
import { usePermissions } from "@/hooks/use-permissions";
import { cn } from "@/lib/utils";

function fileKindLabel(name: string) {
  const extension = name.includes(".")
    ? name.slice(name.lastIndexOf(".") + 1).toUpperCase()
    : "FILE";
  if (extension === "XLSX" || extension === "XLS") {
    return "XLS";
  }
  return extension.slice(0, 4);
}

function notifyStub(fileName?: string) {
  toast.message(
    fileName
      ? `«${fileName}» пока нельзя открыть — это макет ГТ Диска.`
      : "Загрузка и открытие файлов появятся позже."
  );
}

export function GtDiskDesktop() {
  const { can } = usePermissions();
  const canReadObjects = can("objects", "read");
  const { data, isLoading, isError, error } = useObjects({
    enabled: canReadObjects,
  });
  const [path, setPath] = useState<string[]>([]);
  const [history, setHistory] = useState<string[][]>([[]]);
  const [historyIndex, setHistoryIndex] = useState(0);
  const [query, setQuery] = useState("");
  const [selectedId, setSelectedId] = useState<string | null>(null);

  const objects = useMemo(() => sortObjectsByName(data ?? []), [data]);
  const root = useMemo(() => buildGtDiskRoot(objects), [objects]);
  const current = getGtDiskNodeAt(root, path);
  const crumbs = gtDiskCrumbs(root, path);
  const { folders, files } = splitGtDiskChildren(current);
  const needle = query.trim().toLowerCase();
  const visibleFolders = needle
    ? folders.filter((item) =>
        `${item.name} ${item.hint ?? ""}`.toLowerCase().includes(needle)
      )
    : folders;
  const visibleFiles = needle
    ? files.filter((item) => item.name.toLowerCase().includes(needle))
    : files;
  const selected =
    [...visibleFolders, ...visibleFiles].find((item) => item.id === selectedId) ??
    null;
  const objectNodes = (root.children ?? []).filter((child) =>
    child.id.startsWith("object:")
  );

  function goTo(nextPath: string[]) {
    const nextHistory = [...history.slice(0, historyIndex + 1), nextPath];
    setHistory(nextHistory);
    setHistoryIndex(nextHistory.length - 1);
    setPath(nextPath);
    setQuery("");
    setSelectedId(null);
  }

  function goBack() {
    if (historyIndex <= 0) {
      return;
    }
    const nextIndex = historyIndex - 1;
    setHistoryIndex(nextIndex);
    setPath(history[nextIndex] ?? []);
    setQuery("");
    setSelectedId(null);
  }

  function goForward() {
    if (historyIndex >= history.length - 1) {
      return;
    }
    const nextIndex = historyIndex + 1;
    setHistoryIndex(nextIndex);
    setPath(history[nextIndex] ?? []);
    setQuery("");
    setSelectedId(null);
  }

  function openFolder(folder: GtDiskNode) {
    goTo([...path, folder.id]);
  }

  function handleItemClick(node: GtDiskNode) {
    setSelectedId(node.id);
  }

  function handleItemOpen(node: GtDiskNode) {
    if (node.kind === "folder") {
      openFolder(node);
      return;
    }
    notifyStub(node.name);
  }

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

  const isEmpty = visibleFolders.length === 0 && visibleFiles.length === 0;
  const itemCount = visibleFolders.length + visibleFiles.length;

  return (
    <div
      data-fill-viewport
      className="flex h-full min-h-0 min-w-0 w-full flex-1 flex-col"
    >
      <div
        className="flex min-h-0 min-w-0 flex-1 flex-col overflow-hidden rounded-3xl border border-border/80 bg-background/80 shadow-float ring-1 ring-foreground/5 backdrop-blur-xl"
        tabIndex={0}
        onKeyDown={(event) => {
          if (event.key === "Enter" && selected) {
            event.preventDefault();
            handleItemOpen(selected);
          }
          if (event.key === "Backspace" && path.length > 0 && !query) {
            event.preventDefault();
            goTo(path.slice(0, -1));
          }
          if (event.key === "ArrowLeft" && (event.metaKey || event.altKey)) {
            event.preventDefault();
            goBack();
          }
          if (event.key === "ArrowRight" && (event.metaKey || event.altKey)) {
            event.preventDefault();
            goForward();
          }
        }}
      >
        <div className="flex shrink-0 items-center gap-3 border-b border-border/70 bg-muted/40 px-4 py-3 backdrop-blur-md">
          <div className="flex overflow-hidden rounded-full border border-border/80 bg-background/70 p-0.5 shadow-xs">
            <Button
              type="button"
              variant="ghost"
              size="icon-xs"
              className="rounded-full"
              onClick={goBack}
              disabled={historyIndex <= 0}
              aria-label="Назад"
            >
              <ChevronLeftIcon />
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="icon-xs"
              className="rounded-full"
              onClick={goForward}
              disabled={historyIndex >= history.length - 1}
              aria-label="Вперёд"
            >
              <ChevronRightIcon />
            </Button>
          </div>
          <p className="min-w-0 flex-1 truncate text-center font-heading text-sm font-medium tracking-tight">
            {current.name}
          </p>
          <InputGroup className="h-8 w-52 rounded-full border-border/70 bg-background/80 shadow-xs">
            <InputGroupAddon>
              <SearchIcon />
            </InputGroupAddon>
            <InputGroupInput
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Поиск"
              aria-label="Поиск в папке"
            />
          </InputGroup>
        </div>

        <div className="flex min-h-0 min-w-0 flex-1">
          <aside className="flex w-56 shrink-0 flex-col gap-5 overflow-y-auto border-r border-border/70 bg-muted/25 px-3 py-4">
            <div className="flex flex-col gap-1">
              <p className="px-2.5 pb-1 text-[10px] font-medium tracking-[0.18em] text-muted-foreground uppercase">
                Избранное
              </p>
              <SidebarRow
                icon={<HardDriveIcon className="size-3.5" />}
                label={GT_DISK_TITLE}
                active={path.length === 0}
                onClick={() => goTo([])}
              />
              <SidebarRow
                icon={<LandmarkIcon className="size-3.5" />}
                label="Документы компании"
                active={path[0] === "company"}
                onClick={() => goTo(["company"])}
              />
            </div>
            <div className="flex min-h-0 flex-1 flex-col gap-1">
              <p className="px-2.5 pb-1 text-[10px] font-medium tracking-[0.18em] text-muted-foreground uppercase">
                Объекты
              </p>
              {objectNodes.length === 0 ? (
                <p className="px-2.5 text-xs text-muted-foreground">Пока нет</p>
              ) : (
                objectNodes.map((object) => (
                  <SidebarRow
                    key={object.id}
                    icon={<GtDiskFolderGlyph className="size-4" />}
                    label={object.name}
                    active={path[0] === object.id}
                    onClick={() => goTo([object.id])}
                  />
                ))
              )}
            </div>
            <p className="px-2.5 text-[11px] leading-relaxed text-muted-foreground/90">
              {GT_DISK_LEAD}
            </p>
          </aside>

          <div className="flex min-h-0 min-w-0 flex-1">
            <div className="flex min-h-0 min-w-0 flex-1 flex-col bg-gradient-to-b from-muted/20 to-background">
              <div
                key={path.join("/") || "root"}
                className="min-h-0 flex-1 overflow-y-auto p-7"
                onClick={() => setSelectedId(null)}
              >
                {isEmpty ? (
                  <div className="flex h-full min-h-56 flex-col items-center justify-center gap-3 text-center">
                    <GtDiskFolderGlyph className="size-20 opacity-50" />
                    <p className="font-heading text-base font-medium">
                      {needle ? "Ничего не найдено" : "Папка пустая"}
                    </p>
                    <p className="max-w-xs text-sm text-muted-foreground">
                      {needle
                        ? "Измените запрос или откройте другую папку."
                        : "Двойной щелчок открывает папку."}
                    </p>
                  </div>
                ) : (
                  <div className="grid grid-cols-[repeat(auto-fill,minmax(8rem,1fr))] gap-x-4 gap-y-7">
                    {visibleFolders.map((folder) => (
                      <FinderIcon
                        key={folder.id}
                        selected={selectedId === folder.id}
                        label={folder.name}
                        onSelect={() => handleItemClick(folder)}
                        onOpen={() => handleItemOpen(folder)}
                      >
                        <GtDiskFolderGlyph className="size-[4.5rem]" />
                      </FinderIcon>
                    ))}
                    {visibleFiles.map((file) => (
                      <FinderIcon
                        key={file.id}
                        selected={selectedId === file.id}
                        label={file.name}
                        caption={fileKindLabel(file.name)}
                        onSelect={() => handleItemClick(file)}
                        onOpen={() => handleItemOpen(file)}
                      >
                        <GtDiskFileGlyph
                          className="size-[3.75rem]"
                          label={fileKindLabel(file.name)}
                        />
                      </FinderIcon>
                    ))}
                  </div>
                )}
              </div>

              <div className="flex shrink-0 items-center gap-3 border-t border-border/70 bg-background/60 px-4 py-2 text-[11px] text-muted-foreground backdrop-blur-md">
                <nav
                  aria-label="Путь"
                  className="flex min-w-0 flex-1 items-center gap-0.5 overflow-x-auto"
                >
                  {crumbs.map((crumb, index) => (
                    <span
                      key={`${crumb.id}-${index}`}
                      className="flex items-center gap-0.5"
                    >
                      {index > 0 ? (
                        <ChevronRightIcon className="size-3 shrink-0 opacity-40" />
                      ) : null}
                      <button
                        type="button"
                        className={cn(
                          "rounded-full px-2 py-0.5 transition-colors hover:bg-muted hover:text-foreground",
                          index === crumbs.length - 1 &&
                            "bg-muted font-medium text-foreground"
                        )}
                        onClick={() => goTo(crumb.path)}
                      >
                        {crumb.name}
                      </button>
                    </span>
                  ))}
                </nav>
                <span className="shrink-0 tabular-nums">
                  {itemCount} {itemCount === 1 ? "элемент" : "элементов"}
                </span>
              </div>
            </div>

            <aside className="hidden w-56 shrink-0 flex-col border-l border-border/70 bg-muted/15 p-5 md:flex">
              {selected ? (
                <div className="flex flex-col items-center gap-4 text-center">
                  <div className="flex size-24 items-center justify-center">
                    {selected.kind === "folder" ? (
                      <GtDiskFolderGlyph className="size-20" />
                    ) : (
                      <GtDiskFileGlyph
                        className="size-16"
                        label={fileKindLabel(selected.name)}
                      />
                    )}
                  </div>
                  <div className="flex min-w-0 flex-col gap-1">
                    <p className="font-heading text-sm font-medium leading-snug">
                      {selected.name}
                    </p>
                    <p className="text-xs text-muted-foreground">
                      {selected.kind === "folder" ? "Папка" : "Файл"}
                    </p>
                  </div>
                  {selected.hint ? (
                    <>
                      <Separator />
                      <p className="text-xs leading-relaxed text-muted-foreground">
                        {selected.hint}
                      </p>
                    </>
                  ) : null}
                </div>
              ) : (
                <div className="flex h-full flex-col items-center justify-center gap-2 text-center">
                  <p className="text-xs font-medium tracking-wide text-muted-foreground uppercase">
                    Сведения
                  </p>
                  <p className="text-xs leading-relaxed text-muted-foreground">
                    Выберите папку или файл
                  </p>
                </div>
              )}
            </aside>
          </div>
        </div>
      </div>
    </div>
  );
}

function SidebarRow({
  icon,
  label,
  active,
  onClick,
}: {
  icon: ReactNode;
  label: string;
  active: boolean;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "flex w-full items-center gap-2.5 rounded-full px-2.5 py-1.5 text-left text-[12.5px] transition-colors",
        active
          ? "bg-foreground text-background shadow-xs"
          : "text-foreground/80 hover:bg-background/80"
      )}
    >
      <span className="flex size-4 shrink-0 items-center justify-center opacity-90">
        {icon}
      </span>
      <span className="min-w-0 truncate">{label}</span>
    </button>
  );
}

function FinderIcon({
  selected,
  label,
  caption,
  onSelect,
  onOpen,
  children,
}: {
  selected: boolean;
  label: string;
  caption?: string;
  onSelect: () => void;
  onOpen: () => void;
  children: ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={(event) => {
        event.stopPropagation();
        onSelect();
      }}
      onDoubleClick={(event) => {
        event.stopPropagation();
        onOpen();
      }}
      className="group flex flex-col items-center gap-2 rounded-2xl p-2 text-center"
    >
      <span
        className={cn(
          "flex size-24 items-center justify-center rounded-2xl transition-all duration-200",
          selected
            ? "bg-foreground/8 ring-1 ring-foreground/15"
            : "group-hover:bg-muted/60"
        )}
      >
        {children}
      </span>
      <span
        className={cn(
          "line-clamp-2 max-w-[7.5rem] rounded-lg px-2 py-0.5 text-[12px] leading-snug",
          selected ? "bg-foreground text-background" : "text-foreground"
        )}
      >
        {label}
      </span>
      {caption ? (
        <span className="text-[10px] tracking-wide text-muted-foreground uppercase">
          {caption}
        </span>
      ) : null}
    </button>
  );
}
