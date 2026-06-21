function root = labkitRepoRoot()
%LABKITREPOROOT Return the LabKit repository root from test runner code.
%
% Expected caller: tests and build/test runner helpers.
% Output: absolute repository root path as a character vector.

    root = fileparts(fileparts(fileparts(mfilename("fullpath"))));
end
