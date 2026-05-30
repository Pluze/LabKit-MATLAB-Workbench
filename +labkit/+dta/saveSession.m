function saveSession(session, filepath)
%SAVESESSION Save a LabKit session struct to a MAT file.

    if nargin < 2 || isempty(filepath)
        error('A session filepath is required.');
    end
    if ~isstruct(session) || ~isfield(session, 'type') || ~strcmp(session.type, 'labkit_session')
        error('Input must be a labkit_session struct.');
    end

    save(filepath, 'session');
end
