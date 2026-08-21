%CREATESESSION Rebuild transient DIC inputs and prepared overlay caches.
function session = createSession(project, ~)
    paths = resolvedPaths(project.inputs.sources);
    cache = dic_postprocess.sourceFiles.loadProjectInputs( ...
        paths, ~isempty(project.results.summaryTable));
    [cache.overlayExx, cache.overlayEyy] = preparedOverlays( ...
        cache, project.parameters);
    session = struct( ...
        "selection", struct( ...
            "matFile", labkit.app.event.ListSelection(), ...
            "referenceFile", labkit.app.event.ListSelection(), ...
            "maskFile", labkit.app.event.ListSelection()), ...
        "cache", cache);
end

function paths = resolvedPaths(sources)
    paths = struct( ...
        "dicMat", pathForRole(sources, "strain"), ...
        "referenceImage", pathForRole(sources, "reference"), ...
        "maskImage", pathForRole(sources, "mask"));
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
    resolved = labkit.app.source.paths(sources(match));
    if ~isempty(resolved)
        filepath = resolved(1);
    end
end

function [overlayExx, overlayEyy] = preparedOverlays(cache, parameters)
    overlayExx = [];
    overlayEyy = [];
    if ~hasPreparedInputs(cache) || ...
            parameters.colorMax <= parameters.colorMin
        return;
    end
    [~, overlayExx, overlayEyy] = ...
        dic_postprocess.analysisRun.prepareOutputs(cache, parameters);
end

function tf = hasPreparedInputs(inputs)
    tf = isfield(inputs.strain, 'exx') && ...
        ~isempty(inputs.referenceImage) && ~isempty(inputs.maskImage);
end
