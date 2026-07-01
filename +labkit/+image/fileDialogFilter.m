function filterSpec = fileDialogFilter(varargin)
%FILEDIALOGFILTER Return a file-chooser-compatible image filter.
%
% App-facing contract:
%   filterSpec = labkit.image.fileDialogFilter()
%   filterSpec = labkit.image.fileDialogFilter("IncludeAll", true)
%
% Inputs:
%   IncludeAll - optional logical scalar, default false. When true, append an
%       "All files (*.*)" row after the image-file row.
%
% Outputs:
%   filterSpec - cell array accepted by filePanel filters and MATLAB
%       file-chooser filter specs.

    opts = parseOptions(varargin{:});
    imageRow = {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp', ...
        'Image files (*.png, *.jpg, *.jpeg, *.tif, *.tiff, *.bmp)'};
    if opts.IncludeAll
        filterSpec = [imageRow; {'*.*', 'All files (*.*)'}];
    else
        filterSpec = imageRow;
    end
end

function opts = parseOptions(varargin)
    p = inputParser;
    p.FunctionName = "labkit.image.fileDialogFilter";
    p.addParameter("IncludeAll", false, @isLogicalScalar);
    p.parse(varargin{:});
    opts = p.Results;
    opts.IncludeAll = logical(opts.IncludeAll);
end

function tf = isLogicalScalar(value)
    tf = (islogical(value) || isnumeric(value)) && isscalar(value);
end
