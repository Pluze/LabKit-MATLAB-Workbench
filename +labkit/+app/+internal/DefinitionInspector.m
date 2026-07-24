classdef (Hidden, Sealed) DefinitionInspector
    % Internal test inspection boundary for compiled App definitions.

    methods (Static)
        function ids = targetIds(definition)
            contract = compiledContract(definition);
            ids = contract.TargetIds;
        end

        function ids = materializedTargetIds(definition)
            % Return semantic IDs backed by one native MATLAB component.
            %
            % TargetIds also includes interaction declarations.  Those
            % declarations are view targets but intentionally share the axes
            % of their owning plot rather than materializing a component with
            % their own tag.  Layout conformance therefore uses the compiled
            % platform plan as the native materialization contract.
            contract = compiledContract(definition);
            nodes = contract.PlatformPlan.Nodes;
            ids = string({nodes(~arrayfun(@(node) ...
                isempty(node.Capabilities), nodes)).Id});
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
