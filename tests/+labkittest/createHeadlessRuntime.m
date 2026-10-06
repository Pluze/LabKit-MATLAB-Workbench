function runtime = createHeadlessRuntime( ...
        definition, initialProject, backend, journal)
%CREATEHEADLESSRUNTIME Construct a headless App runtime for test assertions.
%   RUNTIME = labkittest.createHeadlessRuntime(DEFINITION, INITIALPROJECT,
%   BACKEND, JOURNAL) is the stable test-only construction seam for App
%   specifications. Callers own runtime.close cleanup and
%   must supply a caller-owned temporary SessionJournal.
%
%   Production Apps launch through DEFINITION.launch and must not call SDK
%   runtime internals.

if ~isa(definition, "labkit.app.Definition") || ~isscalar(definition)
    error("LabKit:TestRuntime:InvalidDefinition", ...
        "Headless test runtime construction requires one Definition.");
end
if nargin < 4 || isempty(journal)
    error("LabKit:TestRuntime:MissingJournal", ...
        "Headless test runtime construction requires an explicit test journal.");
end

runtime = labkit.app.internal.runtime.RuntimeFactory.create("headless",  ...
    definition, initialProject, backend, journal);
end
