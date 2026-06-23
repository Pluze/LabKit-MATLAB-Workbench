function info = versionInfo(facade, current, compatible, status, notes)
%VERSIONINFO Build a LabKit facade version contract struct.
%
% App-facing contract:
%   info = labkit.contract.versionInfo(facade, current, compatible, status, notes)
%
% Inputs:
%   facade - short facade name, for example "ui" or "dta".
%   current - current semantic contract version, for example "2.0.0".
%   compatible - string array of implemented contract ranges, for example
%       ">=2.0 <3".
%   status - "stable", "deprecated", or "experimental".
%   notes - short maintainer-facing compatibility note.
%
% Outputs:
%   info - plain struct with name, facade, current, compatible, status, and
%       notes fields.

    facade = normalizeFacade(facade);
    current = normalizeText(current, 'current');
    compatible = string(compatible);
    compatible = compatible(:);
    compatible = strtrim(compatible(strlength(strtrim(compatible)) > 0));
    status = lower(normalizeText(status, 'status'));
    notes = normalizeText(notes, 'notes');

    if isempty(compatible)
        error('labkit:contract:InvalidVersionInfo', ...
            'Facade "%s" must advertise at least one compatible range.', facade);
    end
    if ~any(status == ["stable"; "deprecated"; "experimental"])
        error('labkit:contract:InvalidVersionInfo', ...
            'Facade "%s" has unsupported status "%s".', facade, status);
    end

    info = struct();
    info.name = "labkit." + facade;
    info.facade = facade;
    info.current = current;
    info.compatible = compatible;
    info.status = status;
    info.notes = notes;
end

function facade = normalizeFacade(value)
    facade = lower(normalizeText(value, 'facade'));
    if startsWith(facade, "labkit.")
        facade = extractAfter(facade, strlength("labkit."));
    end
    if strlength(facade) == 0
        error('labkit:contract:InvalidVersionInfo', ...
            'Facade name cannot be empty.');
    end
end

function text = normalizeText(value, label)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error('labkit:contract:InvalidVersionInfo', ...
            '%s must be a text scalar.', label);
    end
    text = strtrim(string(value));
end
