function [forceZero_N, travelZero_mm] = appliedZeroLevels(analysis)
%APPLIEDZEROLEVELS Return validated offsets shared by plots and analysis.
forceZero_N = finiteField(analysis, "forceZero_N");
travelZero_mm = finiteField(analysis, "travelZero_mm");
end

function value = finiteField(analysis, name)
value = 0;
if isfield(analysis, name)
    value = double(analysis.(name));
end
if ~isscalar(value) || ~isfinite(value)
    error("mark10_monitor:analysis:InvalidZeroLevel", ...
        "%s must be a finite scalar.", name);
end
end
