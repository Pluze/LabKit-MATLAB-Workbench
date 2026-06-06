% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function session = makeSessionStruct(kind, opts)
%MAKESESSIONSTRUCT Create the canonical private LabKit session struct.
%
% Called by:
%   labkit.dta.makeSession and session-loading helpers.
%
% Inputs:
%   kind - optional session family label; defaults to "generic".
%   opts - optional struct. opts.options seeds session.options and opts.notes
%          seeds session.notes.
%
% Output:
%   session - labkit_session struct with type, version, kind, timestamps,
%             items, results, options, notes, and logmsg fields.

    if nargin < 1 || isempty(kind)
        kind = 'generic';
    end
    if nargin < 2
        opts = struct();
    end

    timestamp = datestr(now, 'yyyy-mm-ddTHH:MM:SS');

    session = struct();
    session.type = 'labkit_session';
    session.version = 1;
    session.kind = char(kind);
    session.createdAt = timestamp;
    session.modifiedAt = timestamp;
    session.items = struct([]);
    session.results = struct([]);
    session.options = struct();
    session.notes = '';
    session.logmsg = {};

    if isfield(opts, 'options')
        session.options = opts.options;
    end
    if isfield(opts, 'notes')
        session.notes = char(opts.notes);
    end
end
