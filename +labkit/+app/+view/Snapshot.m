classdef (Sealed) Snapshot
    %SNAPSHOT Build one immutable complete visible-state snapshot.
    %
    % Usage:
    %   view = labkit.app.view.Snapshot()
    %   view = view.value(target, value)
    %   view = view.choices(target, choices)
    %   view = view.limits(target, limits)
    %   view = view.enabled(target, enabled)
    %   view = view.visible(target, visible)
    %   view = view.text(target, text)
    %   view = view.filePaths(target, paths)
    %   view = view.fileItemStatuses(target, statuses)
    %   view = view.listSelection(target, selection)
    %   view = view.tableCellSelection(target, selection)
    %   view = view.tableData(target, data, Name=Value)
    %   view = view.renderPlot(target, model, Name=Value)
    %   view = view.workspacePage(target, Name=Value)
    %   view = view.anchorPath(interaction, points, Name=Value)
    %   view = view.pairedAnchors(interaction, pointSets, Name=Value)
    %   view = view.pointSlots(interaction, value, Name=Value)
    %   view = view.rectangle(interaction, position, Name=Value)
    %   view = view.regionSelection(interaction, Name=Value)
    %   view = view.interval(interaction, range, Name=Value)
    %   view = view.scaleReference(interaction, endpoints, Name=Value)
    %   view = view.include(fragment)
    %
    % Description:
    %   View snapshot is a closed immutable operation vocabulary. One value
    %   describes the complete current visible state; Definition validates
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
    %   statuses - Empty or one reader-facing status per file-list row.
    %   selection - Selection value accepted by the target.
    %   data - App-owned table, numeric array, or cell array.
    %   model - App-owned model passed to the renderer declared by plotArea.
    %
    % Options:
    %   ViewRevision - Nonnegative integer identifying the requested initial
    %       viewport. The adapter preserves user zoom while the value is
    %       unchanged and accepts renderer limits once when it changes.
    %       Default: 0.
    %
    % Outputs:
    %   view - New immutable labkit.app.view.Snapshot snapshot.
    %   fragment - Another Snapshot whose non-duplicate operations should be
    %       included in this snapshot.
    %
    % Errors:
    %   labkit:app:contract:InvalidValue - An operation argument is malformed.
    %   labkit:app:contract:DuplicateId - The same operation is supplied twice
    %       for one target.
    %
    % Example:
    %   view = labkit.app.view.Snapshot();
    %   view = view.choices("group", ["A", "B"]);
    %   view = view.value("group", "A");
    %   assert(isa(view, "labkit.app.view.Snapshot"))
    %
    % See also labkit.app.Definition, labkit.app.layout.workbench

    properties (SetAccess = private, GetAccess = private)
        Operations (1, :) cell
    end

    methods
        function obj = Snapshot()
            obj.Operations = {};
        end

        function obj = value(obj, target, value)
            obj = append(obj, "value", target, value);
        end

        function obj = choices(obj, target, choices)
            if ischar(choices)
                choices = string(choices);
            elseif iscellstr(choices)
                choices = string(choices);
            elseif ~isstring(choices)
                error("labkit:app:contract:InvalidValue", ...
                    "View snapshot choices must be text.");
            end
            obj = append(obj, "choices", target, reshape(choices, 1, []));
        end

        function obj = limits(obj, target, limits)
            if ~(isnumeric(limits) && isequal(size(limits), [1 2]) && ...
                    all(isfinite(limits)) && limits(1) <= limits(2))
                error("labkit:app:contract:InvalidValue", ...
                    "View snapshot limits must be an increasing finite 1-by-2 row.");
            end
            obj = append(obj, "limits", target, limits);
        end

        function obj = enabled(obj, target, enabled)
            obj = append(obj, "enabled", target, ...
                logicalScalar(enabled, "enabled"));
        end

        function obj = visible(obj, target, visible)
            obj = append(obj, "visible", target, ...
                logicalScalar(visible, "visible"));
        end

        function obj = text(obj, target, text)
            if ~(ischar(text) || (isstring(text) && isscalar(text)))
                error("labkit:app:contract:InvalidValue", ...
                    "View snapshot text must be scalar text.");
            end
            obj = append(obj, "text", target, string(text));
        end

        function obj = filePaths(obj, target, paths)
            if ischar(paths)
                paths = string(paths);
            elseif iscellstr(paths)
                paths = string(paths);
            elseif ~isstring(paths)
                error("labkit:app:contract:InvalidValue", ...
                    "View snapshot files must be a string or cell array.");
            end
            obj = append(obj, "filePaths", ...
                target, reshape(paths, 1, []));
        end

        function obj = fileItemStatuses(obj, target, statuses)
            statuses = textRow(statuses, "file item statuses");
            obj = append(obj, "fileItemStatuses", target, statuses);
        end

        function obj = listSelection(obj, target, selection)
            if ~isa(selection, "labkit.app.event.ListSelection")
                error("labkit:app:contract:InvalidValue", ...
                    "ViewSnapshot listSelection requires ListSelection.");
            end
            obj = append(obj, "listSelection", target, selection);
        end

        function obj = tableCellSelection(obj, target, selection)
            if ~isa(selection, "labkit.app.event.TableCellSelection")
                error("labkit:app:contract:InvalidValue", ...
                    "ViewSnapshot tableCellSelection requires " + ...
                    "TableCellSelection.");
            end
            obj = append(obj, ...
                "tableCellSelection", target, selection);
        end

        function obj = tableData(obj, target, data, varargin)
            if ~(istable(data) || isnumeric(data) || iscell(data))
                error("labkit:app:contract:InvalidValue", ...
                    "View snapshot table data has an unsupported type.");
            end
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.view.Snapshot.tableData", ...
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
            obj = append(obj, "tableData", target, value);
        end

        function obj = renderPlot(obj, target, model, varargin)
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.view.Snapshot.renderPlot", ...
                "ViewRevision", varargin{:});
            revision = optionValue(options, "ViewRevision", 0);
            if ~isnumeric(revision) || ~isscalar(revision) || ...
                    ~isfinite(revision) || revision < 0 || ...
                    revision ~= fix(revision)
                error("labkit:app:contract:InvalidValue", ...
                    "View snapshot ViewRevision must be a " + ...
                    "nonnegative integer.");
            end
            value = struct( ...
                "Model", {model}, ...
                "ViewRevision", double(revision));
            obj = append(obj, "renderPlot", target, value);
        end

        function obj = workspacePage(obj, target, varargin)
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.view.Snapshot.workspacePage", ...
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
                    error("labkit:app:contract:InvalidValue", ...
                        "View snapshot workspace Status must be scalar text.");
                end
                status = string(supplied);
            end
            obj = append(obj, "workspacePage", target, ...
                struct("Enabled", enabled, "Status", status));
        end

        function obj = anchorPath(obj, interaction, points, varargin)
            obj = appendInteraction( ...
                obj, "anchorPath", interaction, points, varargin{:});
        end

        function obj = pairedAnchors(obj, interaction, pointSets, varargin)
            obj = appendInteraction( ...
                obj, "pairedAnchors", interaction, pointSets, varargin{:});
        end

        function obj = pointSlots(obj, interaction, value, varargin)
            obj = appendInteraction( ...
                obj, "pointSlots", interaction, value, varargin{:});
        end

        function obj = rectangle(obj, interaction, position, varargin)
            obj = appendInteraction( ...
                obj, "rectangle", interaction, position, varargin{:});
        end

        function obj = regionSelection(obj, interaction, varargin)
            obj = appendInteraction( ...
                obj, "regionSelection", interaction, [], varargin{:});
        end

        function obj = interval(obj, interaction, range, varargin)
            obj = appendInteraction( ...
                obj, "interval", interaction, range, varargin{:});
        end

        function obj = scaleReference(obj, interaction, endpoints, varargin)
            obj = appendInteraction( ...
                obj, "scaleReference", interaction, endpoints, varargin{:});
        end

        function obj = include(obj, fragment)
            %INCLUDE Compose a feature-owned snapshot fragment.
            if ~isa(fragment, "labkit.app.view.Snapshot")
                error("labkit:app:contract:InvalidValue", ...
                    "View snapshot include requires another Snapshot.");
            end
            for k = 1:numel(fragment.Operations)
                operation = fragment.Operations{k};
                obj = append(obj, operation.Kind, ...
                    operation.Target, operation.Value);
            end
        end
    end

    methods (Access = private)
        function obj = append(obj, kind, target, value)
            target = scalarId(target, "target");
            for k = 1:numel(obj.Operations)
                operation = obj.Operations{k};
                if operation.Kind == kind && operation.Target == target
                    error("labkit:app:contract:DuplicateId", ...
                        "View snapshot repeats %s for target %s.", ...
                        kind, target);
                end
            end
            obj.Operations{end + 1} = struct( ...
                "Kind", kind, ...
                "Target", target, ...
                "Value", value);
        end
    end

    methods (Access = { ...
            ?labkit.app.internal.CompiledDefinition, ...
            ?labkit.app.internal.MatlabPlatformAdapter})
        function operations = operationsForCompiler(obj)
            operations = obj.Operations;
        end
    end

    methods (Access = ?labkit.app.internal.RuntimeKernel)
        function result = overlayForRuntime(base, custom)
            if ~isa(custom, "labkit.app.view.Snapshot")
                error("labkit:app:contract:InvalidValue", ...
                    "View snapshot overlay requires a View snapshot value.");
            end
            operationCount = numel(base.Operations);
            operations = cell(1, operationCount + numel(custom.Operations));
            operations(1:operationCount) = base.Operations;
            for k = 1:numel(custom.Operations)
                incoming = custom.Operations{k};
                replaced = false;
                for n = 1:operationCount
                    current = operations{n};
                    if current.Kind == incoming.Kind && ...
                            current.Target == incoming.Target
                        operations{n} = incoming;
                        replaced = true;
                        break;
                    end
                end
                if ~replaced
                    operationCount = operationCount + 1;
                    operations{operationCount} = incoming;
                end
            end
            operations = operations(1:operationCount);
            result = labkit.app.view.Snapshot();
            result.Operations = operations;
        end
    end
end

function obj = appendInteraction(obj, kind, interaction, value, varargin)
options = labkit.app.internal.OptionParser.parse( ...
    "labkit.app.view.Snapshot." + kind, ...
    ["ImageSize", "Enabled"], varargin{:});
imageSize = optionValue(options, "ImageSize", []);
if ~isempty(imageSize) && ...
        ~(isnumeric(imageSize) && isvector(imageSize) && ...
          numel(imageSize) >= 2 && all(isfinite(imageSize(1:2))) && ...
          all(imageSize(1:2) >= 1))
    error("labkit:app:contract:InvalidValue", ...
        "View snapshot interaction ImageSize must contain finite " + ...
        "positive height and width.");
end
enabled = optionValue(options, "Enabled", true);
enabled = logicalScalar(enabled, "interaction Enabled");
obj = append(obj, kind, interaction, struct( ...
    "Value", {value}, "ImageSize", double(imageSize(:).'), ...
    "Enabled", enabled));
end

function value = scalarId(value, label)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error("labkit:app:contract:InvalidValue", ...
            "View snapshot %s must be scalar text.", label);
    end
    value = string(value);
    if strlength(value) == 0 || ~isvarname(char(value))
        error("labkit:app:contract:InvalidValue", ...
            "View snapshot %s must be a MATLAB identifier.", label);
    end
end

function value = logicalScalar(value, label)
    if ~(islogical(value) && isscalar(value))
        error("labkit:app:contract:InvalidValue", ...
            "View snapshot %s must be a logical scalar.", label);
    end
end

function values = textRow(values, label)
    if ischar(values)
        values = string(values);
    elseif iscellstr(values)
        values = string(values);
    elseif ~isstring(values)
        error("labkit:app:contract:InvalidValue", ...
            "View snapshot %s must be text.", label);
    end
    values = reshape(values, 1, []);
end

function values = logicalRow(values, label)
    if ~(islogical(values) && (isscalar(values) || isrow(values)))
        error("labkit:app:contract:InvalidValue", ...
            "View snapshot %s must be a logical scalar or row.", label);
    end
    values = reshape(values, 1, []);
end

function assertEditableWidth(editable, columns)
    if ~isscalar(editable) && ~isempty(columns) && ...
            numel(editable) ~= numel(columns)
        error("labkit:app:contract:InvalidValue", ...
            "View snapshot ColumnEditable must be scalar or match Columns.");
    end
end

function value = optionValue(options, name, defaultValue)
    value = defaultValue;
    if isfield(options, name)
        value = options.(name);
    end
end
