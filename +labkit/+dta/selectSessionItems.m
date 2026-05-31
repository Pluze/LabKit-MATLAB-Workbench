function [items, idx] = selectSessionItems(session, selectedNames)
%SELECTSESSIONITEMS Select DTA session items by display name.
%
% Usage:
%   [items, idx] = labkit.dta.selectSessionItems(session, selectedNames);
%
% Inputs:
%   session - labkit_session struct with items field.
%   selectedNames - optional char/string/cellstr item display names. Empty
%                   selects no items.
%
% Output:
%   items - selected item struct array.
%   idx - numeric indices into session.items.

    if nargin < 2
        selectedNames = {};
    end
    if ~isfield(session, 'items')
        error('labkit:dta:InvalidSession', 'Session must contain an items field.');
    end

    [items, idx] = selectItemsByNames(session.items, selectedNames);
end
