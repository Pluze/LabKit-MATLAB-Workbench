% Private filePanel helper. Expected caller: buildFilePanelControl and its
% adapter callbacks. Input is a user or test supplied path list. Output is a
% nonempty-column string array. Side effects: none.
function paths = filePanelNormalizePathList(value)
    if isempty(value)
        paths = strings(0, 1);
    elseif ischar(value)
        paths = string({value});
    elseif isstring(value)
        paths = value;
    elseif iscell(value)
        paths = string(value);
    else
        error('labkit:ui:app:InvalidFilePathList', ...
            'filePanel values must be char, string, or a cell array.');
    end
    paths = paths(:);
    paths = paths(strlength(paths) > 0);
end
