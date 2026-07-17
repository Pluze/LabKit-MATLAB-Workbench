function [curve, ok, msg] = getMainCurve(tables)
%GETMAINCURVE Select the transient table containing T, Vf, and Im data.
%
% Usage:
%   [curve, ok, msg] = labkit.dta.getMainCurve(tables)
%
% Description:
%   First selects a table named CURVE or CURVE1. If neither name is present,
%   selects the first table whose headers include T, Vf, and Im, using
%   case-insensitive comparisons. No table is selected when the input is empty
%   or no compatible columns are found.
%
% Inputs:
%   tables - Structure array of parsed DTA tables. Each element is expected to
%       contain name, headers, and data fields.
%
% Outputs:
%   curve - Selected table structure, or an empty structure on failure.
%   ok - Logical scalar indicating whether a table was selected.
%   msg - Character vector naming the selected table or stating that the
%       main transient table was not found.
%
% Failure Behavior:
%   Empty input or no table with the required headers returns curve=struct(),
%   ok=false, and a diagnostic message. Nonempty elements must expose name
%   and headers fields; malformed table structures raise the originating
%   MATLAB field-access error.
%
% Typical Call:
%   [curve, ok, msg] = labkit.dta.getMainCurve(item.tables);
%   if ok
%       timeSec = labkit.dta.getColumn(curve, "T");
%   end
%
% See also labkit.dta.getColumn,
%   labkit.dta.detectPulses,
%   labkit.dta.loadFile

    ok = false;
    msg = 'Main transient table not found.';
    curve = struct();
    if isempty(tables)
        return;
    end

    idxMain = [];
    for i = 1:numel(tables)
        nm = lower(strtrim(tables(i).name));
        if strcmp(nm, 'curve') || strcmp(nm, 'curve1')
            idxMain = i;
            break;
        end
    end
    if isempty(idxMain)
        for i = 1:numel(tables)
            h = lower(tables(i).headers);
            if any(strcmp(h, 't')) && any(strcmp(h, 'vf')) && any(strcmp(h, 'im'))
                idxMain = i;
                break;
            end
        end
    end
    if isempty(idxMain)
        return;
    end

    curve = tables(idxMain);
    ok = true;
    msg = sprintf('Using table: %s', curve.name);
end
