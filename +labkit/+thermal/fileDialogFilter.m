function filterSpec = fileDialogFilter(varargin)
%FILEDIALOGFILTER Return a file-chooser-compatible thermal image filter.
%
% App-facing contract:
%   filterSpec = labkit.thermal.fileDialogFilter()
%   filterSpec = labkit.thermal.fileDialogFilter("IncludeAll", true)
%
% Inputs:
%   IncludeAll - optional logical scalar, default false. When true, append an
%       "All files (*.*)" row after the thermal-file row.
%
% Outputs:
%   filterSpec - cell array accepted by filePanel filters and MATLAB
%       file-chooser filter specs.

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
