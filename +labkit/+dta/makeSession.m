function session = makeSession(kind, opts)
%MAKESESSION Create a DTA app session without exposing lower-level data APIs.
%
% Usage:
%   session = labkit.dta.makeSession();
%   session = labkit.dta.makeSession("chrono");
%
% Inputs:
%   kind - optional char/string session kind, default "dta".
%   opts - reserved optional struct for future session defaults.
%
% Output:
%   session - labkit_session struct with type, version, kind, createdAt,
%             modifiedAt, items, results, options, notes, and logmsg.

    if nargin < 1
        kind = 'dta';
    end
    if nargin < 2
        opts = struct();
    end

    session = makeSessionStruct(kind, opts);
end
