"use client";

import { useState } from "react";
import { XIcon } from "lucide-react";

import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Field,
  FieldDescription,
  FieldLabel,
} from "@/components/ui/field";
import {
  Select,
  SelectContent,
  SelectGroup,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import type { EmployeeObjectOption } from "@/features/employees/types/employee.types";

type EmployeeObjectsFieldProps = {
  objects: EmployeeObjectOption[];
  value: string[];
  disabled?: boolean;
  onChange: (objectIds: string[]) => void;
};

export function EmployeeObjectsField({
  objects,
  value,
  disabled,
  onChange,
}: EmployeeObjectsFieldProps) {
  const [selectKey, setSelectKey] = useState(0);
  const selected = objects.filter((object) => value.includes(object.id));
  const available = objects.filter((object) => !value.includes(object.id));
  const items = available.map((object) => ({
    value: object.id,
    label: object.name,
  }));

  function addObject(objectId: string | null) {
    if (!objectId || value.includes(objectId)) {
      return;
    }
    onChange([...value, objectId]);
    setSelectKey((current) => current + 1);
  }

  function removeObject(objectId: string) {
    onChange(value.filter((id) => id !== objectId));
  }

  return (
    <Field>
      <FieldLabel htmlFor="employee-objects">Объекты</FieldLabel>
      {objects.length === 0 ? (
        <FieldDescription>
          Сначала добавьте объекты в справочник.
        </FieldDescription>
      ) : (
        <div className="flex flex-col gap-2">
          {available.length > 0 ? (
            <Select
              key={selectKey}
              items={items}
              disabled={disabled}
              onValueChange={addObject}
            >
              <SelectTrigger id="employee-objects" className="w-full">
                <SelectValue placeholder="Добавить объект" />
              </SelectTrigger>
              <SelectContent>
                <SelectGroup>
                  {available.map((object) => (
                    <SelectItem key={object.id} value={object.id}>
                      {object.name}
                    </SelectItem>
                  ))}
                </SelectGroup>
              </SelectContent>
            </Select>
          ) : (
            <FieldDescription>Выбраны все объекты.</FieldDescription>
          )}
          {selected.length > 0 ? (
            <div className="flex flex-wrap gap-2">
              {selected.map((object) => (
                <Badge key={object.id} variant="secondary">
                  {object.name}
                  <Button
                    type="button"
                    variant="ghost"
                    size="icon-xs"
                    disabled={disabled}
                    aria-label={`Убрать ${object.name}`}
                    onClick={() => removeObject(object.id)}
                  >
                    <XIcon />
                  </Button>
                </Badge>
              ))}
            </div>
          ) : (
            <FieldDescription>Объекты не выбраны.</FieldDescription>
          )}
        </div>
      )}
    </Field>
  );
}
