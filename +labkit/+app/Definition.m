classdef (Sealed) Definition
    %DEFINITION Compile and launch one immutable App SDK contract.
    %
    % Usage:
    %   app = labkit.app.Definition(Entrypoint=entrypoint, AppId=appId, ...
    %       Title=title, ...
    %       Family=family, AppVersion=version, Updated=date, ...
    %       Requirements=requirements, Workbench=workbench, Name=Value)
    %   fig = app.launch()
    %   requirements = app.launch("requirements")
    %   version = app.launch("version")
    %
    % Description:
    %   Definition validates product metadata, handlers referenced by semantic
    %   layout nodes, renderer ownership, CallbackContext capabilities, global
    %   IDs, event types, and references in one atomic constructor. The static
    %   target graph is cached once. validateViewSnapshot checks a complete
    %   view snapshot against that graph without rebuilding the layout.
    %
    % Required Name-Value Arguments:
    %   Entrypoint - Public MATLAB launch function name as a scalar identifier.
    %   AppId - Stable App identifier beginning with an ASCII letter and
    %       containing letters, digits, underscore, hyphen, or period.
    %   Title - Nonempty reader-facing scalar text.
    %   Family - Nonempty reader-facing scalar text.
    %   AppVersion - Semantic version in X.Y.Z form.
    %   Updated - Product date in YYYY-MM-DD form.
    %   Requirements - Empty value or labkit.contract.requirements result.
    %   Workbench - Root value returned by labkit.app.layout.workbench.
    %
    % Optional Name-Value Arguments:
    %   DisplayName - Nonempty scalar text. Default: Title.
    %   ProjectSchema - labkit.app.project.Schema or empty for a static App.
    %       Default: empty.
    %   CreateSession - Fixed callback session = callback(project,context).
    %       Portable project sources remain opaque; use
    %       context.resolveSourcePaths
    %       while rebuilding transient session data. Default: empty.
    %   BuildView - Fixed callback view = callback(state). Default: empty.
    %   ExtraHandlers - Row cell array of StateHandler values available only
    %       to programmatic dispatch. Layout signals are collected
    %       automatically. Default: {}.
    %   Renderers - Scalar struct mapping renderer IDs to function handles.
    %       Default: struct().
    %   StrictCapabilities - Unique row string array drawn from "dispatch",
    %       "workflow", "diagnostics", "dialogs", "project", "render",
    %       "resources", and "results". Omit this option on the standard
    %       authoring path; all context groups are then available. Supply an
    %       explicit row only for advanced strict capability auditing.
    %   StartupHandler - Event="action" handler queued after the first view
    %       commit. Default: empty.
    %   BuildDebugSample - Fixed callback pack = callback(context). Default:
    %       empty.
    %
    % Outputs:
    %   app - Immutable compiled labkit.app.Definition value.
    %
    % Definition Methods:
    %   launch() - Build and show the native MATLAB App figure.
    %   launch("requirements") - Return declared facade requirements without
    %       creating a figure.
    %   launch("version") - Return product version metadata without creating
    %       a figure.
    %   validateViewSnapshot(view) - Validate target references, target
    %       capabilities, renderer ownership, and complete target coverage.
    %       Returns true or throws before any runtime UI mutation.
    %
    % Errors:
    %   labkit:app:contract:UnknownArgument - A required argument is missing or
    %       an argument is unknown, duplicated, or unpaired.
    %   labkit:app:contract:InvalidValue - Metadata, requirements, workbench,
    %       handlers, renderers, or capabilities are malformed.
    %   labkit:app:contract:DuplicateId - A layout, handler, or renderer ID is
    %       duplicated.
    %   labkit:app:contract:UnknownReference - A renderer or
    %       view target is undeclared.
    %   labkit:app:contract:UnsupportedOperation - A view operation is
    %       not legal for its target.
    %   labkit:app:contract:InvalidValue - A launch request or output count is
    %       unsupported.
    %
    % Typical Call:
    %   run = labkit.app.StateHandler("run", @runAnalysis);
    %   workbench = labkit.app.layout.workbench({ ...
    %       labkit.app.layout.button("run", "Run", run)});
    %   app = labkit.app.Definition( ...
    %       Entrypoint="labkit_Example_app", AppId="example.app", ...
    %       Title="Example", Family="Examples", AppVersion="1.0.0", ...
    %       Updated="2026-07-19", Requirements=[], Workbench=workbench);
    %
    % See also labkit.app.StateHandler, labkit.app.layout.workbench,
    %   labkit.app.view.Snapshot, labkit.contract.requirements

    properties (SetAccess = immutable)
        Entrypoint (1, 1) string
        AppId (1, 1) string
        Title (1, 1) string
        DisplayName (1, 1) string
        Family (1, 1) string
        AppVersion (1, 1) string
        Updated (1, 1) string
        Requirements
        ProjectSchema
        CreateSession
        BuildView
        StartupHandler
        BuildDebugSample
        TargetIds (1, :) string
        GrantedCapabilities (1, :) string
    end

    properties (SetAccess = immutable, GetAccess = private)
        TargetNodes (1, :) cell
        Handlers (1, :) cell
        RendererIds (1, :) string
        PlatformPlan (1, 1) struct
    end

    methods
        function obj = Definition(varargin)
            names = [ ...
                "Entrypoint", "AppId", "Title", "DisplayName", "Family", ...
                "AppVersion", "Updated", "Requirements", "Workbench", ...
                "ProjectSchema", "CreateSession", "BuildView", ...
                "ExtraHandlers", "Renderers", "StrictCapabilities", ...
                "StartupHandler", "BuildDebugSample"];
            options = labkit.app.internal.OptionParser.parse( ...
                "labkit.app.Definition", names, varargin{:});
            required = [ ...
                "Entrypoint", "AppId", "Title", "Family", "AppVersion", ...
                "Updated", "Requirements", "Workbench"];
            for name = required
                if ~isfield(options, name)
                    error("labkit:app:contract:UnknownArgument", ...
                        "labkit.app.Definition requires argument %s.", name);
                end
            end

            obj.Entrypoint = matlabId(options.Entrypoint, "Entrypoint");
            obj.AppId = appId(options.AppId);
            obj.Title = nonemptyText(options.Title, "Title");
            displayName = obj.Title;
            if isfield(options, "DisplayName")
                displayName = nonemptyText( ...
                    options.DisplayName, "DisplayName");
            end
            obj.DisplayName = displayName;
            obj.Family = nonemptyText(options.Family, "Family");
            obj.AppVersion = semanticVersion(options.AppVersion);
            obj.Updated = isoDate(options.Updated);
            obj.Requirements = validateRequirements(options.Requirements);
            obj.ProjectSchema = validateProjectSchema( ...
                optionValue(options, "ProjectSchema", []));
            obj.CreateSession = optionalFixedCallback( ...
                options, "CreateSession", 2, 1);
            obj.BuildView = optionalFixedCallback( ...
                options, "BuildView", 1, 1);
            obj.GrantedCapabilities = validateCapabilities( ...
                optionValue(options, ...
                    "StrictCapabilities", allCapabilities()));
            extraHandlers = validateExtraHandlers( ...
                optionValue(options, "ExtraHandlers", {}));
            obj.StartupHandler = validateStart( ...
                optionValue(options, "StartupHandler", []));
            obj.BuildDebugSample = optionalFixedCallback( ...
                options, "BuildDebugSample", 1, 1);
            [renderers, rendererIds] = validateRenderers( ...
                optionValue(options, "Renderers", struct()));
            obj.RendererIds = rendererIds;

            layout = options.Workbench;
            if ~isa(layout, "labkit.app.internal.LayoutNode") || ...
                    layout.Kind ~= "workbench"
                error("labkit:app:contract:InvalidValue", ...
                    "Definition Workbench must be a workbench Layout value.");
            end
            nodes = layout.flattenForCompiler();
            ids = string(cellfun(@(value) value.Id, nodes, ...
                "UniformOutput", false));
            assertUnique(ids, "Layout");
            targetMask = cellfun(@(value) ...
                ~isempty(value.Capabilities), nodes);
            obj.TargetNodes = nodes(targetMask);
            obj.TargetIds = ids(targetMask);
            obj.Handlers = collectHandlers( ...
                nodes, extraHandlers, obj.StartupHandler);
            validateRendererReferences(nodes, rendererIds, renderers);
            obj.PlatformPlan = compilePlatformPlan(nodes, renderers);
        end

        function accepted = validateViewSnapshot(obj, view)
            if ~isa(view, "labkit.app.view.Snapshot")
                error("labkit:app:contract:InvalidValue", ...
                    "Definition view snapshot must be a " + ...
                    "labkit.app.view.Snapshot value.");
            end
            operations = view.operationsForCompiler();
            covered = false(size(obj.TargetIds));
            for k = 1:numel(operations)
                operation = operations{k};
                index = find(obj.TargetIds == operation.Target, 1);
                if isempty(index)
                    error("labkit:app:contract:UnknownReference", ...
                        "Unknown view target: %s.", operation.Target);
                end
                node = obj.TargetNodes{index};
                if ~any(node.Capabilities == operation.Kind)
                    error("labkit:app:contract:UnsupportedOperation", ...
                        "Target %s does not support %s.", ...
                        operation.Target, operation.Kind);
                end
                if operation.Kind == "renderPlot" && ...
                        (~any(obj.RendererIds == operation.Reference) || ...
                        ~any(node.RendererIds == operation.Reference))
                    error("labkit:app:contract:UnknownReference", ...
                        "Target %s does not declare renderer %s.", ...
                        operation.Target, operation.Reference);
                end
                covered(index) = true;
            end
            missing = obj.TargetIds(~covered);
            if ~isempty(missing)
                error("labkit:app:contract:UnknownReference", ...
                    "Complete view snapshot is missing target: %s.", ...
                    missing(1));
            end
            accepted = true;
        end

        function varargout = launch(obj, varargin)
            %LAUNCH Answer metadata requests or show the native MATLAB App.
            if ~isempty(varargin)
                if numel(varargin) ~= 1 || ...
                        ~(ischar(varargin{1}) || ...
                        (isstring(varargin{1}) && isscalar(varargin{1})))
                    error("labkit:app:contract:InvalidValue", ...
                        "Definition launch accepts one optional request.");
                end
                request = lower(string(varargin{1}));
                if nargout > 1
                    error("labkit:app:contract:InvalidValue", ...
                        "Definition metadata requests return one output.");
                end
                switch request
                    case "requirements"
                        varargout = {obj.Requirements};
                    case "version"
                        varargout = {struct( ...
                            "name", obj.Entrypoint, ...
                            "displayName", obj.DisplayName, ...
                            "family", obj.Family, ...
                            "version", obj.AppVersion, ...
                            "updated", obj.Updated)};
                    otherwise
                        error("labkit:app:contract:InvalidValue", ...
                            "Definition launch request is unsupported: %s.", ...
                            request);
                end
                return;
            end
            if nargout > 1
                error("labkit:app:contract:InvalidValue", ...
                    "Definition launch returns at most one figure.");
            end
            runtime = obj.createMatlabRuntime();
            runtime.showFigure();
            figure = runtime.figureHandle();
            if nargout == 1
                varargout = {figure};
            else
                varargout = {};
            end
        end
    end

    methods (Hidden)
        function ids = handlerIdsForRuntime(obj)
            ids = string(cellfun(@(handler) handler.Id, obj.Handlers, ...
                "UniformOutput", false));
        end

        function tf = hasHandlerForRuntime(obj, handler)
            tf = any(cellfun(@(candidate) ...
                isequaln(candidate, handler), obj.Handlers));
        end

        function runtime = createRuntimeForTesting( ...
                obj, initialProject, backend)
            if nargin < 2
                initialProject = [];
            end
            if nargin < 3
                backend = struct();
            end
            runtime = labkit.app.internal.RuntimeKernel( ...
                obj, initialProject, backend);
        end

        function runtime = createMatlabRuntime(obj, initialProject, backend)
            if nargin < 2
                initialProject = [];
            end
            if nargin < 3
                backend = struct();
            end
            runtime = labkit.app.internal.RuntimeKernel( ...
                obj, initialProject, backend, "matlab");
        end

        function plan = platformPlanForRuntime(obj)
            plan = obj.PlatformPlan;
        end
    end
end

function plan = compilePlatformPlan(nodes, renderers)
    compiled = repmat(struct( ...
        "Kind", "", "Id", "", "ChildIds", strings(1, 0), ...
        "Capabilities", strings(1, 0), "Signals", {{}}, ...
        "RendererIds", strings(1, 0), "AxisIds", strings(1, 0), ...
        "PageIds", strings(1, 0), "InitialPage", "", ...
        "Configuration", struct()), 1, numel(nodes));
    for k = 1:numel(nodes)
        node = nodes{k};
        childIds = string(cellfun(@(child) child.Id, node.Children, ...
            "UniformOutput", false));
        compiled(k) = struct( ...
            "Kind", node.Kind, "Id", node.Id, "ChildIds", childIds, ...
            "Capabilities", node.Capabilities, ...
            "Signals", {node.Signals}, ...
            "RendererIds", node.RendererIds, "AxisIds", node.AxisIds, ...
            "PageIds", node.PageIds, "InitialPage", node.InitialPage, ...
            "Configuration", node.configurationForCompiler());
    end
    plan = struct("Nodes", compiled, "Renderers", renderers);
end

function value = optionValue(options, name, defaultValue)
    value = defaultValue;
    if isfield(options, name)
        value = options.(name);
    end
end

function value = matlabId(value, label)
    value = nonemptyText(value, label);
    if ~isvarname(char(value))
        error("labkit:app:contract:InvalidValue", ...
            "Definition %s must be a MATLAB identifier.", label);
    end
end

function value = appId(value)
    value = nonemptyText(value, "Id");
    if isempty(regexp(char(value), ...
            '^[A-Za-z][A-Za-z0-9_.-]*$', "once"))
        error("labkit:app:contract:InvalidValue", ...
            "Definition AppId has invalid syntax.");
    end
end

function value = nonemptyText(value, label)
    if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
            strlength(string(value)) == 0
        error("labkit:app:contract:InvalidValue", ...
            "Definition %s must be nonempty scalar text.", label);
    end
    value = string(value);
end

function value = semanticVersion(value)
    value = nonemptyText(value, "AppVersion");
    if isempty(regexp(char(value), ...
            '^(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)[.](0|[1-9][0-9]*)$', ...
            "once"))
        error("labkit:app:contract:InvalidValue", ...
            "Definition AppVersion must use X.Y.Z syntax.");
    end
end

function value = isoDate(value)
    value = nonemptyText(value, "Updated");
    if isempty(regexp(char(value), ...
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}$', "once"))
        error("labkit:app:contract:InvalidValue", ...
            "Definition Updated must use YYYY-MM-DD syntax.");
    end
    try
        parsed = datetime(value, "InputFormat", "yyyy-MM-dd");
    catch
        error("labkit:app:contract:InvalidValue", ...
            "Definition Updated is not a valid date.");
    end
    if string(parsed, "yyyy-MM-dd") ~= value
        error("labkit:app:contract:InvalidValue", ...
            "Definition Updated is not a canonical date.");
    end
end

function value = validateRequirements(value)
    if isempty(value)
        return;
    end
    if ~isstruct(value) || ~isscalar(value) || ...
            ~isfield(value, "type") || ...
            string(value.type) ~= "labkit.requirements" || ...
            ~isfield(value, "facades")
        error("labkit:app:contract:InvalidValue", ...
            "Requirements must come from labkit.contract.requirements.");
    end
end

function value = validateProjectSchema(value)
    if ~isempty(value) && ~isa(value, "labkit.app.project.Schema")
        error("labkit:app:contract:InvalidValue", ...
            "Definition ProjectSchema must be a project.Schema or empty.");
    end
end

function callback = optionalFixedCallback(options, name, inputs, outputs)
    callback = [];
    if ~isfield(options, name) || isempty(options.(name))
        return;
    end
    callback = options.(name);
    if ~isa(callback, "function_handle") || ~isscalar(callback) || ...
            nargin(callback) ~= inputs || nargout(callback) ~= outputs
        error("labkit:app:contract:CallbackRoleMismatch", ...
            "Definition %s requires %d inputs and %d outputs.", ...
            name, inputs, outputs);
    end
end

function value = validateStart(value)
    if isempty(value)
        return;
    end
    if ~isa(value, "labkit.app.StateHandler") || value.Event ~= "action"
        error("labkit:app:contract:CallbackRoleMismatch", ...
            "Definition StartupHandler must use Event=action.");
    end
end

function values = validateCapabilities(values)
    if ischar(values)
        values = string(values);
    elseif iscellstr(values)
        values = string(values);
    elseif ~isstring(values)
        error("labkit:app:contract:InvalidValue", ...
            "Definition StrictCapabilities must be text.");
    end
    values = reshape(values, 1, []);
    allowed = allCapabilities();
    if numel(unique(values)) ~= numel(values) || ...
            any(~ismember(values, allowed))
        error("labkit:app:contract:InvalidValue", ...
            "Definition StrictCapabilities contain a duplicate or unknown value.");
    end
end

function values = allCapabilities()
    values = [ ...
        "dispatch", "workflow", "diagnostics", "dialogs", ...
        "project", "render", "resources", "results"];
end

function values = validateExtraHandlers(values)
    if ~iscell(values) || (~isempty(values) && ~isrow(values)) || ...
            ~all(cellfun(@(value) isa(value, "labkit.app.StateHandler"), values))
        error("labkit:app:contract:InvalidValue", ...
            "Definition ExtraHandlers must be a row of StateHandler values.");
    end
end

function [renderers, ids] = validateRenderers(renderers)
    if ~isstruct(renderers) || ~isscalar(renderers)
        error("labkit:app:contract:InvalidValue", ...
            "Definition Renderers must be a scalar struct.");
    end
    ids = string(fieldnames(renderers)).';
    for k = 1:numel(ids)
        callback = renderers.(ids(k));
        if ~isa(callback, "function_handle") || ~isscalar(callback) || ...
                nargin(callback) ~= 2 || nargout(callback) ~= 0
            error("labkit:app:contract:InvalidValue", ...
                "Definition renderer %s must be a fixed two-input, " + ...
                "zero-output function.", ids(k));
        end
    end
end

function assertUnique(values, label)
    if numel(unique(values)) ~= numel(values)
        error("labkit:app:contract:DuplicateId", ...
            "%s IDs must be globally unique.", label);
    end
end

function handlers = collectHandlers(nodes, extraHandlers, start)
    handlers = {};
    for k = 1:numel(nodes)
        signals = nodes{k}.Signals;
        for s = 1:numel(signals)
            handlers{end + 1} = signals{s};
        end
    end
    handlers = [handlers, extraHandlers];
    if ~isempty(start)
        handlers{end + 1} = start;
    end
    handlers = uniqueCommands(handlers);
end

function values = uniqueCommands(values)
    uniqueValues = {};
    for k = 1:numel(values)
        value = values{k};
        sameId = find(cellfun(@(candidate) candidate.Id == value.Id, ...
            uniqueValues), 1);
        if isempty(sameId)
            uniqueValues{end + 1} = value;
        elseif ~isequaln(uniqueValues{sameId}, value)
            error("labkit:app:contract:DuplicateId", ...
                "StateHandler ID %s has conflicting values.", value.Id);
        end
    end
    values = uniqueValues;
end

function validateRendererReferences(nodes, rendererIds, ~)
    for k = 1:numel(nodes)
        missing = setdiff(nodes{k}.RendererIds, rendererIds);
        if ~isempty(missing)
            error("labkit:app:contract:UnknownReference", ...
                "Layout preview references an undeclared renderer: %s.", ...
                missing(1));
        end
    end
end

function state = runAnalysis(state, ~)
    state.finished = true;
end
