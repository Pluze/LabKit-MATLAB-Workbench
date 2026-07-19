function applicationState = generate(applicationState, callbackContext)
%GENERATE Load strain data and prepare overlays plus the ROI summary.
cache = applicationState.session.cache;
matPath = pathForRole( ...
    applicationState.project.inputs.sources, "strain", callbackContext);
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
    applicationState.session.cache.strain = ...
        dic_postprocess.sourceFiles.loadNcorrStrain(matPath);
    applicationState = prepare(applicationState);
    callbackContext.appendStatus( ...
        "Generated EXX/EYY overlays and ROI summary.");
catch exception
    callbackContext.reportError("Generate failed", exception);
    callbackContext.alert(exception.message, "DIC postprocess error");
    callbackContext.appendStatus("Generate failed: " + exception.message);
end
end

function filepath = pathForRole(sources, role, context)
filepath = "";
if isempty(sources)
    return;
end
match = find(string({sources.role}) == role, 1);
if isempty(match)
    return;
end
paths = context.resolveSourcePaths(sources(match));
if ~isempty(paths)
    filepath = paths(1);
end
end

function state = prepare(state)
[summary, overlayExx, overlayEyy] = ...
    dic_postprocess.analysisRun.prepareOutputs( ...
        state.session.cache, state.project.parameters);
state.project.results.summaryTable = summary;
state.session.cache.overlayExx = overlayExx;
state.session.cache.overlayEyy = overlayEyy;
end

function accepted = validColorRange(parameters)
accepted = parameters.colorMax > parameters.colorMin;
end
