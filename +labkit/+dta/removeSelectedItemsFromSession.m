function [session, report] = removeSelectedItemsFromSession(session, selectedNames, callbacks)
%REMOVESELECTEDITEMSFROMSESSION Remove selected DTA session items by display name.
%
% Usage:
%   [session, report] = labkit.dta.removeSelectedItemsFromSession(session, names);
%
% Inputs:
%   session - labkit_session struct with items field.
%   selectedNames - char/string/cellstr names matching session item names.
%   callbacks - optional struct with onRemoved(name,item).
%
% Output:
%   session - updated session.
%   report - struct describing removed, missing, and count fields.

    if nargin < 3
        callbacks = struct();
    end

    [session, report] = removeSelectedSessionItems(session, selectedNames, callbacks);
end
