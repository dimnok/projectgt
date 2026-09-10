"use client";

import { useState } from "react";

import type { ObjectFilters } from "@/features/objects/types/object.types";

export function useObjectFilters() {
  const [status, setStatus] = useState<ObjectFilters["status"]>("all");

  return { status, setStatus };
}
