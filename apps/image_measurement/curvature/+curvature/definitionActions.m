% App-owned V2 action registry for Curvature Measurement. Handlers receive
% canonical state/events/services and own durable curve/calibration edits,
% scientific results, model-based exports, and workflow messages.
function actions = definitionActions()
    actions = struct( ...
        "openImage", @onOpenImage, ...
        "toggleCurveEdit", @onToggleCurveEdit, ...
        "curvePointsEdited", @onCurvePointsEdited, ...
        "undoCurvePoint", @onUndoCurvePoint, ...
        "clearCurve", @onClearCurve, ...
        "measureScaleReference", @onMeasureScaleReference, ...
        "scaleReferenceEdited", @onScaleReferenceEdited, ...
        "scaleCalibrationChanged", @onScaleCalibrationChanged, ...
        "scaleBarSettingChanged", @onScaleBarSettingChanged, ...
        "placeScaleBar", @onPlaceScaleBar, ...
        "fitSettingChanged", @onFitSettingChanged, ...
        "viewSettingChanged", @onViewSettingChanged, ...
        "fitCurvature", @onFitCurvature, ...
        "measureCurveLength", @onMeasureCurveLength, ...
        "exportCsv", @onExportCsv, ...
        "exportOverlay", @onExportOverlay);
end

function state = onOpenImage(state, event, services)
    paths = services.events.paths(event, "addedFiles");
    if isempty(paths)
        paths = services.events.paths(event, "files");
    end
    if isempty(paths)
        state = services.workflow.log(state, "Image selection cancelled.");
        return;
    end
    try
        imageData = imread(paths(1));
    catch ME
        services.diagnostics.report('Could not read image', ME);
        services.dialogs.alert(ME.message, 'Could not read image');
        return;
    end
    state.project.inputs.sources = services.project.sourceRecord( ...
        "image", "image", paths(1), true);
    state.project.annotations.curvePoints = zeros(0, 2);
    calibration = state.project.annotations.calibration;
    state.project.annotations.calibration = ...
        labkit.ui.interaction.scaleBarCalibration( ...
        [], calibration.referenceLength, calibration.unit);
    state.session.cache.imagePath = paths(1);
    state.session.cache.image = imageData;
    state.session.workflow.editMode = "none";
    state.session.workflow.statusMessage = "Image loaded.";
    state.session.view.scaleBar = [];
    state = clearMeasurements(state);
    state = services.workflow.log(state, "Loaded image: " + paths(1));
end

function state = onToggleCurveEdit(state, ~, services)
    if isempty(state.session.cache.image)
        services.dialogs.alert('Open an image before editing curve points.', ...
            'No image loaded');
        return;
    end
    if state.session.workflow.editMode == "curve"
        state.session.workflow.editMode = "none";
        message = "Finished curve edit.";
    else
        state.session.workflow.editMode = "curve";
        state = clearMeasurements(state);
        message = ["Started curve edit. Double-click blank image space to " ...
            "add or insert points; drag points to move them; double-click " ...
            "a point to delete it."];
    end
    state = services.workflow.log(state, message);
end

function state = onCurvePointsEdited(state, event, services)
    points = normalizePoints(event.value);
    state.project.annotations.curvePoints = points;
    state = clearMeasurements(state);
    state = services.workflow.log(state, sprintf( ...
        'Curve edit updated: %d point(s).', size(points, 1)));
end

function state = onUndoCurvePoint(state, ~, services)
    points = state.project.annotations.curvePoints;
    if isempty(points)
        return;
    end
    state.project.annotations.curvePoints(end, :) = [];
    state = clearMeasurements(state);
    state = services.workflow.log(state, "Undid last curve point.");
end

function state = onClearCurve(state, ~, services)
    state.project.annotations.curvePoints = zeros(0, 2);
    state = clearMeasurements(state);
    state = services.workflow.log(state, "Cleared curve points.");
end

function state = onMeasureScaleReference(state, ~, services)
    if isempty(state.session.cache.image)
        services.dialogs.alert( ...
            'Open an image before measuring reference pixels.', ...
            'No image loaded');
        return;
    end
    if state.session.workflow.editMode == "reference"
        state.session.workflow.editMode = "none";
        message = "Finished reference-pixel edit.";
    else
        state.session.workflow.editMode = "reference";
        state.session.view.scaleBar = [];
        message = ["Started reference-pixel edit. Double-click two endpoints " ...
            "and drag them to refine the reference line."];
    end
    state = clearMeasurements(state);
    state = services.workflow.log(state, message);
end

function state = onScaleReferenceEdited(state, event, ~)
    points = normalizePoints(event.value);
    if size(points, 1) > 2
        points = points(end-1:end, :);
    end
    calibration = state.project.annotations.calibration;
    state.project.annotations.calibration = ...
        labkit.ui.interaction.scaleBarCalibration( ...
        NaN, calibration.referenceLength, calibration.unit, ...
        struct("referenceLine", points));
    state.session.view.scaleBar = [];
    state = clearMeasurements(state);
end

function state = onScaleCalibrationChanged(state, event, ~)
    calibration = state.project.annotations.calibration;
    referencePixels = calibration.referencePixels;
    referenceLength = calibration.referenceLength;
    unit = calibration.unit;
    referenceLine = calibration.referenceLine;
    target = string(event.target);
    if target == "scaleReferencePixels"
        referencePixels = positiveOrNaN(event.value);
        referenceLine = zeros(0, 2);
    elseif target == "scaleReferenceLength"
        referenceLength = nonnegativeScalar(event.value, referenceLength);
    elseif target == "scaleCalibrationUnit"
        unit = string(event.value);
    end
    state.project.annotations.calibration = ...
        labkit.ui.interaction.scaleBarCalibration( ...
        referencePixels, referenceLength, unit, ...
        struct("referenceLine", referenceLine));
    state.session.view.scaleBar = [];
    state = clearMeasurements(state);
end

function state = onScaleBarSettingChanged(state, ~, ~)
    state.project.parameters.scaleBarLength = nonnegativeScalar( ...
        state.project.parameters.scaleBarLength, 0);
    state.session.view.scaleBar = [];
end

function state = onPlaceScaleBar(state, ~, services)
    calibration = state.project.annotations.calibration;
    if isempty(state.session.cache.image) || ~calibration.isCalibrated
        services.dialogs.alert(["Measure or enter reference pixels, then " ...
            "enter a positive reference length and unit."], ...
            'Calibration required');
        return;
    end
    try
        state.session.view.scaleBar = ...
            labkit.ui.interaction.scaleBarGeometry( ...
            size(state.session.cache.image), calibration, ...
            state.project.parameters.scaleBarLength, ...
            state.project.parameters.scaleBarPosition, ...
            state.project.parameters.scaleBarColor);
        state.session.workflow.editMode = "none";
        state = services.workflow.log(state, sprintf( ...
            'Placed scale bar: %.6g %s.', ...
            state.project.parameters.scaleBarLength, calibration.unit));
    catch ME
        services.diagnostics.report('Could not place scale bar', ME);
        services.dialogs.alert(ME.message, 'Could not place scale bar');
    end
end

function state = onFitSettingChanged(state, ~, ~)
    state.project.parameters.densePointCount = max(3, round( ...
        nonnegativeScalar(state.project.parameters.densePointCount, 300)));
    state = clearMeasurements(state);
end

function state = onViewSettingChanged(state, ~, ~)
    state.project.parameters.showDensePoints = ...
        logical(state.project.parameters.showDensePoints);
end

function state = onFitCurvature(state, ~, services)
    points = state.project.annotations.curvePoints;
    if size(points, 1) < 3
        services.dialogs.alert( ...
            'At least 3 curve points are required to fit curvature.', ...
            'Not enough points');
        return;
    end
    try
        path = visibleCurve(state);
        task = curvature.appState.fitTask(points, path, ...
            state.project.annotations.calibration, struct( ...
            "doDensify", state.project.parameters.densify, ...
            "denseN", state.project.parameters.densePointCount));
        if state.project.results.fit.ok && ...
                state.session.cache.fitFingerprint == task.fingerprint
            state = services.workflow.log(state, ...
                "Curvature fit already matches current curve and scale.");
            return;
        end
        fit = curvature.analysisRun.computeCurvatureFit( ...
            task.points(:, 1), task.points(:, 2), task.calibration, ...
            task.options.doDensify, task.options.denseN, ...
            task.fitPath(:, 1), task.fitPath(:, 2));
    catch ME
        services.diagnostics.report('Circle fit failed', ME);
        services.dialogs.alert(ME.message, 'Circle fit failed');
        return;
    end
    state.project.results.fit = fit;
    state.project.results.length = curvature.appState.lengthResultFromFit(fit);
    state.project.results.lastCsvExport = [];
    state.project.results.lastOverlayExport = [];
    state.session.cache.fitFingerprint = task.fingerprint;
    state.session.cache.lengthFingerprint = "";
    state = services.workflow.log(state, sprintf( ...
        'Fit complete: R = %.6g %s, curvature = %.6g %s.', ...
        fit.R_show, fit.unitLen, fit.kappa_show, fit.unitK));
end

function state = onMeasureCurveLength(state, ~, services)
    points = state.project.annotations.curvePoints;
    if size(points, 1) < 2
        services.dialogs.alert( ...
            'At least 2 curve points are required to measure curve length.', ...
            'Not enough points');
        return;
    end
    try
        path = visibleCurve(state);
        task = curvature.appState.lengthTask(points, path, ...
            state.project.annotations.calibration);
        if state.project.results.length.ok && ...
                state.session.cache.lengthFingerprint == task.fingerprint
            state = services.workflow.log(state, ...
                "Curve length already matches current curve and scale.");
            return;
        end
        result = curvature.analysisRun.computeCurveLength( ...
            task.lengthPath(:, 1), task.lengthPath(:, 2), task.calibration);
    catch ME
        services.diagnostics.report('Curve length failed', ME);
        services.dialogs.alert(ME.message, 'Curve length failed');
        return;
    end
    state.project.results.length = result;
    state.project.results.lastCsvExport = [];
    state.session.cache.lengthFingerprint = task.fingerprint;
    state = services.workflow.log(state, sprintf( ...
        'Curve length measured: %.6g %s.', ...
        result.length_show, result.unitLen));
end

function state = onExportCsv(state, ~, services)
    fit = state.project.results.fit;
    lengthResult = state.project.results.length;
    if ~fit.ok && ~lengthResult.ok
        services.dialogs.alert( ...
            'Fit curvature or measure curve length before exporting.', ...
            'No measurement result');
        return;
    end
    [out, cancelled] = services.dialogs.outputFile( ...
        '*.csv', 'Export curvature result CSV', 'curvature_result.csv');
    if cancelled
        state = services.workflow.log(state, "Result CSV export cancelled.");
        return;
    end
    tableData = curvature.resultFiles.buildResultTable( ...
        fit, state.session.cache.imagePath, lengthResult);
    writetable(tableData, out);
    [manifestPath, ~] = writeManifest(state, services, out, ...
        "curvatureResults", "text/csv", "curvature_result.labkit.json");
    state.project.results.lastCsvExport = struct( ...
        "csvPath", string(out), "manifestPath", string(manifestPath));
    state = services.workflow.log(state, "Exported result CSV: " + string(out));
end

function state = onExportOverlay(state, ~, services)
    if isempty(state.session.cache.image)
        services.dialogs.alert('Open an image before exporting an overlay.', ...
            'No image loaded');
        return;
    end
    [out, cancelled] = services.dialogs.outputFile( ...
        '*.png', 'Export overlay PNG', 'curvature_overlay.png');
    if cancelled
        state = services.workflow.log(state, "Overlay PNG export cancelled.");
        return;
    end
    model = previewModel(state);
    curvature.resultFiles.writeOverlayPng(model, out);
    [manifestPath, ~] = writeManifest(state, services, out, ...
        "curvatureOverlay", "image/png", "curvature_overlay.labkit.json");
    state.project.results.lastOverlayExport = struct( ...
        "pngPath", string(out), "manifestPath", string(manifestPath));
    state = services.workflow.log(state, "Exported overlay PNG: " + string(out));
end

function path = visibleCurve(state)
    points = state.project.annotations.curvePoints;
    path = points;
    if size(points, 1) >= 2 && ~isempty(state.session.cache.image)
        path = labkit.ui.interaction.anchorPath( ...
            points, size(state.session.cache.image), ...
            "Style", "Curve", "Closed", false);
    end
end

function model = previewModel(state)
    model = struct( ...
        "imageData", state.session.cache.image, ...
        "points", state.project.annotations.curvePoints, ...
        "curve", visibleCurve(state), ...
        "fit", state.project.results.fit, ...
        "showDensePoints", state.project.parameters.showDensePoints, ...
        "scaleBar", state.session.view.scaleBar);
end

function [manifestPath, report] = writeManifest( ...
        state, services, outputPath, id, mediaType, manifestName)
    [folder, name, extension] = fileparts(outputPath);
    output = services.results.output(id, "primary", ...
        string(name) + string(extension), mediaType);
    summary = struct( ...
        "fitOk", state.project.results.fit.ok, ...
        "lengthOk", state.project.results.length.ok, ...
        "pointCount", size(state.project.annotations.curvePoints, 1));
    spec = struct( ...
        "Outputs", output, "Inputs", state.project.inputs.sources, ...
        "Parameters", state.project.parameters, "Summary", summary, ...
        "ManifestName", manifestName);
    [manifestPath, report] = services.results.writeManifest(folder, spec);
end

function state = clearMeasurements(state)
    state.project.results.fit = curvature.appState.emptyFitResult();
    state.project.results.length = curvature.appState.emptyLengthResult();
    state.project.results.lastCsvExport = [];
    state.project.results.lastOverlayExport = [];
    state.session.cache.fitFingerprint = "";
    state.session.cache.lengthFingerprint = "";
end

function points = normalizePoints(value)
    if isempty(value)
        points = zeros(0, 2);
        return;
    end
    points = double(value);
    if size(points, 2) ~= 2 || any(~isfinite(points), 'all')
        points = zeros(0, 2);
    end
end

function value = positiveOrNaN(value)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value) || value <= 0
        value = NaN;
    end
end

function value = nonnegativeScalar(value, fallback)
    value = double(value);
    if isempty(value) || ~isscalar(value) || ~isfinite(value) || value < 0
        value = fallback;
    end
end
