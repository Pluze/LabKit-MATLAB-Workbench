% Expected caller: rhs_preview.run. Input is the app figure. Output is true
% only for a normal left-click selection when the figure exposes the field.
function tf = isNormalClick(fig)
%ISNORMALCLICK True for left-click style pointer actions.

    tf = true;
    if isempty(fig) || ~isvalid(fig) || ~isprop(fig, 'SelectionType')
        return;
    end
    tf = strcmp(fig.SelectionType, 'normal');
end
