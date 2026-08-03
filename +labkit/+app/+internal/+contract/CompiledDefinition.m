classdef (Hidden, Sealed) CompiledDefinition
    % Internal immutable layout, signal, and presentation contract.

    properties (SetAccess = immutable)
        TargetIds (1, :) string
        PlatformPlan (1, 1) struct
    end

    properties (SetAccess = immutable, GetAccess = private)
        TargetNodes (1, :) cell
        SignalBindings (1, :) cell
        OnStartBinding
    end

    methods (Access = ?labkit.app.Definition)
        function obj = CompiledDefinition(layout, startCallback)
            if ~isa(layout, "labkit.app.internal.contract.LayoutNode") || ...
                    layout.Kind ~= "workbench"
                error("labkit:app:contract:InvalidValue", ...
                    "Definition Workbench must be a workbench Layout value.");
            end
            onStart = [];
            if ~isempty(startCallback)
                onStart = labkit.app.internal.contract.SignalBinding( ...
                    "application", "started", startCallback);
            end
            nodes = layout.flattenForCompiler();
            ids = string(cellfun(@(value) value.Id, nodes, ...
                "UniformOutput", false));
            interactions = collectInteractions(nodes);
            interactionIds = string(cellfun(@(value) value.Id, ...
                interactions, "UniformOutput", false));
            assertUnique([ids interactionIds], "Layout and interaction");
            targetMask = cellfun(@(value) ...
                ~isempty(value.Capabilities), nodes);
            obj.TargetNodes = [nodes(targetMask) interactions];
            obj.TargetIds = string(cellfun(@(value) value.Id, ...
                obj.TargetNodes, "UniformOutput", false));
            obj.OnStartBinding = onStart;
            obj.SignalBindings = collectSignalBindings( ...
                [nodes interactions], onStart);
            obj.PlatformPlan = compilePlatformPlan(nodes);
        end
    end

    methods
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
                if operation.Kind == "renderPlot" && isempty(node.Renderer)
                    error("labkit:app:contract:UnknownReference", ...
                        "Target %s does not declare a renderer.", ...
                        operation.Target);
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

        function ids = signalIds(obj)
            ids = string(cellfun(@(binding) binding.Id, ...
                obj.SignalBindings, "UniformOutput", false));
        end

        function binding = onStartBinding(obj)
            binding = obj.OnStartBinding;
        end

        function tf = hasSignal(obj, binding)
            tf = any(cellfun(@(candidate) ...
                isequaln(candidate, binding), obj.SignalBindings));
        end
    end
end

function plan = compilePlatformPlan(nodes)
compiled = repmat(struct( ...
    "Kind", "", "Id", "", "ChildIds", strings(1, 0), ...
    "Capabilities", strings(1, 0), "Signals", {{}}, ...
    "Renderer", [], "AxisIds", strings(1, 0), ...
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
        "Renderer", node.Renderer, "AxisIds", node.AxisIds, ...
        "PageIds", node.PageIds, "InitialPage", node.InitialPage, ...
        "Configuration", node.configurationForCompiler());
end
plan = struct("Nodes", compiled);
end

function bindings = collectSignalBindings(nodes, start)
capacity = sum(cellfun(@(node) numel(node.Signals), nodes)) + ~isempty(start);
bindings = cell(1, capacity);
bindingCount = 0;
for k = 1:numel(nodes)
    signals = nodes{k}.Signals;
    for s = 1:numel(signals)
        bindingCount = bindingCount + 1;
        bindings{bindingCount} = signals{s};
    end
end
if ~isempty(start)
    bindingCount = bindingCount + 1;
    bindings{bindingCount} = start;
end
bindings = bindings(1:bindingCount);
bindings = uniqueBindings(bindings);
end

function interactions = collectInteractions(nodes)
chunks = cell(1, numel(nodes));
for k = 1:numel(nodes)
    if nodes{k}.Kind ~= "plotArea"
        continue;
    end
    configuration = nodes{k}.configurationForCompiler();
    if isfield(configuration, "Interactions")
        chunks{k} = configuration.Interactions;
    end
end
populated = ~cellfun("isempty", chunks);
if any(populated)
    interactions = [chunks{populated}];
else
    interactions = cell(1, 0);
end
end

function assertUnique(values, label)
if numel(unique(values)) ~= numel(values)
    error("labkit:app:contract:DuplicateId", ...
        "%s IDs must be globally unique.", label);
end
end

function values = uniqueBindings(values)
uniqueValues = cell(size(values));
uniqueCount = 0;
for k = 1:numel(values)
    value = values{k};
    sameId = find(cellfun(@(candidate) candidate.Id == value.Id, ...
        uniqueValues(1:uniqueCount)), 1);
    if isempty(sameId)
        uniqueCount = uniqueCount + 1;
        uniqueValues{uniqueCount} = value;
    elseif ~isequaln(uniqueValues{sameId}, value)
        error("labkit:app:contract:DuplicateId", ...
            "Layout signal ID %s has conflicting callbacks.", value.Id);
    end
end
values = uniqueValues(1:uniqueCount);
end
