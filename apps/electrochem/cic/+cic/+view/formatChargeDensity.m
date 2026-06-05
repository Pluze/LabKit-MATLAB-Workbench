% Expected caller: CIC app runner. Inputs are charge, density, and display unit
% label. Output is the stable read-only UI text. No side effects.

function out = formatChargeDensity(Q_C, cic_mCcm2, unitLabel)
    if isfinite(cic_mCcm2)
        switch unitLabel
            case 'uC/cm^2'
                cic = 1e3 * cic_mCcm2;
            otherwise
                cic = cic_mCcm2;
                unitLabel = 'mC/cm^2';
        end
        out = sprintf('%.6e C | %.6f %s', Q_C, cic, unitLabel);
    else
        out = sprintf('%.6e C | area unavailable', Q_C);
    end
end
