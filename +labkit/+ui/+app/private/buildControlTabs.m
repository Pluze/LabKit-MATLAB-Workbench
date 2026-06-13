% Private UI app helper. Expected caller: labkit.ui.app.create. Inputs are the
% current UI registry, validated tab specs, and debug context. Output is the
% updated UI registry after control-tab sections and controls are built.
function ui = buildControlTabs(ui, tabs, debug)
    for iTab = 1:numel(tabs)
        tabSpec = tabs{iTab};
        grid = ui.([tabSpec.id 'Grid']);
        ui.tabs.(tabSpec.id) = struct('id', tabSpec.id, ...
            'spec', tabSpec, 'grid', grid, ...
            'tab', ui.([tabSpec.id 'Tab']));
        rowMap = logicalRowMap(grid, numel(tabSpec.children));
        for iSection = 1:numel(tabSpec.children)
            ui = buildSection(ui, tabSpec.children{iSection}, grid, ...
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
