import { requestWorksDesktopTour } from "@/features/works/ui/desktop/works-desktop-tour";
import { requestWorksMobileTour } from "@/features/works/ui/mobile/works-mobile-tour";

type LaunchWorksHelpTourOptions = {
  isMobile: boolean;
  pathname: string;
  canOpenWorks: boolean;
  goToWorks: () => void;
};

export function launchWorksHelpTour({
  isMobile,
  pathname,
  canOpenWorks,
  goToWorks,
}: LaunchWorksHelpTourOptions): "started" | "navigating" | "denied" {
  if (!canOpenWorks) {
    return "denied";
  }
  if (pathname !== "/works") {
    if (isMobile) {
      requestWorksMobileTour({ persistRestart: true });
    } else {
      requestWorksDesktopTour({ persistRestart: true });
    }
    goToWorks();
    return "navigating";
  }
  if (isMobile) {
    requestWorksMobileTour();
  } else {
    requestWorksDesktopTour();
  }
  return "started";
}
