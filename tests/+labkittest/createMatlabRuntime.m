function runtime = createMatlabRuntime( ...
        definition, initialProject, backend, journal, varargin)
%CREATEMATLABRUNTIME Construct a native App runtime for test assertions.
%   RUNTIME = labkittest.createMatlabRuntime(DEFINITION, INITIALPROJECT,
%   BACKEND, JOURNAL) is the stable test-only construction seam for public and
%   accepted private hidden-GUI specifications. Callers own runtime.close
%   cleanup and must supply a caller-owned temporary SessionJournal.
%   Production Apps launch through DEFINITION.launch and must not call SDK
%   runtime internals.
%
%   DEFINITION must be one labkit.app.Definition. INITIALPROJECT is empty or a
%   scalar project struct. BACKEND is a scalar struct of test dialog seams.
%   JOURNAL is created with labkittest.temporarySessionJournal. Extra arguments
%   are forwarded to the internal factory for framework-owned test seams.

if ~isa(definition, "labkit.app.Definition") || ~isscalar(definition)
    error("LabKit:TestRuntime:InvalidDefinition", ...
        "Native test runtime construction requires one Definition.");
end
if nargin < 4 || isempty(journal)
    error("LabKit:TestRuntime:MissingJournal", ...
        "Native test runtime construction requires an explicit test journal.");
end

runtime = labkit.app.internal.runtime.RuntimeFactory.createMatlab( ...
    definition, initialProject, backend, journal, varargin{:});
end
