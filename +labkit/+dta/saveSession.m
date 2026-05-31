function saveSession(session, filepath)
%SAVESESSION Save a LabKit session struct to a MAT file.
%
% Inputs:
%   session - labkit_session struct from makeSession/loadSession.
%   filepath - output MAT file path.
%
% Output:
%   Writes variable session to filepath; no return value.

    if nargin < 2 || isempty(filepath)
        error('A session filepath is required.');
    end
    if ~isstruct(session) || ~isfield(session, 'type') || ~strcmp(session.type, 'labkit_session')
        error('Input must be a labkit_session struct.');
    end

    save(filepath, 'session');
end
