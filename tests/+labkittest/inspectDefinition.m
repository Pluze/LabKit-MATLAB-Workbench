function plan = inspectDefinition(definition)
%INSPECTDEFINITION Return the compiled layout plan for test assertions.
%   PLAN = labkittest.inspectDefinition(DEFINITION) is the stable test-only
%   seam for public and accepted private App specifications that must inspect
%   declared layout nodes. Production Apps must not call labkit.app.internal.
%
%   DEFINITION must be one labkit.app.Definition. PLAN is the framework's
%   read-only compiled platform plan and is intended only for assertions.

arguments
    definition (1, 1) labkit.app.Definition
end

plan = labkit.app.internal.contract.DefinitionInspector.platformPlan( ...
    definition);
end
