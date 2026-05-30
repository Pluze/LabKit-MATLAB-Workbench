function session = makeSession(kind, opts)
%MAKESESSION Create a DTA app session without exposing lower-level data APIs.

    if nargin < 1
        kind = 'dta';
    end
    if nargin < 2
        opts = struct();
    end

    session = gamrywb.data.makeSession(kind, opts);
end
