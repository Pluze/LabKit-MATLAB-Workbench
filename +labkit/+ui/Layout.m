classdef (Sealed) Layout
    %LAYOUT Compose an immutable semantic UI target graph.
    %
    % Usage:
    %   field = labkit.ui.Layout.field(id, Name=Value)
    %   table = labkit.ui.Layout.table(id, Name=Value)
    %   action = labkit.ui.Layout.action(id, label, command)
    %   preview = labkit.ui.Layout.preview(id, Renderers=rendererIds)
    %   group = labkit.ui.Layout.group(id, children)
    %   layout = labkit.ui.Layout.root(children)
    %
    % Description:
    %   Layout values declare semantic targets, parent ownership, supported
    %   presentation operations, Command-valued signals, and renderer
    %   references without creating MATLAB graphics. The Phase 2 kernel
    %   deliberately starts with the target kinds needed by the representative
    %   table/plot contract; later migration slices add reviewed semantic kinds
    %   rather than accepting an open props struct.
    %
    % Inputs:
    %   id - Nonempty MATLAB identifier unique within one Application.
    %   label - Nonempty text shown by an action target.
    %   command - labkit.ui.Command whose Role is "invoke".
    %   children - Row cell array of uniquely owned labkit.ui.Layout values.
    %
    % Name-Value Arguments:
    %   Changed - labkit.ui.Command with Role="value" for field or
    %       Role="tableEdit" for table. Default: no signal.
    %   Renderers - Row text array of renderer IDs legal for a preview target.
    %       Each ID must be a MATLAB identifier. Default: an empty string row.
    %
    % Outputs:
    %   field - Immutable field target value.
    %   table - Immutable table target value.
    %   action - Immutable action target value.
    %   preview - Immutable preview target value.
    %   group - Immutable semantic group value.
    %   layout - Immutable root layout value.
    %
    % Errors:
    %   labkit:ui:contract:UnknownArgument - An option is unknown, duplicated,
    %       or unpaired.
    %   labkit:ui:contract:InvalidValue - An ID, label, child, renderer, or
    %       Command value is invalid.
    %   labkit:ui:contract:CallbackRoleMismatch - A signal Command has the
    %       wrong Role for its target.
    %   labkit:ui:contract:UnsupportedOperation - A child kind is illegal for
    %       its parent.
    %
    % Typical Call:
    %   changed = labkit.ui.Command("groupChanged", @changeGroup, Role="value");
    %   group = labkit.ui.Layout.field("group", Changed=changed);
    %   run = labkit.ui.Command("run", @runAnalysis);
    %   layout = labkit.ui.Layout.root({ ...
    %       labkit.ui.Layout.group("inputs", {group, ...
    %           labkit.ui.Layout.action("run", "Run", run)}), ...
    %       labkit.ui.Layout.preview("result", Renderers="comparison")});
    %
    % See also labkit.ui.Application, labkit.ui.Command,
    %   labkit.ui.Presentation

    properties (SetAccess = immutable)
        Kind (1, 1) string
        Id (1, 1) string
        Children (1, :) cell
        Capabilities (1, :) string
        Signal
        RendererIds (1, :) string
    end

    methods (Access = private)
        function obj = Layout(kind, id, children, capabilities, ...
                signal, rendererIds)
            obj.Kind = kind;
            obj.Id = id;
            obj.Children = children;
            obj.Capabilities = capabilities;
            obj.Signal = signal;
            obj.RendererIds = rendererIds;
        end
    end

    methods (Static)
        function obj = field(id, varargin)
            options = parseContractOptions( ...
                "labkit.ui.Layout.field", "Changed", varargin{:});
            signal = optionValue(options, "Changed", []);
            validateSignal(signal, "value", "field");
            obj = labkit.ui.Layout("field", normalizeId(id), {}, ...
                ["value", "choices", "limits", "enabled", ...
                    "visible", "text"], ...
                signal, strings(1, 0));
        end

        function obj = table(id, varargin)
            options = parseContractOptions( ...
                "labkit.ui.Layout.table", "Changed", varargin{:});
            signal = optionValue(options, "Changed", []);
            validateSignal(signal, "tableEdit", "table");
            obj = labkit.ui.Layout("table", normalizeId(id), {}, ...
                ["table", "enabled", "visible"], ...
                signal, strings(1, 0));
        end

        function obj = action(id, label, command)
            if ~(ischar(label) || (isstring(label) && isscalar(label))) || ...
                    strlength(string(label)) == 0
                error("labkit:ui:contract:InvalidValue", ...
                    "Action label must be nonempty scalar text.");
            end
            validateSignal(command, "invoke", "action");
            obj = labkit.ui.Layout("action", normalizeId(id), {}, ...
                ["enabled", "visible", "text"], ...
                command, strings(1, 0));
        end

        function obj = preview(id, varargin)
            options = parseContractOptions( ...
                "labkit.ui.Layout.preview", "Renderers", varargin{:});
            rendererIds = normalizeIds( ...
                optionValue(options, "Renderers", strings(1, 0)), ...
                "renderer");
            obj = labkit.ui.Layout("preview", normalizeId(id), {}, ...
                ["plot", "visible"], [], rendererIds);
        end

        function obj = group(id, children)
            children = normalizeChildren(children);
            allowed = ["field", "table", "action", "group"];
            validateChildKinds(children, allowed, "group");
            obj = labkit.ui.Layout("group", normalizeId(id), children, ...
                strings(1, 0), [], strings(1, 0));
        end

        function obj = root(children)
            children = normalizeChildren(children);
            allowed = ["field", "table", "action", "group", "preview"];
            validateChildKinds(children, allowed, "root");
            obj = labkit.ui.Layout("root", "application", children, ...
                strings(1, 0), [], strings(1, 0));
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
    end
end

function value = optionValue(options, name, defaultValue)
    value = defaultValue;
    if isfield(options, name)
        value = options.(name);
    end
end

function value = normalizeId(value)
    values = normalizeIds(value, "layout");
    if numel(values) ~= 1
        error("labkit:ui:contract:InvalidValue", ...
            "Layout id must be a scalar MATLAB identifier.");
    end
    value = values;
end

function values = normalizeIds(values, label)
    if ischar(values)
        values = string(values);
    elseif iscellstr(values)
        values = string(values);
    elseif ~isstring(values)
        error("labkit:ui:contract:InvalidValue", ...
            "%s IDs must be text.", label);
    end
    values = reshape(values, 1, []);
    if any(strlength(values) == 0) || ...
            any(~arrayfun(@(value) isvarname(char(value)), values)) || ...
            numel(unique(values)) ~= numel(values)
        error("labkit:ui:contract:InvalidValue", ...
            "%s IDs must be unique nonempty MATLAB identifiers.", label);
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

function state = changeGroup(state, ~, ~)
end

function state = runAnalysis(state, ~)
end
