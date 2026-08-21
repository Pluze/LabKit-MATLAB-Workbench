function classification = classifyPath(file)
%CLASSIFYPATH Classify one repository path for LabKit validation planning.
%   CLASSIFICATION = labkittest.classifyPath(FILE) returns a stable structural
%   classification for one repository-relative path. Kind is "mapped" when
%   the catalog owns automated evidence, "ignored" when a named non-test
%   maintainer task owns the path, or "unknown" when the path has no declared
%   validation ownership. Unknown is intentionally not a conservative fallback:
%   callers must define the production role or explicitly classify the path.

    file = normalizePath(file);
    parts = split(file, "/");
    classification = unknown(file, ...
        "No validation ownership is declared for this repository path.");

    if startsWith(file, "tests/specs/")
        [folder, ~, ~] = fileparts(char(file));
        owner = extractAfter(string(folder), "tests/specs/");
        classification = mapped(file, "specification", owner, ...
            "changed specification selects its physical owner");
        return;
    end
    if startsWith(file, "tests/+labkittest/") || file == "buildfile.m" || ...
            startsWith(file, ".github/")
        classification = mapped(file, "validation-framework", "tests/labkittest", ...
            "validation framework or CI policy behavior");
        return;
    end
    if startsWith(file, ".agents/skills/") && endsWith(file, ".m")
        classification = mapped(file, "validation-framework", "tests/labkittest", ...
            "Skill-owned MATLAB automation executes repository behavior");
        return;
    end
    if startsWith(file, ".agents/") || file == "AGENTS.md" || ...
            file == "sync-develop.sh" || ...
            endsWith(file, "/AGENTS.md") || file == ".gitignore"
        classification = mapped(file, "repository-policy", "repository", ...
            "repository policy behavior");
        return;
    end
    if file == "README.md" || startsWith(file, "docs/") || ...
            startsWith(file, "site/") || ...
            startsWith(file, "tools/docs/")
        classification = ignored(file, "documentation", ...
            "documentation source or generated output; docsCheck owns consistency");
        return;
    end
    if startsWith(file, "tools/maintenance/")
        classification = mapped(file, "maintenance-tool", "tools/maintenance", ...
            "independently callable repository maintenance tool");
        return;
    end
    if startsWith(file, "tools/profiling/")
        classification = mapped(file, "profiling-tool", "tools/profiling", ...
            "independently callable profiling target and report behavior");
        return;
    end
    if startsWith(file, "tools/codecheck/")
        classification = mapped(file, "codecheck-tool", "tools/codecheck", ...
            "independently callable static-analysis and report behavior");
        return;
    end
    if startsWith(file, "tools/deployment/")
        classification = mapped(file, "deployment-tool", "tools/deployment", ...
            "independently callable packaging and version-management behavior");
        return;
    end
    if startsWith(file, "artifacts/") || startsWith(file, ".Trash/") || ...
            startsWith(file, ".DS_Store")
        classification = ignored(file, "generated-artifact", ...
            "generated local artifact; no repository validation is required");
        return;
    end
    if startsWith(file, "tests/+testfixtures/")
        classification = mapped(file, "test-fixture", "tests/labkittest", ...
            "cross-owner synthetic fixture behavior");
        return;
    end
    if file == "labkit_launcher.m"
        classification = mapped(file, "repair-launcher", "labkit_launcher", ...
            "self-contained repair-launcher bootstrap behavior");
        return;
    end
    if startsWith(file, "+labkit/+app/+internal/+launcher/")
        classification = mapped(file, "installed-launcher", ...
            "labkit/app/internal/launcher", ...
            "installed Launcher composition and routing behavior");
        return;
    end
    if startsWith(file, "+labkit/") && numel(parts) >= 2 && startsWith(parts(2), "+")
        area = erase(parts(2), "+");
        if ismember(area, ["app", "biosignal", "contract", "dta", "image", ...
                "mark10", "rhs", "thermal"])
            classification = mapped(file, "framework-facade", "labkit/" + area, ...
                "direct public facade behavior");
            return;
        end
        classification = unknown(file, "Unrecognized LabKit facade area: " + area + ".");
        return;
    end
    if startsWith(file, "apps/") && numel(parts) == 4 && ...
            startsWith(parts(4), "labkit_") && endsWith(parts(4), "_app.m")
        classification = mapped(file, "app-launcher", "", ...
            "public App launcher conformance");
        return;
    end
    if startsWith(file, "apps/") && numel(parts) >= 5 && startsWith(parts(4), "+")
        capability = "";
        if numel(parts) >= 6 && startsWith(parts(5), "+")
            capability = erase(parts(5), "+");
        end
        app = erase(parts(4), "+");
        family = parts(2);
        owner = "apps/" + family + "/" + app;
        if numel(parts) == 5
            name = lower(parts(5));
            switch name
                case "definition.m"
                    role = "app-definition";
                case "createsession.m"
                    role = "app-session";
                case "initialdata.m"
                    role = "app-state";
                otherwise
                    role = "app-product-root";
            end
            classification = mapped(file, role, owner, ...
                "App structural role with explicit evidence policy");
            return;
        end
        if strlength(capability) == 0
            classification = unknown(file, ...
                "Recognized App " + app + " but no capability package is declared.");
            return;
        end
        classification = mapped(file, "app-capability", owner + "/" + capability, ...
            "App capability role with explicit evidence policy");
        return;
    end
end

function value = mapped(file, role, owner, reason)
value = valueFor(file, "mapped", role, owner, reason);
end

function value = ignored(file, role, reason)
value = valueFor(file, "ignored", role, "", reason);
end

function value = unknown(file, reason)
value = valueFor(file, "unknown", "", "", reason);
end

function value = valueFor(file, kind, role, owner, reason)
value = struct("Path", string(file), "Kind", string(kind), "Role", string(role), ...
    "Owner", string(owner), "Reason", string(reason));
end

function value = normalizePath(value)
value = strip(replace(string(value), "\\", "/"));
if strlength(value) == 0 || startsWith(value, "/") || contains(value, "..") || contains(value, ":")
    error("LabKit:TestLocation:InvalidPath", ...
        "File must be a repository-relative path.");
end
end
