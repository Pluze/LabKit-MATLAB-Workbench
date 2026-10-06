function view = present(folder, resultAvailable)
%PRESENT Describe the current export destination and availability.
text = "No output folder chosen";
if strlength(string(folder)) > 0
    text = string(folder);
end
view = labkit.app.view.Snapshot() ...
    .value("outputFolder", text) ...
    .enabled("chooseOutputFolder", true) ...
    .enabled("exportResults", resultAvailable);
end
