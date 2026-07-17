function filterSpec = fileDialogFilter(varargin)
%FILEDIALOGFILTER Return a file-chooser-compatible image filter.
%
% Usage:
%   filterSpec = labkit.image.fileDialogFilter()
%   filterSpec = labkit.image.fileDialogFilter("IncludeAll", true)
%
% Description:
%   Builds the two-column filter specification used by MATLAB file-selection
%   dialogs and LabKit file panels. The first row contains every extension
%   returned by labkit.image.supportedExtensions. By default, files outside
%   that set are hidden from the chooser.
%
% Inputs:
%   None.
%
% Name-Value Arguments:
%   IncludeAll - Logical scalar. true appends an "All files (*.*)" row after
%                the image filter. The default is false. Numeric scalars are
%                converted to logical values.
%
% Outputs:
%   filterSpec - One- or two-row cell array. Column 1 contains wildcard
%                patterns and column 2 contains user-visible descriptions.
%
% Errors:
%   MATLAB inputParser errors are raised for an unknown name, a missing
%   name-value partner, or an IncludeAll value that is not a logical or
%   numeric scalar.
%
% Example:
%   filterSpec = labkit.image.fileDialogFilter("IncludeAll", true);
%
% See also labkit.image.supportedExtensions,
%   labkit.image.isSupportedPath

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
