classdef (Sealed) Application
    %APPLICATION Compile one immutable explicit App contract.
    %
    % Usage:
    %   app = labkit.ui.Application(Command=command, Id=id, Title=title, ...
    %       Family=family, AppVersion=version, Updated=date, ...
    %       Requirements=requirements, Layout=layout, Name=Value)
    %
    % Description:
    %   Application validates product metadata, Commands, renderer ownership,
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
    %   Layout - Root labkit.ui.Layout value.
    %
    % Optional Name-Value Arguments:
    %   DisplayName - Nonempty scalar text. Default: Title.
    %   Commands - Row cell array of unique labkit.ui.Command values used by
    %       Layout signals. Default: {}.
    %   Renderers - Scalar struct mapping renderer IDs to function handles.
    %       Default: struct().
    %   Capabilities - Unique row string array drawn from "dispatch",
    %       "workflow", "diagnostics", "dialogs", "project", "render",
    %       "resources", and "results". Default: an empty string row.
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
    %       Commands, renderers, or capabilities are malformed.
    %   labkit:ui:contract:DuplicateId - A Layout, Command, or renderer ID is
    %       duplicated.
    %   labkit:ui:contract:UnknownReference - A signal, renderer, or
    %       presentation target is undeclared.
    %   labkit:ui:contract:UnsupportedOperation - A presentation operation is
    %       not legal for its target.
    %
    % Typical Call:
    %   run = labkit.ui.Command("run", @runAnalysis);
    %   layout = labkit.ui.Layout.root({ ...
    %       labkit.ui.Layout.action("run", "Run", run)});
    %   app = labkit.ui.Application( ...
    %       Command="labkit_Example_app", Id="example.app", ...
    %       Title="Example", Family="Examples", AppVersion="1.0.0", ...
    %       Updated="2026-07-19", Requirements=[], Layout=layout, ...
    %       Commands={run});
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
        TargetIds (1, :) string
        Capabilities (1, :) string
    end

    properties (SetAccess = immutable, GetAccess = private)
        TargetNodes (1, :) cell
        Commands (1, :) cell
        RendererIds (1, :) string
    end

    methods
        function obj = Application(varargin)
            names = [ ...
                "Command", "Id", "Title", "DisplayName", "Family", ...
                "AppVersion", "Updated", "Requirements", "Layout", ...
                "Commands", "Renderers", "Capabilities"];
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
            obj.Capabilities = validateCapabilities( ...
                optionValue(options, "Capabilities", strings(1, 0)));
            obj.Commands = validateCommands( ...
                optionValue(options, "Commands", {}));
            [renderers, rendererIds] = validateRenderers( ...
                optionValue(options, "Renderers", struct()));
            obj.RendererIds = rendererIds;

            layout = options.Layout;
            if ~isa(layout, "labkit.ui.Layout") || layout.Kind ~= "root"
                error("labkit:ui:contract:InvalidValue", ...
                    "Application Layout must be a root Layout value.");
            end
            nodes = layout.flattenForCompiler();
            ids = string(cellfun(@(value) value.Id, nodes, ...
                "UniformOutput", false));
            assertUnique(ids, "Layout");
            targetMask = cellfun(@(value) ...
                ~isempty(value.Capabilities), nodes);
            obj.TargetNodes = nodes(targetMask);
            obj.TargetIds = ids(targetMask);
            validateSignals(nodes, obj.Commands);
            validateRendererReferences(nodes, rendererIds, renderers);
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
    allowed = [ ...
        "dispatch", "workflow", "diagnostics", "dialogs", ...
        "project", "render", "resources", "results"];
    if numel(unique(values)) ~= numel(values) || ...
            any(~ismember(values, allowed))
        error("labkit:ui:contract:InvalidValue", ...
            "Application Capabilities contain a duplicate or unknown value.");
    end
end

function values = validateCommands(values)
    if ~iscell(values) || (~isempty(values) && ~isrow(values)) || ...
            ~all(cellfun(@(value) isa(value, "labkit.ui.Command"), values))
        error("labkit:ui:contract:InvalidValue", ...
            "Application Commands must be a row cell array of Command values.");
    end
    ids = string(cellfun(@(value) value.Id, values, ...
        "UniformOutput", false));
    assertUnique(ids, "Command");
end

function [renderers, ids] = validateRenderers(renderers)
    if ~isstruct(renderers) || ~isscalar(renderers)
        error("labkit:ui:contract:InvalidValue", ...
            "Application Renderers must be a scalar struct.");
    end
    ids = string(fieldnames(renderers)).';
    for k = 1:numel(ids)
        if ~isa(renderers.(ids(k)), "function_handle")
            error("labkit:ui:contract:InvalidValue", ...
                "Application renderer %s must be a function handle.", ids(k));
        end
    end
end

function assertUnique(values, label)
    if numel(unique(values)) ~= numel(values)
        error("labkit:ui:contract:DuplicateId", ...
            "%s IDs must be globally unique.", label);
    end
end

function validateSignals(nodes, commands)
    commandIds = string(cellfun(@(value) value.Id, commands, ...
        "UniformOutput", false));
    for k = 1:numel(nodes)
        signal = nodes{k}.Signal;
        if isempty(signal)
            continue;
        end
        index = find(commandIds == signal.Id, 1);
        if isempty(index) || ~isequaln(commands{index}, signal)
            error("labkit:ui:contract:UnknownReference", ...
                "Layout signal references an undeclared Command: %s.", ...
                signal.Id);
        end
    end
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
