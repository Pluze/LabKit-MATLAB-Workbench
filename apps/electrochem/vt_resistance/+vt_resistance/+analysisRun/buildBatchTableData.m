% Expected caller: VT resistance presenter and unit tests. Input is item structs.
% Output is the stable UI table cell data. No file side effects.

function C = buildBatchTableData(items)
%BUILDBATCHTABLEDATA Build VT resistance uitable data.

    C = cell(numel(items), 9);
    for i = 1:numel(items)
        item = items(i);
        C{i, 1} = itemName(item);
        A = itemAnalysis(item);
        if isempty(A) || ~isfield(A, 'ok') || ~A.ok
            C{i, 2} = NaN;
            C{i, 3} = NaN;
            C{i, 4} = NaN;
            C{i, 5} = NaN;
            C{i, 6} = NaN;
            C{i, 7} = NaN;
            C{i, 8} = NaN;
            C{i, 9} = 'parse/analyze failed';
            continue;
        end

        C{i, 2} = A.Ic_est_A;
        C{i, 3} = A.Ia_est_A;
        C{i, 4} = A.Vc_ss_V;
        C{i, 5} = A.Va_ss_V;
        C{i, 6} = A.Rc_abs_ohm;
        C{i, 7} = A.Ra_abs_ohm;
        C{i, 8} = A.Ravg_abs_ohm;
        C{i, 9} = A.detectMode;
    end
end

function name = itemName(item)
    if isfield(item, 'name')
        name = item.name;
    else
        name = '';
    end
end

function A = itemAnalysis(item)
    if isfield(item, 'analysis')
        A = item.analysis;
    else
        A = [];
    end
end
