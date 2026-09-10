/**
 * Resizes an image to max 1600px on the long side and encodes JPEG at 85%.
 * SVG files are returned unchanged.
 */
export async function compressImageFile(
  file: File,
  maxSide = 1600,
  quality = 0.85
): Promise<{ blob: Blob; ext: string; mime: string }> {
  if (file.type === "image/svg+xml") {
    return { blob: file, ext: "svg", mime: file.type };
  }

  return new Promise((resolve) => {
    const reader = new FileReader();

    reader.onload = (event) => {
      const img = new Image();
      img.onload = () => {
        let width = img.naturalWidth || img.width;
        let height = img.naturalHeight || img.height;

        if (width > maxSide || height > maxSide) {
          if (width >= height) {
            height = Math.round((height * maxSide) / width);
            width = maxSide;
          } else {
            width = Math.round((width * maxSide) / height);
            height = maxSide;
          }
        }

        const canvas = document.createElement("canvas");
        canvas.width = width;
        canvas.height = height;
        const ctx = canvas.getContext("2d");

        if (!ctx) {
          resolve({ blob: file, ext: "jpg", mime: file.type || "image/jpeg" });
          return;
        }

        ctx.drawImage(img, 0, 0, width, height);
        canvas.toBlob(
          (blob) => {
            if (blob) {
              resolve({ blob, ext: "jpg", mime: "image/jpeg" });
              return;
            }
            resolve({
              blob: file,
              ext: "jpg",
              mime: file.type || "image/jpeg",
            });
          },
          "image/jpeg",
          quality
        );
      };
      img.onerror = () => {
        resolve({ blob: file, ext: "jpg", mime: file.type || "image/jpeg" });
      };
      img.src = event.target?.result as string;
    };

    reader.onerror = () => {
      resolve({ blob: file, ext: "jpg", mime: file.type || "image/jpeg" });
    };
    reader.readAsDataURL(file);
  });
}
