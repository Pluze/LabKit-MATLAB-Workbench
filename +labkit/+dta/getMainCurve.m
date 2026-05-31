function [curve, ok, msg] = getMainCurve(tables)
%GETMAINCURVE Return the transient table containing T/Vf/Im data.
%
% Inputs:
%   tables - parsed DTA table struct array.
%
% Output:
%   curve - selected curve/table struct, or empty struct.
%   ok - logical success flag.
%   msg - status text for logs or UI summaries.

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
