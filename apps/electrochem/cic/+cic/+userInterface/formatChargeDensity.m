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
    switch unitLabel
        case 'uC/cm^2'
            scale = 1e3;
            unitLabel = 'uC/cm^2';
        otherwise
            scale = 1;
            unitLabel = 'mC/cm^2';
    end
end
