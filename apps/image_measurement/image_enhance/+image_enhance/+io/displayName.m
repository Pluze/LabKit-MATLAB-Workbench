% Expected caller: Image Enhance app import/progress helpers. Input is one
% file path. Output is the filename plus extension for user-facing logs.
function name = displayName(path)
    [~, base, ext] = fileparts(char(path));
    name = string([base ext]);
end
