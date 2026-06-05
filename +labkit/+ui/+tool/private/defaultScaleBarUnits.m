function units = defaultScaleBarUnits()
%DEFAULTSCALEBARUNITS Return the app-neutral scale-bar unit order.
%
% Expected caller:
%   Public labkit.ui scale-bar helpers.
%
% Inputs/outputs:
%   No inputs. Returns a row cellstr used for scale-bar unit controls and
%   calibration normalization.
%
% Side effects:
%   None.

    units = {'m', 'cm', 'mm', 'um', 'nm'};
end
