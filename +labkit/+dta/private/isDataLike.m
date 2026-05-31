function tf = isDataLike(tok)
%ISDATALIKE Test whether a split DTA row contains any numeric token.
%
% Inputs:
%   tok - cell array of strings/chars from splitTabs.
%
% Output:
%   tf - true when at least one token converts to a finite numeric value.
%
% Notes:
%   Parser section scanners use this as a permissive data-row check; it does
%   not require every token in the row to be numeric.

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
