function [curve, ok, msg] = getZCurve(tables)
%GETZCURVE Return the EIS ZCURVE table, or a compatible impedance table.
%
% Inputs:
%   tables - parsed DTA table struct array.
%
% Output:
%   curve - selected impedance curve/table struct, or empty struct.
%   ok - logical success flag.
%   msg - status text for logs or UI summaries.

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
