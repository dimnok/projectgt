import { ConnectionIndicator } from "@/components/connection-indicator";
import { LoginForm } from "@/features/auth/ui/login-form";

export default function LoginPage() {
  return (
    <div className="relative mx-auto flex h-full w-full max-w-sm flex-col justify-center gap-6 overflow-hidden p-6 pt-[max(1.5rem,env(safe-area-inset-top))]">
      <div className="absolute top-[max(0.75rem,env(safe-area-inset-top))] right-4 z-10">
        <ConnectionIndicator />
      </div>
      <div className="flex flex-col gap-2">
        <h1 className="font-heading text-2xl font-medium">Вход</h1>
        <p className="text-sm text-muted-foreground">
          Введите номер телефона. Код придёт так же, как в текущем приложении.
        </p>
      </div>
      <LoginForm />
    </div>
  );
}
