function tf = isDataLike(tok)
%ISDATALIKE True when a token row contains at least one numeric value.

    if isempty(tok)
        tf = false;
        return;
    end

    vals = nan(size(tok));
    for i = 1:numel(tok)
        vals(i) = str2double(tok{i});
    end
    tf = any(~isnan(vals));
end
