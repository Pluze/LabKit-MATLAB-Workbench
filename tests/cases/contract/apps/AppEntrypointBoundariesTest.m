classdef AppEntrypointBoundariesTest < matlab.unittest.TestCase
    %APPENTRYPOINTBOUNDARIESTEST Verify LabKit behavior through official MATLAB tests.

    methods (Test, TestTags = {'Integration', 'Style'})
        function test_app_entrypoint_boundaries(testCase)
            setupLabKitTestPath();
            verify_app_entrypoint_boundaries();
        end
    end
end

function verify_app_entrypoint_boundaries()
%TEST_APP_ENTRYPOINT_BOUNDARIES Verify app locations and entrypoint shape.

    root = testRepoRoot();
    h = architectureTestHelpers();

    assert(exist(fullfile(root, 'apps', 'private'), 'dir') ~= 7, ...
        'Apps should use family/app subfolders, not apps/private launchers.');
    assertAppsUseFamilySubfolders(root);

    apps = discoverLabKitApps();
    assert(~isempty(apps), ...
        'App entrypoint boundary guardrail should discover app catalog entries.');
    for k = 1:height(apps)
        appName = char(apps.Command(k));
        source = h.assertAppEntrypoint(root, appName);
        assertFamilyBoundary(h, source, appName, apps.Family(k));
    end
end

function assertFamilyBoundary(h, source, appName, family)
    family = string(family);
    if family == "Electrochem"
        h.assertDTAFacadeUsage(source, appName, electrochemKind(appName), false);
    elseif family == "DIC"
        h.assertDICAppBoundary(source, appName);
    elseif family == "Image Measurement"
        h.assertImageMeasurementAppBoundary(source, appName);
    elseif family == "Gait"
        h.assertGaitAppBoundary(source, appName);
    elseif family == "Wearable"
        h.assertWearableAppBoundary(source, appName);
    elseif family == "Neurophysiology"
        assertNeurophysiologyBoundary(source, appName);
    end
end

function kind = electrochemKind(appName)
    appName = string(appName);
    if contains(appName, "EIS")
        kind = "eis";
    elseif contains(appName, "CSC")
        kind = "cvct";
    else
        kind = "chrono";
    end
end

function assertNeurophysiologyBoundary(source, appName)
    assert(~contains(source, 'labkit.dta.'), ...
        [appName ' should not use the electrochemistry DTA facade.']);
    if contains(string(appName), ["RHSPreview", "NerveResponseAnalysis"])
        assert(contains(source, 'labkit.rhs.'), ...
            [appName ' should use the GUI-free RHS facade.']);
    end
end

function assertAppsUseFamilySubfolders(root)
    appFiles = dir(fullfile(root, 'apps', '**', 'labkit_*_app.m'));
    assert(~isempty(appFiles), ...
        'App entrypoint boundary guardrail should discover app entry files.');
    appsRoot = fullfile(root, 'apps');
    for k = 1:numel(appFiles)
        appFolder = appFiles(k).folder;
        relFolder = string(localRelativePath(appsRoot, appFolder));
        parts = split(relFolder, filesep);
        assert(numel(parts) >= 2, ...
            ['App entrypoints should live under apps/<family>/<app_slug>/: ' ...
            char(fullfile(appFiles(k).folder, appFiles(k).name))]);
        assert(parts(1) ~= "private", ...
            ['App entrypoints should not live under apps/private/: ' ...
            char(fullfile(appFiles(k).folder, appFiles(k).name))]);
    end
end

function rel = localRelativePath(root, pathValue)
    root = char(root);
    pathValue = char(pathValue);
    prefix = [root filesep];
    if startsWith(pathValue, prefix)
        rel = pathValue(numel(prefix)+1:end);
    else
        rel = pathValue;
    end
end
