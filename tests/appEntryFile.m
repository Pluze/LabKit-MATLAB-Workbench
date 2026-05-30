function filepath = appEntryFile(root, appName)
%APPENTRYFILE Resolve an app entry point under apps/.

    filepath = which(appName);
    assert(~isempty(filepath), ['App entry point does not resolve: ' appName]);

    appsRoot = [fullfile(root, 'apps') filesep];
    assert(startsWith(filepath, appsRoot), ...
        [appName ' should resolve from an apps/ category folder.']);
end
