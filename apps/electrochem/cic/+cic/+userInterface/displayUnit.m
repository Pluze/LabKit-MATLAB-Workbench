% Expected caller: CIC app runner and unit tests. Input is a user-facing CIC
% display unit label. Outputs are the numeric scale from mC/cm^2, normalized
% label, and stable suffix text; no side effects.

function [scale, unitLabel, unitSuffix] = displayUnit(unitLabel)
%DISPLAYUNIT Normalize CIC display units for app-owned view text.

    if nargin < 1 || isempty(unitLabel)
        unitLabel = 'mC/cm^2';
    end

    switch unitLabel
        case 'uC/cm^2'
            scale = 1e3;
            unitLabel = 'uC/cm^2';
        otherwise
            scale = 1;
            unitLabel = 'mC/cm^2';
    end

    unitSuffix = regexprep(unitLabel, '[\^/]', '');
end
