function assertLauncherPackageCheckboxSelection(fig, guiHelpers)
% Verify launcher package checkboxes update details and survive app refresh.

    ui = getappdata(fig, 'labkitUiRegistry');
    tableHandle = ui.controls.appTable.table;
    assert(tableHandle.ColumnEditable(1), ...
        'Launcher Package column should be editable.');
    assert(islogical(tableHandle.Data{1, 1}), ...
        'Launcher Package column should render logical checkboxes.');
    tableHandle.Data{1, 1} = true;
    event = struct('Indices', [1 1], 'NewData', true, 'PreviousData', false);
    tableHandle.CellEditCallback(tableHandle, event);
    drawnow;
    details = string(ui.controls.selectedDetails.textArea.Value);
    assert(any(contains(details, "Checked for package: 1 app(s)")), ...
        'Launcher details should report the checked package count.');
    guiHelpers.invokeButton(fig, 'Refresh App List');
    drawnow;
    assert(logical(tableHandle.Data{1, 1}), ...
        'Refreshing the app list should preserve checked package rows.');
end
