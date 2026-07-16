function [curve, ok, msg] = getZCurve(tables)
%GETZCURVE Select the impedance table from parsed EIS data.
%
% Usage:
%   [curve, ok, msg] = labkit.dta.getZCurve(tables)
%
% Description:
%   First selects a table named ZCURVE. If that name is absent, selects the
%   first table whose headers include Freq, Zreal, and Zimag, using
%   case-insensitive comparisons.
%
% Inputs:
%   tables - Structure array of parsed DTA tables. Each element is expected to
%       contain name, headers, and data fields.
%
% Outputs:
%   curve - Selected impedance table structure, or an empty structure on
%       failure.
%   ok - Logical scalar indicating whether a table was selected.
%   msg - Character vector naming the selected table or stating that a
%       ZCURVE table was not found.
%
% Typical Call:
%   [curve, ok, msg] = labkit.dta.getZCurve(item.tables);
%   if ok
%       frequencyHz = labkit.dta.getColumn(curve, "Freq");
%   end

    curve = struct();
    ok = false;
    msg = 'ZCURVE table not found.';

    if isempty(tables)
        return;
    end

    idx = [];
    for i = 1:numel(tables)
        if strcmpi(strtrim(tables(i).name), 'ZCURVE')
            idx = i;
            break;
        end
    end

    if isempty(idx)
        for i = 1:numel(tables)
            h = lower(string(tables(i).headers));
            if any(h == "freq") && any(h == "zreal") && any(h == "zimag")
                idx = i;
                break;
            end
        end
    end

    if isempty(idx)
        return;
    end

    curve = tables(idx);
    ok = true;
    msg = sprintf('Using table: %s', curve.name);
end
