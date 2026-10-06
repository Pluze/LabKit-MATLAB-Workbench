function state = exportAnalysis(state, context)
analysis = state.session.cache.analysis;
if ~isstruct(analysis) || isempty(fieldnames(analysis))
    context.alert("Run analysis before exporting.", "Export analysis");
    return;
end
folder = state.session.workflow.outputFolder;
if strlength(folder) == 0
    chosen = context.chooseOutputFolder(pwd);
    if chosen.Cancelled
        return;
    end
    folder = string(chosen.Value);
    state.session.workflow.outputFolder = folder;
end
if exist(folder, "dir") ~= 7
    mkdir(folder);
end
name = "nerve_response_analysis.json";
path = fullfile(folder, name);
nerve_response_analysis.resultFiles.writeAnalysisJson(analysis, path);

state.session.workflow.statusMessage = ...
    "Exported nerve-response analysis.";
state.session.workflow.lastAction = "Exported analysis";
context.log("info", "nerve_response_analysis.resultfiles.exportanalysis.completed", ...
    "Exported the analysis results.");
end
