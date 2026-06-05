% App-private image measurement display helper. Expected caller: batch-crop
% app callbacks and selected-file normalization. Input is a path value. Output
% is a filename-like display string and has no side effects.
function name = displayNameFromPath(pathValue)
%DISPLAYNAMEFROMPATH Return the app display name for a source image path.

    [~, base, ext] = fileparts(char(pathValue));
    name = [base ext];
    if isempty(name)
        name = char(pathValue);
    end
end
