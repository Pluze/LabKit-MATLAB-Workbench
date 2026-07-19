classdef (Sealed, Hidden) LayoutNode
    %LAYOUT Compose an immutable semantic UI ownership graph.
    %
    % Usage:
    %   node = labkit.app.internal.LayoutNode.button(id, label, command, Name=Value)
    %   node = labkit.app.layout.field(id, Name=Value)
    %   node = labkit.app.layout.rangeField(id, Name=Value)
    %   node = labkit.app.internal.LayoutNode.slider(id, Name=Value)
    %   node = labkit.app.internal.LayoutNode.fileList(id, Name=Value)
    %   node = labkit.app.internal.LayoutNode.plotArea(id, Name=Value)
    %   node = labkit.app.internal.LayoutNode.dataTable(id, Name=Value)
    %   node = labkit.app.internal.LayoutNode.logPanel(id)
    %   node = labkit.app.internal.LayoutNode.statusPanel(id)
    %   node = labkit.app.layout.group(id, children, Name=Value)
    %   node = labkit.app.layout.section(id, title, children, Name=Value)
    %   node = labkit.app.internal.LayoutNode.tab(id, title, children)
    %   workspace = labkit.app.layout.workspace()
    %   layout = labkit.app.layout.workbench(children, Workspace=workspace)
    %
    % Description:
    %   Layout exposes the fourteen audited semantic concepts through one
    %   sealed value class. Constructors reject unknown options and
    %   role-mismatched Command signals. The compiler validates global IDs,
    %   single-parent ownership, nesting, workspace pages, renderers, and
    %   target capabilities without creating MATLAB graphics.
    %
    % Inputs:
    %   id - Nonempty MATLAB identifier unique within one Application.
    %   label - Nonempty reader-facing action text.
    %   title - Nonempty reader-facing section or tab title.
    %   command - labkit.app.StateHandler with Event="action".
    %   children - Row cell array of labkit.app.internal.LayoutNode values.
    %
    % Name-Value Arguments:
    %   ValueChanged - Event="valueChange" StateHandler for field, rangeField,
    %       slider, or plot-area mode changes. Default: empty.
    %   Bind - Optional strict state field path rooted at project or session.
    %       Bound controls need no ValueChanged handler for ordinary updates.
    %       Expressions, indexing, and function calls are not supported.
    %       Default: empty.
    %   SelectionBind - Optional strict state field path for fileList
    %       selection. Default: empty.
    %   CellEdited - Event="tableCellEdit" StateHandler for dataTable.
    %       Default: empty.
    %   SelectionChanged - Event="listSelection" StateHandler for fileList.
    %       Default: empty.
    %   CellSelectionChanged - Event="tableCellSelection" StateHandler for
    %       dataTable. Default: empty.
    %   Columns - Row text array of initial dataTable column labels.
    %       Default: empty.
    %   RowNames - Row text array of initial dataTable row labels.
    %       Default: empty.
    %   ColumnEditable - Logical scalar or row marking editable dataTable
    %       columns. Default: false.
    %   Renderers - Unique renderer-ID row for previewArea. Default: empty.
    %   AxisIds - Unique axes-ID row for previewArea. Default: "main".
    %   Workspace - One workspace Layout for workbench. Default: empty.
    %   Layout - "auto", "vertical", or "horizontal" for group. Default:
    %       "auto".
    %   Collapsible - Logical scalar for section. Default: false.
    %   Expanded - Logical scalar for section. Default: true.
    %   Kind - "text", "numeric", "choice", or "logical" for field.
    %       Default: "text".
    %   Label - Reader-facing field, rangeField, or panner label. Default:
    %       the semantic id.
    %   Mode - "files" or "folder" for fileList. Default: "files".
    %   SelectionMode - "single" or "multiple" for fileList. Default:
    %       "multiple".
    %
    % Outputs:
    %   node - Immutable semantic labkit.app.internal.LayoutNode value.
    %   workspace - Workspace value supporting page and initialPage methods.
    %   layout - Root workbench value accepted by labkit.app.Definition.
    %
    % Layout Methods:
    %   page(id,title,content) - Return a workspace with one additional page.
    %   initialPage(id) - Return a workspace selecting a declared page.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - An option is unknown, duplicated,
    %       or unpaired.
    %   labkit:app:contract:InvalidValue - A value, child, or ID is malformed.
    %   labkit:app:contract:DuplicateId - A workspace page ID repeats.
    %   labkit:app:contract:UnknownReference - InitialPage is undeclared.
    %   labkit:app:contract:CallbackRoleMismatch - A signal has the wrong Role.
    %   labkit:app:contract:UnsupportedOperation - Nesting is illegal.
    %
    % Typical Call:
    %   run = labkit.app.StateHandler("run", @runAnalysis);
    %   controls = {labkit.app.internal.LayoutNode.button("run", "Run", run)};
    %   workspace = labkit.app.layout.workspace( ...
    %       labkit.app.internal.LayoutNode.plotArea("result", Renderers="drawResult"));
    %   layout = labkit.app.layout.workbench(controls, Workspace=workspace);
    %
    % See also labkit.app.Definition, labkit.app.StateHandler,
    %   labkit.app.view.Snapshot

    properties (SetAccess = private)
        Kind (1, 1) string
        Id (1, 1) string
        Children (1, :) cell
        Capabilities (1, :) string
        Signals (1, :) cell
        RendererIds (1, :) string
        AxisIds (1, :) string
        PageIds (1, :) string
        InitialPage (1, 1) string
    end

    properties (SetAccess = private, GetAccess = private)
        Configuration (1, 1) struct
    end

    methods (Access = private)
        function obj = LayoutNode(kind, id, children, capabilities, signals, ...
                rendererIds, axisIds, configuration)
            obj.Kind = kind;
            obj.Id = id;
            obj.Children = children;
            obj.Capabilities = capabilities;
            obj.Signals = signals;
            obj.RendererIds = rendererIds;
            obj.AxisIds = axisIds;
            obj.PageIds = strings(1, 0);
            obj.InitialPage = "";
            obj.Configuration = configuration;
        end
    end

    methods (Static)
        function obj = button(id, label, command, varargin)
            options = labkit.app.internal.OptionParser.parse("labkit.app.layout.button", ...
                ["BusyMessage", "Enabled"], varargin{:});
            validateSignal(command, "action", "button");
            configuration = struct( ...
                "Label", nonemptyText(label, "action label"), ...
                "BusyMessage", scalarText(optionValue( ...
                    options, "BusyMessage", ""), "BusyMessage"), ...
                "Enabled", logicalValue(optionValue( ...
                    options, "Enabled", true), "Enabled"));
            obj = makeLeaf("button", id, ...
                ["enabled", "visible", "text"], {command}, configuration);
        end

        function obj = field(id, varargin)
            names = ["Label", "Kind", "Value", "Choices", "Limits", "Step", "Bind", ...
                "ValueDisplayFormat", "ShowTicks", "Enabled", "ValueChanged"];
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.layout.field", names, varargin{:});
            kind = enumText(optionValue(options, "Kind", "text"), ...
                ["text", "numeric", "choice", "logical"], "field Kind");
            signal = optionValue(options, "ValueChanged", []);
            validateSignal(signal, "valueChange", "field");
            configuration = struct( ...
                "Label", scalarText(optionValue(options, ...
                    "Label", id), "Label"), ...
                "Kind", kind, ...
                "Value", optionValue(options, "Value", []), ...
                "Choices", textRow(optionValue( ...
                    options, "Choices", strings(1, 0)), "Choices"), ...
                "Limits", optionalLimits(optionValue( ...
                    options, "Limits", []), "Limits"), ...
                "Step", optionalPositive(optionValue( ...
                    options, "Step", []), "Step"), ...
                "ValueDisplayFormat", scalarText(optionValue( ...
                    options, "ValueDisplayFormat", ""), ...
                    "ValueDisplayFormat"), ...
                "ShowTicks", logicalValue(optionValue( ...
                    options, "ShowTicks", false), "ShowTicks"), ...
                "Enabled", logicalValue(optionValue( ...
                    options, "Enabled", true), "Enabled"), ...
                "Bind", bindingPath(optionValue(options, "Bind", "")));
            obj = makeLeaf("field", id, ...
                ["value", "choices", "limits", "enabled", "visible", "text"], ...
                signalCell(signal), configuration);
        end

        function obj = rangeField(id, varargin)
            options = labkit.app.internal.OptionParser.parse("labkit.app.layout.rangeField", ...
                ["Label", "Value", "Limits", "Enabled", "Bind", ...
                 "ValueChanged"], varargin{:});
            signal = optionValue(options, "ValueChanged", []);
            validateSignal(signal, "valueChange", "rangeField");
            configuration = struct( ...
                "Label", scalarText(optionValue(options, ...
                    "Label", id), "Label"), ...
                "Value", optionalPair(optionValue( ...
                    options, "Value", []), "Value"), ...
                "Limits", optionalLimits(optionValue( ...
                    options, "Limits", []), "Limits"), ...
                "Enabled", logicalValue(optionValue( ...
                    options, "Enabled", true), "Enabled"), ...
                "Bind", bindingPath(optionValue(options, "Bind", "")));
            obj = makeLeaf("rangeField", id, ...
                ["value", "limits", "enabled", "visible"], ...
                signalCell(signal), configuration);
        end

        function obj = slider(id, varargin)
            names = ["Label", "Value", "Limits", "Step", "ShowTicks", "Bind", ...
                "Enabled", "ValueChanged"];
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.layout.slider", names, varargin{:});
            signal = optionValue(options, "ValueChanged", []);
            validateSignal(signal, "valueChange", "slider");
            limits = optionalLimits(optionValue( ...
                options, "Limits", [0 1]), "Limits");
            value = optionValue(options, "Value", limits(1));
            if ~(isnumeric(value) && isscalar(value) && isfinite(value))
                error("labkit:app:contract:InvalidValue", ...
                    "layout.slider Value must be a finite scalar.");
            end
            configuration = struct( ...
                "Label", scalarText(optionValue(options, ...
                    "Label", id), "Label"), ...
                "Value", double(value), "Limits", limits, ...
                "Step", optionalPositive(optionValue( ...
                    options, "Step", []), "Step"), ...
                "ShowTicks", logicalValue(optionValue( ...
                    options, "ShowTicks", false), "ShowTicks"), ...
                "Enabled", logicalValue(optionValue( ...
                    options, "Enabled", true), "Enabled"), ...
                "Bind", bindingPath(optionValue(options, "Bind", "")));
            obj = makeLeaf("slider", id, ...
                ["value", "limits", "enabled", "visible", "text"], ...
                signalCell(signal), configuration);
        end

        function obj = fileList(id, varargin)
            names = ["Mode", "Filters", "SelectionMode", "MaxFiles", ...
                "FolderWarningThreshold", "ShowStatus", "StartPath", ...
                "ChooseLabel", "FolderLabel", "RecursiveFolderLabel", ...
                "RemoveLabel", "ClearLabel", "EmptyText", "Chosen", ...
                "Removed", "Cleared", "SelectionChanged", "Bind", ...
                "SelectionBind", "SourceRole", "SourceIdPrefix", "Required"];
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.layout.fileList", names, varargin{:});
            signals = {
                roleSignal(options, "Chosen", "listSelection", "fileList")
                roleSignal(options, "Removed", "listSelection", "fileList")
                roleSignal(options, "Cleared", "action", "fileList")
                roleSignal(options, "SelectionChanged", ...
                    "listSelection", "fileList")}.';
            signals = signals(~cellfun(@isempty, signals));
            configuration = struct( ...
                "Mode", enumText(optionValue(options, "Mode", "files"), ...
                    ["files", "folder"], "fileList Mode"), ...
                "Filters", textRow(optionValue( ...
                    options, "Filters", strings(1, 0)), "Filters"), ...
                "SelectionMode", enumText(optionValue( ...
                    options, "SelectionMode", "multiple"), ...
                    ["single", "multiple"], "SelectionMode"), ...
                "MaxFiles", positiveOrInf(optionValue( ...
                    options, "MaxFiles", Inf), "MaxFiles"), ...
                "FolderWarningThreshold", positiveOrInf(optionValue( ...
                    options, "FolderWarningThreshold", 500), ...
                    "FolderWarningThreshold"), ...
                "ShowStatus", logicalValue(optionValue( ...
                    options, "ShowStatus", true), "ShowStatus"), ...
                "StartPath", scalarText(optionValue( ...
                    options, "StartPath", ""), "StartPath"), ...
                "ChooseLabel", scalarText(optionValue( ...
                    options, "ChooseLabel", "Choose"), "ChooseLabel"), ...
                "FolderLabel", scalarText(optionValue( ...
                    options, "FolderLabel", "Choose Folder"), "FolderLabel"), ...
                "RecursiveFolderLabel", scalarText(optionValue(options, ...
                    "RecursiveFolderLabel", "Choose Folder Recursively"), ...
                    "RecursiveFolderLabel"), ...
                "RemoveLabel", scalarText(optionValue( ...
                    options, "RemoveLabel", "Remove"), "RemoveLabel"), ...
                "ClearLabel", scalarText(optionValue( ...
                    options, "ClearLabel", "Clear"), "ClearLabel"), ...
                "EmptyText", scalarText(optionValue( ...
                    options, "EmptyText", "No files selected"), "EmptyText"), ...
                "Bind", bindingPath(optionValue(options, "Bind", "")), ...
                "SelectionBind", bindingPath(optionValue( ...
                    options, "SelectionBind", "")), ...
                "SourceRole", nonemptyText(optionValue( ...
                    options, "SourceRole", id), "SourceRole"), ...
                "SourceIdPrefix", nonemptyText(optionValue( ...
                    options, "SourceIdPrefix", id), "SourceIdPrefix"), ...
                "Required", logicalValue(optionValue( ...
                    options, "Required", true), "Required"));
            obj = makeLeaf("fileList", id, ...
                ["filePaths", "listSelection", ...
                 "enabled", "visible", "text"], ...
                signals, configuration);
        end

        function obj = plotArea(id, varargin)
            names = ["AxisIds", "Renderers", "ViewModes", "ValueChanged"];
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.layout.plotArea", names, varargin{:});
            signal = optionValue(options, "ValueChanged", []);
            validateSignal(signal, "valueChange", "plotArea");
            axisIds = idRow(optionValue(options, "AxisIds", "main"), "axis");
            rendererIds = idRow(optionValue( ...
                options, "Renderers", strings(1, 0)), "renderer");
            configuration = struct("ViewModes", textRow(optionValue( ...
                options, "ViewModes", strings(1, 0)), "ViewModes"));
            obj = labkit.app.internal.LayoutNode("plotArea", normalizeId(id), {}, ...
                ["renderPlot", "value", "visible"], signalCell(signal), ...
                rendererIds, axisIds, configuration);
        end

        function obj = dataTable(id, varargin)
            options = labkit.app.internal.OptionParser.parse("labkit.app.layout.dataTable", ...
                ["Columns", "RowNames", "ColumnEditable", ...
                 "CellEdited", "CellSelectionChanged"], varargin{:});
            signals = {
                roleSignal(options, "CellEdited", ...
                    "tableCellEdit", "dataTable")
                roleSignal(options, "CellSelectionChanged", ...
                    "tableCellSelection", "dataTable")}.';
            signals = signals(~cellfun(@isempty, signals));
            columns = textRow(optionValue( ...
                options, "Columns", strings(1, 0)), "Columns");
            editable = logicalRow(optionValue( ...
                options, "ColumnEditable", false), "ColumnEditable");
            assertEditableWidth(editable, columns);
            configuration = struct( ...
                "Columns", columns, ...
                "RowNames", textRow(optionValue( ...
                    options, "RowNames", strings(1, 0)), "RowNames"), ...
                "ColumnEditable", editable);
            obj = makeLeaf("dataTable", id, ...
                ["tableData", "tableCellSelection", ...
                 "enabled", "visible"], ...
                signals, configuration);
        end

        function obj = logPanel(id)
            obj = makeLeaf("logPanel", id, ["text", "visible"], {}, struct());
        end

        function obj = statusPanel(id)
            obj = makeLeaf( ...
                "statusPanel", id, ["text", "visible"], {}, struct());
        end

        function obj = group(id, children, varargin)
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.layout.group", "Layout", varargin{:});
            children = normalizeChildren(children);
            validateChildKinds(children, controlGroupKinds(), "group");
            configuration = struct("Layout", enumText(optionValue( ...
                options, "Layout", "auto"), ...
                ["auto", "vertical", "horizontal"], "group Layout"));
            obj = makeContainer("group", id, children, configuration);
        end

        function obj = section(id, title, children, varargin)
            options = labkit.app.internal.OptionParser.parse("labkit.app.layout.section", ...
                ["Collapsible", "Expanded"], varargin{:});
            children = normalizeChildren(children);
            validateChildKinds(children, leafAndGroupKinds(), "section");
            configuration = struct( ...
                "Title", nonemptyText(title, "section title"), ...
                "Collapsible", logicalValue(optionValue( ...
                    options, "Collapsible", false), "Collapsible"), ...
                "Expanded", logicalValue(optionValue( ...
                    options, "Expanded", true), "Expanded"));
            obj = makeContainer("section", id, children, configuration);
        end

        function obj = tab(id, title, children)
            children = normalizeChildren(children);
            validateChildKinds(children, ...
                [leafAndGroupKinds(), "section"], "tab");
            obj = makeContainer("tab", id, children, ...
                struct("Title", nonemptyText(title, "tab title")));
        end

        function obj = workspace(varargin)
            content = {};
            if ~isempty(varargin) && isa(varargin{1}, "labkit.app.internal.LayoutNode")
                content = {varargin{1}};
                varargin = varargin(2:end);
            end
            options = labkit.app.internal.OptionParser.parse("labkit.app.layout.workspace", ...
                "PageChanged", varargin{:});
            signal = optionValue(options, "PageChanged", []);
            validateSignal(signal, "valueChange", "workspace");
            if ~isempty(content)
                validateChildKinds(content, workspaceContentKinds(), ...
                    "workspace");
            end
            obj = labkit.app.internal.LayoutNode("workspace", "workspace", content, ...
                strings(1, 0), signalCell(signal), strings(1, 0), ...
                strings(1, 0), struct());
        end

        function obj = workbench(children, varargin)
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.layout.workbench", "Workspace", varargin{:});
            children = normalizeChildren(children);
            validateChildKinds(children, ...
                [leafAndGroupKinds(), "section", "tab"], "workbench");
            workspace = optionValue(options, "Workspace", []);
            if ~isempty(workspace)
                if ~isa(workspace, "labkit.app.internal.LayoutNode") || ...
                        workspace.Kind ~= "workspace"
                    error("labkit:app:contract:InvalidValue", ...
                        "Layout workbench Workspace must be a workspace value.");
                end
                children{end + 1} = workspace;
            end
            obj = labkit.app.internal.LayoutNode("workbench", "application", children, ...
                strings(1, 0), {}, strings(1, 0), strings(1, 0), struct());
        end
    end

    methods
        function obj = page(obj, id, title, content)
            if obj.Kind ~= "workspace"
                error("labkit:app:contract:UnsupportedOperation", ...
                    "Layout page is available only on a workspace.");
            end
            if ~isempty(obj.Children) && isempty(obj.PageIds)
                error("labkit:app:contract:UnsupportedOperation", ...
                    "A single-content workspace cannot also declare " + ...
                    "named pages.");
            end
            id = normalizeId(id);
            if any(obj.PageIds == id)
                error("labkit:app:contract:DuplicateId", ...
                    "Workspace page ID repeats: %s.", id);
            end
            if ~isa(content, "labkit.app.internal.LayoutNode")
                error("labkit:app:contract:InvalidValue", ...
                    "Workspace page content must be a Layout value.");
            end
            validateChildKinds({content}, workspaceContentKinds(), ...
                "workspace page");
            pageNode = labkit.app.internal.LayoutNode("workspacePage", id, {content}, ...
                ["workspacePage"], {}, strings(1, 0), strings(1, 0), ...
                struct("Title", nonemptyText(title, "workspace page title")));
            obj.Children{end + 1} = pageNode;
            obj.PageIds(end + 1) = id;
            if strlength(obj.InitialPage) == 0
                obj.InitialPage = id;
            end
        end

        function obj = initialPage(obj, id)
            if obj.Kind ~= "workspace"
                error("labkit:app:contract:UnsupportedOperation", ...
                    "Layout initialPage is available only on a workspace.");
            end
            id = normalizeId(id);
            if ~any(obj.PageIds == id)
                error("labkit:app:contract:UnknownReference", ...
                    "Workspace initial page is undeclared: %s.", id);
            end
            obj.InitialPage = id;
        end
    end

    methods (Access = ?labkit.app.Definition)
        function nodes = flattenForCompiler(obj)
            chunks = cell(1, 1 + numel(obj.Children));
            chunks{1} = {obj};
            for k = 1:numel(obj.Children)
                chunks{k + 1} = obj.Children{k}.flattenForCompiler();
            end
            nodes = [chunks{:}];
        end

        function value = configurationForCompiler(obj)
            value = obj.Configuration;
        end
    end
end

function obj = makeLeaf(kind, id, capabilities, signals, configuration)
    obj = labkit.app.internal.LayoutNode(kind, normalizeId(id), {}, capabilities, ...
        signals, strings(1, 0), strings(1, 0), configuration);
end

function obj = makeContainer(kind, id, children, configuration)
    obj = labkit.app.internal.LayoutNode(kind, normalizeId(id), children, ...
        strings(1, 0), {}, strings(1, 0), strings(1, 0), configuration);
end

function value = optionValue(options, name, defaultValue)
    value = defaultValue;
    if isfield(options, name)
        value = options.(name);
    end
end

function value = normalizeId(value)
    values = idRow(value, "layout");
    if numel(values) ~= 1
        error("labkit:app:contract:InvalidValue", ...
            "Layout id must be a scalar MATLAB identifier.");
    end
    value = values;
end

function values = idRow(values, label)
    values = textRow(values, label + " IDs");
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
        "plotArea", "dataTable", "logPanel", "statusPanel", "group"];
end

function kinds = controlGroupKinds()
    kinds = ["button", "field", "rangeField", "slider", ...
        "fileList", "group"];
end

function kinds = workspaceContentKinds()
    kinds = [leafAndGroupKinds(), "section"];
end

function signal = roleSignal(options, name, role, target)
    signal = optionValue(options, name, []);
    validateSignal(signal, role, target);
end

function values = signalCell(signal)
    values = {};
    if ~isempty(signal)
        values = {signal};
    end
end

function validateSignal(value, event, target)
    if isempty(value)
        return;
    end
    if ~isa(value, "labkit.app.StateHandler")
        error("labkit:app:contract:InvalidValue", ...
            "%s signal must be a Command value.", target);
    end
    if value.Event ~= event
        error("labkit:app:contract:CallbackRoleMismatch", ...
            "%s event requires StateHandler Event=%s.", target, event);
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
    value = scalarText(value, label);
    if strlength(value) == 0
        error("labkit:app:contract:InvalidValue", ...
            "Layout %s must be nonempty.", label);
    end
end

function value = enumText(value, allowed, label)
    value = scalarText(value, label);
    if ~any(value == allowed)
        error("labkit:app:contract:InvalidValue", ...
            "Layout %s has an unsupported value: %s.", label, value);
    end
end

function value = bindingPath(value)
    value = scalarText(value, "Bind");
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

function state = runAnalysis(state, ~)
    state.finished = true;
end
