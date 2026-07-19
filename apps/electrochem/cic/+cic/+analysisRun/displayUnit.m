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
            % Constant: 1000 converts mC/cm^2 to uC/cm^2 for display.
            microcoulombsPerMillicoulomb = 1e3;
            scale = microcoulombsPerMillicoulomb;
            unitLabel = 'uC/cm^2';
        otherwise
            scale = 1;
            unitLabel = 'mC/cm^2';
    end

    unitSuffix = regexprep(unitLabel, '[\^/]', '');
end
