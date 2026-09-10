const GAP = 8;
const MAX_SIDE = 1600;
const JPEG_QUALITY = 0.85;

export const MAX_MORNING_PHOTOS = 4;

type Rect = { x: number; y: number; w: number; h: number };

function canvasSize(count: number): { width: number; height: number } {
  if (count === 2) {
    return { width: MAX_SIDE, height: Math.round(MAX_SIDE / 2) };
  }
  return { width: MAX_SIDE, height: MAX_SIDE };
}

function cellRects(count: number, width: number, height: number): Rect[] {
  if (count <= 1) {
    return [{ x: 0, y: 0, w: width, h: height }];
  }

  const col = Math.floor((width - GAP) / 2);
  const restX = width - col - GAP;

  if (count === 2) {
    return [
      { x: 0, y: 0, w: col, h: height },
      { x: col + GAP, y: 0, w: restX, h: height },
    ];
  }

  const row = Math.floor((height - GAP) / 2);
  const restY = height - row - GAP;

  if (count === 3) {
    return [
      { x: 0, y: 0, w: col, h: height },
      { x: col + GAP, y: 0, w: restX, h: row },
      { x: col + GAP, y: row + GAP, w: restX, h: restY },
    ];
  }

  return [
    { x: 0, y: 0, w: col, h: row },
    { x: col + GAP, y: 0, w: restX, h: row },
    { x: 0, y: row + GAP, w: col, h: restY },
    { x: col + GAP, y: row + GAP, w: restX, h: restY },
  ];
}

function drawCover(
  ctx: CanvasRenderingContext2D,
  image: CanvasImageSource & { width: number; height: number },
  rect: Rect
) {
  const sourceWidth = image.naturalWidth || image.width;
  const sourceHeight = image.naturalHeight || image.height;
  const sourceRatio = sourceWidth / sourceHeight;
  const cellRatio = rect.w / rect.h;
  let sx = 0;
  let sy = 0;
  let sw = sourceWidth;
  let sh = sourceHeight;

  if (sourceRatio > cellRatio) {
    sw = sourceHeight * cellRatio;
    sx = (sourceWidth - sw) / 2;
  } else {
    sh = sourceWidth / cellRatio;
    sy = (sourceHeight - sh) / 2;
  }

  ctx.drawImage(image, sx, sy, sw, sh, rect.x, rect.y, rect.w, rect.h);
}

function loadImage(file: File): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const image = new Image();
    image.onload = () => {
      URL.revokeObjectURL(url);
      resolve(image);
    };
    image.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error("Не удалось прочитать одно из фото"));
    };
    image.src = url;
  });
}

/**
 * Собирает 2–4 снимка в один JPEG-коллаж. Одно фото не обрабатывает.
 */
export async function composeWorkPhotoCollage(files: File[]): Promise<File> {
  if (files.length < 2 || files.length > MAX_MORNING_PHOTOS) {
    throw new Error("Для коллажа нужно от 2 до 4 фото");
  }

  const images = await Promise.all(files.map(loadImage));
  const { width, height } = canvasSize(files.length);
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  if (!ctx) {
    throw new Error("Не удалось собрать коллаж");
  }

  ctx.fillStyle = "#0a0a0a";
  ctx.fillRect(0, 0, width, height);

  const rects = cellRects(files.length, width, height);
  images.forEach((image, index) => {
    drawCover(ctx, image, rects[index]);
  });

  const blob = await new Promise<Blob>((resolve, reject) => {
    canvas.toBlob(
      (next) => {
        if (!next) {
          reject(new Error("Не удалось сохранить коллаж"));
          return;
        }
        resolve(next);
      },
      "image/jpeg",
      JPEG_QUALITY
    );
  });

  return new File([blob], "morning-collage.jpg", { type: "image/jpeg" });
}
