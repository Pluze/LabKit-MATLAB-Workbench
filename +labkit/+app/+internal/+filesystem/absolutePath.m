function values = absolutePath(values)
%ABSOLUTEPATH Return lexically normalized absolute filesystem paths.
% Callers provide text paths. Relative paths are resolved against pwd; dot
% segments are removed without resolving symbolic links or touching disk.

values = string(values);
for index = 1:numel(values)
    values(index) = normalizeOne(values(index));
end
end

function value = normalizeOne(value)
value = replace(value, "\", "/");
if ~isAbsolute(value)
    value = replace(string(fullfile(pwd, value)), "\", "/");
end
[prefix, parts, protectedCount] = splitAbsolute(value);
kept = strings(1, numel(parts));
keptCount = 0;
for part = parts(:).'
    if strlength(part) == 0 || part == "."
        continue
    end
    if part == ".."
        if keptCount > protectedCount
            keptCount = keptCount - 1;
        end
        continue
    end
    keptCount = keptCount + 1;
    kept(keptCount) = part;
end
kept = kept(1:keptCount);
if prefix == "//"
    value = "//" + join(kept, "/");
elseif endsWith(prefix, ":")
    value = prefix + "/" + join(kept, "/");
else
    value = "/" + join(kept, "/");
end
value = replace(value, "/", filesep);
end

function tf = isAbsolute(value)
tf = startsWith(value, "/") || ...
    ~isempty(regexp(char(value), '^[A-Za-z]:/', 'once'));
end

function [prefix, parts, protectedCount] = splitAbsolute(value)
if startsWith(value, "//")
    prefix = "//";
    parts = split(extractAfter(value, 2), "/");
    protectedCount = min(2, numel(parts));
    return
end
drive = regexp(char(value), '^[A-Za-z]:', 'match', 'once');
if ~isempty(drive)
    prefix = string(drive);
    parts = split(extractAfter(value, 3), "/");
    protectedCount = 0;
    return
end
prefix = "/";
parts = split(extractAfter(value, 1), "/");
protectedCount = 0;
end
