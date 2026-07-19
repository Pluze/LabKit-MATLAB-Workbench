% Private scale-bar unit defaults. Expected caller: labkit.app.interaction scale-bar
% helpers. No inputs; output is the app-neutral unit label order. No side
% effects or app-specific assumptions.
function units = defaultScaleBarUnits()
%DEFAULTSCALEBARUNITS Return the app-neutral scale-bar unit order.
%
% Expected caller:
%   Public labkit.app scale-bar helpers.
%
% Inputs/outputs:
%   No inputs. Returns a row cellstr used for scale-bar unit controls and
%   calibration normalization.
%
% Side effects:
%   None.

    units = {'m', 'cm', 'mm', 'um', 'nm'};
end
