function tool = scaleBar(parent, row, runtime, opts)
%SCALEBAR Create a reusable image scale-bar interaction tool.
%
% Usage:
%   runtime = labkit.ui.tool.createRuntime(imageAxes);
%   tool = labkit.ui.tool.scaleBar(parentGrid, 3, runtime, opts);
%   tool.setImageSize(size(imageData));
%   tool.setBackground(hImage);
%   cal = tool.calibration();
%   tool.setCalibration(cal);
%   tool.renderOverlay();
%
% Inputs:
%   parent - uigridlayout parent that will receive the scale-bar panel.
%   row - logical parent row for the panel.
%   runtime - interaction runtime returned by labkit.ui.tool.createRuntime.
%   opts - optional struct.
%
% Options:
%   title, units, positions, colors, defaultUnit, defaultReferenceLength,
%   defaultScaleBarLength, defaultPosition, and defaultColor are forwarded to
%   the private scale-bar panel. Defaults are the standard scale-bar UI defaults.
%   imageSize - optional initial image size.
%   onBeforeReferenceEdit - callback before reference endpoint editing starts.
%   onReferenceEditChanged - callback after reference edit mode or points change.
%   onCalibrationChanged - callback after calibration fields or reference line change.
%   onScaleBarChanged - callback after display length, position, color, or placed
%                       scale-bar geometry changes.
%   onScaleBarPlaced - callback after the place action stores a scale bar.
%   onError - callback(title, message) for user-facing tool errors.
%   onTrace - callback(message), default []. Receives verbose debug trace
%             messages for scale-bar interaction state changes.
%
% Output:
%   tool - struct exposing the underlying panel handles plus methods:
%          setImageSize(imageSize), setBackground(handle), resetForNewImage(),
%          calibration(), setCalibration(cal), setReferencePixels(px),
%          clearReferencePixels(), finishReferenceEdit(), isReferenceEditActive(), refresh(),
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
        'Third input must be a labkit.ui.tool.createRuntime result.');

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
    state.onTrace = optionValue(opts, 'onTrace', []);

    panelOpts = opts;
    panelOpts.onMeasureReference = @onMeasureReferenceButton;
    panelOpts.onCalibrationChanged = @onPanelCalibrationChanged;
    panelOpts.onScaleBarChanged = @onPanelScaleBarChanged;
    panelOpts.onPlaceScaleBar = @onPlaceScaleBarButton;
    scalePanel = scaleBarPanel(parent, row, panelOpts);

    tool = scalePanel;
    tool.setImageSize = @setImageSize;
    tool.setBackground = @setBackground;
    tool.resetForNewImage = @resetForNewImage;
    tool.calibration = @calibration;
    tool.setCalibration = @setCalibration;
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
    trace('created scale-bar tool');

    function setImageSize(imageSize)
        trace(sprintf('setImageSize %s', sizeText(imageSize)));
        state.imageSize = imageSize;
        if ~isempty(state.referenceEditor)
            state.referenceEditor.setImageSize(imageSize);
        end
        refreshEnabled();
    end

    function setBackground(h)
        trace(sprintf('setBackground valid=%d', isValidHandle(h)));
        state.background = h;
        if ~isempty(state.referenceEditor)
            state.referenceEditor.setBackground(h);
        end
    end

    function resetForNewImage(imageSize)
        trace('resetForNewImage begin');
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
        trace('resetForNewImage end');
    end

    function cal = calibration()
        cal = labkit.ui.tool.scaleBarCalibration(scalePanel.referencePixels(), ...
            scalePanel.referenceLength(), scalePanel.scaleUnit(), ...
            struct('units', {scalePanel.controls.unitDropdown.Items}, ...
            'defaultUnit', scalePanel.controls.unitDropdown.Items{1}, ...
            'referenceLine', state.referenceLine));
    end

    function setCalibration(cal)
        trace('setCalibration');
        state.referenceLine = referenceLineFromCalibration(cal);
        state.scaleBar = [];
        scalePanel.setCalibration(cal);
        if state.referenceEditActive && ~isempty(state.referenceEditor)
            state.suppressReferenceEditorCallback = true;
            cleanupObj = onCleanup(@() clearReferenceEditorSuppression());
            state.referenceEditor.setPoints(state.referenceLine);
        end
        refreshEnabled();
    end

    function setReferencePixels(px)
        trace(sprintf('setReferencePixels %.6g', px));
        state.referenceLine = zeros(0, 2);
        state.scaleBar = [];
        scalePanel.setReferencePixels(px);
        refreshEnabled();
    end

    function clearReferencePixels()
        trace('clearReferencePixels');
        state.referenceLine = zeros(0, 2);
        state.scaleBar = [];
        scalePanel.clearReferencePixels();
        refreshEnabled();
    end

    function finishReferenceEdit(notify)
        if nargin < 1
            notify = true;
        end
        trace(sprintf('finishReferenceEdit begin active=%d notify=%d', ...
            state.referenceEditActive, notify));
        if ~state.referenceEditActive
            trace('finishReferenceEdit skipped inactive');
            return;
        end
        state.referenceEditActive = false;
        if ~isempty(state.referenceEditor)
            trace('finishReferenceEdit deactivate reference editor');
            state.referenceEditor.setActive(false);
        end
        refreshEnabled();
        if notify
            invokeCallback('onReferenceEditChanged', scalePanel.panel, 'finish');
        end
        trace('finishReferenceEdit end');
    end

    function tf = isReferenceEditActive()
        tf = state.referenceEditActive;
    end

    function refresh()
        trace(sprintf('refresh active=%d', state.referenceEditActive));
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
        trace('clearScaleBar');
        state.scaleBar = [];
    end

    function tf = hasScaleBar()
        tf = ~isempty(state.scaleBar);
    end

    function setEnabled(enabledState)
        if nargin < 1
            enabledState = struct();
        end
        trace(sprintf('setEnabled hasImage=%s referenceEditActive=%d', ...
            fieldText(enabledState, 'hasImage'), state.referenceEditActive));
        state.enabledState = enabledState;
        refreshEnabled();
    end

    function deleteTool()
        trace('deleteTool');
        if ~isempty(state.referenceEditor)
            state.referenceEditor.delete();
        end
    end

    function onMeasureReferenceButton(~, ~)
        trace(sprintf('Measure reference button pressed active=%d imageSize=%s', ...
            state.referenceEditActive, sizeText(state.imageSize)));
        if isempty(state.imageSize)
            reportError('No image loaded', ...
                'Open an image before measuring reference pixels.');
            return;
        end

        if state.referenceEditActive
            trace('Measure reference button finishing active edit');
            finishReferenceEdit(true);
            return;
        end

        trace('Measure reference button starting edit');
        invokeCallback('onBeforeReferenceEdit', scalePanel.panel, []);
        state.referenceEditActive = true;
        ensureReferenceEditor();
        activateReferenceEditor();
        state.scaleBar = [];
        refreshEnabled();
        invokeCallback('onReferenceEditChanged', scalePanel.panel, 'start');
        trace('Measure reference button start complete');
    end

    function onPanelCalibrationChanged(src, evt)
        trace('panel calibration changed');
        state.scaleBar = [];
        invokeCallback('onCalibrationChanged', src, evt);
    end

    function onPanelScaleBarChanged(src, evt)
        trace('panel scale-bar settings changed');
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
        trace(sprintf('Place scale bar button pressed imageSize=%s', sizeText(state.imageSize)));
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
            trace(sprintf('Place scale bar failed: %s %s', ME.identifier, ME.message));
            reportError('Could not place scale bar', ME.message);
            return;
        end
        finishReferenceEdit(false);
        invokeCallback('onScaleBarPlaced', scalePanel.panel, []);
        invokeCallback('onScaleBarChanged', scalePanel.panel, []);
        trace('Place scale bar complete');
    end

    function ensureReferenceEditor()
        trace('ensureReferenceEditor begin');
        refreshBackgroundFromAxes();
        if isempty(state.referenceEditor)
            trace('ensureReferenceEditor create editor');
            state.referenceEditor = labkit.ui.tool.anchorEditor(state.runtime, state.imageSize, ...
                struct('closed', false, ...
                'style', 'Straight lines', ...
                'maxPoints', 2, ...
                'onTrace', state.onTrace, ...
                'onChanged', @onReferenceEditorChanged));
        else
            trace('ensureReferenceEditor reuse editor');
            state.suppressReferenceEditorCallback = true;
            cleanupObj = onCleanup(@() clearReferenceEditorSuppression());
            state.referenceEditor.setImageSize(state.imageSize);
            state.referenceEditor.setStyle('Straight lines');
        end
        if ~isempty(state.background)
            state.referenceEditor.setBackground(state.background);
        end
        trace('ensureReferenceEditor end');
    end

    function refreshBackgroundFromAxes()
        if ~isempty(state.background) && isvalid(state.background)
            trace('refreshBackgroundFromAxes kept existing background');
            return;
        end
        if isempty(state.ax) || ~isvalid(state.ax)
            trace('refreshBackgroundFromAxes skipped invalid axes');
            return;
        end
        images = findobj(state.ax, 'Type', 'image');
        if ~isempty(images)
            state.background = images(1);
            trace(sprintf('refreshBackgroundFromAxes found %d image object(s)', numel(images)));
        else
            trace('refreshBackgroundFromAxes found no image object');
        end
    end

    function onReferenceEditorChanged(points, reason)
        trace(sprintf('reference editor changed reason=%s points=%d suppress=%d', ...
            char(string(reason)), size(points, 1), state.suppressReferenceEditorCallback));
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
        trace(sprintf('activateReferenceEditor begin storedPoints=%d', size(state.referenceLine, 1)));
        points = state.referenceLine;
        if isempty(points)
            points = zeros(0, 2);
        end

        state.suppressReferenceEditorCallback = true;
        cleanupObj = onCleanup(@() clearReferenceEditorSuppression());
        state.referenceEditor.setPoints(points);
        state.referenceEditor.setActive(true);
        trace('activateReferenceEditor end');
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
        trace(sprintf('refreshEnabled hasImage=%d referenceEditActive=%d blockInputs=%s blockPlacement=%s', ...
            enabledState.hasImage, enabledState.referenceEditActive, ...
            fieldText(enabledState, 'blockInputs'), fieldText(enabledState, 'blockPlacement')));
    end

    function invokeCallback(name, src, evt)
        trace(sprintf('invokeCallback %s', name));
        callback = optionValue(opts, name, []);
        if isempty(callback)
            trace(sprintf('invokeCallback %s skipped empty', name));
            return;
        end
        callback(src, evt);
        trace(sprintf('invokeCallback %s complete', name));
    end

    function reportError(titleText, message)
        trace(sprintf('reportError %s: %s', char(string(titleText)), char(string(message))));
        callback = optionValue(opts, 'onError', []);
        if isempty(callback)
            error('labkit_ui:createScaleBarTool:Error', '%s', message);
        end
        callback(titleText, message);
    end

    function trace(message)
        if isempty(state.onTrace)
            return;
        end
        state.onTrace(sprintf('scaleBarTool: %s', char(message)));
    end
end

function line = referenceLineFromCalibration(cal)
    line = zeros(0, 2);
    if ~isstruct(cal) || ~isfield(cal, 'referenceLine') || isempty(cal.referenceLine)
        return;
    end
    candidate = double(cal.referenceLine);
    if isequal(size(candidate), [2 2]) && all(isfinite(candidate(:)))
        line = candidate;
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

function txt = sizeText(value)
    if isempty(value)
        txt = '[]';
        return;
    end
    dims = size(value);
    if isvector(value) && numel(value) <= 4
        dims = value(:).';
    end
    txt = strjoin(cellstr(string(dims)), 'x');
end

function txt = fieldText(s, name)
    if isstruct(s) && isfield(s, name)
        value = s.(name);
        if islogical(value) || isnumeric(value)
            txt = char(string(value));
        else
            txt = char(string(value));
        end
    else
        txt = 'unset';
    end
end

function tf = isValidHandle(h)
    tf = ~isempty(h) && all(isvalid(h));
end
