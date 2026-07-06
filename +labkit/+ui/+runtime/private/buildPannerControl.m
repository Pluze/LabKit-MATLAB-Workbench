% Private UI runtime helper. Expected caller: buildControl panner branch.
% Inputs are one panner spec, parent grid, and target row. Output is the
% semantic panner adapter. Side effects: creates spinner/slider controls and
% wires debounced semantic callbacks.
function adapter = buildPannerControl(pannerSpec, parentGrid, row)
    props = pannerSpec.props;
    labelText = optionValue(props, 'label', pannerSpec.id);
    enabled = optionValue(props, 'enabled', true);

    label = uilabel(parentGrid, 'Text', labelText, ...
        'HorizontalAlignment', 'right');
    applyTextFit(label);
    label.Layout.Row = row;
    label.Layout.Column = 1;

    hasSlider = pannerHasFiniteSlider(props);
    if hasSlider
        grid = uigridlayout(parentGrid, [1 2]);
        grid.ColumnWidth = {76, '1x'};
    else
        grid = uigridlayout(parentGrid, [1 1]);
        grid.ColumnWidth = {'1x'};
    end
    grid.Padding = [0 0 0 0];
    grid.ColumnSpacing = 6;
    grid.Layout.Row = row;
    grid.Layout.Column = 2;

    valueSpinner = uispinner(grid, 'Enable', onOff(enabled));
    valueSpinner.Layout.Row = 1;
    valueSpinner.Layout.Column = 1;
    applyCommonValueProps(valueSpinner, props);
    valueSpinner.Value = clampNumericValue(valueSpinner.Value, valueSpinner.Limits);
    applyPannerSpinnerStep(valueSpinner, props);

    slider = [];
    if hasSlider
        slider = uislider(grid, 'Enable', onOff(enabled));
        slider.Layout.Row = 1;
        slider.Layout.Column = 2;
        applyCommonValueProps(slider, props);
        applySliderTicks(slider, props);
        slider.Value = clampNumericValue(slider.Value, slider.Limits);
        syncPannerValue(slider, valueSpinner, slider.Value);
    end

    adapter = basePannerAdapter(pannerSpec);
    adapter.label = label;
    adapter.grid = grid;
    adapter.valueSpinner = valueSpinner;
    adapter.slider = slider;
    adapter.handle = valueSpinner;
    adapter.valueHandle = valueSpinner;
    adapter.getValue = @() valueSpinner.Value;
    adapter.setValue = @(value) setPannerValue(slider, valueSpinner, value);

    appCallback = optionValue(props, 'onChange', []);
    if hasSlider
        slider.ValueChangedFcn = semanticPannerSliderCallback(pannerSpec.id, appCallback);
        if isprop(slider, 'ValueChangingFcn')
            slider.ValueChangingFcn = semanticPannerSliderChangingCallback( ...
                pannerSpec.id, appCallback);
        end
        setOriginalCallbackName(slider, appCallback);
    end
    valueSpinner.ValueChangedFcn = semanticPannerSpinnerCallback( ...
        pannerSpec.id, appCallback);
    setOriginalCallbackName(valueSpinner, appCallback);
end

function adapter = basePannerAdapter(spec)
    adapter = struct();
    adapter.id = spec.id;
    adapter.kind = 'panner';
    adapter.layout = spec;
    adapter.props = spec.props;
end

function tf = pannerHasFiniteSlider(props)
    tf = isfield(props, 'limits') && numel(props.limits) == 2 && ...
        all(isfinite(double(props.limits)));
end

function applySliderTicks(control, props)
    if isempty(control) || ~contains(class(control), 'Slider') || ...
            ~isfield(props, 'showTicks') || logical(props.showTicks)
        return;
    end
    if isprop(control, 'MajorTicks')
        control.MajorTicks = [];
    end
    if isprop(control, 'MinorTicks')
        control.MinorTicks = [];
    end
end

function setPannerValue(slider, valueSpinner, value)
    value = clampNumericValue(value, valueSpinner.Limits);
    sliderValueMatches = isempty(slider) || isequaln(slider.Value, value);
    if sliderValueMatches && isequaln(valueSpinner.Value, value)
        return;
    end
    sliderCallback = [];
    if ~isempty(slider)
        sliderCallback = slider.ValueChangedFcn;
    end
    spinnerCallback = valueSpinner.ValueChangedFcn;
    cleanupObj = onCleanup(@() restorePannerCallbacks( ...
        slider, sliderCallback, valueSpinner, spinnerCallback));
    if ~isempty(slider)
        slider.ValueChangedFcn = [];
    end
    valueSpinner.ValueChangedFcn = [];
    syncPannerValue(slider, valueSpinner, value);
    clear cleanupObj;
end

function syncPannerValue(slider, valueSpinner, value)
    value = clampNumericValue(value, valueSpinner.Limits);
    if ~isempty(slider)
        slider.Value = clampNumericValue(value, slider.Limits);
    end
    valueSpinner.Value = value;
end

function applyPannerSpinnerStep(valueSpinner, props)
    if isfield(props, 'step')
        return;
    end
    if ~all(isfinite(double(valueSpinner.Limits)))
        return;
    end
    valueSpinner.Step = pannerStepAmount(props, valueSpinner.Limits);
end

function restorePannerCallbacks(slider, sliderCallback, valueSpinner, spinnerCallback)
    restoreValueChangedCallback(slider, sliderCallback);
    restoreValueChangedCallback(valueSpinner, spinnerCallback);
end

function callback = semanticPannerSliderCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        control.setValue(source.Value);
        if isempty(appCallback)
            return;
        end
        event = semanticEvent(control, source, rawEvent, 'user');
        event.value = control.getValue();
        event.action = 'slide';
        runSemanticAppCallback(ui, control, event, appCallback, id);
    end
end

function callback = semanticPannerSliderChangingCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        nextValue = rawEventValue(rawEvent, 'Value', source.Value);
        control.setValue(nextValue);
        if isempty(appCallback)
            return;
        end
        event = semanticEvent(control, source, rawEvent, 'user');
        event.value = control.getValue();
        event.action = 'slide';
        runSemanticAppCallback(ui, control, event, appCallback, id);
    end
end

function callback = semanticPannerSpinnerCallback(id, appCallback)
    callback = @wrapped;

    function wrapped(source, rawEvent)
        ui = currentUiRegistry(source);
        if isFigureBusy(ui.figure)
            return;
        end
        control = ui.controls.(id);
        previousValue = rawEventValue(rawEvent, 'PreviousValue', []);
        control.setValue(source.Value);
        if isempty(appCallback) || isequaln(previousValue, control.getValue())
            return;
        end
        event = semanticEvent(control, source, rawEvent, 'user');
        event.value = control.getValue();
        event.previousValue = previousValue;
        event.action = 'edit';
        runSemanticAppCallback(ui, control, event, appCallback, id);
    end
end

function step = pannerStepAmount(props, limits)
    limits = double(limits);
    if ~all(isfinite(limits))
        step = 1;
        return;
    end
    span = max(eps, diff(limits));
    step = optionValue(props, 'step', NaN);
    if ~isfinite(step) || step <= 0
        fraction = optionValue(props, 'stepFraction', 0.002);
        step = span .* max(eps, double(fraction));
    end
    if isfield(props, 'minStep')
        step = max(step, double(props.minStep));
    end
    if isfield(props, 'maxStep')
        step = min(step, double(props.maxStep));
    end
end

function value = clampNumericValue(value, limits)
    value = double(value);
    if ~isfinite(value)
        value = limits(1);
    end
    value = min(limits(2), max(limits(1), value));
end

function restoreValueChangedCallback(handle, callback)
    if ~isempty(handle) && isvalid(handle)
        handle.ValueChangedFcn = callback;
    end
end

function ui = currentUiRegistry(source)
    fig = ancestor(source, 'figure');
    ui = getappdata(fig, 'labkitUiRegistry');
end

function tf = isFigureBusy(fig)
    tf = false;
    try
        tf = isappdata(fig, 'labkitUiBusyDepth') && ...
            getappdata(fig, 'labkitUiBusyDepth') > 0;
    catch
        tf = false;
    end
end

function value = rawEventValue(rawEvent, propertyName, defaultValue)
    value = defaultValue;
    if nargin < 3
        defaultValue = [];
    end
    if isstruct(rawEvent) && isfield(rawEvent, propertyName)
        value = rawEvent.(propertyName);
    elseif isobject(rawEvent) && isprop(rawEvent, propertyName)
        value = rawEvent.(propertyName);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end

function text = onOff(value)
    if islogical(value) && isscalar(value)
        if value
            text = 'on';
        else
            text = 'off';
        end
    else
        text = char(string(value));
    end
end
