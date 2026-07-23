function targets = locate(file, varargin)
%LOCATE Show where an author adds evidence for a production source file.
%   TARGETS = labkittest.locate(FILE) maps one repository-relative production
%   source file to its required evidence targets. Each target has Owner,
%   Contract, Environment, Folder, Reason, and AuthorOwned fields. Folder is
%   the exact tests/specs insertion directory; Authors never infer it from
%   unit/contract/gui folders or from an App-wide fallback.
%
%   A calculation exposes its direct scientific target plus its bounded result
%   and presentation consumers. An App definition exposes parameterized
%   definition, smoke, and isolated-boundary conformance targets. Targets with
%   AuthorOwned=false are framework-owned parameterized conformance and need
%   no new App-specific wrapper.
%
%   TARGETS = labkittest.locate(FILE, SpecsRoot=FOLDER) uses FOLDER to form
%   the insertion paths. Unknown source roles throw rather than guessing; the
%   changed-file planner catches that condition and widens visibly.

    opts = parseOptions(file, varargin{:});
    parts = split(opts.File, "/");
    if startsWith(opts.File, "apps/") && numel(parts) >= 6 && ...
            startsWith(parts(4), "+") && startsWith(parts(5), "+")
        appOwner = "apps/" + parts(2) + "/" + parts(3);
        owner = appOwner + "/" + erase(parts(5), "+");
        name = lower(parts(end));
        if startsWith(name, "compute") || startsWith(name, "calculate") || ...
                startsWith(name, "analyze")
            targets = [ ...
                target(opts.SpecsRoot, owner, "scientific", "headless", "", true, ...
                    "direct calculation behavior"), ...
                target(opts.SpecsRoot, appOwner + "/resultFiles", "result", "headless", "", true, ...
                    "bounded result-schema consumer"), ...
                target(opts.SpecsRoot, appOwner + "/workbench", "presentation", "headless", "", true, ...
                    "bounded presentation consumer")];
            return;
        end
        targets = target(opts.SpecsRoot, owner, "source", "headless", "", true, ...
            "direct capability source behavior");
        return;
    end
    if startsWith(opts.File, "apps/") && endsWith(opts.File, "/definition.m") && ...
            numel(parts) >= 3
        packageName = erase(parts(end - 1), "+");
        targets = [ ...
            target(opts.SpecsRoot, "apps/conformance", "definition", "headless", ...
                packageName, false, "parameterized App definition conformance"), ...
            target(opts.SpecsRoot, "apps/conformance", "product", "hidden-gui", ...
                packageName, false, "parameterized App smoke conformance"), ...
            target(opts.SpecsRoot, "apps/conformance", "product", "isolated-process", ...
                packageName, false, "parameterized App isolated-boundary conformance")];
        return;
    end
    if startsWith(opts.File, ".agents/") || opts.File == "AGENTS.md"
        targets = target(opts.SpecsRoot, "system/repository", "system", ...
            "headless", "", true, "repository policy behavior");
        return;
    end
    error("LabKit:TestLocation:UnknownSource", ...
        "No authoring location is defined for %s.", opts.File);
end

function opts = parseOptions(file, varargin)
    p = inputParser;
    p.FunctionName = "labkittest.locate";
    p.addRequired("File", @isTextScalar);
    p.addParameter("SpecsRoot", defaultSpecsRoot(), @isFolderPath);
    p.parse(file, varargin{:});
    opts = p.Results;
    opts.File = normalizePath(opts.File);
    opts.SpecsRoot = string(opts.SpecsRoot);
end

function value = target(specsRoot, owner, contract, environment, app, authorOwned, reason)
    value = struct( ...
        "Owner", string(owner), ...
        "Contract", string(contract), ...
        "Environment", string(environment), ...
        "App", string(app), ...
        "Folder", string(fullfile(specsRoot, char(replace(owner, "/", filesep)))), ...
        "AuthorOwned", logical(authorOwned), ...
        "Reason", string(reason));
end

function root = defaultSpecsRoot()
    packageFolder = fileparts(mfilename("fullpath"));
    root = fullfile(fileparts(fileparts(packageFolder)), "tests", "specs");
end

function value = normalizePath(value)
    value = strip(replace(string(value), "\\", "/"));
    if strlength(value) == 0 || startsWith(value, "/") || ...
            contains(value, "..") || contains(value, ":")
        error("LabKit:TestLocation:InvalidPath", ...
            "File must be a repository-relative source path.");
    end
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end

function tf = isFolderPath(value)
    tf = isTextScalar(value) && exist(char(value), "dir") == 7;
end
