% Private scale-bar/tool control helper. Expected caller: labkit.ui.tool
% private panels. Inputs are a parent grid, visible label text, and panner
% options. Outputs are label, spinner, slider, and host grid handles. Side
% effects are limited to creating linked UI controls under the parent.
function [lbl, spinner, slider, host] = createLabeledPanner(parent, labelText, varargin)
%CREATELABELEDPANNER Create a compact spinner with optional linked slider.
%
% Inputs:
%   parent - parent grid.
%   labelText - visible label.
%   varargin - name/value arguments. Value, Limits, Step,
%       ValueDisplayFormat, Enable, and ValueChangedFcn are forwarded to the
%       spinner. SliderLimits optionally enables a finite linked slider.
%
% Output:
%   lbl - uilabel handle.
%   spinner - uispinner handle.
%   slider - uislider handle or [] when no finite SliderLimits are supplied.
%   host - grid that owns the spinner/slider pair.

    opts = parseOptions(varargin);

    lbl = uilabel(parent, ...
        'Text', labelText, ...
        'HorizontalAlignment', 'right');

    sliderLimits = optionValue(opts, 'SliderLimits', []);
    hasSlider = isnumeric(sliderLimits) && numel(sliderLimits) == 2 && ...
        all(isfinite(sliderLimits)) && sliderLimits(2) > sliderLimits(1);
    if hasSlider
        host = uigridlayout(parent, [1 2]);
        host.ColumnWidth = {76, '1x'};
    else
        host = uigridlayout(parent, [1 1]);
        host.ColumnWidth = {'1x'};
    end
    host.Padding = [0 0 0 0];
    host.ColumnSpacing = 6;

    spinnerArgs = removeInternalOptions(opts, {'SliderLimits'});
    spinner = uispinner(host, spinnerArgs{:});
    spinner.Layout.Row = 1;
    spinner.Layout.Column = 1;

    slider = [];
    appCallback = getOption(opts, 'ValueChangedFcn', []);
    debounceDelay = max(0, double(getOption(opts, 'DebounceMs', 500)) / 1000);
    debounceTimer = [];
    latestSource = [];
    latestEvent = [];
    if hasSlider
        slider = uislider(host, 'Limits', double(sliderLimits), ...
            'Value', clampValue(spinner.Value, double(sliderLimits)));
        slider.Layout.Row = 1;
        slider.Layout.Column = 2;
        slider.MajorTicks = [];
        slider.MinorTicks = [];
        slider.ValueChangedFcn = @onSliderChanged;
        if isprop(slider, 'ValueChangingFcn')
            slider.ValueChangingFcn = @onSliderChanging;
        end
        syncSliderToSpinner();
    end
    spinner.ValueChangedFcn = @onSpinnerChanged;

    function onSpinnerChanged(src, evt)
        syncSliderToSpinner();
        invokeAppCallback(src, evt);
    end

    function onSliderChanged(src, evt)
        spinner.Value = src.Value;
        invokeAppCallback(spinner, evt);
    end

    function onSliderChanging(src, evt)
        nextValue = evt.Value;
        spinner.Value = nextValue;
    end

    function syncSliderToSpinner()
        if isempty(slider) || ~isvalid(slider)
            return;
        end
        slider.Value = clampValue(spinner.Value, slider.Limits);
    end

    function invokeAppCallback(src, evt)
        if isempty(appCallback)
            return;
        end
        latestSource = src;
        latestEvent = evt;
        clearDebounceTimer();
        if debounceDelay <= 0
            fireAppCallback();
            return;
        end
        debounceTimer = timer( ...
            'ExecutionMode', 'singleShot', ...
            'StartDelay', debounceDelay, ...
            'TimerFcn', @(timerObj, ~) fireDebouncedCallback(timerObj));
        start(debounceTimer);
    end

    function fireDebouncedCallback(timerObj)
        clearDebounceTimer(timerObj);
        fireAppCallback();
    end

    function fireAppCallback()
        if isempty(latestSource) || ~isvalid(latestSource)
            return;
        end
        appCallback(latestSource, latestEvent);
    end

    function clearDebounceTimer(timerObj)
        if nargin < 1
            timerObj = debounceTimer;
        end
        if isempty(timerObj)
            return;
        end
        try
            if isvalid(timerObj)
                stop(timerObj);
                delete(timerObj);
            end
        catch
        end
        if isequal(timerObj, debounceTimer)
            debounceTimer = [];
        end
    end
end

function opts = parseOptions(args)
    opts = struct();
    if mod(numel(args), 2) ~= 0
        error('labkit:ui:tool:InvalidPannerOptions', ...
            'createLabeledPanner options must be name/value pairs.');
    end
    for k = 1:2:numel(args)
        opts.(char(string(args{k}))) = args{k + 1};
    end
end

function args = removeInternalOptions(opts, internalNames)
    names = fieldnames(opts);
    args = {};
    for k = 1:numel(names)
        name = names{k};
        if any(strcmp(name, internalNames))
            continue;
        end
        args(end + 1:end + 2) = {name, opts.(name)};
    end
end

function value = getOption(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isfield(opts, name)
        value = opts.(name);
    end
end

function value = clampValue(value, limits)
    value = double(value);
    if ~isfinite(value)
        value = limits(1);
    end
    value = min(limits(2), max(limits(1), value));
end
