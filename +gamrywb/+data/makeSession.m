function session = makeSession(kind, opts)
%MAKESESSION Create a shared Gamry workbench session struct.

    if nargin < 1 || isempty(kind)
        kind = 'generic';
    end
    if nargin < 2
        opts = struct();
    end

    timestamp = datestr(now, 'yyyy-mm-ddTHH:MM:SS');

    session = struct();
    session.type = 'gamrywb_session';
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
