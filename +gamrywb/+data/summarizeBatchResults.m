function T = summarizeBatchResults(items, resultField)
%SUMMARIZEBATCHRESULTS Build a small common summary table for item results.

    if nargin < 2 || isempty(resultField)
        resultField = 'analysis';
    end

    names = cell(numel(items), 1);
    filepaths = cell(numel(items), 1);
    ok = false(numel(items), 1);
    messages = cell(numel(items), 1);

    for k = 1:numel(items)
        names{k} = fieldOrEmpty(items(k), 'name');
        filepaths{k} = fieldOrEmpty(items(k), 'filepath');

        if isfield(items(k), resultField) && isstruct(items(k).(resultField)) ...
                && ~isempty(items(k).(resultField))
            result = items(k).(resultField);
            if isfield(result, 'ok') && isscalar(result.ok)
                ok(k) = logical(result.ok);
            end
            if isfield(result, 'message')
                messages{k} = char(result.message);
            else
                messages{k} = '';
            end
        else
            messages{k} = '';
        end
    end

    T = table(names, filepaths, ok, messages, ...
        'VariableNames', {'Name', 'Filepath', 'Ok', 'Message'});
end

function txt = fieldOrEmpty(item, fieldName)
    if isfield(item, fieldName) && ~isempty(item.(fieldName))
        txt = char(item.(fieldName));
    else
        txt = '';
    end
end
