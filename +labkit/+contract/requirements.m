function req = requirements(varargin)
%REQUIREMENTS Build a LabKit facade requirement contract.
%
% App-facing contract:
%   req = labkit.contract.requirements("ui", ">=2.0 <3", ...)
%
% Inputs:
%   Facade/range pairs - facade names such as "ui", "dta", "rhs",
%       "biosignal", or "image", followed by simple semantic-version ranges.
%       Ranges use whitespace-separated constraints such as ">=2.0 <3".
%
% Outputs:
%   req - struct with type and facades fields. The facades field is a struct
%       array with facade and range fields, suitable for app requirements()
%       functions and labkit.contract.checkRequirements.

    if mod(numel(varargin), 2) ~= 0
        error('labkit:contract:InvalidRequirements', ...
            'Requirements must be facade/range pairs.');
    end

    entries = repmat(struct('facade', "", 'range', ""), 0, 1);
    for k = 1:2:numel(varargin)
        facade = normalizeFacade(varargin{k});
        rangeText = normalizeRange(varargin{k + 1});
        if ~isempty(entries) && any([entries.facade] == facade)
            error('labkit:contract:DuplicateRequirement', ...
                'Facade "%s" is listed more than once.', facade);
        end
        entries(end + 1, 1) = struct('facade', facade, 'range', rangeText);
    end

    req = struct();
    req.type = "labkit.requirements";
    req.facades = entries;
end

function facade = normalizeFacade(value)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error('labkit:contract:InvalidFacadeName', ...
            'Facade names must be text scalars.');
    end
    facade = lower(strtrim(string(value)));
    if startsWith(facade, "labkit.")
        facade = extractAfter(facade, strlength("labkit."));
    end
    if strlength(facade) == 0 || any(~isstrprop(char(facade), 'alphanum') & char(facade) ~= '_')
        error('labkit:contract:InvalidFacadeName', ...
            'Invalid LabKit facade name "%s".', facade);
    end
end

function rangeText = normalizeRange(value)
    if ~(ischar(value) || (isstring(value) && isscalar(value)))
        error('labkit:contract:InvalidVersionRange', ...
            'Version ranges must be text scalars.');
    end
    rangeText = strtrim(string(value));
    if strlength(rangeText) == 0
        error('labkit:contract:InvalidVersionRange', ...
            'Version ranges cannot be empty.');
    end
end
