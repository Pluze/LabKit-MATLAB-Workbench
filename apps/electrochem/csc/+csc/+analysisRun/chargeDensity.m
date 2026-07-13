% App-owned CSC unit helper. Expected callers are CSC analysis, display, and
% export paths. Inputs are charge in C and electrode area in cm^2. Output is
% charge density in mC/cm^2 or NaN for invalid area. No side effects.
function value = chargeDensity(chargeC, areaCm2)
%CHARGEDENSITY Convert charge and electrode area to CSC density.

    if isfinite(areaCm2) && areaCm2 > 0
        % Constant: 1000 converts coulombs to millicoulombs for CSC density.
        millicoulombsPerCoulomb = 1e3;
        value = millicoulombsPerCoulomb * chargeC / areaCm2;
    else
        value = NaN;
    end
end
