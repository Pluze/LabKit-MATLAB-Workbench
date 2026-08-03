% Expected caller: CSC fileList PathFilter. Input is newly proposed source
% paths. Output retains only DTA files detected as CV/CT; no GUI side effects.
function accepted = matchesDtaKind(paths)
arguments
    paths (1, :) string
end
accepted = false(size(paths));
for k = 1:numel(paths)
    [kind, status] = labkit.dta.detectType(paths(k));
    accepted(k) = status.ok && kind == "cvct";
end
end
