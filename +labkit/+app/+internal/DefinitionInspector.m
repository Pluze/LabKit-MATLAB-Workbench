classdef (Hidden, Sealed) DefinitionInspector
    % Internal test inspection boundary for compiled App definitions.

    methods (Static)
        function ids = targetIds(definition)
            contract = compiledContract(definition);
            ids = contract.TargetIds;
        end

        function ids = signalIds(definition)
            contract = compiledContract(definition);
            ids = contract.signalIds();
        end

        function plan = platformPlan(definition)
            contract = compiledContract(definition);
            plan = contract.PlatformPlan;
        end
    end
end

function contract = compiledContract(definition)
if ~isa(definition, "labkit.app.Definition") || ~isscalar(definition)
    error("labkit:app:runtime:InvariantFailure", ...
        "DefinitionInspector requires one Definition.");
end
contract = definition.Compiled;
end
