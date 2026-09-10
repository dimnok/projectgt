"use client";

import { useState } from "react";
import { ImageIcon } from "lucide-react";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { EmptyState } from "@/components/shared/empty-state";
import type { Work } from "@/features/works/types/work.types";
import { extractPhotoTime } from "@/features/works/utils/work.utils";

type WorkPhotosProps = {
  work: Work;
};

export function WorkPhotos({ work }: WorkPhotosProps) {
  const [preview, setPreview] = useState<{
    title: string;
    url: string;
  } | null>(null);

  const morning = work.photoUrl;
  const evening = work.eveningPhotoUrl;

  if (!morning && !evening) {
    return (
      <EmptyState
        title="Фотографий нет"
        description="У этой смены ещё нет утреннего или вечернего фото."
        icon={ImageIcon}
      />
    );
  }

  return (
    <>
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
        {morning ? (
          <PhotoCard
            title="Утро"
            url={morning}
            onOpen={() => setPreview({ title: "Утро", url: morning })}
          />
        ) : null}
        {evening ? (
          <PhotoCard
            title="Вечер"
            url={evening}
            onOpen={() => setPreview({ title: "Вечер", url: evening })}
          />
        ) : null}
      </div>
      <Dialog
        open={Boolean(preview)}
        onOpenChange={(open) => {
          if (!open) {
            setPreview(null);
          }
        }}
      >
        <DialogContent className="max-w-3xl p-0 sm:max-w-3xl">
          <DialogHeader className="px-4 pt-4">
            <DialogTitle>{preview?.title}</DialogTitle>
            <DialogDescription className="sr-only">
              Фото смены
            </DialogDescription>
          </DialogHeader>
          {preview ? (
            // Stored public URL from the `works` bucket, same as the app.
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={preview.url}
              alt={preview.title}
              className="max-h-[80vh] w-full rounded-b-xl object-contain bg-muted"
            />
          ) : null}
        </DialogContent>
      </Dialog>
    </>
  );
}

function PhotoCard({
  title,
  url,
  onOpen,
}: {
  title: string;
  url: string;
  onOpen: () => void;
}) {
  const time = extractPhotoTime(url);

  return (
    <Card size="sm" className="gap-0 overflow-hidden py-0 shadow-xs">
      <button
        type="button"
        onClick={onOpen}
        className="w-full text-left outline-none transition-colors hover:bg-muted/30 focus-visible:ring-1 focus-visible:ring-ring"
      >
        <CardHeader className="py-2.5 px-3 border-b border-border/60">
          <CardTitle className="text-xs font-medium">
            {title}
            {time ? ` · ${time}` : ""}
          </CardTitle>
        </CardHeader>
        <CardContent className="overflow-hidden p-0 rounded-b-xl">
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src={url}
            alt={title}
            className="aspect-[16/10] max-h-56 w-full rounded-b-xl object-cover sm:max-h-64"
          />
        </CardContent>
      </button>
    </Card>
  );
}
