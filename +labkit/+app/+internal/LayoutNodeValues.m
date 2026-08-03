% Normalize and validate values for the owning internal class.
% Expected callers are internal class methods; inputs and outputs retain
% their declared MATLAB shapes. Methods have no side effects except
% raising stable contract errors for malformed values.
classdef (Sealed, Hidden) LayoutNodeValues
    methods (Static)
        function value = optionValue(options, name, defaultValue)
            value = defaultValue;
            if isfield(options, name)
                value = options.(name);
            end
        end

        function value = normalizeId(value)
            values = labkit.app.internal.LayoutNodeValues.idRow(value, "layout");
            if numel(values) ~= 1
                error("labkit:app:contract:InvalidValue", ...
                    "Layout id must be a scalar MATLAB identifier.");
            end
            value = values;
        end

        function values = idRow(values, label)
            values = labkit.app.internal.LayoutNodeValues.textRow(values, label + " IDs");
            if any(strlength(values) == 0) || ...
                    any(~arrayfun(@(value) isvarname(char(value)), values)) || ...
                    numel(unique(values)) ~= numel(values)
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s IDs must be unique MATLAB identifiers.", label);
            end
        end

        function children = normalizeChildren(children)
            if ~iscell(children) || (~isempty(children) && ~isrow(children)) || ...
                    ~all(cellfun(@(value) isa(value, "labkit.app.internal.LayoutNode"), children))
                error("labkit:app:contract:InvalidValue", ...
                    "Layout children must be a row cell array of Layout values.");
            end
        end

        function validateChildKinds(children, allowed, parent)
            for k = 1:numel(children)
                if ~any(children{k}.Kind == allowed)
                    error("labkit:app:contract:UnsupportedOperation", ...
                        "%s cannot own a %s Layout.", parent, children{k}.Kind);
                end
            end
        end

        function kinds = leafAndGroupKinds()
            kinds = ["button", "field", "rangeField", "slider", "fileList", ...
                "plotArea", "dataTable", "statusPanel", "group"];
        end

        function kinds = controlGroupKinds()
            kinds = ["button", "field", "rangeField", "slider", ...
                "fileList", "group"];
        end

        function kinds = workspaceContentKinds()
            kinds = [labkit.app.internal.LayoutNodeValues.leafAndGroupKinds(), "section"];
        end

        function values = signalCell(signal)
            values = {};
            if ~isempty(signal)
                values = {signal};
            end
        end

        function signal = namedSignal(target, options, optionName, signalName)
        signal = labkit.app.internal.LayoutNodeValues.optionalSignal( ...
            target, signalName, labkit.app.internal.LayoutNodeValues.optionValue(options, optionName, []));
        end

        function signal = optionalSignal(target, signalName, callback)
        signal = [];
        if ~isempty(callback)
            signal = labkit.app.internal.LayoutNodeValues.bindSignal(target, signalName, callback);
        end
        end

        function signal = bindSignal(target, signalName, callback)
        signal = labkit.app.internal.SignalBinding(target, signalName, callback);
        end

        function callback = rendererCallback(callback)
        if ~isa(callback, "function_handle") || ~isscalar(callback)
            error("labkit:app:contract:InvalidValue", ...
                "layout.plotArea renderer must be a function handle.");
        end
        if nargin(callback) ~= 2 || nargout(callback) > 0
            error("labkit:app:contract:CallbackRoleMismatch", ...
                "layout.plotArea renderer must accept axes and model with no output.");
        end
        end

        function callback = pathFilterCallback(callback)
        if isempty(callback)
            return;
        end
        if ~isa(callback, "function_handle") || ~isscalar(callback)
            error("labkit:app:contract:InvalidValue", ...
                "layout.fileList PathFilter must be a function handle.");
        end
        if nargin(callback) ~= 1 || nargout(callback) ~= 1
            error("labkit:app:contract:CallbackRoleMismatch", ...
                "layout.fileList PathFilter must accept paths and return " + ...
                "one logical mask.");
        end
        end

        function specs = interactionSpecs(specs, plotId, axisIds)
        if isempty(specs)
            specs = {};
            return;
        end
        if ~iscell(specs) || ~isrow(specs) || ...
                ~all(cellfun(@(value) ...
                    isa(value, "labkit.app.internal.InteractionSpec"), specs))
            error("labkit:app:contract:InvalidValue", ...
                "layout.plotArea Interactions must be a row cell array of " + ...
                "labkit.app.interaction declarations.");
        end
        for k = 1:numel(specs)
            specs{k} = specs{k}.attachToPlot(plotId, axisIds);
        end
        ids = string(cellfun(@(value) value.Id, specs, "UniformOutput", false));
        if numel(unique(ids)) ~= numel(ids)
            error("labkit:app:contract:DuplicateId", ...
                "layout.plotArea interaction IDs must be unique.");
        end
        end

        function value = scalarText(value, label)
            if ~(ischar(value) || (isstring(value) && isscalar(value)))
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s must be scalar text.", label);
            end
            value = string(value);
        end

        function value = nonemptyText(value, label)
            value = labkit.app.internal.LayoutNodeValues.scalarText(value, label);
            if strlength(value) == 0
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s must be nonempty.", label);
            end
        end

        function value = enumText(value, allowed, label)
            value = labkit.app.internal.LayoutNodeValues.scalarText(value, label);
            if ~any(value == allowed)
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s has an unsupported value: %s.", label, value);
            end
        end

        function value = bindingPath(value)
            value = labkit.app.internal.LayoutNodeValues.scalarText(value, "Bind");
            if strlength(value) == 0
                return;
            end
            if isempty(regexp(char(value), ...
                    '^(project|session)(\.[A-Za-z]\w*)+$', "once"))
                error("labkit:app:contract:InvalidValue", ...
                    "Layout Bind must be a project or session field path.");
            end
        end

        function values = textRow(values, label)
            if ischar(values)
                values = string(values);
            elseif iscellstr(values)
                values = string(values);
            elseif ~isstring(values)
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s must be text.", label);
            end
            values = reshape(values, 1, []);
        end

        function value = defaultAxesLayout(axisCount)
            value = "single";
            if axisCount > 1
                value = "stack";
            end
        end

        function values = optionalAxisText(options, name, axisCount)
            values = strings(1, 0);
            if isfield(options, name)
                values = labkit.app.internal.LayoutNodeValues.textRow(options.(name), name);
                if numel(values) ~= axisCount
                    error("labkit:app:contract:InvalidValue", ...
                        "Layout %s must contain one value per axis.", name);
                end
            end
        end

        function values = optionalLayoutSizes(options, name, axisCount)
            values = {};
            if ~isfield(options, name)
                return;
            end
            values = options.(name);
            if ~iscell(values) || ~isrow(values) || numel(values) ~= axisCount
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s must be a row cell array with one value per axis.", ...
                    name);
            end
            for k = 1:numel(values)
                value = values{k};
                numericSize = isnumeric(value) && isscalar(value) && ...
                    isfinite(value) && value > 0;
                flexibleSize = (ischar(value) || ...
                    (isstring(value) && isscalar(value))) && ...
                    any(string(value) == ["fit", "1x"]);
                if ~(numericSize || flexibleSize)
                    error("labkit:app:contract:InvalidValue", ...
                        "Layout %s entries must be positive pixels, fit, or 1x.", ...
                        name);
                end
                if isstring(value)
                    values{k} = char(value);
                end
            end
        end

        function values = scrollZoomAxes(options, axisCount)
            values = repmat("xy", 1, axisCount);
            if ~isfield(options, "ScrollZoomAxes")
                return;
            end
            values = labkit.app.internal.LayoutNodeValues.textRow(options.ScrollZoomAxes, "ScrollZoomAxes");
            if numel(values) ~= axisCount || ...
                    any(~ismember(values, ["xy", "x", "y"]))
                error("labkit:app:contract:InvalidValue", ...
                    "Layout ScrollZoomAxes must contain xy, x, or y for every axis.");
            end
        end

        function assertAxesLayout(layout, axisCount)
            if layout == "single" && axisCount ~= 1
                error("labkit:app:contract:InvalidValue", ...
                    "Layout single plot areas require exactly one axis.");
            end
            if layout == "pair" && axisCount < 2
                error("labkit:app:contract:InvalidValue", ...
                    "Layout pair plot areas require at least two axes.");
            end
        end

        function value = logicalValue(value, label)
            if ~(islogical(value) && isscalar(value))
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s must be a logical scalar.", label);
            end
        end

        function values = logicalRow(values, label)
            if ~(islogical(values) && (isscalar(values) || isrow(values)))
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s must be a logical scalar or row.", label);
            end
            values = reshape(values, 1, []);
        end

        function assertEditableWidth(editable, columns)
            if ~isscalar(editable) && ~isempty(columns) && ...
                    numel(editable) ~= numel(columns)
                error("labkit:app:contract:InvalidValue", ...
                    "Layout ColumnEditable must be scalar or match Columns.");
            end
        end

        function value = optionalLimits(value, label)
            if isempty(value)
                value = [];
                return;
            end
            if ~(isnumeric(value) && isequal(size(value), [1 2]) && ...
                    all(isfinite(value)) && value(1) <= value(2))
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s must be an increasing finite 1-by-2 row.", label);
            end
            value = double(value);
        end

        function value = optionalPair(value, label)
            if isempty(value)
                value = [];
                return;
            end
            if ~(isnumeric(value) && isequal(size(value), [1 2]) && ...
                    all(isfinite(value)))
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s must be a finite 1-by-2 row.", label);
            end
            value = double(value);
        end

        function value = optionalPositive(value, label)
            if isempty(value)
                return;
            end
            if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value > 0)
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s must be a positive scalar.", label);
            end
            value = double(value);
        end

        function value = positiveOrInf(value, label)
            if ~(isnumeric(value) && isscalar(value) && value > 0 && ...
                    (isfinite(value) || isinf(value)))
                error("labkit:app:contract:InvalidValue", ...
                    "Layout %s must be a positive scalar or Inf.", label);
            end
            value = double(value);
        end

    end
end
