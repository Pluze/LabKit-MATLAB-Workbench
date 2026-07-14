function [targetFile, result] = resolveOrPromptForFileReference(anchorFile, reference, options)
%RESOLVEORPROMPTFORFILEREFERENCE Resolve a saved file or ask the user to locate it.
%
% App-facing contract:
%   [targetFile, result] = labkit.ui.runtime.resolveOrPromptForFileReference( ...
%       anchorFile, reference)
%   [...] = resolveOrPromptForFileReference(..., Name=Value)
%
% Inputs:
%   anchorFile - scalar text project, snapshot, manifest, or autosave path.
%   reference - scalar struct intended for `resolvePortableFileReference`.
%
% Name-value options:
%   Filter - uigetfile-compatible filter; default all files.
%   DialogTitle - prompt title prefix; default `Locate referenced file`.
%   ReferenceLabel - user-facing field/object name included when automatic
%       resolution fails; default `referenced file`.
%   Chooser - injectable `(filter,title,initialFolder)` function handle;
%       default `@uigetfile`.
%
% Outputs:
%   targetFile - canonical automatically resolved or manually selected path;
%       empty text when the user cancels or the selection is invalid.
%   result - struct with `matchKind`, `prompted`, `cancelled`, and `pathIssue`.
%       Match kinds include the resolver values plus `selected`, `cancelled`,
%       and `invalid_selection`.
%
% Malformed references and unavailable paths enter the same manual fallback.
% The app remains responsible for validating selected file contents.

    arguments
        anchorFile (1, 1) string
        reference (1, 1) struct
        options.Filter = {'*.*', 'All files'}
        options.DialogTitle (1, 1) string = "Locate referenced file"
        options.ReferenceLabel (1, 1) string = "referenced file"
        options.Chooser (1, 1) function_handle = @uigetfile
    end
    pathIssue = false;
    try
        [targetFile, matchKind] = ...
            labkit.ui.runtime.resolvePortableFileReference(anchorFile, reference);
    catch
        targetFile = "";
        matchKind = "none";
        pathIssue = true;
    end
    if strlength(targetFile) > 0
        result = outcome(matchKind, false, false, pathIssue);
        return;
    end
    [initialFolder, ~, ~] = fileparts(anchorFile);
    titleText = options.DialogTitle + " - " + options.ReferenceLabel + ...
        " (saved path unavailable)";
    [file, folder] = options.Chooser( ...
        options.Filter, char(titleText), char(initialFolder));
    if isequal(file, 0) || isequal(folder, 0)
        targetFile = "";
        result = outcome("cancelled", true, true, true);
        return;
    end
    selected = string(fullfile(folder, file));
    [exists, attributes] = fileattrib(char(selected));
    if ~exists || attributes.directory
        targetFile = "";
        result = outcome("invalid_selection", true, false, true);
        return;
    end
    targetFile = string(attributes.Name);
    result = outcome("selected", true, false, true);
end

function result = outcome(matchKind, prompted, cancelled, pathIssue)
    result = struct('matchKind', string(matchKind), ...
        'prompted', logical(prompted), 'cancelled', logical(cancelled), ...
        'pathIssue', logical(pathIssue));
end
