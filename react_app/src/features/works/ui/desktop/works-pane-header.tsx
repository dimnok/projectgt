"use client";

import type { ReactNode } from "react";

import {
  Card,
  CardContent,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";

type WorksPaneHeaderProps = {
  title: string;
  children: ReactNode;
};

export function WorksPaneHeader({ title, children }: WorksPaneHeaderProps) {
  return (
    <Card className="h-full shadow-float max-lg:[--card-spacing:--spacing(3)]">
      <CardHeader className="border-b max-lg:hidden">
        <CardTitle>{title}</CardTitle>
      </CardHeader>
      <CardContent className="flex flex-1 flex-nowrap items-center gap-3">
        {children}
      </CardContent>
    </Card>
  );
}
