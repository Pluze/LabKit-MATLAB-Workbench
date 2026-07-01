function paths = normalizePaths(paths, varargin)
%NORMALIZEPATHS Normalize image file path inputs to a string column.
%
% App-facing contract:
%   paths = labkit.image.normalizePaths(paths)
%   paths = labkit.image.normalizePaths(paths, "AllowEmpty", false)
%
% Inputs:
%   paths - char, string, cell array, or empty value from an app/filePanel.
%   AllowEmpty - optional logical scalar, default true. When false, an empty
%       normalized result throws labkit:image:NoPaths.
%
% Outputs:
%   paths - string column with empty entries removed.

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
