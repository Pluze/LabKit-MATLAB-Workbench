% App-owned image measurement package helper. Expected caller: owning app callbacks
% and package tests. Inputs, outputs, and side effects are
% documented with the helper function below.
function name = displayNameFromPath(pathValue)
%DISPLAYNAMEFROMPATH Return the app display name for a source image path.
%
% Expected caller:
%   labkit_FocusStack_app display helpers and package-owned summary-table code.
%
% Inputs/outputs:
%   String-like path value. Returns base filename plus extension, or the
%   original value when no file name can be derived.
%
% Side effects:
%   None.

    [~, base, ext] = fileparts(char(pathValue));
    name = [base ext];
    if isempty(name)
        name = char(pathValue);
    end
end
