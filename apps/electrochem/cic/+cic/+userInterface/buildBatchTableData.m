% Expected caller: CIC app runner and unit tests. Inputs are item structs and a
% display unit label. Outputs are the stable UI table cell data and column names.
% No file side effects.

function [C, columnNames] = buildBatchTableData(items, unitLabel)
%BUILDBATCHTABLEDATA Build legacy CIC batch uitable data.

    if nargin < 2
        unitLabel = 'mC/cm^2';
    end
    [scale, unitLabel] = displayScale(unitLabel);
    columnNames = {'File', 'Amp(A)', 'Emc(V)', 'Ema(V)', ...
        ['Qc(' unitLabel ')'], ['Qa(' unitLabel ')'], ['Qtot(' unitLabel ')'], 'Safe'};

    C = cell(numel(items), 8);
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
            C{i, 8} = 'parse/analyze failed';
            continue;
        end

        C{i, 2} = A.ampEstimate_A;
        C{i, 3} = A.Emc;
        C{i, 4} = A.Ema;
        C{i, 5} = scale * A.CICc_mCcm2;
        C{i, 6} = scale * A.CICa_mCcm2;
        C{i, 7} = scale * A.CICt_mCcm2;
        C{i, 8} = ternary(A.safe, 'safe', A.limitSide);
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

function [scale, unitLabel] = displayScale(unitLabel)
    [scale, unitLabel] = cic.userInterface.displayUnit(unitLabel);
end

function txt = ternary(cond, a, b)
    if cond
        txt = a;
    else
        txt = b;
    end
end
