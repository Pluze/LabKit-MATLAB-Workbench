% Expected caller: CIC app runner. Inputs are charge, density, and display unit
% label. Output is the stable read-only UI text. No side effects.

function out = formatChargeDensity(Q_C, cic_mCcm2, unitLabel)
    if isfinite(cic_mCcm2)
        [scale, unitLabel] = displayScale(unitLabel);
        cic = scale * cic_mCcm2;
        out = sprintf('%.6e C | %.6f %s', Q_C, cic, unitLabel);
    else
        out = sprintf('%.6e C | area unavailable', Q_C);
    end
end

function [scale, unitLabel] = displayScale(unitLabel)
    [scale, unitLabel] = cic.analysisRun.displayUnit(unitLabel);
end
