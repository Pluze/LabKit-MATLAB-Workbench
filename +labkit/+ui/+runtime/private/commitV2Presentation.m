% Private UI runtime helper. Expected caller: runV2App after a validated state
% commit. Inputs are a v2 runtime and semantic state. Side effects reconcile
% bound controls, declared control presentation, and registered plot renderers
% without exposing the raw UI registry to app presenters.
function presentation = commitV2Presentation(runtime, state, preserveView)
    if nargin < 3
        preserveView = false;
    end
    presentation = runtime.definition.present(state);
    if isempty(presentation)
        presentation = struct();
    end
    if ~isstruct(presentation) || ~isscalar(presentation)
        error('labkit:ui:runtime:InvalidPresentation', ...
            'Present must return a scalar struct.');
    end
    if isfield(presentation, 'controls')
        applyControlConstraints(runtime.ui, presentation.controls);
    end
    applyBindings(runtime.ui, runtime.bindings, state);
    if isfield(presentation, 'controls')
        applyControls(runtime.ui, presentation.controls);
    end
    applyWorkflowLog(runtime.ui, state.session.workflow);
    if isfield(presentation, 'previews')
        priorPreviews = struct();
        if isfield(runtime.lastPresentation, 'previews')
            priorPreviews = runtime.lastPresentation.previews;
        end
        applyPreviews(runtime, presentation.previews, priorPreviews, ...
            logical(preserveView));
    end
    if isfield(presentation, 'interactions')
        reconcileV2Interactions(runtime, presentation.interactions);
    else
        reconcileV2Interactions(runtime, struct());
    end
end

function applyWorkflowLog(ui, workflow)
    if ~isstruct(workflow) || ~isscalar(workflow) || ...
            ~isfield(workflow, 'logLines')
        return;
    end
    value = cellstr(string(workflow.logLines(:)));
    if isempty(value)
        value = {''};
    end
    ids = fieldnames(ui.controls);
    for k = 1:numel(ids)
        control = ui.controls.(ids{k});
        if isstruct(control) && isfield(control, 'kind') && ...
                strcmp(control.kind, 'logPanel')
            setControlValue(ui, ids{k}, value);
        end
    end
end

function applyControlConstraints(ui, controls)
    if ~isstruct(controls) || ~isscalar(controls)
        error('labkit:ui:runtime:InvalidPresentation', ...
            'Presentation controls must be a scalar struct.');
    end
    ids = fieldnames(controls);
    for k = 1:numel(ids)
        id = string(ids{k});
        spec = controls.(ids{k});
        if ~isstruct(spec) || ~isscalar(spec)
            continue;
        end
        [found, value] = propertyValue(spec, "Items");
        if found
            setControlItems(ui, id, value);
        end
        [found, value] = propertyValue(spec, "Limits");
        if found
            setControlLimits(ui, id, value);
        end
    end
end

function applyBindings(ui, bindings, state)
    for k = 1:numel(bindings)
        value = valueAtPath(state, bindings(k).path);
        setControlValue(ui, bindings(k).id, value);
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
            setControlValue(ui, id, spec);
            continue;
        end
        applyControlSpec(ui, id, spec);
    end
end

function applyControlSpec(ui, id, spec)
    [found, value] = propertyValue(spec, "Files");
    if found
        setControlValue(ui, id, value);
    end
    [found, value] = propertyValue(spec, "Selection");
    if found
        setControlFileSelection(ui, id, value);
    end
    [found, value] = propertyValue(spec, "Status");
    if found
        applyFilePanelStatus(ui, id, value);
    end
    [found, value] = propertyValue(spec, "Items");
    if found
        setControlItems(ui, id, value);
    end
    [found, value] = propertyValue(spec, "Limits");
    if found
        setControlLimits(ui, id, value);
    end
    [found, value] = propertyValue(spec, "Enabled");
    if found
        setControlEnabled(ui, id, value);
    end
    [found, value] = propertyValue(spec, "Text");
    if found
        applyControlText(ui, id, value);
    end
    names = ["Value", "Data"];
    for k = 1:numel(names)
        [found, value] = propertyValue(spec, names(k));
        if found
            setControlValue(ui, id, value);
            break;
        end
    end
end

function applyControlText(ui, id, value)
    field = char(id);
    if ~isfield(ui.controls, field)
        error('labkit:ui:runtime:InvalidPresentation', ...
            'Presentation references unknown control "%s".', id);
    end
    control = ui.controls.(field);
    candidates = {'button', 'valueHandle', 'handle'};
    for k = 1:numel(candidates)
        name = candidates{k};
        if isfield(control, name) && isgraphics(control.(name)) && ...
                isprop(control.(name), 'Text')
            control.(name).Text = char(string(value));
            return;
        end
    end
    setControlValue(ui, id, value);
end

function applyFilePanelStatus(ui, id, value)
    field = char(id);
    if ~isfield(ui.controls, field)
        error('labkit:ui:runtime:InvalidPresentation', ...
            'Presentation references unknown control "%s".', id);
    end
    control = ui.controls.(field);
    if ~isfield(control, 'kind') || ~strcmp(control.kind, 'filePanel') || ...
            ~isfield(control, 'status') || isempty(control.status) || ...
            ~isvalid(control.status)
        error('labkit:ui:runtime:InvalidPresentation', ...
            'Control "%s" does not expose file-panel status text.', id);
    end
    control.status.Value = char(string(value));
end

function applyPreviews(runtime, previews, priorPreviews, preserveView)
    if ~isstruct(previews) || ~isscalar(previews)
        error('labkit:ui:runtime:InvalidPresentation', ...
            'Presentation previews must be a scalar struct.');
    end
    ids = fieldnames(previews);
    for k = 1:numel(ids)
        id = string(ids{k});
        spec = previews.(ids{k});
        [hasAxes, axesSpecs] = propertyValue(spec, "Axes");
        if hasAxes
            priorAxes = priorAxisSpecs(priorPreviews, id);
            applyPreviewAxes(runtime, id, axesSpecs, priorAxes, preserveView);
            continue;
        end
        if samePreviewRequest(priorPreviews, id, spec)
            continue;
        end
        applyPreview(runtime, id, spec, preserveView);
    end
end

function applyPreviewAxes(runtime, previewId, axesSpecs, priorAxes, preserveView)
    if ~isstruct(axesSpecs) || ~isscalar(axesSpecs)
        error('labkit:ui:runtime:InvalidPresentation', ...
            'Preview "%s" Axes must be a scalar struct.', previewId);
    end
    axisIds = fieldnames(axesSpecs);
    for k = 1:numel(axisIds)
        axisId = string(axisIds{k});
        spec = axesSpecs.(axisIds{k});
        if ~isstruct(spec) || ~isscalar(spec)
            error('labkit:ui:runtime:InvalidPresentation', ...
                'Preview "%s" axis "%s" must be a scalar struct.', ...
                previewId, axisId);
        end
        if isfield(priorAxes, char(axisId)) && ...
                isequaln(priorAxes.(char(axisId)), spec)
            continue;
        end
        spec.Axis = axisId;
        applyPreview(runtime, previewId, spec, preserveView);
    end
end

function axesSpecs = priorAxisSpecs(priorPreviews, previewId)
    axesSpecs = struct();
    if ~isstruct(priorPreviews) || ~isscalar(priorPreviews) || ...
            ~isfield(priorPreviews, char(previewId))
        return;
    end
    [found, value] = propertyValue( ...
        priorPreviews.(char(previewId)), "Axes");
    if found && isstruct(value) && isscalar(value)
        axesSpecs = value;
    end
end

function tf = samePreviewRequest(priorPreviews, previewId, spec)
    tf = isstruct(priorPreviews) && isscalar(priorPreviews) && ...
        isfield(priorPreviews, char(previewId)) && ...
        isequaln(priorPreviews.(char(previewId)), spec);
end

function applyPreview(runtime, id, spec, preserveView)
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
            ax = resolvePreviewAxes(runtime.ui, id, string(axisId));
        else
            ax = resolvePreviewAxes(runtime.ui, id);
        end
        priorView = captureManualView(ax, preserveView);
        restoreView = onCleanup(@() restoreManualView(ax, priorView));
        invokeRenderer(runtime.definition.renderers.(rendererId), ax, model);
        clear restoreView;
end

function view = captureManualView(ax, preserveView)
    view = struct('x', [], 'y', []);
    if ~preserveView || isempty(ax) || ~isvalid(ax)
        return;
    end
    if strcmp(ax.XLimMode, 'manual')
        view.x = double(ax.XLim);
    end
    if strcmp(ax.YLimMode, 'manual')
        view.y = double(ax.YLim);
    end
end

function restoreManualView(ax, view)
    if isempty(ax) || ~isvalid(ax)
        return;
    end
    if ~isempty(view.x)
        ax.XLim = view.x;
    end
    if ~isempty(view.y)
        ax.YLim = view.y;
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
