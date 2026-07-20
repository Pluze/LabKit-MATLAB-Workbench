function req = requirements(varargin)
%REQUIREMENTS Describe the LabKit API versions required by a caller.
%
% Usage:
%   req = labkit.contract.requirements("app", ">=1.0 <2", ...)
%
% Description:
%   Builds a normalized requirement structure from facade/range pairs. A
%   facade name may be written as "app" or "labkit.app". Names are converted to
%   lowercase and the optional "labkit." prefix is removed. No compatibility
%   check is performed until checkRequirements or assertRequirements is called.
%
% Inputs:
%   varargin - Alternating facade names and version ranges. Facade names are
%       text scalars containing letters, digits, or underscores. A range is a
%       nonempty text scalar containing whitespace-separated constraints such
%       as ">=2.0 <3". Supported operators are >, >=, <, <=, =, and ==.
%
% Outputs:
%   req - Scalar structure with type="labkit.requirements" and a facades
%       structure array. Each facades element has normalized facade and range
%       fields. Calling requirements() with no pairs returns an empty list.
%
% Errors:
%   Throws labkit:contract:InvalidRequirements for an odd number of arguments,
%   labkit:contract:InvalidFacadeName for an invalid name,
%   labkit:contract:InvalidVersionRange for an empty or nontext range, and
%   labkit:contract:DuplicateRequirement when a facade appears more than once.
%
% Example:
%   req = labkit.contract.requirements( ...
%       "app", ">=1 <2", ...
%       "image", ">=4.0 <5");
%   report = labkit.contract.checkRequirements(req);
%
% See also labkit.contract.checkRequirements,
%   labkit.contract.assertRequirements,
%   labkit.contract.versionInfo

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
