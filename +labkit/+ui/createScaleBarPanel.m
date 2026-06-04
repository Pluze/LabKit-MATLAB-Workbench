function ui = createScaleBarPanel(parent, row, opts)
%CREATESCALEBARPANEL Create reusable scale-bar calibration controls.
%
% Usage:
%   ui = labkit.ui.createScaleBarPanel(parentGrid, 2, opts);
%   ui.setReferencePixels(125);
%   [pxPerUnit, unitName] = ui.pixelsPerUnit();
%   spec = ui.scaleBarSpec(size(imageData));
%
% Inputs:
%   parent - uigridlayout parent that will receive the scale-bar panel.
%   row - logical parent row for the panel.
%   opts - optional struct.
%
% Options:
%   title - panel title, default 'Scale Bar'.
%   units - cellstr/string array of unit labels, default {'um','mm','nm','cm'}.
%   positions - cellstr/string array of display positions, default common corners/centers.
%   colors - cellstr/string array of color names, default {'Black','White'}.
%            Black and White are the supported drawing colors.
%   defaultUnit - default unit label, default first unit.
%   defaultReferenceLength - positive reference length value, default 100.
%   defaultScaleBarLength - positive display scale-bar length, default 100.
%   defaultPosition - default position label, default 'Bottom right'.
%   defaultColor - default color label, default 'Black'.
%   onMeasureReference - callback for the reference-pixel edit button.
%   onCalibrationChanged - callback after reference pixels/length/unit changes.
%   onScaleBarChanged - callback after display length/position/color changes.
%   onPlaceScaleBar - callback for the place scale-bar button.
%
% Output:
%   ui - struct containing panel/grid handles, controls, and methods:
%        setReferencePixels(px), clearReferencePixels(), referencePixels(),
%        referenceLength(), scaleUnit(), scaleBarLength(), pixelsPerUnit(),
%        scaleBarSpec(imageSize), updateReadout(), setEnabled(state).
%
%   scaleBarSpec(imageSize) returns a struct with fields line, label, color,
%   labelPosition, verticalAlignment, pixelsPerUnit, unit, barLength,
%   position, and colorName. Apps own drawing the returned spec onto axes.
%
%   setEnabled(state) accepts hasImage, referenceEditActive, blockInputs, and
%   blockPlacement logical fields; omitted fields use interactive defaults.

    if nargin < 3
        opts = struct();
    end

    units = cellstr(string(optionValue(opts, 'units', {'um', 'mm', 'nm', 'cm'})));
    positions = cellstr(string(optionValue(opts, 'positions', { ...
        'Bottom center', 'Bottom left', 'Bottom right', ...
        'Top center', 'Top left', 'Top right'})));
    colors = cellstr(string(optionValue(opts, 'colors', {'Black', 'White'})));

    defaultUnit = char(string(optionValue(opts, 'defaultUnit', units{1})));
    defaultPosition = char(string(optionValue(opts, 'defaultPosition', 'Bottom right')));
    defaultColor = char(string(optionValue(opts, 'defaultColor', colors{1})));
    defaultReferenceLength = optionValue(opts, 'defaultReferenceLength', 100);
    defaultScaleBarLength = optionValue(opts, 'defaultScaleBarLength', 100);

    panelTitle = char(string(optionValue(opts, 'title', 'Scale Bar')));
    panelUi = labkit.ui.createPanelGrid(parent, panelTitle, row, [10 2], ...
        struct('rowHeight', {{'fit', 'fit', 'fit', 'fit', 'fit', ...
        'fit', 'fit', 'fit', 'fit', 'fit'}}, ...
        'columnWidth', {{145, '1x'}}));
    grid = panelUi.grid;

    btnMeasureReference = uibutton(grid, ...
        'Text', 'Measure reference pixels', ...
        'ButtonPushedFcn', optionValue(opts, 'onMeasureReference', []));
    btnMeasureReference.Layout.Row = 1;
    btnMeasureReference.Layout.Column = [1 2];

    [lblReferencePx, edtReferencePx] = labkit.ui.createLabeledSpinner(grid, ...
        'Reference pixels:', 'Value', 0, 'Limits', [0 Inf], 'Step', 1, ...
        'ValueChangedFcn', @onCalibrationChanged);
    lblReferencePx.Layout.Row = 2;
    lblReferencePx.Layout.Column = 1;
    edtReferencePx.Layout.Row = 2;
    edtReferencePx.Layout.Column = 2;

    [lblReferenceLen, edtReferenceLen] = labkit.ui.createLabeledSpinner(grid, ...
        'Reference length:', 'Value', defaultReferenceLength, ...
        'Limits', [0 Inf], 'Step', 10, ...
        'ValueChangedFcn', @onCalibrationChanged);
    lblReferenceLen.Layout.Row = 3;
    lblReferenceLen.Layout.Column = 1;
    edtReferenceLen.Layout.Row = 3;
    edtReferenceLen.Layout.Column = 2;

    [lblUnit, ddUnit] = labkit.ui.createLabeledDropdown(grid, ...
        'Scale unit:', 'Items', units, 'Value', defaultChoice(defaultUnit, units), ...
        'ValueChangedFcn', @onCalibrationChanged);
    lblUnit.Layout.Row = 4;
    lblUnit.Layout.Column = 1;
    ddUnit.Layout.Row = 4;
    ddUnit.Layout.Column = 2;

    [lblBarLen, edtBarLen] = labkit.ui.createLabeledSpinner(grid, ...
        'Scale bar length:', 'Value', defaultScaleBarLength, ...
        'Limits', [0 Inf], 'Step', 10, ...
        'ValueChangedFcn', @onScaleBarChanged);
    lblBarLen.Layout.Row = 5;
    lblBarLen.Layout.Column = 1;
    edtBarLen.Layout.Row = 5;
    edtBarLen.Layout.Column = 2;

    [lblPosition, ddPosition] = labkit.ui.createLabeledDropdown(grid, ...
        'Scale position:', 'Items', positions, ...
        'Value', defaultChoice(defaultPosition, positions), ...
        'ValueChangedFcn', @onScaleBarChanged);
    lblPosition.Layout.Row = 6;
    lblPosition.Layout.Column = 1;
    ddPosition.Layout.Row = 6;
    ddPosition.Layout.Column = 2;

    [lblColor, ddColor] = labkit.ui.createLabeledDropdown(grid, ...
        'Scale color:', 'Items', colors, ...
        'Value', defaultChoice(defaultColor, colors), ...
        'ValueChangedFcn', @onScaleBarChanged);
    lblColor.Layout.Row = 7;
    lblColor.Layout.Column = 1;
    ddColor.Layout.Row = 7;
    ddColor.Layout.Column = 2;

    btnPlaceScaleBar = uibutton(grid, ...
        'Text', 'Place scale bar', ...
        'ButtonPushedFcn', optionValue(opts, 'onPlaceScaleBar', []));
    btnPlaceScaleBar.Layout.Row = 8;
    btnPlaceScaleBar.Layout.Column = [1 2];

    [txtReferencePx, lblReferencePxReadout] = labkit.ui.createReadOnlyInfoRow( ...
        grid, 9, 'Reference px:');
    [txtPxPerUnit, lblPxPerUnit] = labkit.ui.createReadOnlyInfoRow( ...
        grid, 10, 'Pixels/unit:');
    lblReferencePxReadout.HorizontalAlignment = 'right';
    lblPxPerUnit.HorizontalAlignment = 'right';

    ui = panelUi;
    ui.controls = struct( ...
        'measureReferenceButton', btnMeasureReference, ...
        'referencePixelsSpinner', edtReferencePx, ...
        'referenceLengthSpinner', edtReferenceLen, ...
        'unitDropdown', ddUnit, ...
        'barLengthSpinner', edtBarLen, ...
        'positionDropdown', ddPosition, ...
        'colorDropdown', ddColor, ...
        'placeButton', btnPlaceScaleBar, ...
        'referencePixelsReadout', txtReferencePx, ...
        'pixelsPerUnitReadout', txtPxPerUnit);
    ui.setReferencePixels = @setReferencePixels;
    ui.clearReferencePixels = @clearReferencePixels;
    ui.referencePixels = @referencePixels;
    ui.referenceLength = @referenceLength;
    ui.scaleUnit = @scaleUnit;
    ui.scaleBarLength = @scaleBarLength;
    ui.pixelsPerUnit = @pixelsPerUnit;
    ui.scaleBarSpec = @scaleBarSpec;
    ui.updateReadout = @updateReadout;
    ui.setEnabled = @setEnabled;

    updateReadout();

    function onCalibrationChanged(src, evt)
        updateReadout();
        callback = optionValue(opts, 'onCalibrationChanged', []);
        if ~isempty(callback)
            callback(src, evt);
        end
    end

    function onScaleBarChanged(src, evt)
        updateReadout();
        callback = optionValue(opts, 'onScaleBarChanged', []);
        if ~isempty(callback)
            callback(src, evt);
        end
    end

    function setReferencePixels(px)
        edtReferencePx.Value = max(0, px);
        updateReadout();
    end

    function clearReferencePixels()
        edtReferencePx.Value = 0;
        updateReadout();
    end

    function px = referencePixels()
        px = positiveOrNaN(edtReferencePx.Value);
    end

    function value = referenceLength()
        value = edtReferenceLen.Value;
        if isempty(value) || ~isfinite(value) || value < 0
            value = 0;
        end
    end

    function unitName = scaleUnit()
        unitName = char(string(ddUnit.Value));
    end

    function value = scaleBarLength()
        value = edtBarLen.Value;
        if isempty(value) || ~isfinite(value) || value < 0
            value = 0;
        end
    end

    function [pxPerUnit, unitName] = pixelsPerUnit()
        unitName = scaleUnit();
        px = referencePixels();
        len = referenceLength();
        if isfinite(px) && px > 0 && len > 0
            pxPerUnit = px / len;
        else
            pxPerUnit = 0;
        end
    end

    function spec = scaleBarSpec(imageSize)
        [pxPerUnit, unitName] = pixelsPerUnit();
        barLen = scaleBarLength();
        if pxPerUnit <= 0 || barLen <= 0
            error('labkit_ui:createScaleBarPanel:InvalidScaleBar', ...
                'A positive calibration and scale-bar length are required.');
        end

        line = defaultScaleBarLine(imageSize, barLen * pxPerUnit, ddPosition.Value);
        [labelY, verticalAlignment] = scaleBarLabelPosition(line, ddPosition.Value);
        spec = struct( ...
            'line', line, ...
            'label', sprintf('%.6g %s', barLen, unitName), ...
            'color', scaleBarColor(ddColor.Value), ...
            'labelPosition', [mean(line(:, 1)), labelY], ...
            'verticalAlignment', verticalAlignment, ...
            'pixelsPerUnit', pxPerUnit, ...
            'unit', unitName, ...
            'barLength', barLen, ...
            'position', char(string(ddPosition.Value)), ...
            'colorName', char(string(ddColor.Value)));
    end

    function updateReadout()
        px = referencePixels();
        if isfinite(px)
            txtReferencePx.Value = sprintf('%.6g', px);
        else
            txtReferencePx.Value = '-';
        end

        [pxPerUnit, unitName] = pixelsPerUnit();
        if pxPerUnit > 0
            txtPxPerUnit.Value = sprintf('%.6g px/%s', pxPerUnit, unitName);
        else
            txtPxPerUnit.Value = '-';
        end
    end

    function setEnabled(state)
        if nargin < 1
            state = struct();
        end
        hasImage = optionValue(state, 'hasImage', true);
        referenceEditActive = optionValue(state, 'referenceEditActive', false);
        blockInputs = optionValue(state, 'blockInputs', false);
        blockPlacement = optionValue(state, 'blockPlacement', false);
        [pxPerUnit, ~] = pixelsPerUnit();

        btnMeasureReference.Enable = ternary(hasImage, 'on', 'off');
        btnMeasureReference.Text = ternary(referenceEditActive, ...
            'Finish reference edit', 'Measure reference pixels');
        edtReferencePx.Enable = ternary(hasImage && ~blockInputs && ~referenceEditActive, 'on', 'off');
        edtReferenceLen.Enable = ternary(hasImage && ~blockInputs, 'on', 'off');
        ddUnit.Enable = ternary(hasImage && ~blockInputs, 'on', 'off');
        edtBarLen.Enable = ternary(hasImage && ~blockInputs, 'on', 'off');
        ddPosition.Enable = ternary(hasImage && ~blockInputs, 'on', 'off');
        ddColor.Enable = ternary(hasImage && ~blockInputs, 'on', 'off');
        btnPlaceScaleBar.Enable = ternary(hasImage && pxPerUnit > 0 && ~blockPlacement, 'on', 'off');
    end
end

function line = defaultScaleBarLine(imageSize, scaleBarPx, position)
    validateattributes(scaleBarPx, {'numeric'}, {'scalar', 'finite', 'positive'});
    widthPx = imageSize(2);
    heightPx = imageSize(1);
    margin = max(5, min(widthPx, heightPx) * 0.08);
    usableWidth = widthPx - 2 * margin;
    if scaleBarPx > usableWidth
        error('labkit_ui:createScaleBarPanel:ScaleBarTooLong', ...
            'Scale bar is %.6g px, but the image only has %.6g px available horizontally.', ...
            scaleBarPx, usableWidth);
    end

    position = string(position);
    if contains(position, "left", 'IgnoreCase', true)
        x1 = margin + 0.5;
    elseif contains(position, "right", 'IgnoreCase', true)
        x1 = widthPx - margin - scaleBarPx + 0.5;
    else
        x1 = (widthPx - scaleBarPx) / 2 + 0.5;
    end
    x2 = x1 + scaleBarPx;

    if contains(position, "top", 'IgnoreCase', true)
        y = margin + 0.5;
    else
        y = heightPx - margin + 0.5;
    end
    y = max(1, min(heightPx, y));
    line = [x1 y; x2 y];
end

function [labelY, verticalAlignment] = scaleBarLabelPosition(line, position)
    lineY = mean(line(:, 2));
    if contains(string(position), "top", 'IgnoreCase', true)
        labelY = lineY + 12;
        verticalAlignment = 'top';
    else
        labelY = lineY - 12;
        verticalAlignment = 'bottom';
    end
end

function color = scaleBarColor(colorName)
    if strcmpi(char(string(colorName)), 'White')
        color = [1 1 1];
    else
        color = [0 0 0];
    end
end

function choice = defaultChoice(value, choices)
    choice = choices{1};
    idx = find(strcmp(choices, value), 1);
    if ~isempty(idx)
        choice = choices{idx};
    end
end

function value = positiveOrNaN(value)
    if isempty(value) || ~isfinite(value) || value <= 0
        value = NaN;
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

function value = ternary(condition, trueValue, falseValue)
    if condition
        value = trueValue;
    else
        value = falseValue;
    end
end
