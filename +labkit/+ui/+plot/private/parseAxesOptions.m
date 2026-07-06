% Private UI plot axes helper. Expected caller: public axes helper wrappers.
% Inputs are name/value args and a defaults struct. Output is a struct with
% defaults overridden by provided name/value pairs.
function opts = parseAxesOptions(args, defaults)
    opts = defaults;
    if isempty(args)
        return;
    end
    if mod(numel(args), 2) ~= 0
        error('labkit:ui:plot:InvalidOptions', ...
            'Axes helper options must be name/value pairs.');
    end
    for k = 1:2:numel(args)
        name = char(string(args{k}));
        if ~isfield(opts, name)
            error('labkit:ui:plot:InvalidOption', ...
                'Unsupported axes helper option "%s".', name);
        end
        opts.(name) = args{k + 1};
    end
end
