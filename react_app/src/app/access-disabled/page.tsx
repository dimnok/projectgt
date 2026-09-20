import { AccessDisabledScreen } from "@/features/auth/ui/access-disabled-screen";
import { AuthFlowShell } from "@/features/auth/ui/auth-flow-shell";

export default function AccessDisabledPage() {
  return (
    <AuthFlowShell className="max-w-sm">
      <AccessDisabledScreen />
    </AuthFlowShell>
  );
}
