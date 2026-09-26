"use client";

import { ImageIcon, MoonIcon, SunIcon } from "lucide-react";

import { EmptyState } from "@/components/shared/empty-state";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { WorkPhotoGallery } from "@/features/works/ui/shared/work-photo-gallery";
import type { Work } from "@/features/works/types/work.types";
import { MAX_WORK_PHOTOS_PER_KIND } from "@/features/works/utils/work.utils";

type WorkPhotosProps = {
  work: Work;
  canModify?: boolean;
};

export function WorkPhotos({ work, canModify = false }: WorkPhotosProps) {
  const hasMorning = work.photoUrls.length > 0;
  const hasEvening = work.eveningPhotoUrls.length > 0;

  if (!hasMorning && !hasEvening && !canModify) {
    return (
      <EmptyState
        title="Фотографий нет"
        description="У этой смены ещё нет утренних или вечерних фото."
        icon={ImageIcon}
      />
    );
  }

  return (
    <div className="flex flex-col gap-3">
      {hasMorning || canModify ? (
        <PhotoCard
          title="Утро"
          icon={SunIcon}
          count={work.photoUrls.length}
        >
          <WorkPhotoGallery work={work} kind="morning" canModify={canModify} />
        </PhotoCard>
      ) : null}
      {hasEvening || canModify ? (
        <PhotoCard
          title="Вечер"
          icon={MoonIcon}
          count={work.eveningPhotoUrls.length}
        >
          <WorkPhotoGallery work={work} kind="evening" canModify={canModify} />
        </PhotoCard>
      ) : null}
    </div>
  );
}

function PhotoCard({
  title,
  icon: Icon,
  count,
  children,
}: {
  title: string;
  icon: typeof SunIcon;
  count: number;
  children: React.ReactNode;
}) {
  return (
    <Card size="sm" className="gap-0 overflow-hidden py-0 shadow-xs">
      <CardHeader className="border-b border-border/60 px-3 py-2.5">
        <CardTitle className="flex items-center gap-2 text-xs font-medium">
          <Icon className="size-3.5 text-muted-foreground" />
          <span>{title}</span>
          {count > 0 ? (
            <span className="text-muted-foreground">
              · {count} из {MAX_WORK_PHOTOS_PER_KIND}
            </span>
          ) : null}
        </CardTitle>
      </CardHeader>
      <CardContent className="p-3">{children}</CardContent>
    </Card>
  );
}
