function h = architectureTestHelpers()
%ARCHITECTURETESTHELPERS Shared project architecture guardrail assertions.

    h = struct();
    h.assertNoPackageMFiles = @assertNoPackageMFiles;
    h.assertTopLevelMFiles = @assertTopLevelMFiles;
    h.assertPackageMFiles = @assertPackageMFiles;
    h.assertPackageSourcesDoNotContain = @assertPackageSourcesDoNotContain;
    h.assertAppEntrypoint = @assertAppEntrypoint;
    h.assertSingleFileApp = @assertAppEntrypoint;
    h.assertDTAFacadeUsage = @assertDTAFacadeUsage;
    h.assertDICAppBoundary = @assertDICAppBoundary;
    h.assertImageMeasurementAppBoundary = @assertImageMeasurementAppBoundary;
    h.assertWearableAppBoundary = @assertWearableAppBoundary;
    h.guiWords = @guiWords;
    h.appEntrypointWords = @appEntrypointWords;
    h.experimentWorkflowWords = @experimentWorkflowWords;
end

function source = assertAppEntrypoint(root, appName, launchName, legacyCall)
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

    appSource = fileread(appFile);
    appOwnedSource = readAppOwnedSource(appFile);
    assert(contains(appSource, ['function varargout = ' appName]), ...
        [appName ' should expose one public app entry-point source file.']);
    assert(~contains(appSource, launchName), ...
        [appName ' should not delegate to a separate launcher.']);
    assert(~contains(appSource, ['labkit.app.' launchName]), ...
        [appName ' should not route app implementation through the reusable package.']);
    assert(~contains(appSource, '_legacy'), [appName ' should not call legacy implementations.']);
    assert(~contains(appSource, legacyCall), ...
        [appName ' should not delegate to a removed root legacy-compatible wrapper.']);
    assert(~contains(appSource, 'labkit.io.'), ...
        [appName ' should not call low-level IO APIs directly.']);
    assert(~contains(appSource, 'labkit.data.'), ...
        [appName ' should not call removed data APIs directly.']);
    assert(~contains(appSource, 'labkit.analysis.'), ...
        [appName ' should not call internal analysis APIs directly.']);
    assert(~contains(appSource, 'labkit.util.'), ...
        [appName ' should not call utility APIs directly.']);
    assert(contains(appOwnedSource, 'labkit.ui.app.createShell'), ...
        [appName ' should build its GUI from the layered app shell facade.']);
    assert(~contains(appOwnedSource, 'labkit.ui.create'), ...
        [appName ' should not call removed flat UI create* helpers.']);
    assert(~contains(appOwnedSource, 'labkit.ui.appendLog'), ...
        [appName ' should not call removed flat UI log helpers.']);
    assert(~contains(appOwnedSource, 'labkit.ui.tabSpec'), ...
        [appName ' should not call removed flat UI tab helpers.']);
    assert(~contains(appOwnedSource, 'labkit.ui.layoutRow'), ...
        [appName ' should not call removed flat UI layout helpers.']);
    assert(~contains(appOwnedSource, 'labkit.ui.runWithBusyState'), ...
        [appName ' should not call removed flat UI busy-state helpers.']);
    assert(~contains(appOwnedSource, 'labkit.ui.createWorkbench'), ...
        [appName ' should not call removed flat UI shell helpers.']);
    assert(~contains(appOwnedSource, 'labkit.ui.handleAppRequest'), ...
        [appName ' should not call removed flat UI request helpers.']);
    assert(~contains(appOwnedSource, 'labkit.ui.createAppDebugLog'), ...
        [appName ' should not call removed flat UI debug helpers.']);
    assert(~contains(appOwnedSource, 'labkit.ui.createImageAxesRuntime'), ...
        [appName ' should not call removed flat UI runtime helpers.']);
    assert(~contains(appOwnedSource, 'labkit.ui.createStandardWorkbenchShell'), ...
        [appName ' should not use compatibility shell wrappers directly.']);
    assert(~contains(appOwnedSource, 'labkit.ui.createTabbedDualPlotShell'), ...
        [appName ' should not use compatibility shell wrappers directly.']);
    forbiddenViewHelpers = {'appendLog', 'clearAxes', 'enablePopout', ...
        'fileSelectionPanel', 'logPanel', ...
        'refreshListboxItems', 'refreshListboxSelection', 'resetAxes', ...
        'resultTable', 'showImage', 'textPanel'};
    for iHelper = 1:numel(forbiddenViewHelpers)
        oldViewCall = ['labkit.ui.view.' forbiddenViewHelpers{iHelper}];
        assert(~contains(appOwnedSource, oldViewCall), ...
            [appName ' should use the unified view panel/draw/update facade instead of ' oldViewCall '.']);
    end

    source = appOwnedSource;
    assert(~contains(source, 'labkit.io.'), ...
        [appName ' app-owned source should not call low-level IO APIs directly.']);
    assert(~contains(source, 'labkit.data.'), ...
        [appName ' app-owned source should not call removed data APIs directly.']);
    assert(~contains(source, 'labkit.analysis.'), ...
        [appName ' app-owned source should not call internal analysis APIs directly.']);
    assert(~contains(source, 'labkit.util.'), ...
        [appName ' app-owned source should not call utility APIs directly.']);
end

function source = readAppOwnedSource(appFile)
    appDir = fileparts(appFile);
    sourceParts = {fileread(appFile)};

    privateDir = fullfile(appDir, 'private');
    if exist(privateDir, 'dir') == 7
        sourceParts = appendSourceFiles(sourceParts, collectMFiles(privateDir));
    end

    packageEntries = dir(fullfile(appDir, '+*'));
    packageDirs = packageEntries([packageEntries.isdir]);
    for iDir = 1:numel(packageDirs)
        packageDir = fullfile(packageDirs(iDir).folder, packageDirs(iDir).name);
        sourceParts = appendSourceFiles(sourceParts, collectMFiles(packageDir));
    end

    source = strjoin(sourceParts, newline);
end

function sourceParts = appendSourceFiles(sourceParts, files)
    for iFile = 1:numel(files)
        sourceParts{end+1} = fileread(files{iFile}); %#ok<AGROW>
    end
end

function files = collectMFiles(folder)
    fileEntries = dir(fullfile(folder, '**', '*.m'));
    files = cell(numel(fileEntries), 1);
    for iFile = 1:numel(fileEntries)
        files{iFile} = fullfile(fileEntries(iFile).folder, fileEntries(iFile).name);
    end
    files = sort(files);
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
    assert(contains(source, 'labkit.ui.app.createShell'), ...
        [appName ' should build from the reusable GUI foundation.']);
    assert(~contains(source, '+labkit/+dic'), ...
        [appName ' should keep DIC workflow code app-local.']);
    assertAppUsesManagedImageInteractions(source, appName);
end

function assertImageMeasurementAppBoundary(source, appName)
    assert(~contains(source, 'labkit.dta.'), ...
        [appName ' should not use the electrochemistry DTA facade.']);
    assert(contains(source, 'labkit.ui.app.createShell'), ...
        [appName ' should build from the reusable GUI foundation.']);
    assert(~contains(source, '+labkit/+dic'), ...
        [appName ' should not depend on DIC implementation packages.']);
    assert(~contains(source, '+labkit/+image_measurement'), ...
        [appName ' should keep image-measurement workflow code app-local.']);
    packageName = imageMeasurementPackageForApp(appName);
    assert(contains(source, [packageName '.']), ...
        [appName ' should use its app-owned package namespace.']);
    allPackageNames = {'batch_crop', 'curvature', 'focus_stack'};
    otherPackageNames = setdiff(allPackageNames, {packageName});
    for iPackage = 1:numel(otherPackageNames)
        assert(~contains(source, [otherPackageNames{iPackage} '.']), ...
            [appName ' should not call sibling image-measurement app package ' ...
            otherPackageNames{iPackage} '.']);
    end
    assert(~contains(source, 'batchImageCropWorkflow') && ...
        ~contains(source, 'focusStackWorkflow') && ...
        ~contains(source, 'curvatureMeasurementWorkflow'), ...
        [appName ' should not use string-dispatch workflow adapters.']);
    assertAppUsesManagedImageInteractions(source, appName);
end

function packageName = imageMeasurementPackageForApp(appName)
    switch appName
        case 'labkit_BatchImageCrop_app'
            packageName = 'batch_crop';
        case 'labkit_CurvatureMeasurement_app'
            packageName = 'curvature';
        case 'labkit_FocusStack_app'
            packageName = 'focus_stack';
        otherwise
            error('Unknown image-measurement app entrypoint: %s', appName);
    end
end

function assertWearableAppBoundary(source, appName)
    assert(~contains(source, 'labkit.dta.'), ...
        [appName ' should not use the electrochemistry DTA facade.']);
    assert(contains(source, 'labkit.ui.app.createShell'), ...
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

function assertAppUsesManagedImageInteractions(source, appName)
    assert(~contains(source, 'WindowScrollWheelFcn'), ...
        [appName ' should register image scroll behavior through labkit.ui.tool.createRuntime.']);
    assert(~contains(source, 'WindowButtonMotionFcn') && ~contains(source, 'WindowButtonUpFcn'), ...
        [appName ' should not own image-tool drag callbacks directly.']);
    assert(~contains(source, '.ButtonDownFcn'), ...
        [appName ' should not own image axes pointer callbacks directly.']);
end

function words = guiWords()
    words = {'uifigure', 'uigridlayout', 'uigetfile', 'uigetdir', 'uialert', ...
        'uilabel', 'uidropdown', 'uitable'};
end

function words = appEntrypointWords()
    words = {'labkit_CIC_app', 'labkit_VTResistance_app', 'labkit_CSC_app', ...
        'labkit_EIS_app', 'labkit_ChronoOverlay_app', ...
        'labkit_DICPreprocess_app', 'labkit_DICPostprocess_app', ...
        'labkit_CurvatureMeasurement_app', 'labkit_FocusStack_app', ...
        'labkit_BatchImageCrop_app', 'labkit_ECGPrint_app'};
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
