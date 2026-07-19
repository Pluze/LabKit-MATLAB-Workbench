function result = checkLabKitDocs(sourceRoot, committedSiteRoot)
%CHECKLABKITDOCS Verify that tracked HTML matches structured sources.
% Expected caller: buildtool docsCheck and project documentation tests.
% Inputs:
%   sourceRoot        - documentation source folder containing Markdown pages.
%   committedSiteRoot - tracked generated site folder.
% Output:
%   result - renderer result plus comparedFileCount.
% Side effects: creates and removes a temporary generated site.

    repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
    if nargin < 1 || strlength(string(sourceRoot)) == 0
        sourceRoot = fullfile(repoRoot, "docs");
    end
    if nargin < 2 || strlength(string(committedSiteRoot)) == 0
        committedSiteRoot = fullfile(repoRoot, "site");
    end

    generatedRoot = tempname;
    cleanup = onCleanup(@() removeDocFolder(generatedRoot));
    result = renderLabKitDocs(sourceRoot, generatedRoot);
    [matches, diagnostic, count] = compareLabKitDocTrees( ...
        generatedRoot, committedSiteRoot);
    if ~matches
        error("LabKit:Docs:StaleGeneratedSite", ...
            "Tracked site differs from generated documentation: %s", diagnostic);
    end
    result.comparedFileCount = count;
    clear cleanup
end

function removeDocFolder(folder)
    if isfolder(folder)
        rmdir(folder, "s");
    end
end
