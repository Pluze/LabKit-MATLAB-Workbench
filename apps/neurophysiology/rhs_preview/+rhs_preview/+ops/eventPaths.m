% Expected caller: rhs_preview.run. Input is a semantic pathPanel event.
% Output is a string column of selected paths.
function paths = eventPaths(event)
%EVENTPATHS Extract selected paths from a UI event.

    paths = strings(0, 1);
    if isstruct(event) && isfield(event, "paths")
        paths = string(event.paths(:));
    elseif isobject(event) && isprop(event, "paths")
        paths = string(event.paths(:));
    end
end
