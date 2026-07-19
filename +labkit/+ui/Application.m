classdef (Sealed) Application
    %APPLICATION Compile one immutable explicit App contract.
    %
    % Usage:
    %   app = labkit.ui.Application(Command=command, Id=id, Title=title, ...
    %       Family=family, AppVersion=version, Updated=date, ...
    %       Requirements=requirements, Layout=layout, Name=Value)
    %
    % Description:
    %   Application validates product metadata, Commands collected from Layout
    %   signals, renderer ownership,
    %   declared RuntimeContext capabilities, Layout ownership, global IDs,
    %   signal roles, and references in one atomic constructor. The immutable
    %   static target graph is cached once. validatePresentation checks a
    %   complete snapshot against that graph without re-flattening Layout.
    %
    % Required Name-Value Arguments:
    %   Command - Public MATLAB launch function name as a scalar identifier.
    %   Id - Stable App identifier beginning with an ASCII letter and
    %       containing letters, digits, underscore, hyphen, or period.
    %   Title - Nonempty reader-facing scalar text.
    %   Family - Nonempty reader-facing scalar text.
    %   AppVersion - Semantic version in X.Y.Z form.
    %   Updated - Product date in YYYY-MM-DD form.
    %   Requirements - Empty value or labkit.contract.requirements result.
    %   Layout - Root workbench labkit.ui.Layout value.
    %
    % Optional Name-Value Arguments:
    %   DisplayName - Nonempty scalar text. Default: Title.
    %   Project - labkit.ui.ProjectContract value or empty for a static App.
    %       Default: empty.
    %   Session - Fixed callback session = createSession(project). Default:
    %       empty.
    %   Present - Fixed callback view = present(state). Default: empty.
    %   ExtraCommands - Row cell array of labkit.ui.Command values available
    %       only to programmatic dispatch. Layout signals are collected
    %       automatically. Default: {}.
    %   Renderers - Scalar struct mapping renderer IDs to function handles.
    %       Default: struct().
    %   Capabilities - Unique row string array drawn from "dispatch",
    %       "workflow", "diagnostics", "dialogs", "project", "render",
    %       "resources", and "results". Omit this option on the standard
    %       authoring path; all context groups are then available. Supply an
    %       explicit row only for advanced strict capability auditing.
    %   Start - Declared Role="invoke" Command queued after the first
    %       presentation. Default: empty.
    %   DebugSample - Fixed callback pack = writeSample(context). Default:
    %       empty.
    %
    % Outputs:
    %   app - Immutable compiled labkit.ui.Application value.
    %
    % Application Methods:
    %   validatePresentation(view) - Validate target references, target
    %       capabilities, renderer ownership, and complete target coverage.
    %       Returns true or throws before any runtime UI mutation.
    %
    % Errors:
    %   labkit:ui:contract:UnknownArgument - A required argument is missing or
    %       an argument is unknown, duplicated, or unpaired.
    %   labkit:ui:contract:InvalidValue - Metadata, requirements, Layout,
    %       ExtraCommands, renderers, or capabilities are malformed.
    %   labkit:ui:contract:DuplicateId - A Layout, Command, or renderer ID is
    %       duplicated.
    %   labkit:ui:contract:UnknownReference - A renderer or
    %       presentation target is undeclared.
    %   labkit:ui:contract:UnsupportedOperation - A presentation operation is
    %       not legal for its target.
    %
    % Typical Call:
    %   run = labkit.ui.Command("run", @runAnalysis);
    %   layout = labkit.ui.Layout.workbench({ ...
    %       labkit.ui.Layout.action("run", "Run", run)});
    %   app = labkit.ui.Application( ...
    %       Command="labkit_Example_app", Id="example.app", ...
    %       Title="Example", Family="Examples", AppVersion="1.0.0", ...
    %       Updated="2026-07-19", Requirements=[], Layout=layout);
    %   view = labkit.ui.Presentation().enabled("run", true);
    %
    % See also labkit.ui.Command, labkit.ui.Layout,
    %   labkit.ui.Presentation, labkit.contract.requirements

    properties (SetAccess = immutable)
        Command (1, 1) string
        Id (1, 1) string
        Title (1, 1) string
        DisplayName (1, 1) string
        Family (1, 1) string
        AppVersion (1, 1) string
        Updated (1, 1) string
        Requirements
        Project
        Session
        Present
        Start
        DebugSample
        TargetIds (1, :) string
        Capabilities (1, :) string
    end

    properties (SetAccess = immutable, GetAccess = private)
        TargetNodes (1, :) cell
        Commands (1, :) cell
        RendererIds (1, :) string
        PlatformPlan (1, 1) struct
    end

    methods
        function obj = Application(varargin)
            names = [ ...
                "Command", "Id", "Title", "DisplayName", "Family", ...
                "AppVersion", "Updated", "Requirements", "Layout", ...
                "Project", "Session", "Present", "ExtraCommands", "Renderers", ...
                "Capabilities", "Start", "DebugSample"];
            options = parseContractOptions( ...
                "labkit.ui.Application", names, varargin{:});
            required = [ ...
                "Command", "Id", "Title", "Family", "AppVersion", ...
                "Updated", "Requirements", "Layout"];
            for name = required
                if ~isfield(options, name)
                    error("labkit:ui:contract:UnknownArgument", ...
                        "labkit.ui.Application requires argument %s.", name);
                end
            end

            obj.Command = matlabId(options.Command, "Command");
            obj.Id = appId(options.Id);
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
            obj.Project = validateProjectContract( ...
                optionValue(options, "Project", []));
            obj.Session = optionalFixedCallback( ...
                options, "Session", 1, 1);
            obj.Present = optionalFixedCallback( ...
                options, "Present", 1, 1);
            obj.Capabilities = validateCapabilities( ...
                optionValue(options, "Capabilities", allCapabilities()));
            extraCommands = validateExtraCommands( ...
                optionValue(options, "ExtraCommands", {}));
            obj.Start = validateStart( ...
                optionValue(options, "Start", []));
            obj.DebugSample = optionalFixedCallback( ...
                options, "DebugSample", 1, 1);
            [renderers, rendererIds] = validateRenderers( ...
                optionValue(options, "Renderers", struct()));
            obj.RendererIds = rendererIds;

            layout = options.Layout;
            if ~isa(layout, "labkit.ui.Layout") || ...
                    layout.Kind ~= "workbench"
                error("labkit:ui:contract:InvalidValue", ...
                    "Application Layout must be a workbench Layout value.");
            end
            nodes = layout.flattenForCompiler();
            ids = string(cellfun(@(value) value.Id, nodes, ...
                "UniformOutput", false));
            assertUnique(ids, "Layout");
            targetMask = cellfun(@(value) ...
                ~isempty(value.Capabilities), nodes);
            obj.TargetNodes = nodes(targetMask);
            obj.TargetIds = ids(targetMask);
            obj.Commands = collectCommands(nodes, extraCommands, obj.Start);
            validateRendererReferences(nodes, rendererIds, renderers);
            obj.PlatformPlan = compilePlatformPlan(nodes, renderers);
        end

        function accepted = validatePresentation(obj, view)
            if ~isa(view, "labkit.ui.Presentation")
                error("labkit:ui:contract:InvalidValue", ...
                    "Application presentation must be a Presentation value.");
            end
            operations = view.operationsForCompiler();
            covered = false(size(obj.TargetIds));
            for k = 1:numel(operations)
                operation = operations{k};
                index = find(obj.TargetIds == operation.Target, 1);
                if isempty(index)
                    error("labkit:ui:contract:UnknownReference", ...
                        "Unknown presentation target: %s.", operation.Target);
                end
                node = obj.TargetNodes{index};
                if ~any(node.Capabilities == operation.Kind)
                    error("labkit:ui:contract:UnsupportedOperation", ...
                        "Target %s does not support %s.", ...
                        operation.Target, operation.Kind);
                end
                if operation.Kind == "plot" && ...
                        (~any(obj.RendererIds == operation.Reference) || ...
                        ~any(node.RendererIds == operation.Reference))
                    error("labkit:ui:contract:UnknownReference", ...
                        "Target %s does not declare renderer %s.", ...
                        operation.Target, operation.Reference);
                end
                covered(index) = true;
            end
            missing = obj.TargetIds(~covered);
            if ~isempty(missing)
                error("labkit:ui:contract:UnknownReference", ...
                    "Complete presentation is missing target: %s.", ...
                    missing(1));
            end
            accepted = true;
        end
    end

    methods (Hidden)
        function ids = commandIdsForRuntime(obj)
            ids = string(cellfun(@(command) command.Id, obj.Commands, ...
                "UniformOutput", false));
        end

        function tf = hasCommandForRuntime(obj, command)
            tf = any(cellfun(@(candidate) ...
                isequaln(candidate, command), obj.Commands));
        end

        function runtime = createRuntimeForTesting( ...
                obj, initialProject, backend)
            if nargin < 2
                initialProject = [];
            end
            if nargin < 3
                backend = struct();
            end
            runtime = labkit.ui.RuntimeKernel( ...
                obj, initialProject, backend);
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
        error("labkit:ui:contract:InvalidValue", ...
            "Application %s must be a MATLAB identifier.", label);
    end
end

function value = appId(value)
    value = nonemptyText(value, "Id");
    if isempty(regexp(char(value), ...
            '^[A-Za-z][A-Za-z0-9_.-]*$', "once"))
        error("labkit:ui:contract:InvalidValue", ...
            "Application Id has invalid syntax.");
    end
end

function value = nonemptyText(value, label)
    if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
            strlength(string(value)) == 0
        error("labkit:ui:contract:InvalidValue", ...
            "Application %s must be nonempty scalar text.", label);
    end
    value = string(value);
end

function value = semanticVersion(value)
    value = nonemptyText(value, "AppVersion");
    if isempty(regexp(char(value), ...
            '^(0|[1-9][0-9]*)[.](0|[1-9][0-9]*)[.](0|[1-9][0-9]*)$', ...
            "once"))
        error("labkit:ui:contract:InvalidValue", ...
            "Application AppVersion must use X.Y.Z syntax.");
    end
end

function value = isoDate(value)
    value = nonemptyText(value, "Updated");
    if isempty(regexp(char(value), ...
            '^[0-9]{4}-[0-9]{2}-[0-9]{2}$', "once"))
        error("labkit:ui:contract:InvalidValue", ...
            "Application Updated must use YYYY-MM-DD syntax.");
    end
    try
        parsed = datetime(value, "InputFormat", "yyyy-MM-dd");
    catch
        error("labkit:ui:contract:InvalidValue", ...
            "Application Updated is not a valid date.");
    end
    if string(parsed, "yyyy-MM-dd") ~= value
        error("labkit:ui:contract:InvalidValue", ...
            "Application Updated is not a canonical date.");
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
        error("labkit:ui:contract:InvalidValue", ...
            "Requirements must come from labkit.contract.requirements.");
    end
end

function value = validateProjectContract(value)
    if ~isempty(value) && ~isa(value, "labkit.ui.ProjectContract")
        error("labkit:ui:contract:InvalidValue", ...
            "Application Project must be a ProjectContract value or empty.");
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
        error("labkit:ui:contract:CallbackRoleMismatch", ...
            "Application %s requires %d inputs and %d outputs.", ...
            name, inputs, outputs);
    end
end

function value = validateStart(value)
    if isempty(value)
        return;
    end
    if ~isa(value, "labkit.ui.Command") || value.Role ~= "invoke"
        error("labkit:ui:contract:CallbackRoleMismatch", ...
            "Application Start must be a Role=invoke Command.");
    end
end

function values = validateCapabilities(values)
    if ischar(values)
        values = string(values);
    elseif iscellstr(values)
        values = string(values);
    elseif ~isstring(values)
        error("labkit:ui:contract:InvalidValue", ...
            "Application Capabilities must be text.");
    end
    values = reshape(values, 1, []);
    allowed = allCapabilities();
    if numel(unique(values)) ~= numel(values) || ...
            any(~ismember(values, allowed))
        error("labkit:ui:contract:InvalidValue", ...
            "Application Capabilities contain a duplicate or unknown value.");
    end
end

function values = allCapabilities()
    values = [ ...
        "dispatch", "workflow", "diagnostics", "dialogs", ...
        "project", "render", "resources", "results"];
end

function values = validateExtraCommands(values)
    if ~iscell(values) || (~isempty(values) && ~isrow(values)) || ...
            ~all(cellfun(@(value) isa(value, "labkit.ui.Command"), values))
        error("labkit:ui:contract:InvalidValue", ...
            "Application ExtraCommands must be a row cell array of Command values.");
    end
end

function [renderers, ids] = validateRenderers(renderers)
    if ~isstruct(renderers) || ~isscalar(renderers)
        error("labkit:ui:contract:InvalidValue", ...
            "Application Renderers must be a scalar struct.");
    end
    ids = string(fieldnames(renderers)).';
    for k = 1:numel(ids)
        callback = renderers.(ids(k));
        if ~isa(callback, "function_handle") || ~isscalar(callback) || ...
                nargin(callback) ~= 2 || nargout(callback) ~= 0
            error("labkit:ui:contract:InvalidValue", ...
                "Application renderer %s must be a fixed two-input, " + ...
                "zero-output function.", ids(k));
        end
    end
end

function assertUnique(values, label)
    if numel(unique(values)) ~= numel(values)
        error("labkit:ui:contract:DuplicateId", ...
            "%s IDs must be globally unique.", label);
    end
end

function commands = collectCommands(nodes, extraCommands, start)
    commands = {};
    for k = 1:numel(nodes)
        signals = nodes{k}.Signals;
        for s = 1:numel(signals)
            commands{end + 1} = signals{s};
        end
    end
    commands = [commands, extraCommands];
    if ~isempty(start)
        commands{end + 1} = start;
    end
    commands = uniqueCommands(commands);
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
            error("labkit:ui:contract:DuplicateId", ...
                "Command ID %s has conflicting Command values.", value.Id);
        end
    end
    values = uniqueValues;
end

function validateRendererReferences(nodes, rendererIds, ~)
    for k = 1:numel(nodes)
        missing = setdiff(nodes{k}.RendererIds, rendererIds);
        if ~isempty(missing)
            error("labkit:ui:contract:UnknownReference", ...
                "Layout preview references an undeclared renderer: %s.", ...
                missing(1));
        end
    end
end

function state = runAnalysis(state, ~)
    state.finished = true;
end
