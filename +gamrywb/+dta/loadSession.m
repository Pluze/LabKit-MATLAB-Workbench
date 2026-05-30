function session = loadSession(filepath)
%LOADSESSION Load a Gamry workbench session struct from a MAT file.

    if nargin < 1 || isempty(filepath)
        error('A session filepath is required.');
    end

    data = load(filepath);
    if ~isfield(data, 'session') || ~isstruct(data.session) ...
            || ~isfield(data.session, 'type') || ~strcmp(data.session.type, 'gamrywb_session')
        error('File does not contain a gamrywb_session struct.');
    end
    session = data.session;
end
