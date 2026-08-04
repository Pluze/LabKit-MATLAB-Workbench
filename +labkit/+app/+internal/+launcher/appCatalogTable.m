function catalog = appCatalogTable(apps)
%APPCATALOGTABLE Convert normalized launcher entries to the list-mode table.
count = numel(apps);
commandColumn = strings(count, 1); displayNameColumn = strings(count, 1);
familyColumn = strings(count, 1); visibilityColumn = strings(count, 1);
folderColumn = strings(count, 1); relativePathColumn = strings(count, 1);
descriptionColumn = strings(count, 1); versionColumn = strings(count, 1);
updatedColumn = strings(count, 1);
for index = 1:count
    commandColumn(index) = apps(index).command;
    displayNameColumn(index) = apps(index).name;
    familyColumn(index) = apps(index).family;
    visibilityColumn(index) = apps(index).visibility;
    folderColumn(index) = apps(index).folder;
    relativePathColumn(index) = apps(index).relativePath;
    descriptionColumn(index) = apps(index).description;
    versionColumn(index) = apps(index).version;
    updatedColumn(index) = apps(index).updated;
end
catalog = table(commandColumn, displayNameColumn, familyColumn, ...
    visibilityColumn, folderColumn, relativePathColumn, descriptionColumn, ...
    versionColumn, updatedColumn, ...
    'VariableNames', {'Command', 'DisplayName', 'Family', 'Visibility', ...
    'Folder', 'RelativePath', 'Description', 'Version', 'Updated'});
end
