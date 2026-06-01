function h = architectureTestHelpers()
%ARCHITECTURETESTHELPERS Shared project architecture guardrail assertions.

    h = struct();
    h.assertNoPackageMFiles = @assertNoPackageMFiles;
    h.assertTopLevelMFiles = @assertTopLevelMFiles;
    h.assertPackageMFiles = @assertPackageMFiles;
    h.assertPackageSourcesDoNotContain = @assertPackageSourcesDoNotContain;
    h.assertSingleFileApp = @assertSingleFileApp;
    h.assertDTAFacadeUsage = @assertDTAFacadeUsage;
    h.assertDICAppBoundary = @assertDICAppBoundary;
    h.assertImageMeasurementAppBoundary = @assertImageMeasurementAppBoundary;
    h.assertWearableAppBoundary = @assertWearableAppBoundary;
    h.guiWords = @guiWords;
    h.appEntrypointWords = @appEntrypointWords;
    h.experimentWorkflowWords = @experimentWorkflowWords;
end

function source = assertSingleFileApp(root, appName, launchName, legacyCall)
    appFile = appEntryFile(root, appName);
    privateLaunchFile = fullfile(root, 'apps', 'private', [launchName '.m']);
    packageLaunchFile = fullfile(root, '+labkit', '+app', [launchName '.m']);
    rootLevelAppFile = fullfile(root, 'apps', [appName '.m']);

    assert(exist(appFile, 'file') == 2, ['Missing app entry point: ' appName]);
    assert(~isempty(which(appName)), ['App entry point does not resolve: ' appName]);
    assert(exist(rootLevelAppFile, 'file') ~= 2, ...
        [appName ' should live under an apps category folder, not apps/ root.']);
    assert(exist(privateLaunchFile, 'file') ~= 2, ...
        [appName ' should not keep a separate apps/private launcher.']);
    assert(exist(packageLaunchFile, 'file') ~= 2, ...
        [appName ' implementation should not live in the reusable +labkit package.']);

    source = fileread(appFile);
    assert(contains(source, ['function varargout = ' appName]), ...
        [appName ' should be a single public app source file.']);
    assert(~contains(source, launchName), ...
        [appName ' should not delegate to a separate launcher.']);
    assert(~contains(source, ['labkit.app.' launchName]), ...
        [appName ' should not route app implementation through the reusable package.']);
    assert(~contains(source, '_legacy'), [appName ' should not call legacy implementations.']);
    assert(~contains(source, legacyCall), ...
        [appName ' should not delegate to a removed root legacy-compatible wrapper.']);
    assert(~contains(source, 'labkit.io.'), ...
        [appName ' should not call low-level IO APIs directly.']);
    assert(~contains(source, 'labkit.data.'), ...
        [appName ' should not call removed data APIs directly.']);
    assert(~contains(source, 'labkit.analysis.'), ...
        [appName ' should not call internal analysis APIs directly.']);
    assert(~contains(source, 'labkit.util.'), ...
        [appName ' should not call utility APIs directly.']);
    assert(contains(source, 'labkit.ui.createWorkbench'), ...
        [appName ' should build its GUI from the unified workbench shell helper.']);
    assert(~contains(source, 'labkit.ui.createStandardWorkbenchShell'), ...
        [appName ' should not use compatibility shell wrappers directly.']);
    assert(~contains(source, 'labkit.ui.createTabbedDualPlotShell'), ...
        [appName ' should not use compatibility shell wrappers directly.']);
end

function assertDTAFacadeUsage(source, appName, expectedKind, expectsFolderDiscovery)
    usesDTAFacade = contains(source, 'labkit.dta.loadFile') || ...
        contains(source, 'labkit.dta.addFilesToSession');
    expectedKindLiteral = sprintf('"%s"', expectedKind);
    assert(usesDTAFacade && contains(source, expectedKindLiteral), ...
        [appName ' should load DTA files through the GUI-free DTA facade.']);

    if expectsFolderDiscovery
        assert(contains(source, 'labkit.dta.findFiles(folder)'), ...
            [appName ' should discover folders through the GUI-free DTA facade.']);
    end
    assert(~contains(source, 'labkit.io.findDTAFilesRecursive(folder)'), ...
        [appName ' should not call low-level recursive file discovery directly.']);
end

function assertDICAppBoundary(source, appName)
    assert(~contains(source, 'labkit.dta.'), ...
        [appName ' should not use the electrochemistry DTA facade.']);
    assert(contains(source, 'labkit.ui.createWorkbench'), ...
        [appName ' should build from the reusable GUI foundation.']);
    assert(~contains(source, '+labkit/+dic'), ...
        [appName ' should keep DIC workflow code app-local.']);
end

function assertImageMeasurementAppBoundary(source, appName)
    assert(~contains(source, 'labkit.dta.'), ...
        [appName ' should not use the electrochemistry DTA facade.']);
    assert(contains(source, 'labkit.ui.createWorkbench'), ...
        [appName ' should build from the reusable GUI foundation.']);
    assert(~contains(source, '+labkit/+dic'), ...
        [appName ' should not depend on DIC implementation packages.']);
    assert(~contains(source, '+labkit/+image_measurement'), ...
        [appName ' should keep image-measurement workflow code app-local.']);
end

function assertWearableAppBoundary(source, appName)
    assert(~contains(source, 'labkit.dta.'), ...
        [appName ' should not use the electrochemistry DTA facade.']);
    assert(contains(source, 'labkit.ui.createWorkbench'), ...
        [appName ' should build from the reusable GUI foundation.']);
    assert(contains(source, 'labkit.biosignal.'), ...
        [appName ' should use the GUI-free biosignal facade for signal operations.']);
    assert(~contains(source, '+labkit/+ecg'), ...
        [appName ' should not depend on a separate ECG package.']);
end

function assertPackageMFiles(packageDir, expectedFiles, label)
    assert(exist(packageDir, 'dir') == 7, [label ' package directory should exist.']);

    fileEntries = dir(fullfile(packageDir, '*.m'));
    actualFiles = sort({fileEntries.name});
    expectedFiles = sort(expectedFiles);
    assert(isequal(actualFiles, expectedFiles), ...
        [label ' package .m files should be exactly: ' strjoin(expectedFiles, ', ')]);

    dirEntries = dir(packageDir);
    childDirs = {dirEntries([dirEntries.isdir]).name};
    childDirs = childDirs(~ismember(childDirs, {'.', '..'}));
    assert(isempty(childDirs), ...
        [label ' package should not keep child directories: ' strjoin(childDirs, ', ')]);
end

function assertTopLevelMFiles(packageDir, expectedFiles, label)
    assert(exist(packageDir, 'dir') == 7, [label ' package directory should exist.']);

    fileEntries = dir(fullfile(packageDir, '*.m'));
    actualFiles = sort({fileEntries.name});
    expectedFiles = sort(expectedFiles);
    assert(isequal(actualFiles, expectedFiles), ...
        [label ' package .m files should be exactly: ' strjoin(expectedFiles, ', ')]);
end

function assertPackageSourcesDoNotContain(packageDir, forbiddenWords, label)
    assert(exist(packageDir, 'dir') == 7, [label ' package directory should exist.']);

    fileEntries = dir(fullfile(packageDir, '*.m'));
    for iFile = 1:numel(fileEntries)
        source = fileread(fullfile(packageDir, fileEntries(iFile).name));
        for iWord = 1:numel(forbiddenWords)
            word = forbiddenWords{iWord};
            assert(~contains(source, word), ...
                sprintf('%s package file %s should not contain app-domain word "%s".', ...
                label, fileEntries(iFile).name, word));
        end
    end
end

function words = guiWords()
    words = {'uifigure', 'uigridlayout', 'uigetfile', 'uigetdir', 'uialert', ...
        'uilabel', 'uidropdown', 'uitable'};
end

function words = appEntrypointWords()
    words = {'labkit_CIC_app', 'labkit_VTResistance_app', 'labkit_CSC_app', ...
        'labkit_EIS_app', 'labkit_ChronoOverlay_app', ...
        'labkit_DICPreprocess_app', 'labkit_DICPostprocess_app', ...
        'labkit_CurvatureMeasurement_app', 'labkit_ECGPrint_app'};
end

function words = experimentWorkflowWords()
    words = {'computeCIC', 'computeVTResistance', 'computeCSC', ...
        'buildResultsTable', 'writeResultsCSV'};
end

function assertNoPackageMFiles(packageDir, label)
    if exist(packageDir, 'dir') ~= 7
        return;
    end

    fileEntries = dir(fullfile(packageDir, '*.m'));
    actualFiles = sort({fileEntries.name});
    assert(isempty(actualFiles), ...
        [label ' package should not keep .m files: ' strjoin(actualFiles, ', ')]);

    dirEntries = dir(packageDir);
    childDirs = {dirEntries([dirEntries.isdir]).name};
    childDirs = childDirs(~ismember(childDirs, {'.', '..'}));
    assert(isempty(childDirs), ...
        [label ' package should not keep child directories: ' strjoin(childDirs, ', ')]);
end
