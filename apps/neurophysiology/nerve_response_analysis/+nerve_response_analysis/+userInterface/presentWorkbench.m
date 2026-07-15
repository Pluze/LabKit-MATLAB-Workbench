% Expected caller: Runtime V2. Input is canonical Nerve Response Analysis
% state. Output is deterministic controls, summary, details, log, and preview
% model without UI registry access or side effects.
function view = presentWorkbench(state)
    model = presentationModel(state);
    hasFilter = ~isempty(state.project.inputs.filterSource);
    hasAnalysis = isstruct(state.session.cache.analysis) && ...
        ~isempty(fieldnames(state.session.cache.analysis));
    hasOutput = strlength(state.session.workflow.outputFolder) > 0;

    view = struct();
    view.controls.sessionFile = sourcePanel( ...
        state.project.inputs.filterSource, "No filter selected");
    view.controls.protocolFile = sourcePanel( ...
        state.project.inputs.protocolSource, "No protocol selected");
    view.controls.outputFolder = valueSpec(outputFolderText( ...
        state.session.workflow.outputFolder));
    view.controls.runAnalysis = enabledSpec(hasFilter);
    view.controls.exportAnalysis = enabledSpec(hasAnalysis && hasOutput);
    view.controls.statusField = valueSpec(state.session.workflow.statusMessage);
    view.controls.summaryTable = tableSpec( ...
        nerve_response_analysis.userInterface.summaryTableData(model));
    view.controls.details = valueSpec( ...
        nerve_response_analysis.userInterface.detailLines(model));
    view.controls.logPanel = valueSpec(cellstr(state.session.workflow.logLines));
    view.controls.preview = valueSpec(state.session.view.previewMode);
    view.previews.preview = struct( ...
        "Renderer", "analysisPreview", "Model", model);
end

function model = presentationModel(state)
    model = struct( ...
        "sessionFile", sourcePath(state.project.inputs.filterSource), ...
        "protocolFile", sourcePath(state.project.inputs.protocolSource), ...
        "outputFolder", state.session.workflow.outputFolder, ...
        "maxRecordings", state.project.parameters.maxRecordings, ...
        "maxDurationSec", state.project.parameters.maxDurationSec, ...
        "previewMode", state.session.view.previewMode, ...
        "analysis", state.session.cache.analysis, ...
        "statusMessage", state.session.workflow.statusMessage, ...
        "lastAction", state.session.workflow.lastAction);
end

function spec = sourcePanel(sources, emptyStatus)
    files = struct("id", {}, "path", {}, "status", {});
    if ~isempty(sources)
        files = struct("id", "item1", ...
            "path", string(sources(1).reference.originalPath), "status", "");
    end
    status = string(emptyStatus);
    if ~isempty(files)
        status = string(files.path);
    end
    spec = struct("Files", files, "Status", status);
end

function filepath = sourcePath(sources)
    filepath = "";
    if ~isempty(sources)
        filepath = string(sources(1).reference.originalPath);
    end
end

function text = outputFolderText(filepath)
    text = "No output folder selected";
    if strlength(string(filepath)) > 0
        text = string(filepath);
    end
end

function spec = valueSpec(value)
    spec = struct();
    spec.Value = value;
end

function spec = enabledSpec(value)
    spec = struct("Enabled", logical(value));
end

function spec = tableSpec(value)
    spec = struct();
    spec.Data = value;
end
