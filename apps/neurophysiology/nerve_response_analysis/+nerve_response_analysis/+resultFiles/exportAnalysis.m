% App-owned implementation for nerve_response_analysis.resultFiles.exportAnalysis within the nerve_response_analysis product workflow.
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
    Summary=analysisSummary(analysis), ...
    ManifestName="nerve_response_analysis.labkit.json");
written = context.writeResultPackage(folder, package);
state.project.results.lastExport = struct("jsonPath", string(path), ...
    "manifestPath", string(written.Value));
state.session.workflow.statusMessage = ...
    "Exported nerve-response analysis.";
state.session.workflow.lastAction = "Exported analysis";
context.log("info", "nerve_response_analysis.resultfiles.exportanalysis.completed", ...
    "Exported the analysis results.");
end

function summary = analysisSummary(analysis)
summary = struct( ...
    "recordingCount", double(analysis.recordingCount), ...
    "analyzedCount", double(analysis.analyzedCount), ...
    "eventCount", tableHeight(analysis, "events"), ...
    "trainCount", tableHeight(analysis, "trains"), ...
    "metricCount", tableHeight(analysis, "metrics"), ...
    "issueCount", tableHeight(analysis, "issues"));
end

function count = tableHeight(analysis, field)
count = 0;
if isfield(analysis, field) && istable(analysis.(field))
    count = height(analysis.(field));
end
end
