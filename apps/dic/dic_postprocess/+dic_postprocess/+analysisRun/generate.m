% App-owned implementation for dic_postprocess.analysisRun.generate within the dic_postprocess product workflow.
function applicationState = generate(applicationState, callbackContext)
%GENERATE Load strain data and prepare overlays plus the ROI summary.
cache = applicationState.session.cache;
matPath = pathForRole( ...
    applicationState.project.inputs.sources, "strain");
if strlength(matPath) == 0 || isempty(cache.referenceImage) || ...
        isempty(cache.maskImage)
    callbackContext.alert( ...
        "Load the DIC MAT file, reference image, and mask image first.", ...
        "Missing inputs");
    return;
end
if ~validColorRange(applicationState.project.parameters)
    callbackContext.alert( ...
        "Color max must be greater than color min.", ...
        "Invalid color range");
    return;
end
try
    candidate = applicationState;
    candidate.session.cache.strain = ...
        dic_postprocess.sourceFiles.loadNcorrStrain(matPath);
    [summary, overlayExx, overlayEyy] = ...
        dic_postprocess.analysisRun.prepareOutputs( ...
            candidate.session.cache, candidate.project.parameters);
    candidate.project.results.summaryTable = summary;
    candidate.session.cache.overlayExx = overlayExx;
    candidate.session.cache.overlayEyy = overlayEyy;
    applicationState = candidate;
    callbackContext.log("info", "dic_postprocess.analysisrun.generate.status",  ...
        "Generated EXX/EYY overlays and ROI summary.");
catch exception
    callbackContext.log("error", "dic_postprocess.analysisrun.generate.exception", "Generate failed", ...
        Category="failure", Audience="developer", Exception=exception);
    callbackContext.alert(exception.message, "DIC postprocess error");
    callbackContext.log("info", ...
        "dic_postprocess.analysisrun.generate.status", ...
        "DIC postprocess generation failed.");
end
end

function filepath = pathForRole(sources, role)
filepath = "";
if isempty(sources)
    return;
end
match = find(string({sources.role}) == role, 1);
if isempty(match)
    return;
end
paths = labkit.app.source.paths(sources(match));
if ~isempty(paths)
    filepath = paths(1);
end
end

function accepted = validColorRange(parameters)
accepted = parameters.colorMax > parameters.colorMin;
end
