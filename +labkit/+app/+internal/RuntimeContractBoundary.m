% Resolve compiled callback, platform, and state invariants for RuntimeKernel.
% Expected caller: RuntimeKernel. Inputs are the compiled internal contract,
% immutable Definition metadata, and callback payloads. Outputs are validated
% bindings, initial state values, adapters, or reader-facing busy text.
classdef (Sealed, Hidden) RuntimeContractBoundary
    methods (Static)
        function binding = interactionSignal(contract, interactionId, signal)
            plan = contract.PlatformPlan;
            binding = [];
            for k = 1:numel(plan.Nodes)
                config = plan.Nodes(k).Configuration;
                if ~isfield(config, "Interactions")
                    continue;
                end
                interactions = config.Interactions;
                match = find(cellfun(@(value) ...
                    value.Id == string(interactionId), interactions), 1);
                if ~isempty(match)
                    binding = interactions{match}.signal(string(signal));
                    break;
                end
            end
            if isempty(binding)
                error("labkit:app:contract:UnknownReference", ...
                    "Interaction %s has no %s callback.", ...
                    interactionId, signal);
            end
        end

        function binding = signalForTarget( ...
                contract, target, signal, required)
            if nargin < 4
                required = true;
            end
            plan = contract.PlatformPlan;
            index = find(string({plan.Nodes.Id}) == string(target), 1);
            binding = [];
            if ~isempty(index)
                signals = plan.Nodes(index).Signals;
                match = find(cellfun( ...
                    @(value) value.Signal == signal, signals), 1);
                if ~isempty(match)
                    binding = signals{match};
                end
            end
            if required && isempty(binding)
                error("labkit:app:contract:UnknownReference", ...
                    "Workbench target has no %s callback: %s.", ...
                    signal, target);
            end
        end

        function [config, current] = fileListState( ...
                contract, state, target)
            plan = contract.PlatformPlan;
            index = find(string({plan.Nodes.Id}) == string(target), 1);
            if isempty(index) || plan.Nodes(index).Kind ~= "fileList"
                error("labkit:app:contract:UnknownReference", ...
                    "Layout target is not a fileList: %s.", target);
            end
            config = plan.Nodes(index).Configuration;
            if strlength(config.Bind) == 0
                error("labkit:app:contract:UnknownReference", ...
                    "fileList target has no source binding: %s.", target);
            end
            current = labkit.app.internal.RuntimeStatePath.read( ...
                state, config.Bind);
        end

        function adapter = createAdapter(application, contract, platform)
            if ~(ischar(platform) || ...
                    (isstring(platform) && isscalar(platform)))
                error("labkit:app:runtime:InvariantFailure", ...
                    "Runtime platform must be scalar text.");
            end
            switch string(platform)
                case "headless"
                    adapter = labkit.app.internal.HeadlessPlatformAdapter();
                case "matlab"
                    plan = contract.PlatformPlan;
                    title = application.Title + " v" + ...
                        application.AppVersion + " (" + ...
                        application.Updated + ")";
                    if ~isempty(application.ProjectSchema)
                        title = title + " *";
                    end
                    adapter = labkit.app.internal.MatlabPlatformAdapter( ...
                        plan, title);
                otherwise
                    error("labkit:app:runtime:InvariantFailure", ...
                        "Runtime platform is unsupported: %s.", platform);
            end
        end

        function project = initialProject(application, supplied)
            if ~isempty(supplied)
                project = supplied;
            elseif ~isempty(application.ProjectSchema)
                project = application.ProjectSchema.Create();
            else
                project = struct();
            end
            if ~isstruct(project) || ~isscalar(project)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Application project must be a scalar struct.");
            end
        end

        function validateDispatch(contract, binding, payload)
            if ~isa(binding, "labkit.app.internal.SignalBinding") || ...
                    ~contract.hasSignal(binding)
                error("labkit:app:contract:UnknownReference", ...
                    "Runtime dispatch callback is undeclared.");
            end
            if ~binding.AcceptsPayload && ~isempty(payload)
                error("labkit:app:contract:InvalidValue", ...
                    "Callback %s does not accept a payload.", binding.Id);
            end
            if strlength(binding.PayloadClass) > 0 && ...
                    ~isa(payload, binding.PayloadClass)
                error("labkit:app:contract:InvalidValue", ...
                    "Callback %s payload must be %s.", ...
                    binding.Id, binding.PayloadClass);
            end
        end

        function validateState(application, state)
            if ~isstruct(state) || ~isscalar(state) || ...
                    ~all(isfield(state, ["project", "session"])) || ...
                    ~isstruct(state.project) || ~isscalar(state.project) || ...
                    ~isstruct(state.session) || ~isscalar(state.session)
                error("labkit:app:runtime:InvariantFailure", ...
                    "Command must return scalar project/session state.");
            end
            if ~isempty(application.ProjectSchema)
                accepted = application.ProjectSchema.Validate(state.project);
                if ~(islogical(accepted) && isscalar(accepted) && accepted)
                    error("labkit:app:runtime:InvariantFailure", ...
                        "Project validation rejected command state.");
                end
            end
        end

        function message = busyMessage(contract, binding)
            message = extractBefore(binding.Id, "__");
            plan = contract.PlatformPlan;
            index = find(string({plan.Nodes.Id}) == message, 1);
            if isempty(index)
                return
            end
            config = plan.Nodes(index).Configuration;
            if isfield(config, "BusyMessage") && ...
                    strlength(config.BusyMessage) > 0
                message = config.BusyMessage;
            elseif isfield(config, "Label") && strlength(config.Label) > 0
                message = config.Label;
            end
        end
    end
end
