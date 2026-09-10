"use client";

import { SettingsIcon } from "lucide-react";

import { Button } from "@/components/ui/button";
import {
  DropdownMenu,
  DropdownMenuCheckboxItem,
  DropdownMenuContent,
  DropdownMenuGroup,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import { useEstimateTableLayout } from "@/features/estimates/hooks/use-estimate-table-layout";
import { ESTIMATE_COLUMNS } from "@/features/estimates/utils/estimate-table-columns";

type EstimateColumnsMenuProps = {
  size?: "icon-sm" | "icon-lg";
};

export function EstimateColumnsMenu({ size = "icon-lg" }: EstimateColumnsMenuProps) {
  const { hidden, setColumnVisible, resetLayout } = useEstimateTableLayout();

  return (
    <DropdownMenu>
      <DropdownMenuTrigger
        render={
          <Button
            type="button"
            variant="outline"
            size={size}
            className="bg-card hover:bg-muted/40"
            aria-label="Настройка колонок таблицы"
            title="Настройка колонок таблицы"
          />
        }
      >
        <SettingsIcon />
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-52">
        <DropdownMenuGroup>
          <DropdownMenuLabel>Показать колонки</DropdownMenuLabel>
          {ESTIMATE_COLUMNS.map((column) => (
            <DropdownMenuCheckboxItem
              key={column.id}
              checked={!hidden.has(column.id)}
              disabled={!column.hideable && !hidden.has(column.id)}
              onCheckedChange={(checked) => setColumnVisible(column, checked)}
            >
              {column.label}
            </DropdownMenuCheckboxItem>
          ))}
        </DropdownMenuGroup>
        <DropdownMenuSeparator />
        <DropdownMenuGroup>
          <DropdownMenuItem onClick={resetLayout}>Сбросить вид</DropdownMenuItem>
        </DropdownMenuGroup>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
