function folder = resolveLabKitDocFolder(folder, identifier, message)
%RESOLVELABKITDOCFOLDER Validate and absolutize one documentation folder.
% Expected callers: documentation rendering and link/tree maintenance tools.
% Inputs are a folder plus the caller-owned error identifier and message.
% Output is an absolute folder path. Side effects: none.

folder = string(folder);
if ~isfolder(folder)
    error(identifier, message, folder);
end
if ~isAbsolutePath(folder)
    folder = string(fullfile(pwd, folder));
end
end

function tf = isAbsolutePath(path)
tf = startsWith(path, filesep) || ...
    ~isempty(regexp(char(path), '^[A-Za-z]:[\\/]', 'once'));
end
