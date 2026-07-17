function filterSpec = fileDialogFilter(varargin)
%FILEDIALOGFILTER Create a file-selection filter for thermal images.
%
% Usage:
%   filterSpec = labkit.thermal.fileDialogFilter()
%   filterSpec = labkit.thermal.fileDialogFilter("IncludeAll", true)
%
% Description:
%   Returns the pattern and description rows used by MATLAB file-selection
%   dialogs and LabKit file panels. The thermal row includes .jpg, .jpeg, and
%   .rjpg files. A matching extension does not prove that a JPEG contains
%   radiometric data; use labkit.thermal.inspectFile to inspect its contents.
%
% Name-Value Arguments:
%   IncludeAll - Logical or numeric scalar. When true, adds an "All files"
%       row after the thermal-image row. Default: false.
%
% Outputs:
%   filterSpec - One- or two-row cell array. Column 1 contains wildcard
%       patterns and column 2 contains the text shown in the file dialog.
%
% Errors:
%   MATLAB inputParser errors are raised for an unknown name, a missing
%   name-value partner, or an IncludeAll value that is not a logical or
%   numeric scalar.
%
% Example:
%   filters = labkit.thermal.fileDialogFilter("IncludeAll", true);
%   assert(isequal(size(filters), [2 2]))
%
% See also labkit.thermal.supportedExtensions,
%   labkit.thermal.inspectFile

    opts = parseOptions(varargin{:});
    thermalRow = {'*.jpg;*.jpeg;*.rjpg', ...
        'FLIR radiometric JPEG (*.jpg, *.jpeg, *.rjpg)'};
    if opts.IncludeAll
        filterSpec = [thermalRow; {'*.*', 'All files (*.*)'}];
    else
        filterSpec = thermalRow;
    end
end

function opts = parseOptions(varargin)
    p = inputParser;
    p.FunctionName = "labkit.thermal.fileDialogFilter";
    p.addParameter("IncludeAll", false, @isLogicalScalar);
    p.parse(varargin{:});
    opts = p.Results;
    opts.IncludeAll = logical(opts.IncludeAll);
end

function tf = isLogicalScalar(value)
    tf = (islogical(value) || isnumeric(value)) && isscalar(value);
end
