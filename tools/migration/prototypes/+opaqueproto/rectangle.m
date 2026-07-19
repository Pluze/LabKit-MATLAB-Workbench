function value = rectangle(varargin)
    options = rectangleOptions(varargin{:});
    readToken(options.Changed, "command");
    value = makeToken("interaction", struct( ...
        "Kind", "rectangle", "Target", options.Target, ...
        "Value", options.Bounds, "Changed", options.Changed));
end

function options = rectangleOptions(varargin)
    known = ["Target", "Bounds", "Changed"];
    if mod(numel(varargin), 2) ~= 0
        error("labkit:ui:contract:UnknownArgument", ...
            "rectangle requires named arguments.");
    end
    options = struct();
    for k = 1:2:numel(varargin)
        name = string(varargin{k});
        if ~isscalar(name) || ~any(name == known) || isfield(options, name)
            error("labkit:ui:contract:UnknownArgument", ...
                "Unknown or duplicate rectangle argument: %s", name);
        end
        options.(name) = varargin{k + 1};
    end
    if ~all(isfield(options, known))
        error("prototype:ui:InvalidValue", ...
            "rectangle requires Target, Bounds, and Changed.");
    end
    if ~isscalar(options.Target) || strlength(string(options.Target)) == 0 || ...
            ~isequal(size(options.Bounds), [1 4]) || ...
            ~isnumeric(options.Bounds) || ...
            ~isa(options.Changed, "function_handle")
        error("prototype:ui:InvalidValue", ...
            "Invalid rectangle argument value.");
    end
end
