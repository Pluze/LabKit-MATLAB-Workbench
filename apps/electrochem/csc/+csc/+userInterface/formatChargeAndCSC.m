% Expected caller: CSC app runner and unit tests. Inputs are charge in C and
% optional electrode area in cm^2. Output is the stable CSC display string.
% No file or UI side effects.

function text = formatChargeAndCSC(charge_C, area_cm2)
%FORMATCHARGEANDCSC Format charge and optional CSC normalization.

    if nargin < 2
        area_cm2 = NaN;
    end

    if isnan(area_cm2) || area_cm2 <= 0
        text = sprintf('%.12e C', charge_C);
    else
        csc_mC_cm2 = 1e3 * charge_C / area_cm2;
        text = sprintf('%.12e C | %.12e mC/cm^2', charge_C, csc_mC_cm2);
    end
end
