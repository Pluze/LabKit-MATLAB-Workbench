function journal = temporarySessionJournal(definition, rootFolder)
%TEMPORARYSESSIONJOURNAL Create one test-private journal beneath caller-owned scratch.
% Expected callers are LabKit specifications and isolated test probes. The
% caller supplies a TemporaryFolderFixture or isolated-process scratch root.

rootFolder = string(rootFolder);
if ~(isscalar(rootFolder) && strlength(rootFolder) > 0)
    error("LabKit:TestJournal:InvalidRoot", ...
        "Temporary session journals require one nonempty scratch root.");
end
journal = labkit.app.internal.SessionJournal( ...
    definition, RootFolder=rootFolder);
end
