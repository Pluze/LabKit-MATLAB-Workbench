function txtInfo = createInfoArea(parent, value)
%CREATEINFOAREA Create the shared read-only info text area.

    txtInfo = uitextarea(parent, 'Editable', 'off');
    txtInfo.Layout.Row = 4;
    txtInfo.Value = value;
end
