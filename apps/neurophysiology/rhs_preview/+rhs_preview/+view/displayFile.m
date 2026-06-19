% Expected caller: rhs_preview.run and view helpers. Input is one path-like
% value. Output is a filename-only display string without local directories.
function text = displayFile(filepath)
%DISPLAYFILE Filename-only display label.

    filepath = string(filepath);
    if strlength(filepath) == 0
        text = "none";
        return;
    end
    [~, name, ext] = fileparts(char(filepath));
    text = string([name ext]);
end
