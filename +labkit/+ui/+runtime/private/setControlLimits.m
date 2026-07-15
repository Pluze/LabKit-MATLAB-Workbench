% Private UI runtime helper. Expected caller: V2 presentation commit. Applies
% validated numeric limits while suppressing app callbacks.
function setControlLimits(ui, id, limits)
%
% Internal contract:
%   setControlLimits(ui, id, limits)
%
% Inputs:
%   ui - UI registry returned by labkit.ui.runtime.create.
%   id - globally unique semantic control id.
%   limits - two-element increasing numeric vector.
%
% Output:
%   None. Controls with a current Value are clamped into the new limits while
%   their value-change callback is temporarily suppressed.

    limits = double(limits(:)).';
    if numel(limits) ~= 2 || any(isnan(limits)) || limits(1) >= limits(2)
        error('labkit:ui:control:InvalidLimits', ...
            'Limits must be an increasing two-element numeric vector.');
    end

    control = resolveControl(ui, id);
    if ~isPanner(control) && any(~isfinite(limits))
        error('labkit:ui:control:InvalidLimits', ...
            'Only panner controls accept infinite numeric limits.');
    end
    handles = limitsHandles(control, limits);
    if isempty(handles)
        error('labkit:ui:control:NoLimits', ...
            'Control "%s" does not expose numeric Limits.', control.id);
    end

    for k = 1:numel(handles)
        handle = handles{k};
        callback = callbackProperty(handle);
        cleanupObj = suppressCallback(handle, callback);
        handle.Limits = limits;
        if isprop(handle, 'Value') && isnumeric(handle.Value) && isscalar(handle.Value)
            handle.Value = min(limits(2), max(limits(1), handle.Value));
        end
        clear cleanupObj;
    end
    updatePannerStep(control, limits);
end

function updatePannerStep(control, limits)
    if ~isPanner(control) || ~isfield(control, 'valueSpinner') || ...
            ~isvalid(control.valueSpinner)
        return;
    end
    if isfield(control.props, 'step')
        return;
    end
    if ~all(isfinite(limits))
        return;
    end
    span = max(eps, diff(double(limits)));
    fraction = optionValue(control.props, 'stepFraction', 0.002);
    step = span .* max(eps, double(fraction));
    if isfield(control.props, 'minStep')
        step = max(step, double(control.props.minStep));
    end
    if isfield(control.props, 'maxStep')
        step = min(step, double(control.props.maxStep));
    end
    control.valueSpinner.Step = step;
end

function handles = limitsHandles(control, limits)
    if isPanner(control)
        handles = pannerLimitsHandles(control, limits);
        return;
    end
    allHandles = controlHandles(control);
    handles = cell(1, numel(allHandles));
    count = 0;
    for k = 1:numel(allHandles)
        handle = allHandles{k};
        if isprop(handle, 'Limits')
            count = count + 1;
            handles{count} = handle;
        end
    end
    handles = handles(1:count);
end

function handles = pannerLimitsHandles(control, limits)
    handles = {};
    if isfield(control, 'valueSpinner') && ~isempty(control.valueSpinner) && ...
            isvalid(control.valueSpinner)
        handles{end+1} = control.valueSpinner;
    end
    if all(isfinite(limits)) && isfield(control, 'slider') && ...
            ~isempty(control.slider) && isvalid(control.slider)
        handles{end+1} = control.slider;
    end
end

function tf = isPanner(control)
    tf = isfield(control, 'kind') && strcmp(control.kind, 'panner');
end

function callback = callbackProperty(handle)
    callback = struct('property', '', 'value', []);
    for name = {'ValueChangedFcn'}
        prop = name{1};
        if isprop(handle, prop)
            callback.property = prop;
            callback.value = handle.(prop);
            return;
        end
    end
end

function cleanupObj = suppressCallback(handle, callback)
    if isempty(callback.property)
        cleanupObj = onCleanup(@() []);
        return;
    end
    handle.(callback.property) = [];
    cleanupObj = onCleanup(@() restoreCallback(handle, callback));
end

function restoreCallback(handle, callback)
    if ~isempty(handle) && isvalid(handle) && isprop(handle, callback.property)
        handle.(callback.property) = callback.value;
    end
end

function value = optionValue(opts, name, defaultValue)
    value = defaultValue;
    if isstruct(opts) && isfield(opts, name)
        value = opts.(name);
    end
end
