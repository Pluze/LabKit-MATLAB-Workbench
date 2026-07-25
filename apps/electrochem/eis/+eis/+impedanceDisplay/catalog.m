% Expected callers: EIS project, layout, plotting, and export capabilities.
% Output is the single App-owned impedance display-unit catalog.
function units = catalog()
%CATALOG Return supported impedance display units and conversion metadata.
%
% Output:
%   units - Scalar struct. choices contains UI labels, ohmsPerUnit converts
%       base ohms to the selected display unit, and exportTokens contains
%       ASCII unit suffixes for result column names.

omega = string(char(hex2dec("03A9")));
units = struct( ...
    "choices", ["m" + omega, omega, "k" + omega, "M" + omega], ...
    "ohmsPerUnit", [1e-3, 1, 1e3, 1e6], ...
    "exportTokens", ["mohm", "ohm", "kohm", "Mohm"]);
end
