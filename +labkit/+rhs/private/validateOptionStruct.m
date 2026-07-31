function validateOptionStruct(value, allowed)
% Package-private validation for public RHS option structures.
if ~isstruct(value) || ~isscalar(value)
    error('labkit:rhs:InvalidOptions', ...
        'RHS options must be a scalar struct.');
end
unknown = setdiff(string(fieldnames(value)), string(allowed));
if ~isempty(unknown)
    error('labkit:rhs:InvalidOptions', ...
        'Unknown RHS option: %s.', unknown(1));
end
end
