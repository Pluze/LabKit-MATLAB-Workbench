% Expected caller: EIS app runner. Input is EIS item structs. Output is the
% stable summary text cell array. No side effects.

function summary = buildSummary(items)
    summary = cell(0, 1);
    summary{end+1} = sprintf('Loaded files: %d', numel(items));
    for i = 1:numel(items)
        freq = itemField(items(i), 'freq_Hz', 'Freq');
        fmin = min(freq, [], 'omitnan');
        fmax = max(freq, [], 'omitnan');
        summary{end+1} = sprintf('%s | N=%d | Freq %.4g to %.4g Hz | order: %s', ...
            items(i).name, items(i).n, fmin, fmax, ternary(items(i).freqDesc, 'high->low', 'low->high/mixed'));
    end
end

function values = itemField(item, canonicalName, legacyName)
    if isfield(item, canonicalName) && ~isempty(item.(canonicalName))
        values = item.(canonicalName);
    elseif isfield(item, legacyName) && ~isempty(item.(legacyName))
        values = item.(legacyName);
    else
        values = [];
    end
end

function txt = ternary(cond, a, b)
    if cond
        txt = a;
    else
        txt = b;
    end
end
