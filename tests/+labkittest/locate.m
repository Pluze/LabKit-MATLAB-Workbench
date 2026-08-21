function targets = locate(file, varargin)
%LOCATE Show where an author adds evidence for a production source file.
%   TARGETS = labkittest.locate(FILE) maps one repository-relative production
%   source file to its required evidence targets. Each target has Owner,
%   Contract, Environment, Folder, Reason, AuthorOwned, and ManualCheck fields.
%   ManualCheck names an explicit non-automatable responsibility; it is empty
%   when automated evidence is sufficient. Folder is
%   the exact tests/specs insertion directory; Authors never infer it from
%   unit/contract/gui folders or from an App-wide fallback.
%
%   An App analysis-run source exposes its direct scientific target plus
%   bounded result and presentation consumers. Result and workbench sources
%   map directly to their semantic owners; buildLayout also selects the
%   parameterized product smoke identity. State/session roots and App
%   definitions have their own structural roles. Targets with AuthorOwned=false
%   are framework-owned parameterized conformance and need no App wrapper.
%
%   TARGETS = labkittest.locate(FILE, SpecsRoot=FOLDER) uses FOLDER to form
%   the insertion paths. Path classification and evidence strategy are
%   separate: unknown structure throws rather than widening into a full run.

    opts = parseOptions(file, varargin{:});
    classification = labkittest.classifyPath(opts.File);
    if classification.Kind == "ignored"
        error("LabKit:TestLocation:IgnoredPath", ...
            "No test location is required for %s: %s", opts.File, classification.Reason);
    end
    if classification.Kind == "unknown"
        error("LabKit:TestLocation:UnknownSource", ...
            "No validation ownership exists for %s. %s", opts.File, classification.Reason);
    end
    if ismember(classification.Role, ["validation-framework", "test-fixture"])
        targets = target(opts.SpecsRoot, classification.Owner, "system", ...
            "headless", "", true, classification.Reason);
        return;
    end
    if classification.Role == "repository-policy"
        targets = target(opts.SpecsRoot, classification.Owner, "system", ...
            "headless", "", true, classification.Reason);
        return;
    end
    if classification.Role == "repair-launcher" || classification.Role == "installed-launcher"
        targets = target(opts.SpecsRoot, classification.Owner, "system", ...
            "headless", "", true, classification.Reason);
        return;
    end
    if startsWith(opts.File, "tools/")
        targets = target(opts.SpecsRoot, classification.Owner, "system", ...
            "headless", "", true, classification.Reason);
        return;
    end
    parts = split(opts.File, "/");
    if startsWith(opts.File, "+labkit/") && numel(parts) >= 2 && ...
            startsWith(parts(2), "+")
        area = erase(parts(2), "+");
        if ismember(area, ...
                ["app", "biosignal", "contract", "dta", "image", ...
                "mark10", "rhs", "thermal"])
            targets = target(opts.SpecsRoot, classification.Owner, "source", ...
                "headless", "", true, "direct public facade behavior");
            return;
        end
    end
    if startsWith(opts.File, "apps/") && numel(parts) == 4 && ...
            startsWith(parts(4), "labkit_") && endsWith(parts(4), "_app.m")
        % Each public launcher is a thin definition entrypoint.  It has the
        % same launch, GUI, and path-isolation evidence closure as its App
        % definition, while remaining outside the App package folder.
        targets = appDefinitionTargets(opts.SpecsRoot, parts(3));
        return;
    end
    if startsWith(opts.File, "apps/") && numel(parts) >= 5 && ...
            startsWith(parts(4), "+")
        appOwner = "apps/" + parts(2) + "/" + parts(3);
        packageName = erase(parts(4), "+");
        if numel(parts) == 5
            switch lower(parts(5))
                case "definition.m"
                    targets = appDefinitionTargets(opts.SpecsRoot, packageName);
                case "createsession.m"
                    targets = target(opts.SpecsRoot, appOwner + "/session", ...
                        "state", "headless", "", true, ...
                        "App session reconstruction behavior");
                case "initialdata.m"
                    targets = target(opts.SpecsRoot, appOwner + "/state", ...
                        "state", "headless", "", true, ...
                        "App initial runtime-data behavior");
                otherwise
                    targets = target(opts.SpecsRoot, appOwner + "/product", ...
                        "product", "headless", "", true, ...
                        "App product-root behavior");
            end
            return;
        end
        if ~startsWith(parts(5), "+")
            error("LabKit:TestLocation:UnknownSource", ...
                "No App capability role is defined for %s.", opts.File);
        end
        capability = erase(parts(5), "+");
        owner = appOwner + "/" + capability;
        name = lower(parts(end));
        switch lower(capability)
            case "analysisrun"
                targets = analysisTargets(opts.SpecsRoot, appOwner, owner);
            case "analysis"
                targets = [ ...
                    target(opts.SpecsRoot, owner, "scientific", "headless", "", true, ...
                        "direct analysis behavior"), ...
                    target(opts.SpecsRoot, owner, "presentation", "headless", "", true, ...
                        "analysis presentation behavior")];
            case "resultfiles"
                targets = target(opts.SpecsRoot, owner, "result", "headless", "", true, ...
                    "direct result-schema behavior");
            case "workbench"
                targets = target(opts.SpecsRoot, owner, "presentation", "", "", true, ...
                    "direct workbench presentation behavior in every declared environment");
                if name == "buildlayout.m"
                    targets = [targets, target(opts.SpecsRoot, "apps/conformance", ...
                        "product", "hidden-gui", packageName, false, ...
                        "parameterized App smoke after layout assembly", ...
                        layoutManualCheck(packageName))];
                end
            case {"steppreview", "curvepreview", "thermalpreview", ...
                    "focuspreview", "imagepreview", "videopreview", ...
                    "displaymapping", "enhancementpipeline", "matchpipeline"}
                targets = target(opts.SpecsRoot, owner, ...
                    "presentation", "headless", "", true, ...
                    "direct App presentation-helper behavior");
            case "motionestimate"
                targets = target(opts.SpecsRoot, owner, ...
                    "scientific", "headless", "", true, ...
                    "direct App scientific-helper behavior");
            otherwise
                targets = target(opts.SpecsRoot, owner, "source", "headless", "", true, ...
                    "direct capability source behavior");
        end
        return;
    end
    if startsWith(opts.File, ".agents/") || opts.File == "AGENTS.md"
        targets = target(opts.SpecsRoot, classification.Owner, "system", ...
            "headless", "", true, "repository policy behavior");
        return;
    end
    error("LabKit:TestLocation:UnknownSource", ...
        "No authoring location is defined for %s.", opts.File);
end

function targets = analysisTargets(specsRoot, appOwner, analysisOwner)
    targets = [ ...
        target(specsRoot, analysisOwner, "scientific", "headless", "", true, ...
            "direct analysis behavior"), ...
        target(specsRoot, appOwner + "/resultFiles", "result", "headless", "", true, ...
            "bounded result-schema consumer"), ...
        target(specsRoot, appOwner + "/workbench", "presentation", "headless", "", true, ...
            "bounded presentation consumer")];
end

function targets = appDefinitionTargets(specsRoot, packageName)
    targets = [ ...
        target(specsRoot, "apps/conformance", "definition", "headless", ...
            packageName, false, "parameterized App definition conformance"), ...
        target(specsRoot, "apps/conformance", "product", "hidden-gui", ...
            packageName, false, "parameterized App smoke conformance"), ...
        target(specsRoot, "apps/conformance", "product", "path-isolated", ...
            "", false, "batched App isolated-boundary conformance")];
end

function value = layoutManualCheck(packageName)
    value = "Open " + packageName + " with a representative synthetic or " + ...
        "approved non-sensitive sample; inspect native dialogs, pointer " + ...
        "interaction, and visual layout after the automated structural check.";
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

function value = target(specsRoot, owner, contract, environment, app, authorOwned, reason, manualCheck)
    if nargin < 8
        manualCheck = "";
    end
    value = struct( ...
        "Owner", string(owner), ...
        "Contract", string(contract), ...
        "Environment", string(environment), ...
        "App", string(app), ...
        "Folder", string(fullfile(specsRoot, char(replace(owner, "/", filesep)))), ...
        "AuthorOwned", logical(authorOwned), ...
        "ManualCheck", string(manualCheck), ...
        "Reason", string(reason));
end

function root = defaultSpecsRoot()
    packageFolder = fileparts(mfilename("fullpath"));
    root = fullfile(fileparts(fileparts(packageFolder)), "tests", "specs");
end

function value = normalizePath(value)
    value = strip(replace(string(value), "\", "/"));
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
