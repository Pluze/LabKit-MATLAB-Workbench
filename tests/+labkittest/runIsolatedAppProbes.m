function [status, output] = runIsolatedAppProbes(apps)
%RUNISOLATEDAPPPROBES Verify public Apps through reset path boundaries.
%   [STATUS, OUTPUT] = labkittest.runIsolatedAppProbes(APPS) probes the
%   supplied public-App descriptors in the catalog runner. Before each App, it
%   restores MATLAB's default path; the App then runs with only the repository
%   root and its own App folder.
%
%   APPS can be a descriptor array from labkittest.publicApps or that
%   function's scalar parameter-value structure. STATUS is zero only when
%   every App proves its definition and synthetic debug-sample contract.
%   OUTPUT names every failing App, so batching startup does not hide which
%   deployable boundary failed. The probe continues after an App failure and
%   reports the aggregate after every supplied App has been probed.

    apps = normalizedApps(apps);
    packageFolder = fileparts(mfilename("fullpath"));
    testsFolder = fileparts(packageFolder);
    root = fileparts(testsFolder);
    scratch = string(tempname);
    cleanup = onCleanup(@() restoreRunner(testsFolder, scratch));
    messages = strings(1, numel(apps));
    failed = false(1, numel(apps));
    for k = 1:numel(apps)
        app = apps(k);
        appScratch = fullfile(scratch, num2str(k));
        try
            restoredefaultpath;
            addpath(testsFolder);
            labkittest.isolatedAppProbe(root, app.Folder, app.Package, appScratch);
            messages(k) = "ISOLATED_APP_PROBE " + app.Package + " PASS";
        catch exception
            failed(k) = true;
            messages(k) = "ISOLATED_APP_PROBE " + app.Package + " FAIL" + newline + ...
                string(getReport(exception, "basic", "hyperlinks", "off"));
        end
    end
    status = double(any(failed));
    output = strjoin(messages, newline);
    clear cleanup
end

function restoreRunner(testsFolder, scratch)
    restoredefaultpath;
    addpath(testsFolder);
    rehash path
    if isfolder(scratch)
        rmdir(scratch, "s");
    end
end


function apps = normalizedApps(value)
    required = ["Package", "Folder"];
    if ~isstruct(value)
        error("LabKit:IsolatedProbe:InvalidApps", ...
            "APPS must come from labkittest.publicApps.");
    end
    if ~all(isfield(value, required))
        labels = fieldnames(value);
        if isempty(labels) || ~all(cellfun(@(label) isstruct(value.(label)), labels))
            error("LabKit:IsolatedProbe:InvalidApps", ...
                "APPS must come from labkittest.publicApps.");
        end
        apps = repmat(value.(labels{1}), 1, numel(labels));
        for k = 1:numel(labels)
            apps(k) = value.(labels{k});
        end
    else
        apps = value;
    end
    if isempty(apps) || ~all(isfield(apps, required))
        error("LabKit:IsolatedProbe:InvalidApps", ...
            "APPS must contain Package and Folder values.");
    end
end
