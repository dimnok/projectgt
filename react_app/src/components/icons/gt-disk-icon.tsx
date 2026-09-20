import type { SVGProps } from "react";

/**
 * Иконка ГТ Диска: жёсткий диск с двумя индикаторами — зелёным и красным.
 *
 * Форма — иконка `hard-drive` из lucide, но у неё точки-индикаторы рисуются
 * тем же цветом, что и корпус. Здесь корпус берёт цвет текста (currentColor),
 * а точки заданы отдельно, поэтому их видно как лампочки.
 */
export function GtDiskIcon({ className, ...props }: SVGProps<SVGSVGElement>) {
  return (
    <svg
      xmlns="http://www.w3.org/2000/svg"
      width="24"
      height="24"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="2"
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
      aria-hidden="true"
      {...props}
    >
      <path d="M10 16h.01" stroke="#16a34a" />
      <path d="M2.212 11.577a2 2 0 0 0-.212.896V18a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-5.527a2 2 0 0 0-.212-.896L18.55 5.11A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z" />
      <path d="M21.946 12.013H2.054" />
      <path d="M6 16h.01" stroke="#dc2626" />
    </svg>
  );
}
