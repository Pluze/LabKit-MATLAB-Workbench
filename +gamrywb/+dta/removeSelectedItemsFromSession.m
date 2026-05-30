function [session, report] = removeSelectedItemsFromSession(session, selectedNames, callbacks)
%REMOVESELECTEDITEMSFROMSESSION Remove selected DTA session items by display name.

    if nargin < 3
        callbacks = struct();
    end

    [session, report] = gamrywb.data.removeSelectedItemsFromSession(session, selectedNames, callbacks);
end
