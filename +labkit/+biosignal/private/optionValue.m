function value = optionValue(opts, name, defaultValue)
%OPTIONVALUE Return an option field or a default value.

    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
