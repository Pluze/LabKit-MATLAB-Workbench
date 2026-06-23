function folder = defaultDialogFolder(kind, proposedFolder)
%DEFAULTDIALOGFOLDER Return a safe default folder for file dialogs.
%
% App-facing contract:
%   folder = labkit.ui.app.defaultDialogFolder(kind)
%   folder = labkit.ui.app.defaultDialogFolder(kind, proposedFolder)
%
% Inputs:
%   kind - "input" or "output". Defaults to "input".
%   proposedFolder - optional folder preferred by the caller.
%
% Outputs:
%   folder - existing folder path outside the LabKit install root. The helper
%       uses remembered input/output folders when available, then falls back to
%       the user profile, userpath, or tempdir.

    if nargin < 1 || isempty(kind)
        kind = "input";
    end
    if nargin < 2
        proposedFolder = "";
    end

    kind = normalizeKind(kind);
    proposed = existingSafeFolder(proposedFolder);
    if strlength(proposed) > 0
        folder = char(proposed);
        return;
    end

    remembered = existingSafeFolder(rememberedFolder(kind));
    if strlength(remembered) > 0
        folder = char(remembered);
        return;
    end

    fallback = existingSafeFolder(userFolder());
    if strlength(fallback) == 0
        fallback = string(tempdir);
    end
    folder = char(fallback);
end

function kind = normalizeKind(kind)
    if ~(ischar(kind) || (isstring(kind) && isscalar(kind)))
        error('labkit:ui:app:InvalidDialogKind', ...
            'Dialog kind must be "input" or "output".');
    end
    kind = lower(strtrim(string(kind)));
    if ~any(kind == ["input", "output"])
        error('labkit:ui:app:InvalidDialogKind', ...
            'Dialog kind must be "input" or "output".');
    end
end

function folder = rememberedFolder(kind)
    if kind == "output"
        prefName = 'LastOutputFolder';
    else
        prefName = 'LastInputFolder';
    end
    if ispref('LabKit', prefName)
        folder = string(getpref('LabKit', prefName));
    else
        folder = "";
    end
end

function folder = userFolder()
    folder = string(getenv('USERPROFILE'));
    if strlength(folder) > 0
        return;
    end
    rawUserPath = string(userpath);
    if strlength(rawUserPath) == 0
        folder = "";
        return;
    end
    parts = split(rawUserPath, pathsep);
    parts = parts(strlength(parts) > 0);
    if isempty(parts)
        folder = "";
    else
        folder = parts(1);
    end
end

function folder = existingSafeFolder(value)
    folder = "";
    if isempty(value)
        return;
    end
    value = string(value);
    if isempty(value)
        return;
    end
    value = strtrim(value(1));
    if strlength(value) == 0 || exist(char(value), 'dir') ~= 7
        return;
    end
    if isInsideLabKitRoot(value)
        return;
    end
    folder = value;
end

function tf = isInsideLabKitRoot(folder)
    root = labkitRoot();
    if strlength(root) == 0
        tf = false;
        return;
    end
    folder = normalizedFolder(folder);
    root = normalizedFolder(root);
    tf = folder == root || startsWith(folder, root + filesep);
end

function root = labkitRoot()
    current = string(mfilename('fullpath'));
    root = string(fileparts(fileparts(fileparts(fileparts(char(current))))));
end

function value = normalizedFolder(value)
    value = string(value);
    try
        value = string(char(java.io.File(char(value)).getCanonicalPath()));
    catch
        value = string(char(value));
    end
    value = eraseTrailingFilesep(value);
end

function value = eraseTrailingFilesep(value)
    value = string(value);
    while strlength(value) > 1 && endsWith(value, filesep)
        value = extractBefore(value, strlength(value));
    end
end
