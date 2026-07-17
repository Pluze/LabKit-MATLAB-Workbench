function value = chargeDensity(chargeC, areaCm2)
%CHARGEDENSITY Convert charge in coulombs to density in mC/cm^2.
%
% Usage:
%   value = csc.analysisRun.chargeDensity(chargeC, areaCm2)
%
% Inputs:
%   chargeC - Numeric scalar or array of charge values in coulombs. Signed
%       values remain signed.
%   areaCm2 - Positive finite scalar electrode area in square centimetres.
%
% Outputs:
%   value - Charge density with the same size as chargeC, in mC/cm^2. When
%       areaCm2 is nonfinite or nonpositive, value is scalar NaN.
%
% Description:
%   The conversion is 1000*chargeC/areaCm2 because one coulomb equals 1000
%   millicoulombs. This unit helper performs no integration and does not take
%   the absolute value of cathodic charge.
%
% Failure Behavior:
%   A nonfinite or nonpositive scalar area returns scalar NaN. areaCm2 must be
%   scalar and chargeC must support numeric division; incompatible MATLAB
%   values or nonscalar area conditions raise the originating logical or
%   arithmetic error.
%
% Example:
%   density = csc.analysisRun.chargeDensity([0.002 -0.001], 0.5);
%   assert(isequal(density, [4 -2]))
%
% See also csc.analysisRun.computeCSC

    if isfinite(areaCm2) && areaCm2 > 0
        % Constant: 1000 converts coulombs to millicoulombs for CSC density.
        millicoulombsPerCoulomb = 1e3;
        value = millicoulombsPerCoulomb * chargeC / areaCm2;
    else
        value = NaN;
    end
end
