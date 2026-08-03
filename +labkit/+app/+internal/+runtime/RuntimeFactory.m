classdef (Hidden, Sealed) RuntimeFactory
    % Internal runtime construction boundary.

    methods (Static)
        function runtime = createHeadless( ...
                definition, initialProject, backend, journal, varargin)
            if nargin < 2
                initialProject = [];
            end
            if nargin < 3
                backend = struct();
            end
            if nargin < 4
                journal = [];
            end
            journalRoot = parseJournalRoot(journal, varargin{:});
            runtime = labkit.app.internal.runtime.RuntimeFactory.create( ...
                definition, initialProject, backend, ...
                "headless", journal, journalRoot);
        end

        function runtime = createMatlab( ...
                definition, initialProject, backend, journal, varargin)
            if nargin < 2
                initialProject = [];
            end
            if nargin < 3
                backend = struct();
            end
            if nargin < 4
                journal = [];
            end
            journalRoot = parseJournalRoot(journal, varargin{:});
            runtime = labkit.app.internal.runtime.RuntimeFactory.create( ...
                definition, initialProject, backend, ...
                "matlab", journal, journalRoot);
        end
    end

    methods (Static, Access = private)
        function runtime = create( ...
                definition, initialProject, backend, platform, journal, journalRoot)
            if ~isa(definition, "labkit.app.Definition") || ...
                    ~isscalar(definition)
                error("labkit:app:runtime:InvariantFailure", ...
                    "RuntimeFactory requires one Definition.");
            end
            journal = prepareJournal(definition, journal, journalRoot);
            try
                projection = labkit.app.internal.diagnostics.SessionJournalProjection(journal);
                stream = labkit.app.internal.diagnostics.SessionEventStream(definition, ...
                    SessionId=journal.sessionId(), ProjectionHook=@projection.project, ...
                    ProjectionHealthHook=@projection.drainHealth);
                recorder = labkit.app.internal.diagnostics.SessionDiagnostics( ...
                    definition, stream, projection, journal);
            catch cause
                try
                    journal.close();
                catch
                    % Journal teardown must not hide the construction failure.
                end
                rethrow(cause);
            end
            try
                runtime = labkit.app.internal.runtime.RuntimeKernel( ...
                    definition, definition.Compiled, initialProject, ...
                    backend, platform, recorder);
            catch cause
                recorder.close();
                rethrow(cause);
            end
        end
    end
end

function journal = prepareJournal(definition, journal, journalRoot)
if isempty(journal)
    if strlength(journalRoot) == 0
        journal = labkit.app.internal.diagnostics.SessionJournal(definition);
    else
        journal = labkit.app.internal.diagnostics.SessionJournal(definition, ...
            RootFolder=journalRoot);
    end
    return;
end
if ~isa(journal, "labkit.app.internal.diagnostics.SessionJournal") || ~isscalar(journal)
    error("labkit:app:runtime:InvariantFailure", ...
        "RuntimeFactory journal seam requires one SessionJournal.");
end
end

function journalRoot = parseJournalRoot(journal, varargin)
journalRoot = "";
if isempty(varargin)
    return;
end
options = labkit.app.internal.contract.OptionParser.parse( ...
    "RuntimeFactory", "JournalRoot", varargin{:});
if ~isfield(options, "JournalRoot")
    return;
end
if ~isempty(journal)
    error("labkit:app:runtime:InvariantFailure", ...
        "RuntimeFactory cannot combine an explicit journal with JournalRoot.");
end
value = options.JournalRoot;
if ~(ischar(value) || (isstring(value) && isscalar(value))) || ...
        strlength(strip(string(value))) == 0
    error("labkit:app:contract:InvalidValue", ...
        "RuntimeFactory JournalRoot must be nonempty scalar text.");
end
journalRoot = string(value);
end
