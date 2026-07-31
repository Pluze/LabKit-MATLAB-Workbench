function result = checkLabKitDocs(sourceRoot, existingSiteRoot)
%CHECKLABKITDOCS Verify deterministic HTML generation from structured sources.
% Expected caller: buildtool docsCheck and project documentation tests.
% Inputs:
%   sourceRoot        - documentation source folder containing Markdown pages.
%   existingSiteRoot - optional existing generated site to compare. When
%                      omitted, the function renders an independent reference.
% Output:
%   result - renderer result plus comparedFileCount.
% Side effects: creates and removes one or two temporary generated sites and
%   reports render/compare stages to the console.

    repoRoot = fileparts(fileparts(fileparts(mfilename("fullpath"))));
    if nargin < 1 || strlength(string(sourceRoot)) == 0
        sourceRoot = fullfile(repoRoot, "docs");
    end
    compareIndependentRenders = ...
        nargin < 2 || strlength(string(existingSiteRoot)) == 0;
    if compareIndependentRenders
        existingSiteRoot = tempname;
        referenceCleanup = onCleanup( ...
            @() removeDocFolder(existingSiteRoot));
        fprintf("DOCS CHECK [1/3] render reference\n");
        renderLabKitDocs(sourceRoot, existingSiteRoot);
    end

    generatedRoot = tempname;
    cleanup = onCleanup(@() removeDocFolder(generatedRoot));
    fprintf("DOCS CHECK [2/3] render candidate\n");
    result = renderLabKitDocs(sourceRoot, generatedRoot);
    fprintf("DOCS CHECK [3/3] compare generated trees\n");
    [matches, diagnostic, count] = compareLabKitDocTrees( ...
        generatedRoot, existingSiteRoot);
    if ~matches
        if compareIndependentRenders
            message = "Repeated documentation renders differ: %s";
        else
            message = "Existing site differs from generated documentation: %s";
        end
        error("LabKit:Docs:StaleGeneratedSite", message, diagnostic);
    end
    result.comparedFileCount = count;
    clear cleanup
    if compareIndependentRenders
        clear referenceCleanup
    end
end

function removeDocFolder(folder)
    if isfolder(folder)
        rmdir(folder, "s");
    end
end
