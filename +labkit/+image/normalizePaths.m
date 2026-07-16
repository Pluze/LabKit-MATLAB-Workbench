function paths = normalizePaths(paths, varargin)
%NORMALIZEPATHS Normalize image file path inputs to a string column.
%
% Usage:
%   paths = labkit.image.normalizePaths(paths)
%   paths = labkit.image.normalizePaths(paths, "AllowEmpty", false)
%
% Description:
%   Converts the path forms commonly returned by MATLAB file selection into
%   one string column. Leading and trailing whitespace is removed and blank
%   entries are discarded. Order and duplicate paths are preserved. A single
%   character vector is treated as one path rather than one path per row.
%
%   This function normalizes text only. It does not expand relative paths,
%   validate extensions, remove duplicates, or test file existence.
%
% Inputs:
%   paths - Character vector, string array, cell array, or empty value.
%
% Outputs:
%   paths - String column containing the nonblank normalized paths.
%
% Name-Value Arguments:
%   AllowEmpty - Logical scalar controlling whether zero paths are accepted.
%                The default is true. false throws labkit:image:NoPaths when
%                normalization produces an empty result.
%
% Errors:
%   labkit:image:InvalidPaths - paths is not char, string, cell, or empty.
%   labkit:image:NoPaths - No path remains and AllowEmpty is false.
%
% Example:
%   paths = labkit.image.normalizePaths([" frame01.png "; ""; "frame02.JPG"]);

    opts = parseOptions(varargin{:});
    if isempty(paths)
        paths = strings(0, 1);
    elseif ischar(paths)
        paths = string({paths});
    elseif isstring(paths)
        paths = paths(:);
    elseif iscell(paths)
        paths = string(paths(:));
    else
        error('labkit:image:InvalidPaths', ...
            'Image paths must be char, string, or a cell array.');
    end

    paths = strtrim(paths);
    paths = paths(strlength(paths) > 0);
    if ~opts.AllowEmpty && isempty(paths)
        error('labkit:image:NoPaths', ...
            'Select at least one image file.');
    end
end

function opts = parseOptions(varargin)
    p = inputParser;
    p.FunctionName = "labkit.image.normalizePaths";
    p.addParameter("AllowEmpty", true, @isLogicalScalar);
    p.parse(varargin{:});
    opts = p.Results;
    opts.AllowEmpty = logical(opts.AllowEmpty);
end

function tf = isLogicalScalar(value)
    tf = (islogical(value) || isnumeric(value)) && isscalar(value);
end
