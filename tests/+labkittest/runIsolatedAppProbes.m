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
%   deployable boundary failed. The child continues after an App failure and
%   reports the aggregate after every supplied App has been probed.

    apps = normalizedApps(apps);
    packageFolder = fileparts(mfilename("fullpath"));
    testsFolder = fileparts(packageFolder);
    root = fileparts(testsFolder);
    scratch = tempname;
    scriptPath = tempname + ".m";
    cleanup = onCleanup(@() removeScratch(scriptPath, scratch));
    writeChildScript(scriptPath, root, testsFolder, apps, scratch);
    command = matlabCommand();
    [status, output] = system(char(shellDoubleQuote(command) + " -batch " + ...
        shellDoubleQuote("run(" + matlabLiteral(scriptPath) + ");")));
    if status ~= 0
        fprintf(2, "ISOLATED MATLAB CHILD OUTPUT:\n%s\n", output);
        error("LabKit:IsolatedProbe:ChildFailed", ...
            "The isolated MATLAB child failed (status %d):\n%s", status, output);
    end
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
    failurePath = fullfile(scratch, "failures.mat");
    fprintf(file, "mkdir(%s);\n", matlabLiteral(scratch));
    for k = 1:numel(apps)
        app = apps(k);
        appScratch = fullfile(scratch, num2str(k));
        fprintf(file, "restoredefaultpath;\nclear classes;\n");
        fprintf(file, "addpath(%s);\n", matlabLiteral(testsFolder));
        fprintf(file, "failurePath = %s;\n", matlabLiteral(failurePath));
        fprintf(file, "if isfile(failurePath), load(failurePath, 'failures'); else, failures = {}; end\n");
        fprintf(file, "try\n");
        fprintf(file, "  labkittest.isolatedAppProbe(%s, %s, %s, %s);\n", ...
            matlabLiteral(root), matlabLiteral(app.Folder), ...
            matlabLiteral(app.Package), matlabLiteral(appScratch));
        fprintf(file, "  fprintf('ISOLATED_APP_PROBE %s PASS\\n');\n", ...
            char(app.Package));
        fprintf(file, "catch exception\n");
        fprintf(file, "  failures{numel(failures) + 1} = sprintf('%%s: %%s', %s, ...\n", ...
            matlabLiteral(app.Package));
        fprintf(file, "    getReport(exception, 'basic', 'hyperlinks', 'off'));\n");
        fprintf(file, "  save(failurePath, 'failures');\n");
        fprintf(file, "  fprintf('ISOLATED_APP_PROBE %s FAIL\\n');\n", ...
            char(app.Package));
        fprintf(file, "end\n");
    end
    fprintf(file, "restoredefaultpath;\nclear classes;\n");
    fprintf(file, "failurePath = %s;\n", matlabLiteral(failurePath));
    fprintf(file, "if isfile(failurePath), load(failurePath, 'failures'); else, failures = {}; end\n");
    fprintf(file, "if ~isempty(failures)\n");
    fprintf(file, "  error('LabKit:IsolatedProbe:BatchFailed', '%%s', ...\n");
    fprintf(file, "    strjoin(failures, sprintf('\\n\\n')));\n");
    fprintf(file, "end\n");
    clear cleanup
end

function removeScratch(scriptPath, scratch)
    if isfile(scriptPath)
        delete(scriptPath);
    end
    if isfolder(scratch)
        rmdir(scratch, "s");
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
