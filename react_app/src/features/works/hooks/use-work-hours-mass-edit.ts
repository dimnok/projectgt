"use client";

import { useState } from "react";

import type { WorkHour } from "@/features/works/types/work.types";
import {
  applyPresetToDrafts,
  collectHourChanges,
  draftsFromHours,
  hasInvalidHourDrafts,
  type WorkHourBulkUpdate,
} from "@/features/works/utils/work-hours-mass-edit";

export function useWorkHoursMassEdit(hours: WorkHour[]) {
  const [isMassEdit, setIsMassEdit] = useState(false);
  const [selectedPreset, setSelectedPreset] = useState<number | null>(null);
  const [drafts, setDrafts] = useState<Record<string, string>>({});

  function enterMassEdit() {
    setIsMassEdit(true);
    setSelectedPreset(null);
    setDrafts(draftsFromHours(hours));
  }

  function applyPreset(preset: number) {
    setIsMassEdit(true);
    setSelectedPreset(preset);
    setDrafts(applyPresetToDrafts(hours, preset));
  }

  function setDraft(hourId: string, value: string) {
    setSelectedPreset(null);
    setDrafts((current) => ({ ...current, [hourId]: value }));
  }

  function exitMassEdit() {
    setIsMassEdit(false);
    setSelectedPreset(null);
  }

  function changes(): WorkHourBulkUpdate[] {
    return collectHourChanges(hours, drafts);
  }

  function hasInvalidDrafts(): boolean {
    return hasInvalidHourDrafts(hours, drafts);
  }

  return {
    isMassEdit,
    selectedPreset,
    drafts,
    enterMassEdit,
    applyPreset,
    setDraft,
    exitMassEdit,
    changes,
    hasInvalidDrafts,
  };
}
