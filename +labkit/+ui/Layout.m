classdef (Sealed) Layout
    %LAYOUT Compose an immutable semantic UI ownership graph.
    %
    % Usage:
    %   node = labkit.ui.Layout.action(id, label, command, Name=Value)
    %   node = labkit.ui.Layout.field(id, Name=Value)
    %   node = labkit.ui.Layout.rangeField(id, Name=Value)
    %   node = labkit.ui.Layout.panner(id, Name=Value)
    %   node = labkit.ui.Layout.filePanel(id, Name=Value)
    %   node = labkit.ui.Layout.previewArea(id, Name=Value)
    %   node = labkit.ui.Layout.resultTable(id, Name=Value)
    %   node = labkit.ui.Layout.logPanel(id)
    %   node = labkit.ui.Layout.statusPanel(id)
    %   node = labkit.ui.Layout.group(id, children, Name=Value)
    %   node = labkit.ui.Layout.section(id, title, children, Name=Value)
    %   node = labkit.ui.Layout.tab(id, title, children)
    %   workspace = labkit.ui.Layout.workspace()
    %   layout = labkit.ui.Layout.workbench(children, Workspace=workspace)
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
    %   command - labkit.ui.Command with Role="invoke".
    %   children - Row cell array of labkit.ui.Layout values.
    %
    % Name-Value Arguments:
    %   Changed - Role="value" Command for field, rangeField, or panner.
    %       Default: empty.
    %   Edited - Role="tableEdit" Command for resultTable. Default: empty.
    %   SelectionChanged - Role="selection" Command for filePanel or
    %       resultTable. Default: empty.
    %   Renderers - Unique renderer-ID row for previewArea. Default: empty.
    %   AxisIds - Unique axes-ID row for previewArea. Default: "main".
    %   Workspace - One workspace Layout for workbench. Default: empty.
    %   Layout - "auto", "vertical", or "horizontal" for group. Default:
    %       "auto".
    %   Collapsible - Logical scalar for section. Default: false.
    %   Expanded - Logical scalar for section. Default: true.
    %   Kind - "text", "numeric", "choice", or "logical" for field.
    %       Default: "text".
    %   Mode - "files" or "folder" for filePanel. Default: "files".
    %   SelectionMode - "single" or "multiple" for filePanel. Default:
    %       "multiple".
    %
    % Outputs:
    %   node - Immutable semantic labkit.ui.Layout value.
    %   workspace - Workspace value supporting page and initialPage methods.
    %   layout - Root workbench value accepted by labkit.ui.Application.
    %
    % Layout Methods:
    %   page(id,title,content) - Return a workspace with one additional page.
    %   initialPage(id) - Return a workspace selecting a declared page.
    %
    % Errors:
    %   labkit:ui:contract:UnknownArgument - An option is unknown, duplicated,
    %       or unpaired.
    %   labkit:ui:contract:InvalidValue - A value, child, or ID is malformed.
    %   labkit:ui:contract:DuplicateId - A workspace page ID repeats.
    %   labkit:ui:contract:UnknownReference - InitialPage is undeclared.
    %   labkit:ui:contract:CallbackRoleMismatch - A signal has the wrong Role.
    %   labkit:ui:contract:UnsupportedOperation - Nesting is illegal.
    %
    % Typical Call:
    %   run = labkit.ui.Command("run", @runAnalysis);
    %   controls = {labkit.ui.Layout.action("run", "Run", run)};
    %   workspace = labkit.ui.Layout.workspace( ...
    %       labkit.ui.Layout.previewArea("result", Renderers="drawResult"));
    %   layout = labkit.ui.Layout.workbench(controls, Workspace=workspace);
    %
    % See also labkit.ui.Application, labkit.ui.Command,
    %   labkit.ui.Presentation

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
        function obj = Layout(kind, id, children, capabilities, signals, ...
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
        function obj = action(id, label, command, varargin)
            options = parseContractOptions("labkit.ui.Layout.action", ...
                ["BusyMessage", "Enabled"], varargin{:});
            validateSignal(command, "invoke", "action");
            configuration = struct( ...
                "Label", nonemptyText(label, "action label"), ...
                "BusyMessage", scalarText(optionValue( ...
                    options, "BusyMessage", ""), "BusyMessage"), ...
                "Enabled", logicalValue(optionValue( ...
                    options, "Enabled", true), "Enabled"));
            obj = makeLeaf("action", id, ...
                ["enabled", "visible", "text"], {command}, configuration);
        end

        function obj = field(id, varargin)
            names = ["Kind", "Value", "Choices", "Limits", "Step", ...
                "ValueDisplayFormat", "ShowTicks", "Enabled", "Changed"];
            options = parseContractOptions( ...
                "labkit.ui.Layout.field", names, varargin{:});
            kind = enumText(optionValue(options, "Kind", "text"), ...
                ["text", "numeric", "choice", "logical"], "field Kind");
            signal = optionValue(options, "Changed", []);
            validateSignal(signal, "value", "field");
            configuration = struct( ...
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
                    options, "Enabled", true), "Enabled"));
            obj = makeLeaf("field", id, ...
                ["value", "choices", "limits", "enabled", "visible", "text"], ...
                signalCell(signal), configuration);
        end

        function obj = rangeField(id, varargin)
            options = parseContractOptions("labkit.ui.Layout.rangeField", ...
                ["Value", "Limits", "Enabled", "Changed"], varargin{:});
            signal = optionValue(options, "Changed", []);
            validateSignal(signal, "value", "rangeField");
            configuration = struct( ...
                "Value", optionalPair(optionValue( ...
                    options, "Value", []), "Value"), ...
                "Limits", optionalLimits(optionValue( ...
                    options, "Limits", []), "Limits"), ...
                "Enabled", logicalValue(optionValue( ...
                    options, "Enabled", true), "Enabled"));
            obj = makeLeaf("rangeField", id, ...
                ["value", "limits", "enabled", "visible"], ...
                signalCell(signal), configuration);
        end

        function obj = panner(id, varargin)
            names = ["Value", "Limits", "Step", "ShowTicks", ...
                "Enabled", "Changed"];
            options = parseContractOptions( ...
                "labkit.ui.Layout.panner", names, varargin{:});
            signal = optionValue(options, "Changed", []);
            validateSignal(signal, "value", "panner");
            limits = optionalLimits(optionValue( ...
                options, "Limits", [0 1]), "Limits");
            value = optionValue(options, "Value", limits(1));
            if ~(isnumeric(value) && isscalar(value) && isfinite(value))
                error("labkit:ui:contract:InvalidValue", ...
                    "Layout panner Value must be a finite scalar.");
            end
            configuration = struct( ...
                "Value", double(value), "Limits", limits, ...
                "Step", optionalPositive(optionValue( ...
                    options, "Step", []), "Step"), ...
                "ShowTicks", logicalValue(optionValue( ...
                    options, "ShowTicks", false), "ShowTicks"), ...
                "Enabled", logicalValue(optionValue( ...
                    options, "Enabled", true), "Enabled"));
            obj = makeLeaf("panner", id, ...
                ["value", "limits", "enabled", "visible", "text"], ...
                signalCell(signal), configuration);
        end

        function obj = filePanel(id, varargin)
            names = ["Mode", "Filters", "SelectionMode", "MaxFiles", ...
                "FolderWarningThreshold", "ShowStatus", "StartPath", ...
                "ChooseLabel", "FolderLabel", "RecursiveFolderLabel", ...
                "RemoveLabel", "ClearLabel", "EmptyText", "Chosen", ...
                "Removed", "Cleared", "SelectionChanged"];
            options = parseContractOptions( ...
                "labkit.ui.Layout.filePanel", names, varargin{:});
            signals = {
                roleSignal(options, "Chosen", "selection", "filePanel")
                roleSignal(options, "Removed", "selection", "filePanel")
                roleSignal(options, "Cleared", "invoke", "filePanel")
                roleSignal(options, "SelectionChanged", ...
                    "selection", "filePanel")}.';
            signals = signals(~cellfun(@isempty, signals));
            configuration = struct( ...
                "Mode", enumText(optionValue(options, "Mode", "files"), ...
                    ["files", "folder"], "filePanel Mode"), ...
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
                    options, "EmptyText", "No files selected"), "EmptyText"));
            obj = makeLeaf("filePanel", id, ...
                ["files", "selection", "enabled", "visible", "text"], ...
                signals, configuration);
        end

        function obj = previewArea(id, varargin)
            names = ["AxisIds", "Renderers", "ViewModes", "ModeChanged"];
            options = parseContractOptions( ...
                "labkit.ui.Layout.previewArea", names, varargin{:});
            signal = optionValue(options, "ModeChanged", []);
            validateSignal(signal, "value", "previewArea");
            axisIds = idRow(optionValue(options, "AxisIds", "main"), "axis");
            rendererIds = idRow(optionValue( ...
                options, "Renderers", strings(1, 0)), "renderer");
            configuration = struct("ViewModes", textRow(optionValue( ...
                options, "ViewModes", strings(1, 0)), "ViewModes"));
            obj = labkit.ui.Layout("previewArea", normalizeId(id), {}, ...
                ["plot", "value", "visible"], signalCell(signal), ...
                rendererIds, axisIds, configuration);
        end

        function obj = resultTable(id, varargin)
            options = parseContractOptions("labkit.ui.Layout.resultTable", ...
                ["Edited", "SelectionChanged"], varargin{:});
            signals = {
                roleSignal(options, "Edited", "tableEdit", "resultTable")
                roleSignal(options, "SelectionChanged", ...
                    "selection", "resultTable")}.';
            signals = signals(~cellfun(@isempty, signals));
            obj = makeLeaf("resultTable", id, ...
                ["table", "selection", "enabled", "visible"], ...
                signals, struct());
        end

        function obj = logPanel(id)
            obj = makeLeaf("logPanel", id, ["text", "visible"], {}, struct());
        end

        function obj = statusPanel(id)
            obj = makeLeaf( ...
                "statusPanel", id, ["text", "visible"], {}, struct());
        end

        function obj = group(id, children, varargin)
            options = parseContractOptions( ...
                "labkit.ui.Layout.group", "Layout", varargin{:});
            children = normalizeChildren(children);
            validateChildKinds(children, controlGroupKinds(), "group");
            configuration = struct("Layout", enumText(optionValue( ...
                options, "Layout", "auto"), ...
                ["auto", "vertical", "horizontal"], "group Layout"));
            obj = makeContainer("group", id, children, configuration);
        end

        function obj = section(id, title, children, varargin)
            options = parseContractOptions("labkit.ui.Layout.section", ...
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
            if ~isempty(varargin) && isa(varargin{1}, "labkit.ui.Layout")
                content = {varargin{1}};
                varargin = varargin(2:end);
            end
            options = parseContractOptions("labkit.ui.Layout.workspace", ...
                "PageChanged", varargin{:});
            signal = optionValue(options, "PageChanged", []);
            validateSignal(signal, "value", "workspace");
            if ~isempty(content)
                validateChildKinds(content, workspaceContentKinds(), ...
                    "workspace");
            end
            obj = labkit.ui.Layout("workspace", "workspace", content, ...
                strings(1, 0), signalCell(signal), strings(1, 0), ...
                strings(1, 0), struct());
        end

        function obj = workbench(children, varargin)
            options = parseContractOptions( ...
                "labkit.ui.Layout.workbench", "Workspace", varargin{:});
            children = normalizeChildren(children);
            validateChildKinds(children, ...
                [leafAndGroupKinds(), "section", "tab"], "workbench");
            workspace = optionValue(options, "Workspace", []);
            if ~isempty(workspace)
                if ~isa(workspace, "labkit.ui.Layout") || ...
                        workspace.Kind ~= "workspace"
                    error("labkit:ui:contract:InvalidValue", ...
                        "Layout workbench Workspace must be a workspace value.");
                end
                children{end + 1} = workspace;
            end
            obj = labkit.ui.Layout("workbench", "application", children, ...
                strings(1, 0), {}, strings(1, 0), strings(1, 0), struct());
        end
    end

    methods
        function obj = page(obj, id, title, content)
            if obj.Kind ~= "workspace"
                error("labkit:ui:contract:UnsupportedOperation", ...
                    "Layout page is available only on a workspace.");
            end
            if ~isempty(obj.Children) && isempty(obj.PageIds)
                error("labkit:ui:contract:UnsupportedOperation", ...
                    "A single-content workspace cannot also declare " + ...
                    "named pages.");
            end
            id = normalizeId(id);
            if any(obj.PageIds == id)
                error("labkit:ui:contract:DuplicateId", ...
                    "Workspace page ID repeats: %s.", id);
            end
            if ~isa(content, "labkit.ui.Layout")
                error("labkit:ui:contract:InvalidValue", ...
                    "Workspace page content must be a Layout value.");
            end
            validateChildKinds({content}, workspaceContentKinds(), ...
                "workspace page");
            pageNode = labkit.ui.Layout("workspacePage", id, {content}, ...
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
                error("labkit:ui:contract:UnsupportedOperation", ...
                    "Layout initialPage is available only on a workspace.");
            end
            id = normalizeId(id);
            if ~any(obj.PageIds == id)
                error("labkit:ui:contract:UnknownReference", ...
                    "Workspace initial page is undeclared: %s.", id);
            end
            obj.InitialPage = id;
        end
    end

    methods (Access = ?labkit.ui.Application)
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
    obj = labkit.ui.Layout(kind, normalizeId(id), {}, capabilities, ...
        signals, strings(1, 0), strings(1, 0), configuration);
end

function obj = makeContainer(kind, id, children, configuration)
    obj = labkit.ui.Layout(kind, normalizeId(id), children, ...
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
        error("labkit:ui:contract:InvalidValue", ...
            "Layout id must be a scalar MATLAB identifier.");
    end
    value = values;
end

function values = idRow(values, label)
    values = textRow(values, label + " IDs");
    if any(strlength(values) == 0) || ...
            any(~arrayfun(@(value) isvarname(char(value)), values)) || ...
            numel(unique(values)) ~= numel(values)
        error("labkit:ui:contract:InvalidValue", ...
            "Layout %s IDs must be unique MATLAB identifiers.", label);
    end
end

function children = normalizeChildren(children)
    if ~iscell(children) || (~isempty(children) && ~isrow(children)) || ...
            ~all(cellfun(@(value) isa(value, "labkit.ui.Layout"), children))
        error("labkit:ui:contract:InvalidValue", ...
            "Layout children must be a row cell array of Layout values.");
    end
end

function validateChildKinds(children, allowed, parent)
    for k = 1:numel(children)
        if ~any(children{k}.Kind == allowed)
            error("labkit:ui:contract:UnsupportedOperation", ...
                "%s cannot own a %s Layout.", parent, children{k}.Kind);
        end
    end
end

function kinds = leafAndGroupKinds()
    kinds = ["action", "field", "rangeField", "panner", "filePanel", ...
        "previewArea", "resultTable", "logPanel", "statusPanel", "group"];
end

function kinds = controlGroupKinds()
    kinds = ["action", "field", "rangeField", "panner", ...
        "filePanel", "group"];
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

function validateSignal(value, role, target)
    if isempty(value)
        return;
    end
    if ~isa(value, "labkit.ui.Command")
        error("labkit:ui:contract:InvalidValue", ...
            "%s signal must be a Command value.", target);
    end
    if value.Role ~= role
        error("labkit:ui:contract:CallbackRoleMismatch", ...
            "%s signal requires Command Role=%s.", target, role);
    end
end

function value = scalarText(value, label)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error("labkit:ui:contract:InvalidValue", ...
            "Layout %s must be scalar text.", label);
    end
    value = string(value);
end

function value = nonemptyText(value, label)
    value = scalarText(value, label);
    if strlength(value) == 0
        error("labkit:ui:contract:InvalidValue", ...
            "Layout %s must be nonempty.", label);
    end
end

function value = enumText(value, allowed, label)
    value = scalarText(value, label);
    if ~any(value == allowed)
        error("labkit:ui:contract:InvalidValue", ...
            "Layout %s has an unsupported value: %s.", label, value);
    end
end

function values = textRow(values, label)
    if ischar(values)
        values = string(values);
    elseif iscellstr(values)
        values = string(values);
    elseif ~isstring(values)
        error("labkit:ui:contract:InvalidValue", ...
            "Layout %s must be text.", label);
    end
    values = reshape(values, 1, []);
end

function value = logicalValue(value, label)
    if ~(islogical(value) && isscalar(value))
        error("labkit:ui:contract:InvalidValue", ...
            "Layout %s must be a logical scalar.", label);
    end
end

function value = optionalLimits(value, label)
    if isempty(value)
        value = [];
        return;
    end
    if ~(isnumeric(value) && isequal(size(value), [1 2]) && ...
            all(isfinite(value)) && value(1) <= value(2))
        error("labkit:ui:contract:InvalidValue", ...
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
        error("labkit:ui:contract:InvalidValue", ...
            "Layout %s must be a finite 1-by-2 row.", label);
    end
    value = double(value);
end

function value = optionalPositive(value, label)
    if isempty(value)
        return;
    end
    if ~(isnumeric(value) && isscalar(value) && isfinite(value) && value > 0)
        error("labkit:ui:contract:InvalidValue", ...
            "Layout %s must be a positive scalar.", label);
    end
    value = double(value);
end

function value = positiveOrInf(value, label)
    if ~(isnumeric(value) && isscalar(value) && value > 0 && ...
            (isfinite(value) || isinf(value)))
        error("labkit:ui:contract:InvalidValue", ...
            "Layout %s must be a positive scalar or Inf.", label);
    end
    value = double(value);
end

function state = runAnalysis(state, ~)
    state.finished = true;
end
