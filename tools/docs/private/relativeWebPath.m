function relative = relativeWebPath(fromOutput, toOutput)
%RELATIVEWEBPATH Return a portable relative URL between generated pages.

    fromFolder = replace(string(fileparts(char(fromOutput))), "\", "/");
    fromParts = splitPath(fromFolder);
    toParts = splitPath(replace(string(toOutput), "\", "/"));
    common = 0;
    limit = min(numel(fromParts), numel(toParts));
    while common < limit && fromParts(common + 1) == toParts(common + 1)
        common = common + 1;
    end
    up = repmat("..", numel(fromParts) - common, 1);
    down = toParts((common + 1):end);
    parts = [up; down];
    if isempty(parts)
        relative = "";
    else
        relative = strjoin(parts, "/");
    end
end

function parts = splitPath(path)
    if strlength(path) == 0 || path == "."
        parts = strings(0, 1);
    else
        parts = split(path, "/");
        parts = parts(strlength(parts) > 0);
    end
end
