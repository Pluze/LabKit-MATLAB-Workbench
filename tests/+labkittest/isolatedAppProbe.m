function isolatedAppProbe(root, appFolder, packageName, scratchRoot)
%ISOLATEDAPPPROBE Verify one App from only its deployable path boundary.
%   labkittest.isolatedAppProbe(ROOT, APPFOLDER, PACKAGE, SCRATCHROOT) is the
%   reset-path implementation used by labkittest.runIsolatedAppProbes. It
%   restores MATLAB's default path, adds ROOT and APPFOLDER only, validates the
%   App definition, and launches its default state. It throws on any
%   boundary or contract failure so the caller can aggregate every App result.

    root = string(root);
    appFolder = string(appFolder);
    packageName = string(packageName);
    scratchRoot = string(scratchRoot);
    validateFolder(root, "repository root");
    validateFolder(appFolder, "App folder");
    if strlength(packageName) == 0 || contains(packageName, ["/", "\\", "."])
        error("LabKit:IsolatedProbe:InvalidPackage", ...
            "Package must be one App package identifier.");
    end
    mkdir(scratchRoot);
    cleanup = onCleanup(@() removeFolder(scratchRoot));
    restoredefaultpath;
    addpath(char(root));
    addpath(char(appFolder));
    rehash path

    definition = feval(char(packageName + ".definition"));
    assert(string(definition.AppId) == packageName, ...
        "LabKit:IsolatedProbe:WrongAppId", ...
        "App definition identity does not match its package.");
    assert(~isempty(regexp(string(definition.AppVersion), '^\d+\.\d+\.\d+$', "once")), ...
        "LabKit:IsolatedProbe:InvalidVersion", ...
        "App definition must expose a semantic AppVersion.");
    if ~isempty(definition.Requirements)
        requirements = labkit.contract.checkRequirements(definition.Requirements);
        assert(requirements.ok, "LabKit:IsolatedProbe:Requirements", ...
            "App definition requirements are not satisfiable.");
    end
    journal = labkit.app.internal.diagnostics.SessionJournal(definition, ...
        RootFolder=fullfile(scratchRoot, "session-journal"));
    runtime = labkit.app.internal.runtime.RuntimeFactory.createHeadless( ...
        definition, [], struct(), ...
        journal);
    runtimeCleanup = onCleanup(@() runtime.close());
    clear runtimeCleanup
    clear cleanup
end

function validateFolder(folder, label)
    if exist(folder, "dir") ~= 7
        error("LabKit:IsolatedProbe:MissingFolder", ...
            "The %s does not exist: %s", label, folder);
    end
end

function removeFolder(folder)
    if isfolder(folder)
        rmdir(folder, "s");
    end
end
