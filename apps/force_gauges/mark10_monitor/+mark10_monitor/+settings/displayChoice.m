function label = displayChoice(name, value)
%DISPLAYCHOICE Convert a canonical setting value into its readable label.
option = requireOption(name);
value = scalarText(value);
labelMatch = find(option.Labels == value, 1);
if ~isempty(labelMatch)
    label = option.Labels(labelMatch);
    return;
end
valueMatch = find(strcmpi(option.Values, value), 1);
if isempty(valueMatch)
    invalid(name, value);
end
label = option.Labels(valueMatch);
end

function option = requireOption(name)
name = string(name);
values = mark10_monitor.settings.options();
if ~isscalar(name) || ~isfield(values, char(name))
    error("mark10_monitor:settings:InvalidChoice", ...
        "Unknown Series 5 setting selector '%s'.", name);
end
option = values.(char(name));
end

function value = scalarText(value)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error("mark10_monitor:settings:InvalidChoice", ...
        "Series 5 setting choice must be scalar text.");
end
value = string(value);
end

function invalid(name, value)
error("mark10_monitor:settings:InvalidChoice", ...
    "Unsupported %s choice '%s'.", name, value);
end
