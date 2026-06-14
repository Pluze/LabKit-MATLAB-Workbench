function apps = discoverLabKitApps()
%DISCOVERLABKITAPPS Return launchable LabKit apps through the public launcher.
%
% Expected caller: smoke and contract tests that need the current app catalog.
% Output is the table returned by labkit_launcher("list"). The helper keeps
% tests on the same discovery path as users instead of maintaining a separate
% app registry.

    apps = labkit_launcher("list");
    assert(istable(apps), ...
        'labkit_launcher list mode should return a table.');
    requiredColumns = {'Command', 'DisplayName', 'Family', 'Folder', ...
        'RelativePath', 'Description'};
    assert(all(ismember(requiredColumns, apps.Properties.VariableNames)), ...
        'labkit_launcher list mode is missing required app catalog columns.');
    assert(height(apps) > 0, ...
        'labkit_launcher list mode should find app entry points.');
end
