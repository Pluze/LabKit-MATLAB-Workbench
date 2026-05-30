function saveSession(session, filepath)
%SAVESESSION Save a Gamry workbench session struct to a MAT file.

    if nargin < 2 || isempty(filepath)
        error('A session filepath is required.');
    end
    if ~isstruct(session) || ~isfield(session, 'type') || ~strcmp(session.type, 'gamrywb_session')
        error('Input must be a gamrywb_session struct.');
    end

    save(filepath, 'session');
end
