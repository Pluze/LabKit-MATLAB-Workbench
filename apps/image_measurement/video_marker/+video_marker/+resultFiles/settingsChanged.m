function state = settingsChanged(state, ~, ~)
%SETTINGSCHANGED Sanitize coordinate export range and invalidate its manifest.
count = max(1, state.session.cache.videoInfo.frameCount);
state.project.parameters.coordinateStartFrame = boundedFrame( ...
    state.project.parameters.coordinateStartFrame, 1, count);
state.project.parameters.coordinateEndFrame = boundedFrame( ...
    state.project.parameters.coordinateEndFrame, count, count);
state.project.results.coordinateManifestPath = "";
end

function value = boundedFrame(candidate, fallback, count)
value = fallback;
if isnumeric(candidate) && isscalar(candidate) && isfinite(double(candidate))
    value = round(double(candidate));
end
value = min(max(1, value), count);
end
