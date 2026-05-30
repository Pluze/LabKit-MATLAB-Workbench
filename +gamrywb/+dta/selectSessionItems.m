function [items, idx] = selectSessionItems(session, selectedNames)
%SELECTSESSIONITEMS Select DTA session items by display name.

    if nargin < 2
        selectedNames = {};
    end
    if ~isfield(session, 'items')
        error('gamrywb:dta:InvalidSession', 'Session must contain an items field.');
    end

    [items, idx] = gamrywb.data.selectItemsByNames(session.items, selectedNames);
end
