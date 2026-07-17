function info = versionInfo(facade, current, compatible, status, notes)
%VERSIONINFO Describe one LabKit API version and its compatibility range.
%
% Usage:
%   info = labkit.contract.versionInfo(facade, current, compatible, status, notes)
%
% Description:
%   Creates the standard structure returned by module version functions. The
%   function normalizes text and validates the status value, but it does not
%   parse current or compatible as semantic versions. checkRequirements parses
%   those values when it performs a comparison.
%
% Inputs:
%   facade - Character vector or string scalar, such as "ui", "dta", or
%       "labkit.image". The optional "labkit." prefix is removed.
%   current - Character vector or string scalar containing the current API
%       version, normally a semantic version such as "2.0.0".
%   compatible - Character vector, string scalar, or string array containing
%       one or more supported requirement ranges, such as ">=2.0 <3".
%   status - "stable", "deprecated", or "experimental". Matching is
%       case-insensitive.
%   notes - Character vector or string scalar summarizing the module contract.
%
% Outputs:
%   info - Scalar structure with name, facade, current, compatible, status,
%       and notes. name includes the "labkit." prefix; compatible is a string
%       column vector; other text values are string scalars.
%
% Errors:
%   Throws labkit:contract:InvalidVersionInfo for nontext scalar inputs, an
%   empty facade, no nonempty compatible ranges, or an unsupported status.
%
% Example:
%   info = labkit.contract.versionInfo( ...
%       "image", "4.1.0", ">=4 <5", "stable", ...
%       "Image file IO and processing functions.");
%
% See also labkit.contract.requirements,
%   labkit.contract.checkRequirements

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
