function view = present(cache, parameters, ~, hasSignal)
choices = string(cache.channelItems);
value = string(parameters.channel);
if ~any(value == choices), value = choices(1); end
view = labkit.app.view.Snapshot() ...
    .choices("channel", choices).value("channel", value) ...
    .enabled("channel", hasSignal).enabled("analyze", hasSignal);
end
