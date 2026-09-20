export type GtDiskKind = "folder" | "file";

export type GtDiskNode = {
  id: string;
  name: string;
  kind: GtDiskKind;
  hint?: string;
  children?: GtDiskNode[];
};

export type GtDiskFolder = {
  id: string;
  name: string;
  hint: string;
  sampleFiles: string[];
};

export const GT_DISK_TITLE = "ГТ Диск";

export const GT_DISK_LEAD =
  "Общее файловое хранилище компании. Документы лежат по объектам, а не в личных папках сотрудников.";

export const GT_DISK_RULES = [
  "Один объект — одна корневая папка. Так проще найти чертёж, смету или акт.",
  "На всех объектах одинаковые разделы. Не нужно вспоминать, куда класть файл.",
  "В рабочей папке только актуальная версия. Старое уходит в «Старые».",
  "Доступ как в остальной программе: кто видит объект — видит его файлы, по роли.",
  "Поиск по имени важнее глубокого дерева. Папок не больше двух-трёх уровней.",
  "Файл считается существующим, только если он здесь — не в почте и не на личном диске.",
] as const;

export const GT_DISK_STUB_NOTE =
  "Пока это макет. Загрузить, скачать и открыть файлы здесь ещё нельзя.";

export const GT_DISK_COMPANY_FOLDERS: GtDiskFolder[] = [
  {
    id: "company-legal",
    name: "Юридические документы",
    hint: "Устав, свидетельства, доверенности",
    sampleFiles: ["Устав.pdf"],
  },
  {
    id: "company-templates",
    name: "Шаблоны",
    hint: "Общие бланки компании",
    sampleFiles: [],
  },
];

export const GT_DISK_OBJECT_FOLDERS: GtDiskFolder[] = [
  {
    id: "drawings",
    name: "Чертежи",
    hint: "Только действующая редакция",
    sampleFiles: ["План_этажа_Rev03.pdf"],
  },
  {
    id: "drawings-old",
    name: "Чертежи · Старые",
    hint: "Предыдущие версии, чтобы не открыть их по ошибке",
    sampleFiles: ["План_этажа_Rev02.pdf"],
  },
  {
    id: "contracts",
    name: "Договоры",
    hint: "Сканы и допсоглашения",
    sampleFiles: ["Договор.pdf"],
  },
  {
    id: "estimates",
    name: "Сметы",
    hint: "Excel и PDF расчётов",
    sampleFiles: ["Смета.xlsx"],
  },
  {
    id: "acts",
    name: "Акты",
    hint: "КС-2, КС-3, закрывающие документы",
    sampleFiles: [],
  },
  {
    id: "photos",
    name: "Фото",
    hint: "По датам, не общей кучей",
    sampleFiles: [],
  },
  {
    id: "other",
    name: "Прочее",
    hint: "Письма и файлы без своего раздела",
    sampleFiles: [],
  },
];

function fileNode(name: string): GtDiskNode {
  return { id: `file:${name}`, name, kind: "file" };
}

function folderFromTemplate(folder: GtDiskFolder): GtDiskNode {
  return {
    id: folder.id,
    name: folder.name,
    kind: "folder",
    hint: folder.hint,
    children: folder.sampleFiles.map(fileNode),
  };
}

function objectFolderTree(): GtDiskNode[] {
  return [
    {
      id: "drawings",
      name: "Чертежи",
      kind: "folder",
      hint: "Только действующая редакция",
      children: [
        fileNode("План_этажа_Rev03.pdf"),
        {
          id: "drawings-old",
          name: "Старые",
          kind: "folder",
          hint: "Предыдущие версии",
          children: [fileNode("План_этажа_Rev02.pdf")],
        },
      ],
    },
    folderFromTemplate(GT_DISK_OBJECT_FOLDERS[2]),
    folderFromTemplate(GT_DISK_OBJECT_FOLDERS[3]),
    folderFromTemplate(GT_DISK_OBJECT_FOLDERS[4]),
    folderFromTemplate(GT_DISK_OBJECT_FOLDERS[5]),
    folderFromTemplate(GT_DISK_OBJECT_FOLDERS[6]),
  ];
}

export type GtDiskObjectInput = {
  id: string;
  name: string;
  address: string;
};

/**
 * Builds the mock disk tree: company documents plus one folder per object.
 */
export function buildGtDiskRoot(objects: GtDiskObjectInput[]): GtDiskNode {
  return {
    id: "root",
    name: GT_DISK_TITLE,
    kind: "folder",
    children: [
      {
        id: "company",
        name: "Документы компании",
        kind: "folder",
        hint: "Общие файлы фирмы, не привязанные к площадке",
        children: GT_DISK_COMPANY_FOLDERS.map(folderFromTemplate),
      },
      ...objects.map((object) => ({
        id: `object:${object.id}`,
        name: object.name,
        kind: "folder" as const,
        hint: object.address.trim() || "Адрес не указан",
        children: objectFolderTree(),
      })),
    ],
  };
}

/**
 * Walks [path] from [root]. Returns the last existing folder if a segment is missing.
 */
export function getGtDiskNodeAt(root: GtDiskNode, path: string[]): GtDiskNode {
  let current = root;

  for (const segment of path) {
    const next = current.children?.find(
      (child) => child.kind === "folder" && child.id === segment
    );
    if (!next) {
      break;
    }
    current = next;
  }

  return current;
}

export function gtDiskCrumbs(root: GtDiskNode, path: string[]) {
  const crumbs: { id: string; name: string; path: string[] }[] = [
    { id: root.id, name: root.name, path: [] },
  ];
  let current = root;
  const walked: string[] = [];

  for (const segment of path) {
    const next = current.children?.find(
      (child) => child.kind === "folder" && child.id === segment
    );
    if (!next) {
      break;
    }
    walked.push(segment);
    crumbs.push({ id: next.id, name: next.name, path: [...walked] });
    current = next;
  }

  return crumbs;
}

export function countGtDiskItems(node: GtDiskNode) {
  return node.children?.length ?? 0;
}

export function splitGtDiskChildren(node: GtDiskNode) {
  const children = node.children ?? [];
  return {
    folders: children.filter((child) => child.kind === "folder"),
    files: children.filter((child) => child.kind === "file"),
  };
}
