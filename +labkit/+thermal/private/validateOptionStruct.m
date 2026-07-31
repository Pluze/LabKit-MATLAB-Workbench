function validateOptionStruct(value, allowed)
% Package-private validation for public thermal option structures.
if ~isstruct(value) || ~isscalar(value)
    error('labkit:thermal:InvalidOptions', ...
        'Thermal options must be a scalar struct.');
end
unknown = setdiff(string(fieldnames(value)), string(allowed));
if ~isempty(unknown)
    error('labkit:thermal:InvalidOptions', ...
        'Unknown thermal option: %s.', unknown(1));
end
end
