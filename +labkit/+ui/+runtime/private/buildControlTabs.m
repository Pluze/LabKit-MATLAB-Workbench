% Private UI runtime helper. Expected caller: labkit.ui.runtime.create. Inputs are the
% current UI registry, validated tab layouts, and debug context. Output is the
% updated UI registry after control-tab sections and controls are built.
function ui = buildControlTabs(ui, tabs, debug)
    for iTab = 1:numel(tabs)
        tabLayout = tabs{iTab};
        grid = ui.([tabLayout.id 'Grid']);
        ui.tabs.(tabLayout.id) = struct('id', tabLayout.id, ...
            'layout', tabLayout, 'grid', grid, ...
            'tab', ui.([tabLayout.id 'Tab']));
        rowMap = logicalRowMap(grid, numel(tabLayout.children));
        for iSection = 1:numel(tabLayout.children)
            ui = buildSection(ui, tabLayout.children{iSection}, grid, ...
                rowMap(iSection), debug);
        end
    end
end

function rowMap = logicalRowMap(grid, rowCount)
    rowMap = 1:rowCount;
    try
        data = grid.UserData;
        if isstruct(data) && isfield(data, 'LabKitLogicalRowMap')
            rowMap = data.LabKitLogicalRowMap;
        end
    catch
    end
end
