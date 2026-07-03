% Expected caller: rhs_preview.definitionActions. Input is app state. Output is the
% user-facing preview-window summary.
function text = windowSummaryText(S)
%WINDOWSUMMARYTEXT Format current preview window.

    bounds = rhs_preview.analysisRun.previewWindowBounds(S);
    fileDurationSec = bounds.durationSec;
    if fileDurationSec <= 0
        text = "Select RHS to estimate preview length.";
        return;
    end

    startSec = rhs_preview.analysisRun.clampWindowStartSec(S.windowStartSec, S);
    stopSec = min(fileDurationSec, startSec + max(double(S.windowDurationSec), eps));
    if bounds.maxStartSec <= 0
        text = string(sprintf("full file: %.6g to %.6g s (%.6g s)", ...
            startSec, stopSec, fileDurationSec));
    else
        text = string(sprintf("%.6g to %.6g s of %.6g s (auto %.6g s)", ...
            startSec, stopSec, fileDurationSec, stopSec - startSec));
    end
end
