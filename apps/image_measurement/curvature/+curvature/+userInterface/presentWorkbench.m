% Expected caller: Runtime V2. Input is canonical curvature state. Output is
% one deterministic control, preview, and managed-interaction presentation
% with no UI handles, file IO, or scientific side effects.
function view = presentWorkbench(state)
    project = state.project;
    session = state.session;
    points = project.annotations.curvePoints;
    fit = project.results.fit;
    lengthResult = project.results.length;
    hasImage = ~isempty(session.cache.image);
    curveEditing = session.workflow.editMode == "curve";
    referenceEditing = session.workflow.editMode == "reference";
    editing = curveEditing || referenceEditing;
    calibration = project.annotations.calibration;

    view = struct();
    view.controls.imageFile = fileSpec(session.cache.imagePath, hasImage);
    summary = curvature.userInterface.summaryViewData( ...
        session.cache.imagePath, points(:, 1), fit, lengthResult, ...
        curveEditing, referenceEditing);
    view.controls.pointCount = valueSpec(summary.pointCountText);
    view.controls.resultTable = tableSpec(summary.tableData);
    view.controls.detailsText = valueSpec(summary.details);
    view.controls.appLog = valueSpec(cellstr(session.workflow.logLines));
    view.controls.startCurveEdit = struct( ...
        "Enabled", hasImage && ~referenceEditing, ...
        "Text", ternary(curveEditing, "Finish curve edit", "Start curve edit"));
    view.controls.undoCurvePoint = enabledSpec(~isempty(points) && ~referenceEditing);
    view.controls.clearCurve = enabledSpec(~isempty(points) && ~referenceEditing);
    view.controls.densify = enabledSpec(~editing);
    view.controls.densePointCount = enabledSpec(~editing);
    view.controls.showDensePoints = enabledSpec(fit.ok && ~editing);
    view.controls.fitCurvature = enabledSpec(size(points, 1) >= 3 && ~editing);
    view.controls.measureCurveLength = enabledSpec(size(points, 1) >= 2 && ~editing);
    view.controls.exportCsv = enabledSpec((fit.ok || lengthResult.ok) && ~editing);
    view.controls.exportOverlay = enabledSpec(hasImage && ~editing);
    view = scalePresentation(view, state, hasImage, referenceEditing, curveEditing);

    curve = visibleCurve(points, session.cache.image);
    model = struct( ...
        "imageData", session.cache.image, ...
        "points", points, ...
        "curve", curve, ...
        "fit", fit, ...
        "showDensePoints", project.parameters.showDensePoints, ...
        "scaleBar", session.view.scaleBar);
    view.previews.imageAxes.Axes.image = struct( ...
        "Renderer", "curvaturePreview", "Model", model);
    if hasImage && curveEditing
        view.interactions.curve = struct( ...
            "Kind", "anchors", ...
            "Targets", "imageAxes", ...
            "Value", points, ...
            "Event", "curvePointsEdited", ...
            "ImageSize", size(session.cache.image), ...
            "ChangePolicy", "commit", ...
            "Options", struct("closed", false, "style", "Curve", ...
            "color", [0 0.45 0.95]));
    elseif hasImage && referenceEditing
        view.interactions.scaleReference = struct( ...
            "Kind", "scaleBarReference", ...
            "Targets", "imageAxes", ...
            "Value", calibration.referenceLine, ...
            "Event", "scaleReferenceEdited", ...
            "ImageSize", size(session.cache.image), ...
            "ChangePolicy", "commit", ...
            "Options", struct("color", [1 1 0]));
    end
end

function view = scalePresentation(view, state, hasImage, editing, curveEditing)
    calibration = state.project.annotations.calibration;
    referencePixels = calibration.referencePixels;
    referenceReadout = "-";
    if isfinite(referencePixels)
        referenceReadout = sprintf('%.6g', referencePixels);
    else
        referencePixels = 0;
    end
    pixelsReadout = "-";
    if calibration.pixelsPerUnit > 0
        pixelsReadout = sprintf('%.6g px/%s', ...
            calibration.pixelsPerUnit, calibration.unit);
    end
    view.controls.measureScaleReference = struct( ...
        "Enabled", hasImage && ~curveEditing, ...
        "Text", ternary(editing, ...
        "Finish reference edit", "Measure reference pixels"));
    view.controls.scaleReferencePixels = controlSpec( ...
        hasImage && ~editing && ~curveEditing, referencePixels);
    view.controls.scaleReferenceLength = controlSpec( ...
        hasImage && ~curveEditing, calibration.referenceLength);
    view.controls.scaleCalibrationUnit = controlSpec( ...
        hasImage && ~curveEditing, calibration.unit);
    view.controls.scaleBarLength = enabledSpec(hasImage && ~curveEditing);
    view.controls.scaleBarPosition = enabledSpec(hasImage && ~curveEditing);
    view.controls.scaleBarColor = enabledSpec(hasImage && ~curveEditing);
    view.controls.placeScaleBar = enabledSpec( ...
        hasImage && calibration.isCalibrated && ~editing && ~curveEditing);
    view.controls.scaleReferenceReadout = valueSpec(referenceReadout);
    view.controls.pixelsPerUnitReadout = valueSpec(pixelsReadout);
end

function curve = visibleCurve(points, imageData)
    curve = zeros(0, 2);
    if isempty(imageData) || size(points, 1) < 2
        return;
    end
    curve = labkit.ui.interaction.anchorPath(points, size(imageData), ...
        "Style", "Curve", "Closed", false);
end

function spec = fileSpec(pathValue, loaded)
    spec = struct("Files", string(pathValue), ...
        "Status", ternary(loaded, "Image loaded", "No image loaded"));
end

function spec = valueSpec(value)
    spec = struct();
    spec.Value = value;
end

function spec = tableSpec(value)
    spec = struct();
    spec.Data = value;
end

function spec = enabledSpec(value)
    spec = struct("Enabled", logical(value));
end

function spec = controlSpec(enabled, value)
    spec = struct("Enabled", logical(enabled), "Value", value);
end

function value = ternary(condition, trueValue, falseValue)
    if condition
        value = trueValue;
    else
        value = falseValue;
    end
end
