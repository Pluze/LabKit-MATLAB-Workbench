% App-owned implementation for dic_postprocess.workbench.present within the dic_postprocess product workflow.
function view = present(applicationState)
%PRESENT Map DIC state into one complete semantic snapshot fragment.
project = applicationState.project;
cache = applicationState.session.cache;
view = labkit.app.view.Snapshot() ...
    .tableData("resultTable", ...
        dic_postprocess.overlayPreview.summaryTableData( ...
            project.results.summaryTable), ...
        Columns=["Metric" "EXX" "EYY"]) ...
    .text("summaryText", summaryText(project)) ...
    .renderPlot("overlayAxes", struct( ...
        "exx", imageModel(cache.overlayExx, "EXX Overlay"), ...
        "eyy", imageModel(cache.overlayEyy, "EYY Overlay")));
end

function text = summaryText(project)
paths = pathsByRole(project.inputs.sources);
availability = "not generated";
if ~isempty(project.results.summaryTable)
    availability = "available";
end
lines = [ ...
    "DIC MAT: " + displayPath(paths.dicMat)
    "Reference image: " + displayPath(paths.referenceImage)
    "Mask image: " + displayPath(paths.maskImage)
    "Overlays: " + availability
    sprintf("Optical image: brightness %.3g, contrast %.3g, gamma %.3g, saturation %.3g", ...
        project.parameters.brightness, project.parameters.contrast, ...
        project.parameters.gamma, project.parameters.saturation)];
text = join(lines, newline);
end

function paths = pathsByRole(sources)
paths = struct("dicMat", "", "referenceImage", "", "maskImage", "");
if isempty(sources)
    return;
end
roles = string({sources.role});
paths.dicMat = originalPath(sources, find(roles == "strain", 1));
paths.referenceImage = originalPath( ...
    sources, find(roles == "reference", 1));
paths.maskImage = originalPath(sources, find(roles == "mask", 1));
end

function path = originalPath(sources, index)
path = "";
if ~isempty(index)
    path = string(sources(index).path);
end
end

function text = displayPath(path)
text = string(path);
if strlength(text) == 0
    text = "none";
end
end

function model = imageModel(imageData, titleText)
model = struct("imageData", imageData, "title", string(titleText));
end
