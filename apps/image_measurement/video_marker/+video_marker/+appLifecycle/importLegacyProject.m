% Expected caller: the V2 read-only legacy variable adapter. Input is the old
% videoMarkerProject value. Outputs are a complete current payload and optional
% navigation resume data. No legacy file is ever written by this adapter.
function [project, resume] = importLegacyProject(legacy)
    if ~isstruct(legacy) || ~isscalar(legacy) || ...
            ~isfield(legacy, 'schemaVersion') || legacy.schemaVersion ~= 1
        error('video_marker:InvalidLegacyProject', ...
            'Unsupported Video Marker legacy project schema.');
    end
    project = video_marker.appLifecycle.createProject();
    project.inputs.sources = legacySources(legacy);
    project.annotations.skeleton = legacy.skeleton;
    project.annotations.frames = ...
        video_marker.frameAnnotations.upgradeAnnotationSchema(legacy.annotations);
    project.annotations.calibration = normalizeCalibration(legacy.calibration);
    if isfield(legacy, 'exportPreferences')
        preferences = legacy.exportPreferences;
        project.parameters.coordinateUnitMode = string(preferences.unitMode);
        project.parameters.coordinateOriginMode = string(preferences.originMode);
        project.parameters.coordinateYAxisMode = string(preferences.yAxisMode);
        project.parameters.coordinateStartFrame = double(preferences.startFrame);
        project.parameters.coordinateEndFrame = double(preferences.endFrame);
    end
    currentFrame = 1;
    if isfield(legacy, 'currentFrame')
        currentFrame = double(legacy.currentFrame);
    end
    resume = struct("currentFrame", currentFrame);
end

function sources = legacySources(legacy)
    sources = struct("id", {}, "required", {}, "role", {}, ...
        "reference", {});
    reference = struct();
    if isfield(legacy, 'videoReference') && isstruct(legacy.videoReference)
        reference = legacy.videoReference;
    elseif isfield(legacy, 'videoPath') && strlength(string(legacy.videoPath)) > 0
        pathValue = string(legacy.videoPath);
        [~, name, extension] = fileparts(pathValue);
        reference = struct("schemaVersion", 1, "relativePath", "", ...
            "originalPath", pathValue, ...
            "fileName", string(name) + string(extension));
    end
    if isempty(fieldnames(reference))
        return;
    end
    sources = struct("id", "video", "required", true, ...
        "role", "video", "reference", reference);
end

function calibration = normalizeCalibration(value)
    line = zeros(0, 2);
    if isstruct(value) && isfield(value, 'referenceLine')
        line = value.referenceLine;
    end
    calibration = labkit.ui.interaction.scaleBarCalibration( ...
        fieldValue(value, 'referencePixels', NaN), ...
        fieldValue(value, 'referenceLength', 0), ...
        fieldValue(value, 'unit', "px"), ...
        struct("referenceLine", line));
end

function value = fieldValue(source, name, fallback)
    value = fallback;
    if isstruct(source) && isfield(source, name)
        value = source.(name);
    end
end
