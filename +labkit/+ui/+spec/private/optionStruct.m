% Private UI spec helper. Expected caller: labkit.ui.spec constructors.
% Converts name/value pairs into a scalar struct without interpreting app
% semantics. Inputs are constructor varargin cells; output is an option struct.
function opts = optionStruct(args)
    if nargin < 1 || isempty(args)
        opts = struct();
        return;
    end

    if mod(numel(args), 2) ~= 0
        error('labkit:ui:spec:InvalidOptions', ...
            'UI spec options must be name/value pairs.');
    end

    opts = struct();
    for k = 1:2:numel(args)
        name = args{k};
        if ~(ischar(name) || (isstring(name) && isscalar(name)))
            error('labkit:ui:spec:InvalidOptionName', ...
                'UI spec option names must be text scalars.');
        end
        field = char(string(name));
        if ~isvarname(field)
            error('labkit:ui:spec:InvalidOptionName', ...
                'UI spec option name "%s" is not a valid MATLAB field name.', field);
        end
        opts.(field) = args{k + 1};
    end
end
