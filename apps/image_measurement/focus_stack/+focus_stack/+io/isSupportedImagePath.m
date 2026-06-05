% App-owned focus-stack extension predicate. Expected caller: focus-stack app
% package loading helpers. Input is a path or filename. Output is a scalar
% logical based on the file extension only.
function tf = isSupportedImagePath(pathValue)
%ISSUPPORTEDIMAGEPATH Return true for supported focus-stack image files.
% Expected caller: focus-stack app package loading helpers. Input is a path or
% filename. Output is a scalar logical based on the file extension only.

    [~, ~, ext] = fileparts(char(pathValue));
    tf = any(strcmpi(ext, focus_stack.io.supportedImageExtensions()));
end
