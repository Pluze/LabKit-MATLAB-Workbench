% Expected caller: CIC app runner. Inputs are charge, density, and display unit
% label. Output is the stable read-only UI text. No side effects.
function txt = formatChargeDensity(charge_C, density_mCcm2, unitLabel)
    txt = cic.core.dispatch("formatChargeDensity", charge_C, density_mCcm2, unitLabel);
end
