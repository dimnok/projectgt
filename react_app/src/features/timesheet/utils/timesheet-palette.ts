/**
 * Object color palette used for Excel timesheet export and object identification.
 */
export const OBJECT_PALETTE_HEX_LIST: string[] = [
  "E3F2FD", // Blue
  "E8F5E9", // Emerald
  "FFF3E0", // Amber
  "F3E5F5", // Purple
  "E0F2F1", // Teal
  "FFEBEE", // Rose
  "F1F8E9", // Lime
  "E8EAF6", // Indigo
  "FFF8E1", // Yellow
  "EDE7F6", // Violet
  "E0F7FA", // Cyan
  "FBE9E7", // Orange
];

export function getObjectColorHex(index: number): string {
  return OBJECT_PALETTE_HEX_LIST[index % OBJECT_PALETTE_HEX_LIST.length];
}
