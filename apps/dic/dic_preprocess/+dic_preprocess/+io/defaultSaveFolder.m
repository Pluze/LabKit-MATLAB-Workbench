% Expected caller: DIC preprocess runner and direct unit tests. Inputs are the
% current reference/moving image paths plus an optional fallback folder. Output
% is the dialog default folder. Side effects: none.

function folder = defaultSaveFolder(referencePath, movingPath, fallbackFolder)
%DEFAULTSAVEFOLDER Choose the DIC preprocess current-image save folder.

    if nargin < 3 || strlength(string(fallbackFolder)) == 0
        fallbackFolder = tempdir;
    end

    [folder, ~] = fileparts(char(referencePath));
    if isempty(folder)
        [folder, ~] = fileparts(char(movingPath));
    end
    if isempty(folder)
        folder = char(fallbackFolder);
    end
end
