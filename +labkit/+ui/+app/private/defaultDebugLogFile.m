% Private debug-launch artifact helper. Expected caller:
% labkit.ui.app.dispatchRequest. Input is an app entry-point name. Output is a
% writable debug log file path under the canonical LabKit artifact root. Side
% effect: creates the parent artifact directory.
function filepath = defaultDebugLogFile(appName)
%DEFAULTDEBUGLOGFILE Return the default app debug trace log path.

    appName = sanitizePathToken(appName, "app");
    artifactsRoot = defaultArtifactsRoot();
    runName = sanitizePathToken(getenv("LABKIT_RUN_NAME"), "");

    if strlength(runName) > 0
        logFolder = fullfile(artifactsRoot, "debug", char(runName), char(appName));
    else
        logFolder = fullfile(artifactsRoot, "debug", char(appName));
    end
    logFolder = ensureWritableFolder(logFolder, appName);

    [~, seed] = fileparts(tempname);
    filename = sprintf('%s_%s_%s.log', ...
        char(appName), datestr(now, 'yyyymmdd_HHMMSS'), seed);
    filepath = fullfile(logFolder, char(filename));
end

function root = defaultArtifactsRoot()
    envRoot = string(getenv("LABKIT_ARTIFACTS"));
    if strlength(envRoot) > 0
        root = char(envRoot);
    else
        root = fullfile(repoRoot(), "artifacts");
    end
end

function root = repoRoot()
    thisFile = mfilename("fullpath");
    privateFolder = fileparts(thisFile);
    appFolder = fileparts(privateFolder);
    uiFolder = fileparts(appFolder);
    labkitFolder = fileparts(uiFolder);
    root = fileparts(labkitFolder);
end

function folder = ensureWritableFolder(folder, appName)
    try
        ensureDirectory(folder);
    catch
        fallbackRoot = fullfile(tempdir, "LabKit-MATLAB-Workbench", "artifacts");
        runName = sanitizePathToken(getenv("LABKIT_RUN_NAME"), "");
        if strlength(runName) > 0
            folder = fullfile(fallbackRoot, "debug", char(runName), char(appName));
        else
            folder = fullfile(fallbackRoot, "debug", char(appName));
        end
        ensureDirectory(folder);
    end
end

function ensureDirectory(folder)
    if exist(folder, "dir") ~= 7
        mkdir(folder);
    end
end

function token = sanitizePathToken(value, fallback)
    token = string(value);
    if strlength(token) == 0
        token = string(fallback);
    end
    token = regexprep(token, "[^A-Za-z0-9_.-]+", "_");
    token = regexprep(token, "^_+|_+$", "");
    if strlength(token) == 0
        token = string(fallback);
    end
end
