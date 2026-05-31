function session = loadSession(filepath)
%LOADSESSION Load a LabKit session struct from a MAT file.
%
% Inputs:
%   filepath - MAT file containing a variable named session.
%
% Output:
%   session - validated labkit_session struct.

    if nargin < 1 || isempty(filepath)
        error('A session filepath is required.');
    end

    data = load(filepath);
    if ~isfield(data, 'session') || ~isstruct(data.session) ...
            || ~isfield(data.session, 'type') || ~strcmp(data.session.type, 'labkit_session')
        error('File does not contain a labkit_session struct.');
    end
    session = data.session;
end
