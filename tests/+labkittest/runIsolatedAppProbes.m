function [status, output] = runIsolatedAppProbes(apps)
%RUNISOLATEDAPPPROBES Verify public Apps through reset path boundaries.
%   [STATUS, OUTPUT] = labkittest.runIsolatedAppProbes(APPS) starts one child
%   MATLAB process for the supplied public-App descriptors. Before each App,
%   that child restores MATLAB's default path and clears loaded classes; the
%   App then runs with only the repository root and its own App folder.
%
%   APPS can be a descriptor array from labkittest.publicApps or that
%   function's scalar parameter-value structure. STATUS is zero only when
%   every App proves its definition and synthetic debug-sample contract.
%   OUTPUT names every failing App, so batching startup does not hide which
%   deployable boundary failed.

    apps = normalizedApps(apps);
    packageFolder = fileparts(mfilename("fullpath"));
    testsFolder = fileparts(packageFolder);
    root = fileparts(testsFolder);
    scratch = tempname;
    scriptPath = tempname + ".m";
    cleanup = onCleanup(@() removeScript(scriptPath));
    writeChildScript(scriptPath, root, testsFolder, apps, scratch);
    command = matlabCommand();
    [status, output] = system(char(shellDoubleQuote(command) + " -batch " + ...
        shellDoubleQuote("run(" + matlabLiteral(scriptPath) + ");")));
    clear cleanup
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

function writeChildScript(path, root, testsFolder, apps, scratch)
    file = fopen(char(path), "w");
    if file < 0
        error("LabKit:IsolatedProbe:WriteScript", ...
            "Unable to create the isolated probe script.");
    end
    cleanup = onCleanup(@() fclose(file));
    for k = 1:numel(apps)
        app = apps(k);
        appScratch = fullfile(scratch, num2str(k));
        fprintf(file, "restoredefaultpath;\nclear classes;\n");
        fprintf(file, "addpath(%s);\n", matlabLiteral(testsFolder));
        fprintf(file, "try\n");
        fprintf(file, "  labkittest.isolatedAppProbe(%s, %s, %s, %s);\n", ...
            matlabLiteral(root), matlabLiteral(app.Folder), ...
            matlabLiteral(app.Package), matlabLiteral(appScratch));
        fprintf(file, "  fprintf('ISOLATED_APP_PROBE %s PASS\\n');\n", ...
            char(app.Package));
        fprintf(file, "catch exception\n");
        fprintf(file, "  error('LabKit:IsolatedProbe:BatchFailed', ...\n");
        fprintf(file, "    '%%s: %%s', %s, getReport(exception, 'basic', 'hyperlinks', 'off'));\n", ...
            matlabLiteral(app.Package));
        fprintf(file, "end\n");
    end
    clear cleanup
end

function removeScript(path)
    if isfile(path)
        delete(path);
    end
end

function command = matlabCommand()
    command = fullfile(matlabroot, "bin", "matlab");
    if ispc
        command = command + ".exe";
    end
end

function text = matlabLiteral(value)
    text = "'" + replace(string(value), "'", "''") + "'";
end

function text = shellDoubleQuote(value)
    value = string(value);
    quote = string(char(34));
    if contains(value, quote)
        error("LabKit:IsolatedProbe:UnsafePath", ...
            "The isolated probe command cannot contain double quotes.");
    end
    text = quote + value + quote;
end
