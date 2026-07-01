classdef AppLaunchGuiTest < matlab.uitest.TestCase
    %APPLAUNCHGUITEST Guard supported apps against missing dedicated GUI tests.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function app_entrypoints_have_dedicated_gui_coverage(testCase)
            setupLabKitTestPath();
            apps = appsWithoutDedicatedLayoutTests(testRepoRoot(), discoverLabKitApps());

            testCase.verifyEqual(height(apps), 0, ...
                "Supported app entry points missing dedicated GUI coverage: " + ...
                strjoin(string(apps.Command), ", "));
        end
    end
end

function apps = appsWithoutDedicatedLayoutTests(root, apps)
    keep = true(height(apps), 1);
    for k = 1:height(apps)
        keep(k) = ~hasDedicatedLayoutTest(root, apps.Folder(k));
    end
    apps = apps(keep, :);
end

function tf = hasDedicatedLayoutTest(root, appFolder)
    appFolder = char(appFolder);
    appsRoot = fullfile(root, 'apps');
    rel = appFolder;
    prefix = [appsRoot filesep];
    if startsWith(appFolder, prefix)
        rel = appFolder(numel(prefix)+1:end);
    end
    relParts = split(string(strrep(rel, filesep, '/')), '/');
    tf = false;
    if numel(relParts) >= 2
        guiFolder = fullfile(root, 'tests', 'cases', 'gui', 'apps', ...
            char(relParts(1)), char(relParts(2)));
        tf = isfolder(guiFolder) && ~isempty(dir(fullfile(guiFolder, '*.m')));
    end
end
