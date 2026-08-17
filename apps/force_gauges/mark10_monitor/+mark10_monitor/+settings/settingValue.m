function value = settingValue(name, displayed)
%SETTINGVALUE Return the canonical driver value for a readable UI choice.
options = mark10_monitor.settings.options();
name = string(name);
if ~isscalar(name) || ~isfield(options, char(name))
    error("mark10_monitor:settings:InvalidChoice", ...
        "Unknown Series 5 setting selector '%s'.", name);
end
option = options.(char(name));
displayed = string(displayed);
if ~isscalar(displayed)
    error("mark10_monitor:settings:InvalidChoice", ...
        "Series 5 setting choice must be scalar text.");
end
match = find(option.Labels == displayed, 1);
if isempty(match)
    match = find(strcmpi(option.Values, displayed), 1);
end
if isempty(match)
    error("mark10_monitor:settings:InvalidChoice", ...
        "Unsupported %s choice '%s'.", name, displayed);
end
value = option.Values(match);
end
