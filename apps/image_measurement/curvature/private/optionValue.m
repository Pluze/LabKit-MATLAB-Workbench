function value = optionValue(opts, name, defaultValue)
%OPTIONVALUE Read a scalar option field with default fallback.
%
% Expected caller:
%   labkit_CurvatureMeasurement_app test handlers and app-private option
%   normalization helpers.
%
% Inputs/outputs:
%   Struct-like option input, field name, and default value. Returns the field
%   value only when opts is a struct and the field exists.
%
% Side effects:
%   None.

    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
