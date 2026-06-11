% Expected caller: labkit_ImageMatch_app and tests. Input is the reference-match
% history. Output is cell data for the visible history table.
function data = historyTableData(steps)

    if isempty(steps)
        data = cell(0, 4);
        return;
    end

    steps = steps(:);
    data = cell(numel(steps), 4);
    for k = 1:numel(steps)
        data{k, 1} = k;
        data{k, 2} = char(steps(k).kind);
        data{k, 3} = char(image_match.ops.describeStep(steps(k)));
        if steps(k).referenceIndex > 0
            data{k, 4} = sprintf('%d', round(steps(k).referenceIndex));
        else
            data{k, 4} = '';
        end
    end
end
