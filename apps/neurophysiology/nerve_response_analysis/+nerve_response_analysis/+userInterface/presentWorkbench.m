% Expected caller: Runtime V2. Input is canonical Nerve Response Analysis
% state. Output is deterministic controls, summary, details, log, and preview
% model without UI registry access or side effects.
function view = presentWorkbench(state)
    model = presentationModel(state);
    filterPath = sourcePath(state, "filterRecord");
    protocolPath = sourcePath(state, "protocol");
    hasFilter = strlength(filterPath) > 0;
    hasAnalysis = isstruct(state.session.cache.analysis) && ...
        ~isempty(fieldnames(state.session.cache.analysis));
    hasOutput = strlength(state.session.workflow.outputFolder) > 0;

    view = struct();
    view.controls.sessionFile = sourcePanel( ...
        filterPath, "No filter selected");
    view.controls.protocolFile = sourcePanel( ...
        protocolPath, "No protocol selected");
    view.controls.outputFolder = valueSpec(outputFolderText( ...
        state.session.workflow.outputFolder));
    view.controls.runAnalysis = enabledSpec(hasFilter);
    view.controls.exportAnalysis = enabledSpec(hasAnalysis && hasOutput);
    view.controls.statusField = valueSpec(state.session.workflow.statusMessage);
    view.controls.summaryTable = tableSpec( ...
        nerve_response_analysis.userInterface.summaryTableData(model));
    view.controls.details = valueSpec( ...
        nerve_response_analysis.userInterface.detailLines(model));
    view.controls.preview = valueSpec(state.session.view.previewMode);
    view.previews.preview = struct( ...
        "Renderer", "analysisPreview", "Model", model);
end

function model = presentationModel(state)
    model = struct( ...
        "sessionFile", sourcePath(state, "filterRecord"), ...
        "protocolFile", sourcePath(state, "protocol"), ...
        "outputFolder", state.session.workflow.outputFolder, ...
        "maxRecordings", state.project.parameters.maxRecordings, ...
        "maxDurationSec", state.project.parameters.maxDurationSec, ...
        "previewMode", state.session.view.previewMode, ...
        "analysis", state.session.cache.analysis, ...
        "statusMessage", state.session.workflow.statusMessage, ...
        "lastAction", state.session.workflow.lastAction);
end

function spec = sourcePanel(filepath, emptyStatus)
    files = struct("id", {}, "path", {}, "status", {});
    if strlength(filepath) > 0
        files = struct("id", "item1", ...
            "path", filepath, "status", "");
    end
    status = string(emptyStatus);
    if ~isempty(files)
        status = string(files.path);
    end
    spec = struct("Files", files, "Status", status);
end

function filepath = sourcePath(state, id)
    filepath = labkit.ui.runtime.sourcePaths( ...
        state.project.inputs.sources, id);
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
