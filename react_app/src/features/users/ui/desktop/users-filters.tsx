"use client";

import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { FieldLabel } from "@/components/ui/field";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { CompanyUserLinkFilter } from "@/features/users/types/user.types";

const LINK_FILTER_ITEMS = [
  { value: "all", label: "Все" },
  { value: "linked", label: "С карточкой" },
  { value: "unlinked", label: "Без карточки" },
];

type UsersFiltersProps = {
  link: CompanyUserLinkFilter;
  onLinkChange: (value: CompanyUserLinkFilter) => void;
};

function isLinkFilter(value: string): value is CompanyUserLinkFilter {
  return value === "all" || value === "linked" || value === "unlinked";
}

export function UsersFilters({ link, onLinkChange }: UsersFiltersProps) {
  return (
    <Card className="shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b max-lg:hidden">
        <CardTitle>Фильтры</CardTitle>
      </CardHeader>
      <CardContent className="flex flex-col gap-3">
        <div className="flex min-w-0 items-center gap-2">
          <FieldLabel htmlFor="users-link" className="shrink-0">
            Привязка
          </FieldLabel>
          <div className="min-w-0 flex-1">
            <Select
              value={link}
              items={LINK_FILTER_ITEMS}
              onValueChange={(value) => {
                if (value && isLinkFilter(value)) {
                  onLinkChange(value);
                }
              }}
            >
              <SelectTrigger id="users-link" className="w-full">
                <SelectValue />
              </SelectTrigger>
              <SelectContent align="start">
                <SelectGroup>
                  {LINK_FILTER_ITEMS.map((item) => (
                    <SelectItem key={item.value} value={item.value}>
                      {item.label}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
          </div>
        </div>
      </CardContent>
    </Card>
  );
}
