function added = addPathIfMissing(folder, position)
%ADDPATHIFMISSING Add one validated launcher-owned folder once.
% POSITION is "-begin" or "-end". The logical result reports whether this
% call changed the MATLAB path so a caller can own any required cleanup.

folder = string(folder);
if ~isscalar(folder) || exist(folder, "dir") ~= 7
    error("labkit:app:internal:launcher:FolderUnavailable", ...
        "Launcher folder is unavailable: %s", folder);
end
position = string(position);
if ~isscalar(position) || ~ismember(position, ["-begin", "-end"])
    error("labkit:app:internal:launcher:InvalidPathPosition", ...
        "Launcher path position must be -begin or -end.");
end
added = ~pathContains(folder);
if added
    addpath(char(folder), char(position));
end
end

function tf = pathContains(folder)
entries = string(strsplit(path, pathsep));
target = normalizePath(folder);
tf = any(normalizePath(entries) == target);
end

function value = normalizePath(value)
values = string(value);
for index = 1:numel(values)
    pathValue = java.nio.file.Paths.get( ...
        char(values(index)), javaArray("java.lang.String", 0));
    values(index) = string( ...
        pathValue.toAbsolutePath().normalize().toString());
end
value = values;
if ispc, value = lower(value); end
end
