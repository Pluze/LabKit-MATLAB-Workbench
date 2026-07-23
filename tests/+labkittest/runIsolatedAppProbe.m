function [status, output] = runIsolatedAppProbe(app)
%RUNISOLATEDAPPPROBE Run one public App contract in a clean MATLAB process.
%   [STATUS, OUTPUT] = labkittest.runIsolatedAppProbe(APP) starts a child
%   MATLAB process that restores the default path, adds only the repository
%   root and APP.Folder, then checks APP.Package.definition and its synthetic
%   debug sample. APP is one value returned by labkittest.publicApps.
%
%   STATUS is zero only when the child completed its isolated proof. OUTPUT is
%   the child command output and is suitable for a test diagnostic. The child
%   process deliberately does not inherit a full LabKit test path.

    required = ["Package", "Folder"];
    if ~isstruct(app) || ~all(isfield(app, required))
        error("LabKit:IsolatedProbe:InvalidApp", ...
            "APP must be a value returned by labkittest.publicApps.");
    end
    packageFolder = fileparts(mfilename("fullpath"));
    testsFolder = fileparts(packageFolder);
    root = fileparts(testsFolder);
    scratch = tempname;
    command = matlabCommand();
    script = "addpath(" + matlabLiteral(testsFolder) + ");" + ...
        "labkittest.isolatedAppProbe(" + matlabLiteral(root) + "," + ...
        matlabLiteral(app.Folder) + "," + matlabLiteral(app.Package) + "," + ...
        matlabLiteral(scratch) + ");";
    [status, output] = system(char(shellDoubleQuote(command) + ...
        " -batch " + shellDoubleQuote(script)));
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
