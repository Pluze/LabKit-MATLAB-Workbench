function validateOptionStruct(value, allowed)
% Package-private validation for public image option structures.
if ~isstruct(value) || ~isscalar(value)
    error('labkit:image:InvalidOptions', ...
        'Image options must be a scalar struct.');
end
unknown = setdiff(string(fieldnames(value)), string(allowed));
if ~isempty(unknown)
    error('labkit:image:InvalidOptions', ...
        'Unknown image option: %s.', unknown(1));
end
end
