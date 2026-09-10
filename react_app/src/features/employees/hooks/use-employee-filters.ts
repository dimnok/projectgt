"use client";

import { useState } from "react";

import type { EmployeeFilters } from "@/features/employees/types/employee.types";

export function useEmployeeFilters() {
  const [status, setStatus] =
    useState<EmployeeFilters["status"]>("working");
  const [objectId, setObjectId] =
    useState<EmployeeFilters["objectId"]>("all");

  return { status, setStatus, objectId, setObjectId };
}
