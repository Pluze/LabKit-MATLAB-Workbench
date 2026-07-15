% Expected caller: eis.definition. Output is the durable EIS project with
% portable source records, reproducible plot options, and export references.
function project = createProject()
    axes = eis.userInterface.axisItems();
    project = struct();
    project.inputs = struct("sources", emptySources());
    project.parameters = struct( ...
        "xName", axes(5), "yName", axes(7), ...
        "lineWidth", 1.4, "markerSize", 6, ...
        "showMarkers", true, "logX", false, "logY", false, ...
        "showLegend", true, "showGrid", true);
    project.annotations = struct();
    project.results = struct("lastExport", []);
    project.extensions = struct();
end

function sources = emptySources()
    sources = struct("id", {}, "required", {}, "role", {}, ...
        "reference", {});
end
