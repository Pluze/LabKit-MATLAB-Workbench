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
output = labkit.app.result.File("nerveResponseAnalysis", "primary", name, ...
    MediaType="application/json");
package = labkit.app.result.Package(Outputs={output}, ...
    Inputs=struct("sources", state.project.inputs.sources), ...
    Parameters=state.project.parameters, ...
    Summary=struct("analyzedCount", analysis.analyzedCount));
written = context.writeResultPackage(folder, package);
state.project.results.lastExport = struct("jsonPath", string(path), ...
    "manifestPath", string(written.Value));
context.appendStatus("Exported analysis: " + string(path));
end
