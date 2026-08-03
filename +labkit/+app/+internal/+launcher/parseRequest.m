function [mode, modeArgs] = parseRequest(args)
%PARSEREQUEST Validate and normalize one launcher entry request.
mode = "gui";
modeArgs = struct("command", "", "source", "online");
if isempty(args)
    return;
end

if ismember(numel(args), [2 3]) && isTextScalar(args{1}) && ...
        strcmpi(string(args{1}), "documentation")
    if ~isTextScalar(args{2}) || ...
            strlength(strtrim(string(args{2}))) == 0
        error("labkit:app:internal:launcher:InvalidInput", ...
            "Documentation mode requires one nonempty app command.");
    end
    modeArgs.command = string(args{2});
    if numel(args) == 3
        if ~isTextScalar(args{3}) || ...
                ~ismember(lower(string(args{3})), ["online", "local"])
            error("labkit:app:internal:launcher:InvalidInput", ...
                "Documentation source must be online or local.");
        end
        modeArgs.source = lower(string(args{3}));
    end
    mode = "documentation";
    return;
end
if numel(args) ~= 1 || ~isTextScalar(args{1})
    error("labkit:app:internal:launcher:InvalidInput", ...
        "Use no input, list, version, or documentation plus an app command and optional source.");
end
mode = lower(string(args{1}));
if ~ismember(mode, ["list", "version"])
    error("labkit:app:internal:launcher:InvalidInput", "Unsupported launcher mode: %s", mode);
end
end

function tf = isTextScalar(value)
tf = ischar(value) || (isstring(value) && isscalar(value));
end
