function snapshot = snapshotLabKitComponents(rootHandle)
%SNAPSHOTLABKITCOMPONENTS Capture a sanitized component snapshot.
%
% Expected caller: GUI structural and gesture tests. Input is a figure,
% panel, axes, or UI component handle. Output is a struct array with generic
% component metadata only; file paths and sample details are not captured.

    handles = findall(rootHandle);
    snapshot = struct("class", {}, "type", {}, "tag", {}, "text", {}, ...
        "title", {}, "visible", {}, "enable", {}, "childCount", {});
    for k = 1:numel(handles)
        h = handles(k);
        if ~isvalid(h)
            continue;
        end
        snapshot(end+1) = struct( ... %#ok<AGROW>
            "class", string(class(h)), ...
            "type", string(readProp(h, "Type")), ...
            "tag", string(readProp(h, "Tag")), ...
            "text", sanitizeText(readProp(h, "Text")), ...
            "title", sanitizeText(readProp(h, "Title")), ...
            "visible", string(readProp(h, "Visible")), ...
            "enable", string(readProp(h, "Enable")), ...
            "childCount", numel(allchild(h)));
    end
end

function value = readProp(h, propName)
    if isprop(h, propName)
        value = h.(propName);
    else
        value = "";
    end
end

function value = sanitizeText(value)
    value = string(value);
    values = cellstr(value);
    driveRootPattern = "[A-Za-z]:[\\/]";
    homePathPattern = "(^|[^A-Za-z0-9])[/\\](Users|home)[/\\]";
    sensitive = ~cellfun(@isempty, regexp(values, driveRootPattern, "once")) ...
        | ~cellfun(@isempty, regexp(values, homePathPattern, "once"));
    value(sensitive) = "[redacted]";
end
