% App-owned implementation for dic_postprocess.resultFiles.saveOverlays within the dic_postprocess product workflow.
function applicationState = saveOverlays( ...
        applicationState, callbackContext)
%SAVEOVERLAYS Write both prepared overlay PNGs.
cache = applicationState.session.cache;
if isempty(cache.overlayExx) || isempty(cache.overlayEyy)
    callbackContext.alert( ...
        "Generate overlays before saving.", "Save overlays");
    return;
end
choice = callbackContext.chooseOutputFolder("");
if choice.Cancelled
    callbackContext.log("info", "dic_postprocess.resultfiles.saveoverlays.status", "Save overlay PNGs cancelled.");
    return;
end
folder = string(choice.Value);
matPath = pathForRole( ...
    applicationState.project.inputs.sources, "strain");
tag = dic_postprocess.resultFiles.tagFromPath(matPath);
exxName = "overlay_exx_" + tag + ".png";
eyyName = "overlay_eyy_" + tag + ".png";
dic_postprocess.resultFiles.exportOverlayImage( ...
    cache.overlayExx, fullfile(folder, exxName));
dic_postprocess.resultFiles.exportOverlayImage( ...
    cache.overlayEyy, fullfile(folder, eyyName));
applicationState.project.results.overlayOutputPath = ...
    string(fullfile(folder, exxName));
callbackContext.log("info", "dic_postprocess.resultfiles.saveoverlays.status",  ...
    "Saved clean overlay PNGs.");
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
