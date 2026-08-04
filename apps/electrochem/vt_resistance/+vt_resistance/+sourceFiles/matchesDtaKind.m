% Expected caller: VT Resistance fileList PathFilter. Input is newly proposed
% source paths. Output retains only DTA files detected as chrono; no GUI side
% effects.
function accepted = matchesDtaKind(paths)
arguments
    paths (1, :) string
end
accepted = false(size(paths));
for k = 1:numel(paths)
    [kind, status] = labkit.dta.detectType(paths(k));
    accepted(k) = status.ok && kind == "chrono";
end
end
