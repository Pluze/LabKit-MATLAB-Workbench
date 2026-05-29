function txtLog = createLogArea(parent, initialValue)
%CREATELOGAREA Create the shared read-only app log text area.

    if nargin < 2
        initialValue = {'GUI started.'};
    end

    txtLog = uitextarea(parent, 'Editable', 'off');
    txtLog.Layout.Row = 5;
    txtLog.Value = initialValue;
end
