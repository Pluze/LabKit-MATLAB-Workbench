function filepath = labkitFixturePath(varargin)
%LABKITFIXTUREPATH Return a path under tests/fixtures.
%
% Expected caller: official tests needing synthetic repository fixtures.
% Inputs: path segments below tests/fixtures. Output is an absolute path.

    root = labkitRepoRoot();
    filepath = fullfile(root, "tests", "fixtures", varargin{:});
end
