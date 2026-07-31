function validateOptionStruct(value, allowed)
% Package-private validation for public biosignal option structures.
if ~isstruct(value) || ~isscalar(value)
    error('labkit:biosignal:InvalidOptions', ...
        'Biosignal options must be a scalar struct.');
end
unknown = setdiff(string(fieldnames(value)), string(allowed));
if ~isempty(unknown)
    error('labkit:biosignal:InvalidOptions', ...
        'Unknown biosignal option: %s.', unknown(1));
end
end
