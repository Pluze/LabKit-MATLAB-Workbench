function state = apply(state, context)
%APPLY Apply safe gauge settings individually with readback verification.
box = context.getResource("mark10Connection");
connection = box("connection");
draft = state.session.settingsDraft;
requests = { ...
    "unit", settingValue("unit", draft.unit); ...
    "mode", settingValue("mode", draft.mode); ...
    "currentFilter", str2double(settingValue( ...
        "currentFilter", draft.currentFilter)); ...
    "displayFilter", str2double(settingValue( ...
        "displayFilter", draft.displayFilter)); ...
    "outputFormat", settingValue("outputFormat", draft.outputFormat); ...
    "autoOutput", str2double(settingValue( ...
        "autoOutput", draft.autoOutput))};
statuses = strings(1, size(requests, 1));
settings = connection.Settings;
for index = 1:size(requests, 1)
    [connection, settings, result] = labkit.mark10.writeSetting( ...
        connection, requests{index, 1}, requests{index, 2});
    statuses(index) = string(requests{index, 1}) + ": " + result.Status;
end
mark10_monitor.connection.retain(box, connection);
state = mark10_monitor.settings.copyReadback(state, settings);
state.session.connection.status = "Settings applied without SAVE.";
failures = statuses(~contains(statuses, ["SUPPORTED", "CONFIRMED"]));
if isempty(failures)
    state.session.connection.lastFailure = "";
else
    state.session.connection.lastFailure = join(failures, newline);
end
end

function value = settingValue(name, displayed)
value = mark10_monitor.settings.settingValue(name, displayed);
end
