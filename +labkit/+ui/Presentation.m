classdef (Sealed) Presentation
    %PRESENTATION Build one immutable complete visible-state snapshot.
    %
    % Usage:
    %   view = labkit.ui.Presentation()
    %   view = view.value(target, value)
    %   view = view.choices(target, choices)
    %   view = view.limits(target, limits)
    %   view = view.enabled(target, enabled)
    %   view = view.visible(target, visible)
    %   view = view.text(target, text)
    %   view = view.files(target, paths)
    %   view = view.selection(target, selection)
    %   view = view.table(target, data, Name=Value)
    %   view = view.plot(target, renderer, model)
    %   view = view.workspacePage(target, Name=Value)
    %
    % Description:
    %   Presentation is a closed immutable operation vocabulary. One value
    %   describes the complete current visible state; Application validates
    %   targets, capabilities, renderer references, and completeness before a
    %   runtime may reconcile it. Apps do not author patches or generic
    %   target/property setters.
    %
    % Inputs:
    %   target - Nonempty Layout target ID.
    %   value - Target value owned by the App state.
    %   choices - Text array or cellstr of legal choices.
    %   limits - Increasing finite two-element numeric row.
    %   enabled - Logical scalar availability.
    %   visible - Logical scalar visibility.
    %   text - Scalar text.
    %   paths - String or cell array of file paths.
    %   selection - Selection value accepted by the target.
    %   data - App-owned table, numeric array, or cell array.
    %   renderer - Declared renderer ID.
    %
    % Outputs:
    %   view - New immutable labkit.ui.Presentation snapshot.
    %
    % Errors:
    %   labkit:ui:contract:InvalidValue - An operation argument is malformed.
    %   labkit:ui:contract:DuplicateId - The same operation is supplied twice
    %       for one target.
    %
    % Example:
    %   view = labkit.ui.Presentation();
    %   view = view.choices("group", ["A", "B"]);
    %   view = view.value("group", "A");
    %   assert(isa(view, "labkit.ui.Presentation"))
    %
    % See also labkit.ui.Application, labkit.ui.Layout

    properties (SetAccess = private, GetAccess = private)
        Operations (1, :) cell
    end

    methods
        function obj = Presentation()
            obj.Operations = {};
        end

        function obj = value(obj, target, value)
            obj = append(obj, "value", target, value, "");
        end

        function obj = choices(obj, target, choices)
            if ischar(choices)
                choices = string(choices);
            elseif iscellstr(choices)
                choices = string(choices);
            elseif ~isstring(choices)
                error("labkit:ui:contract:InvalidValue", ...
                    "Presentation choices must be text.");
            end
            obj = append(obj, "choices", target, reshape(choices, 1, []), "");
        end

        function obj = limits(obj, target, limits)
            if ~(isnumeric(limits) && isequal(size(limits), [1 2]) && ...
                    all(isfinite(limits)) && limits(1) <= limits(2))
                error("labkit:ui:contract:InvalidValue", ...
                    "Presentation limits must be an increasing finite 1-by-2 row.");
            end
            obj = append(obj, "limits", target, limits, "");
        end

        function obj = enabled(obj, target, enabled)
            obj = append(obj, "enabled", target, ...
                logicalScalar(enabled, "enabled"), "");
        end

        function obj = visible(obj, target, visible)
            obj = append(obj, "visible", target, ...
                logicalScalar(visible, "visible"), "");
        end

        function obj = text(obj, target, text)
            if ~(ischar(text) || (isstring(text) && isscalar(text)))
                error("labkit:ui:contract:InvalidValue", ...
                    "Presentation text must be scalar text.");
            end
            obj = append(obj, "text", target, string(text), "");
        end

        function obj = files(obj, target, paths)
            if ischar(paths)
                paths = string(paths);
            elseif iscellstr(paths)
                paths = string(paths);
            elseif ~isstring(paths)
                error("labkit:ui:contract:InvalidValue", ...
                    "Presentation files must be a string or cell array.");
            end
            obj = append(obj, "files", target, reshape(paths, 1, []), "");
        end

        function obj = selection(obj, target, selection)
            if ~isa(selection, "labkit.ui.Selection")
                error("labkit:ui:contract:InvalidValue", ...
                    "Presentation selection must be a Selection value.");
            end
            obj = append(obj, "selection", target, selection, "");
        end

        function obj = table(obj, target, data, varargin)
            if ~(istable(data) || isnumeric(data) || iscell(data))
                error("labkit:ui:contract:InvalidValue", ...
                    "Presentation table data has an unsupported type.");
            end
            options = parseContractOptions( ...
                "labkit.ui.Presentation.table", ...
                ["Columns", "RowNames", "ColumnEditable"], varargin{:});
            columns = textRow(optionValue( ...
                options, "Columns", strings(1, 0)), "Columns");
            editable = logicalRow(optionValue( ...
                options, "ColumnEditable", false), "ColumnEditable");
            assertEditableWidth(editable, columns);
            value = struct( ...
                "Data", {data}, "Columns", columns, ...
                "RowNames", textRow(optionValue( ...
                    options, "RowNames", strings(1, 0)), "RowNames"), ...
                "ColumnEditable", editable);
            obj = append(obj, "table", target, value, "");
        end

        function obj = plot(obj, target, renderer, model)
            renderer = scalarId(renderer, "renderer");
            obj = append(obj, "plot", target, model, renderer);
        end

        function obj = workspacePage(obj, target, varargin)
            options = parseContractOptions( ...
                "labkit.ui.Presentation.workspacePage", ...
                ["Enabled", "Status"], varargin{:});
            enabled = true;
            if isfield(options, "Enabled")
                enabled = logicalScalar(options.Enabled, "Enabled");
            end
            status = "";
            if isfield(options, "Status")
                supplied = options.Status;
                if ~(ischar(supplied) || ...
                        (isstring(supplied) && isscalar(supplied)))
                    error("labkit:ui:contract:InvalidValue", ...
                        "Presentation workspace Status must be scalar text.");
                end
                status = string(supplied);
            end
            obj = append(obj, "workspacePage", target, ...
                struct("Enabled", enabled, "Status", status), "");
        end
    end

    methods (Access = private)
        function obj = append(obj, kind, target, value, reference)
            target = scalarId(target, "target");
            for k = 1:numel(obj.Operations)
                operation = obj.Operations{k};
                if operation.Kind == kind && operation.Target == target
                    error("labkit:ui:contract:DuplicateId", ...
                        "Presentation repeats %s for target %s.", ...
                        kind, target);
                end
            end
            obj.Operations{end + 1} = struct( ...
                "Kind", kind, ...
                "Target", target, ...
                "Value", value, ...
                "Reference", reference);
        end
    end

    methods (Access = {?labkit.ui.Application, ?labkit.ui.MatlabPlatformAdapter})
        function operations = operationsForCompiler(obj)
            operations = obj.Operations;
        end
    end

    methods (Access = ?labkit.ui.RuntimeKernel)
        function result = overlayForRuntime(base, custom)
            if ~isa(custom, "labkit.ui.Presentation")
                error("labkit:ui:contract:InvalidValue", ...
                    "Presentation overlay requires a Presentation value.");
            end
            operations = base.Operations;
            for k = 1:numel(custom.Operations)
                incoming = custom.Operations{k};
                replaced = false;
                for n = 1:numel(operations)
                    current = operations{n};
                    if current.Kind == incoming.Kind && ...
                            current.Target == incoming.Target
                        operations{n} = incoming;
                        replaced = true;
                        break;
                    end
                end
                if ~replaced
                    operations{end + 1} = incoming;
                end
            end
            result = labkit.ui.Presentation();
            result.Operations = operations;
        end
    end
end

function value = scalarId(value, label)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error("labkit:ui:contract:InvalidValue", ...
            "Presentation %s must be scalar text.", label);
    end
    value = string(value);
    if strlength(value) == 0 || ~isvarname(char(value))
        error("labkit:ui:contract:InvalidValue", ...
            "Presentation %s must be a MATLAB identifier.", label);
    end
end

function value = logicalScalar(value, label)
    if ~(islogical(value) && isscalar(value))
        error("labkit:ui:contract:InvalidValue", ...
            "Presentation %s must be a logical scalar.", label);
    end
end

function values = textRow(values, label)
    if ischar(values)
        values = string(values);
    elseif iscellstr(values)
        values = string(values);
    elseif ~isstring(values)
        error("labkit:ui:contract:InvalidValue", ...
            "Presentation %s must be text.", label);
    end
    values = reshape(values, 1, []);
end

function values = logicalRow(values, label)
    if ~(islogical(values) && (isscalar(values) || isrow(values)))
        error("labkit:ui:contract:InvalidValue", ...
            "Presentation %s must be a logical scalar or row.", label);
    end
    values = reshape(values, 1, []);
end

function assertEditableWidth(editable, columns)
    if ~isscalar(editable) && ~isempty(columns) && ...
            numel(editable) ~= numel(columns)
        error("labkit:ui:contract:InvalidValue", ...
            "Presentation ColumnEditable must be scalar or match Columns.");
    end
end

function value = optionValue(options, name, defaultValue)
    value = defaultValue;
    if isfield(options, name)
        value = options.(name);
    end
end
