function tool = createScaleBarTool(parent, row, runtime, opts)
%CREATESCALEBARTOOL Create a reusable image scale-bar interaction tool.
%
% Usage:
%   runtime = labkit.ui.createImageAxesRuntime(imageAxes);
%   tool = labkit.ui.createScaleBarTool(parentGrid, 3, runtime, opts);
%   tool.setImageSize(size(imageData));
%   tool.setBackground(hImage);
%   cal = tool.calibration();
%   tool.renderOverlay();
%
% Inputs:
%   parent - uigridlayout parent that will receive the scale-bar panel.
%   row - logical parent row for the panel.
%   runtime - image axes runtime returned by labkit.ui.createImageAxesRuntime.
%   opts - optional struct.
%
% Options:
%   title, units, positions, colors, defaultUnit, defaultReferenceLength,
%   defaultScaleBarLength, defaultPosition, and defaultColor are forwarded to
%   createScaleBarPanel. Defaults are the standard scale-bar UI defaults.
%   imageSize - optional initial image size.
%   onBeforeReferenceEdit - callback before reference endpoint editing starts.
%   onReferenceEditChanged - callback after reference edit mode or points change.
%   onCalibrationChanged - callback after calibration fields or reference line change.
%   onScaleBarChanged - callback after display length, position, color, or placed
%                       scale-bar geometry changes.
%   onScaleBarPlaced - callback after the place action stores a scale bar.
%   onError - callback(title, message) for user-facing tool errors.
%
% Output:
%   tool - struct exposing the underlying panel handles plus methods:
%          setImageSize(imageSize), setBackground(handle), resetForNewImage(),
%          calibration(), setReferencePixels(px), clearReferencePixels(),
%          finishReferenceEdit(), isReferenceEditActive(), refresh(),
%          scaleBarSpec(), placedScaleBar(), renderOverlay(), clearScaleBar(),
%          hasScaleBar(), setEnabled(state), and delete().
%
% The tool owns generic reference-pixel editing, scale-bar state, calibration
% normalization, and overlay drawing. Apps still own scientific calculations,
% result summaries, alerts/log wording, and exports. When reference editing
% starts, the tool uses the current axes image as the editable background if
% the app has not already supplied one with setBackground().

    if nargin < 4
        opts = struct();
    end

    state = struct();
    assert(isstruct(runtime) && isfield(runtime, 'axes') && ...
        isa(runtime.axes, 'function_handle') && ...
        isfield(runtime, 'createSession') && ...
        isa(runtime.createSession, 'function_handle'), ...
        'Third input must be a labkit.ui.createImageAxesRuntime result.');

    state.runtime = runtime;
    state.ax = runtime.axes();
    state.imageSize = optionValue(opts, 'imageSize', []);
    state.background = [];
    state.referenceEditor = [];
    state.referenceLine = zeros(0, 2);
    state.referenceEditActive = false;
    state.scaleBar = [];
    state.enabledState = struct();
    state.suppressReferenceEditorCallback = false;

    panelOpts = opts;
    panelOpts.onMeasureReference = @onMeasureReferenceButton;
    panelOpts.onCalibrationChanged = @onPanelCalibrationChanged;
    panelOpts.onScaleBarChanged = @onPanelScaleBarChanged;
    panelOpts.onPlaceScaleBar = @onPlaceScaleBarButton;
    scalePanel = labkit.ui.createScaleBarPanel(parent, row, panelOpts);

    tool = scalePanel;
    tool.setImageSize = @setImageSize;
    tool.setBackground = @setBackground;
    tool.resetForNewImage = @resetForNewImage;
    tool.calibration = @calibration;
    tool.setReferencePixels = @setReferencePixels;
    tool.clearReferencePixels = @clearReferencePixels;
    tool.finishReferenceEdit = @finishReferenceEdit;
    tool.isReferenceEditActive = @isReferenceEditActive;
    tool.refresh = @refresh;
    tool.scaleBarSpec = @scaleBarSpec;
    tool.placedScaleBar = @placedScaleBar;
    tool.renderOverlay = @renderOverlay;
    tool.clearScaleBar = @clearScaleBar;
    tool.hasScaleBar = @hasScaleBar;
    tool.setEnabled = @setEnabled;
    tool.delete = @deleteTool;

    refreshEnabled();

    function setImageSize(imageSize)
        state.imageSize = imageSize;
        if ~isempty(state.referenceEditor)
            state.referenceEditor.setImageSize(imageSize);
        end
        refreshEnabled();
    end

    function setBackground(h)
        state.background = h;
        if ~isempty(state.referenceEditor)
            state.referenceEditor.setBackground(h);
        end
    end

    function resetForNewImage(imageSize)
        if nargin >= 1 && ~isempty(imageSize)
            setImageSize(imageSize);
        end
        state.referenceLine = zeros(0, 2);
        state.scaleBar = [];
        scalePanel.clearReferencePixels();
        state.referenceEditActive = false;
        if ~isempty(state.referenceEditor)
            state.referenceEditor.delete();
        end
        state.referenceEditor = [];
        refreshEnabled();
    end

    function cal = calibration()
        cal = labkit.ui.scaleBarCalibration(scalePanel.referencePixels(), ...
            scalePanel.referenceLength(), scalePanel.scaleUnit(), ...
            struct('units', {scalePanel.controls.unitDropdown.Items}, ...
            'defaultUnit', scalePanel.controls.unitDropdown.Items{1}, ...
            'referenceLine', state.referenceLine));
    end

    function setReferencePixels(px)
        state.referenceLine = zeros(0, 2);
        state.scaleBar = [];
        scalePanel.setReferencePixels(px);
        refreshEnabled();
    end

    function clearReferencePixels()
        state.referenceLine = zeros(0, 2);
        state.scaleBar = [];
        scalePanel.clearReferencePixels();
        refreshEnabled();
    end

    function finishReferenceEdit(notify)
        if nargin < 1
            notify = true;
        end
        if ~state.referenceEditActive
            return;
        end
        state.referenceEditActive = false;
        if ~isempty(state.referenceEditor)
            state.referenceEditor.setActive(false);
        end
        refreshEnabled();
        if notify
            invokeCallback('onReferenceEditChanged', scalePanel.panel, 'finish');
        end
    end

    function tf = isReferenceEditActive()
        tf = state.referenceEditActive;
    end

    function refresh()
        if ~state.referenceEditActive
            return;
        end
        ensureReferenceEditor();
        if ~isempty(state.background)
            state.referenceEditor.setBackground(state.background);
        end
        state.referenceEditor.refresh();
    end

    function spec = scaleBarSpec()
        spec = scalePanel.scaleBarSpec(state.imageSize);
    end

    function spec = placedScaleBar()
        spec = state.scaleBar;
    end

    function handles = renderOverlay(drawAxes)
        if nargin < 1 || isempty(drawAxes)
            drawAxes = state.ax;
        end
        handles = drawScaleBarOverlay(drawAxes, state.scaleBar);
    end

    function clearScaleBar()
        state.scaleBar = [];
    end

    function tf = hasScaleBar()
        tf = ~isempty(state.scaleBar);
    end

    function setEnabled(enabledState)
        if nargin < 1
            enabledState = struct();
        end
        state.enabledState = enabledState;
        refreshEnabled();
    end

    function deleteTool()
        if ~isempty(state.referenceEditor)
            state.referenceEditor.delete();
        end
    end

    function onMeasureReferenceButton(~, ~)
        if isempty(state.imageSize)
            reportError('No image loaded', ...
                'Open an image before measuring reference pixels.');
            return;
        end

        if state.referenceEditActive
            finishReferenceEdit(true);
            return;
        end

        invokeCallback('onBeforeReferenceEdit', scalePanel.panel, []);
        state.referenceEditActive = true;
        ensureReferenceEditor();
        activateReferenceEditor();
        state.scaleBar = [];
        refreshEnabled();
        invokeCallback('onReferenceEditChanged', scalePanel.panel, 'start');
    end

    function onPanelCalibrationChanged(src, evt)
        state.scaleBar = [];
        invokeCallback('onCalibrationChanged', src, evt);
    end

    function onPanelScaleBarChanged(src, evt)
        if ~isempty(state.scaleBar)
            try
                state.scaleBar = scaleBarSpec();
            catch
                state.scaleBar = [];
            end
        end
        invokeCallback('onScaleBarChanged', src, evt);
    end

    function onPlaceScaleBarButton(~, ~)
        if isempty(state.imageSize)
            reportError('No image loaded', ...
                'Open an image before placing a scale bar.');
            return;
        end
        cal = calibration();
        if ~cal.isCalibrated
            reportError('Calibration required', ...
                'Measure or enter reference pixels, then enter a positive real reference length and unit.');
            return;
        end

        try
            state.scaleBar = scaleBarSpec();
        catch ME
            reportError('Could not place scale bar', ME.message);
            return;
        end
        finishReferenceEdit(false);
        invokeCallback('onScaleBarPlaced', scalePanel.panel, []);
        invokeCallback('onScaleBarChanged', scalePanel.panel, []);
    end

    function ensureReferenceEditor()
        refreshBackgroundFromAxes();
        if isempty(state.referenceEditor)
            state.referenceEditor = labkit.ui.createAnchorCurveEditor(state.runtime, state.imageSize, ...
                struct('closed', false, ...
                'style', 'Straight lines', ...
                'maxPoints', 2, ...
                'onChanged', @onReferenceEditorChanged));
        else
            state.referenceEditor.setImageSize(state.imageSize);
            state.referenceEditor.setStyle('Straight lines');
        end
        if ~isempty(state.background)
            state.referenceEditor.setBackground(state.background);
        end
    end

    function refreshBackgroundFromAxes()
        if ~isempty(state.background) && isvalid(state.background)
            return;
        end
        if isempty(state.ax) || ~isvalid(state.ax)
            return;
        end
        images = findobj(state.ax, 'Type', 'image');
        if ~isempty(images)
            state.background = images(1);
        end
    end

    function onReferenceEditorChanged(points, reason)
        state.referenceLine = points;
        if state.suppressReferenceEditorCallback
            return;
        end
        if size(points, 1) == 2
            referencePx = hypot(points(2, 1) - points(1, 1), ...
                points(2, 2) - points(1, 2));
            scalePanel.setReferencePixels(referencePx);
        else
            scalePanel.clearReferencePixels();
        end
        state.scaleBar = [];
        refreshEnabled();
        invokeCallback('onCalibrationChanged', scalePanel.panel, reason);
        invokeCallback('onReferenceEditChanged', scalePanel.panel, reason);
    end

    function activateReferenceEditor()
        points = state.referenceLine;
        if isempty(points)
            points = zeros(0, 2);
        end

        state.suppressReferenceEditorCallback = true;
        cleanupObj = onCleanup(@() clearReferenceEditorSuppression()); %#ok<NASGU>
        state.referenceEditor.setPoints(points);
        state.referenceEditor.setActive(true);
    end

    function clearReferenceEditorSuppression()
        state.suppressReferenceEditorCallback = false;
    end

    function refreshEnabled()
        enabledState = state.enabledState;
        if ~isfield(enabledState, 'hasImage')
            enabledState.hasImage = ~isempty(state.imageSize);
        end
        enabledState.referenceEditActive = state.referenceEditActive;
        scalePanel.setEnabled(enabledState);
    end

    function invokeCallback(name, src, evt)
        callback = optionValue(opts, name, []);
        if isempty(callback)
            return;
        end
        callback(src, evt);
    end

    function reportError(titleText, message)
        callback = optionValue(opts, 'onError', []);
        if isempty(callback)
            error('labkit_ui:createScaleBarTool:Error', '%s', message);
        end
        callback(titleText, message);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
