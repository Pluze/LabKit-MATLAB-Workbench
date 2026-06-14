function assertClose(actual, expected, varargin)
%ASSERTCLOSE Assert exact or tolerance-based equality in tests.

    if numel(varargin) == 1
        label = varargin{1};
        assert(isequaln(actual, expected), '%s should match expected values.', label);
        return;
    end

    if numel(varargin) ~= 2
        error('assertClose:InvalidInput', ...
            'Use assertClose(actual, expected, label) or assertClose(actual, expected, tol, label).');
    end

    tol = varargin{1};
    label = varargin{2};
    assert(isequal(size(actual), size(expected)), ...
        '%s should have the expected shape.', label);

    delta = abs(actual(:) - expected(:));
    assert(all(delta < tol), '%s should match expected value.', label);
end
