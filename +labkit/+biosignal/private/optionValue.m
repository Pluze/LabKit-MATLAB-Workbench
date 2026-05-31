function value = optionValue(opts, name, defaultValue)
%OPTIONVALUE Return an option field or a default value without validation.
%
% Inputs:
%   opts - struct or non-struct value.
%   name - option field name.
%   defaultValue - value returned when opts is not a struct or field missing.
%
% Output:
%   value - opts.(name) when present, otherwise defaultValue.
%
% Notes:
%   This is intentionally small and private. Public facades remain
%   responsible for documenting and validating user-facing options.

    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
