% Private UI runtime helper. Expected caller: runV2App after a validated state
% commit. Inputs are a v2 runtime and semantic state. Side effects reconcile
% bound controls, declared control presentation, and registered plot renderers
% without exposing the raw UI registry to app presenters.
function presentation = commitV2Presentation(runtime, state)
    presentation = runtime.definition.present(state);
    if isempty(presentation)
        presentation = struct();
    end
    if ~isstruct(presentation) || ~isscalar(presentation)
        error('labkit:ui:runtime:InvalidPresentation', ...
            'Present must return a scalar struct.');
    end
    applyBindings(runtime.ui, runtime.bindings, state);
    if isfield(presentation, 'controls')
        applyControls(runtime.ui, presentation.controls);
    end
    if isfield(presentation, 'previews')
        applyPreviews(runtime, presentation.previews);
    end
    if isfield(presentation, 'interactions')
        reconcileV2Interactions(runtime, presentation.interactions);
    else
        reconcileV2Interactions(runtime, struct());
    end
end

function applyBindings(ui, bindings, state)
    for k = 1:numel(bindings)
        value = valueAtPath(state, bindings(k).path);
        labkit.ui.control.setValue(ui, bindings(k).id, value);
    end
end

function applyControls(ui, controls)
    if ~isstruct(controls) || ~isscalar(controls)
        error('labkit:ui:runtime:InvalidPresentation', ...
            'Presentation controls must be a scalar struct.');
    end
    ids = fieldnames(controls);
    for k = 1:numel(ids)
        id = string(ids{k});
        spec = controls.(ids{k});
        if ~isstruct(spec) || ~isscalar(spec)
            labkit.ui.control.setValue(ui, id, spec);
            continue;
        end
        applyControlSpec(ui, id, spec);
    end
end

function applyControlSpec(ui, id, spec)
    [found, value] = propertyValue(spec, "Items");
    if found
        labkit.ui.control.setItems(ui, id, value);
    end
    [found, value] = propertyValue(spec, "Limits");
    if found
        labkit.ui.control.setLimits(ui, id, value);
    end
    [found, value] = propertyValue(spec, "Enabled");
    if found
        labkit.ui.control.setEnabled(ui, id, value);
    end
    names = ["Value", "Text", "Data"];
    for k = 1:numel(names)
        [found, value] = propertyValue(spec, names(k));
        if found
            labkit.ui.control.setValue(ui, id, value);
            break;
        end
    end
end

function applyPreviews(runtime, previews)
    if ~isstruct(previews) || ~isscalar(previews)
        error('labkit:ui:runtime:InvalidPresentation', ...
            'Presentation previews must be a scalar struct.');
    end
    ids = fieldnames(previews);
    for k = 1:numel(ids)
        id = string(ids{k});
        spec = previews.(ids{k});
        [hasRenderer, rendererId] = propertyValue(spec, "Renderer");
        [hasModel, model] = propertyValue(spec, "Model");
        if ~hasRenderer || ~hasModel
            error('labkit:ui:runtime:InvalidPresentation', ...
                'Preview "%s" requires Renderer and Model.', id);
        end
        rendererId = char(string(rendererId));
        if ~isfield(runtime.definition.renderers, rendererId)
            error('labkit:ui:runtime:UnknownRenderer', ...
                'Preview "%s" references unknown renderer "%s".', ...
                id, rendererId);
        end
        [hasAxis, axisId] = propertyValue(spec, "Axis");
        if hasAxis && strlength(string(axisId)) > 0
            ax = labkit.ui.plot.getAxes(runtime.ui, id, string(axisId));
        else
            ax = labkit.ui.plot.getAxes(runtime.ui, id);
        end
        invokeRenderer(runtime.definition.renderers.(rendererId), ax, model);
    end
end

function invokeRenderer(renderer, ax, model)
    count = nargin(renderer);
    if count == 0
        renderer();
    elseif count == 1
        renderer(model);
    else
        renderer(ax, model);
    end
end

function value = valueAtPath(state, path)
    parts = split(string(path), ".");
    value = state;
    for k = 1:numel(parts)
        value = value.(char(parts(k)));
    end
end

function [found, value] = propertyValue(spec, name)
    if ~isstruct(spec) || ~isscalar(spec)
        found = false;
        value = [];
        return;
    end
    fields = string(fieldnames(spec));
    index = find(strcmpi(fields, name), 1, 'first');
    found = ~isempty(index);
    value = [];
    if found
        value = spec.(char(fields(index)));
    end
end
