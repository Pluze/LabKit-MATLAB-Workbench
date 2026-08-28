classdef (Sealed, Hidden) InteractionSpec
    %INTERACTIONSPEC Private immutable declaration for one managed gesture.
    %
    % Expected callers: public labkit.app.interaction constructors,
    % LayoutNode.plotArea, Definition, and the native adapter. It owns static
    % identity, styling, and direct callback bindings. Dynamic
    % values remain in view Snapshot operations.

    properties (SetAccess = private)
        Kind (1, 1) string
        Id (1, 1) string
        AxisIds (1, :) string
        Targets (1, :) string
        Capabilities (1, :) string
        Signals (1, :) cell
        Options (1, 1) struct
        Instruction (1, 1) string
    end

    methods
        function obj = InteractionSpec(kind, id, onChanged, options)
            obj.Kind = enumText(kind, [ ...
                "anchorPath", "pairedAnchors", "pointSlots", ...
                "rectangle", "regionSelection", "interval", ...
                "scaleReference"], "kind");
            obj.Id = scalarId(id, "id");
            axes = optionValue(options, "Axes", ...
                optionValue(options, "Axis", "main"));
            obj.AxisIds = idRow(axes, "Axis");
            if obj.Kind ~= "pairedAnchors" && numel(obj.AxisIds) ~= 1
                error("labkit:app:contract:InvalidValue", ...
                    "Interaction %s requires exactly one Axis.", obj.Id);
            elseif obj.Kind == "pairedAnchors" && numel(obj.AxisIds) < 2
                error("labkit:app:contract:InvalidValue", ...
                    "pairedAnchors requires at least two Axes.");
            end
            obj.Targets = strings(1, 0);
            obj.Capabilities = obj.Kind;
            obj.Signals = {labkit.app.internal.contract.SignalBinding( ...
                obj.Id, "interactionChanged", onChanged)};
            obj.Options = optionValue(options, "Style", struct());
            if ~isstruct(obj.Options) || ~isscalar(obj.Options)
                error("labkit:app:contract:InvalidValue", ...
                    "Interaction Style must be a scalar struct.");
            end
            obj.Instruction = scalarText(optionValue( ...
                options, "Instruction", ""), "Instruction");
            background = optionValue(options, "OnBackgroundPressed", []);
            if ~isempty(background)
                obj.Signals{end + 1} = labkit.app.internal.contract.SignalBinding( ...
                    obj.Id, "backgroundPressed", background);
            end
            selection = optionValue(options, "OnSelectionChanged", []);
            if ~isempty(selection)
                obj.Signals{end + 1} = labkit.app.internal.contract.SignalBinding( ...
                    obj.Id, "selectionChanged", selection);
            end
            scrolled = optionValue(options, "OnScrolled", []);
            if ~isempty(scrolled)
                obj.Signals{end + 1} = labkit.app.internal.contract.SignalBinding( ...
                    obj.Id, "scrolled", scrolled);
            end
        end

        function result = attachToPlot(obj, plotId, axisIds)
            plotId = scalarId(plotId, "plot id");
            missing = setdiff(obj.AxisIds, axisIds, "stable");
            if ~isempty(missing)
                error("labkit:app:contract:UnknownReference", ...
                    "Interaction %s references undeclared axis %s.", ...
                    obj.Id, missing(1));
            end
            result = obj;
            if isscalar(axisIds)
                result.Targets = repmat(plotId, size(obj.AxisIds));
            else
                result.Targets = plotId + "." + obj.AxisIds;
            end
        end

        function binding = signal(obj, signalName)
            match = find(cellfun(@(value) ...
                value.Signal == signalName, obj.Signals), 1);
            binding = [];
            if ~isempty(match)
                binding = obj.Signals{match};
            end
        end
    end
end

function values = idRow(values, label)
if ischar(values)
    values = string(values);
elseif iscellstr(values)
    values = string(values);
elseif ~isstring(values)
    error("labkit:app:contract:InvalidValue", ...
        "Interaction %s must be text.", label);
end
values = reshape(values, 1, []);
for k = 1:numel(values)
    values(k) = scalarId(values(k), label);
end
if isempty(values) || numel(unique(values)) ~= numel(values)
    error("labkit:app:contract:InvalidValue", ...
        "Interaction %s values must be nonempty and unique.", label);
end
end

function value = scalarId(value, label)
value = scalarText(value, label);
if strlength(value) == 0 || ~isvarname(char(value))
    error("labkit:app:contract:InvalidValue", ...
        "Interaction %s must be a MATLAB identifier.", label);
end
end

function value = scalarText(value, label)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error("labkit:app:contract:InvalidValue", ...
        "Interaction %s must be scalar text.", label);
end
value = string(value);
end

function value = enumText(value, allowed, label)
value = scalarText(value, label);
if ~any(value == allowed)
    error("labkit:app:contract:InvalidValue", ...
        "Interaction %s is unsupported: %s.", label, value);
end
end

function value = optionValue(options, name, defaultValue)
value = defaultValue;
if isfield(options, name)
    value = options.(name);
end
end
