classdef ProjectStructureGuardrailTest < matlab.unittest.TestCase
    %PROJECTSTRUCTUREGUARDRAILTEST Official project boundary guardrails.

    methods (Test, TestTags = {'Integration', 'Style'})
        function publicPackageSurfaceMatchesDocumentedFacades(testCase)
            root = setupLabKitTestPath();
            h = architectureTestHelpers();

            testCase.verifyFalse(isfolder(fullfile(root, '+labkit', '+app')), ...
                'Reusable +labkit should not keep the transitional +app package.');
            testCase.verifyFalse(isfolder(fullfile(root, '+labkit', '+plot')), ...
                'Reusable +labkit should not keep a plot package for app-specific plotting.');
            h.assertNoPackageMFiles(fullfile(root, '+labkit', '+analysis'), ...
                'Public reusable +labkit analysis');
            h.assertNoPackageMFiles(fullfile(root, '+labkit', '+data'), ...
                'Public reusable +labkit data');
            h.assertNoPackageMFiles(fullfile(root, '+labkit', '+io'), ...
                'Public reusable +labkit IO');
            h.assertNoPackageMFiles(fullfile(root, '+labkit', '+util'), ...
                'Reusable +labkit utility');

            h.assertTopLevelMFiles(fullfile(root, '+labkit', '+ui'), {}, ...
                'Layered +labkit UI root');
            h.assertTopLevelMFiles(fullfile(root, '+labkit', '+ui', '+app'), ...
                {'createShell.m', 'dispatchRequest.m', 'runBusy.m', 'tab.m'}, ...
                'UI app facade');
            h.assertTopLevelMFiles(fullfile(root, '+labkit', '+ui', '+diag'), ...
                {'createContext.m'}, ...
                'UI diagnostics facade');
            h.assertTopLevelMFiles(fullfile(root, '+labkit', '+ui', '+view'), ...
                {'axes.m', 'draw.m', 'form.m', 'panel.m', 'place.m', ...
                'section.m', 'update.m'}, ...
                'UI view facade');
            h.assertTopLevelMFiles(fullfile(root, '+labkit', '+ui', '+tool'), ...
                {'anchorEditor.m', 'createRuntime.m', 'scaleBar.m', ...
                'scaleBarCalibration.m'}, ...
                'UI tool facade');
            h.assertTopLevelMFiles(fullfile(root, '+labkit', '+dta'), ...
                {'addFilesToSession.m', 'detectPulses.m', 'detectType.m', 'findFiles.m', ...
                'getColumn.m', 'getCurveXY.m', 'getMainCurve.m', 'getZCurve.m', ...
                'loadFile.m', 'loadFiles.m', 'loadFolder.m', 'loadSession.m', ...
                'makeSession.m', 'removeSelectedItemsFromSession.m', ...
                'saveSession.m', 'selectSessionItems.m'}, ...
                'Public reusable +labkit DTA facade');
            h.assertTopLevelMFiles(fullfile(root, '+labkit', '+biosignal'), ...
                {'buildTemplate.m', 'compareGroups.m', 'cropSignal.m', ...
                'defaultEcgPeakOptions.m', 'detectEcgPeaks.m', 'filterSignal.m', ...
                'getChannel.m', 'listChannels.m', 'measureSegments.m', ...
                'readRecording.m', 'segmentByEvents.m'}, ...
                'Public reusable +labkit biosignal facade');
        end

        function packageDependencyBoundariesStayDomainNeutral(testCase)
            root = setupLabKitTestPath();
            h = architectureTestHelpers();
            guiWords = h.guiWords();
            appWords = h.appEntrypointWords();
            workflowWords = h.experimentWorkflowWords();

            h.assertPackageSourcesDoNotContain(fullfile(root, '+labkit', '+dta'), ...
                [guiWords {'apps/', 'labkit.io', 'labkit.data'} appWords], ...
                'Reusable +labkit DTA facade');
            h.assertPackageSourcesDoNotContain(fullfile(root, '+labkit', '+dta', 'private'), ...
                [guiWords {'labkit.ui', 'apps/'} appWords workflowWords], ...
                'DTA private implementation');
            h.assertPackageSourcesDoNotContain(fullfile(root, '+labkit', '+biosignal'), ...
                [guiWords {'apps/', 'labkit.ui', 'labkit.dta'} appWords], ...
                'Reusable +labkit biosignal facade');
            h.assertPackageSourcesDoNotContain(fullfile(root, '+labkit', '+biosignal', 'private'), ...
                [guiWords {'apps/', 'labkit.ui', 'labkit.dta'} appWords], ...
                'Biosignal private implementation');

            uiForbidden = [{'DTA', 'Gamry', 'labkit.dta', 'labkit.io', ...
                'labkit.data', 'labkit.analysis', 'apps/'} appWords];
            uiRoots = { ...
                fullfile(root, '+labkit', '+ui'), ...
                fullfile(root, '+labkit', '+ui', '+app'), ...
                fullfile(root, '+labkit', '+ui', '+app', 'private'), ...
                fullfile(root, '+labkit', '+ui', '+view'), ...
                fullfile(root, '+labkit', '+ui', '+view', 'private'), ...
                fullfile(root, '+labkit', '+ui', '+tool'), ...
                fullfile(root, '+labkit', '+ui', '+tool', 'private'), ...
                fullfile(root, '+labkit', '+ui', '+diag')};
            for k = 1:numel(uiRoots)
                h.assertPackageSourcesDoNotContain(uiRoots{k}, uiForbidden, ...
                    ['Reusable UI boundary at ' relativePath(root, uiRoots{k})]);
            end

            testCase.verifyFalse(isfile(fullfile(root, '+labkit', '+ui', 'loadFilesIntoSession.m')), ...
                'GUI-free session loading should live in +labkit/+dta, not +ui.');
            testCase.verifyFalse(isfile(fullfile(root, '+labkit', '+io', 'exportTableCSV.m')), ...
                'One-line CSV writer wrappers should not live in reusable +labkit.');
        end

        function appEntrypointsStayInOwningFolders(testCase)
            root = setupLabKitTestPath();
            h = architectureTestHelpers();

            testCase.verifyFalse(isfolder(fullfile(root, 'apps', 'private')), ...
                'The transitional apps/private launcher directory should be removed.');
            expectedDirs = {'electrochem', 'dic', 'image_measurement', 'wearable'};
            for k = 1:numel(expectedDirs)
                testCase.verifyTrue(isfolder(fullfile(root, 'apps', expectedDirs{k})), ...
                    ['Missing app family folder: apps/' expectedDirs{k}]);
            end

            entries = appEntryManifest();
            for k = 1:size(entries, 1)
                appName = entries{k, 1};
                legacy = legacyEntrypointInfo(appName);
                source = h.assertAppEntrypoint(root, appName, legacy.launchName, legacy.legacyCall);
                assertAppFamilyBoundary(h, source, appName);
            end
        end

        function appOwnedWorkflowDoesNotLeakToReusablePackages(testCase)
            root = setupLabKitTestPath();
            forbiddenPackages = { ...
                fullfile(root, '+labkit', '+analysis'), ...
                fullfile(root, '+labkit', '+data'), ...
                fullfile(root, '+labkit', '+io'), ...
                fullfile(root, '+labkit', '+util'), ...
                fullfile(root, '+labkit', '+dic'), ...
                fullfile(root, '+labkit', '+image_measurement'), ...
                fullfile(root, '+labkit', '+ecg'), ...
                fullfile(root, '+labkit', '+ui', '+control'), ...
                fullfile(root, 'apps', '+labkit_apps')};
            for k = 1:numel(forbiddenPackages)
                testCase.verifyFalse(isfolder(forbiddenPackages{k}), ...
                    ['Helper-dump or app-specific public package must not exist: ' ...
                    relativePath(root, forbiddenPackages{k})]);
            end
        end

        function imageMeasurementAppsUseOwnedPackageNamespaces(testCase)
            root = setupLabKitTestPath();

            assertImageMeasurementPackageLayout(testCase, root, ...
                'batch_crop', 'batch_crop', 'labkit_BatchImageCrop_app.m');
            assertImageMeasurementPackageLayout(testCase, root, ...
                'curvature', 'curvature', 'labkit_CurvatureMeasurement_app.m');
            assertImageMeasurementPackageLayout(testCase, root, ...
                'focus_stack', 'focus_stack', 'labkit_FocusStack_app.m');
        end

        function electrochemAppsUseOwnedPackageNamespaces(testCase)
            root = setupLabKitTestPath();

            testCase.verifyFalse(isfolder(fullfile(root, 'apps', 'electrochem', 'private')), ...
                'Electrochem apps should use app-owned packages, not apps/electrochem/private.');
            workflowFiles = dir(fullfile(root, 'apps', 'electrochem', '**', '*Workflow.m'));
            testCase.verifyTrue(isempty(workflowFiles), ...
                'Electrochem apps should not keep string-dispatch workflow adapters.');

            assertElectrochemPackageLayout(testCase, root, ...
                'chrono_overlay', 'chrono_overlay');
            assertElectrochemPackageLayout(testCase, root, ...
                'cic', 'cic');
            assertElectrochemPackageLayout(testCase, root, ...
                'csc', 'csc');
            assertElectrochemPackageLayout(testCase, root, ...
                'eis', 'eis');
            assertElectrochemPackageLayout(testCase, root, ...
                'vt_resistance', 'vt_resistance');
        end

        function sensitiveSampleHygieneScansTrackedText(testCase)
            root = setupLabKitTestPath();
            files = collectTrackedTextScope(root);
            testCase.assertFalse(isempty(files), ...
                'Sensitive sample hygiene should scan tracked text files.');

            for k = 1:numel(files)
                filepath = files{k};
                content = fileread(filepath);
                rel = relativePath(root, filepath);
                assertNoDriveRootPath(content, rel);
                assertNoCurrentHomePath(content, rel);
                assertNoSampleTimestampToken(content, rel);
            end
        end

        function startupPathKeepsPrivateHelpersPrivate(testCase)
            root = setupLabKitTestPath();

            testCase.verifyTrue(isfile(fullfile(root, 'startup_labkit.m')), ...
                'startup_labkit.m is missing.');
            testCase.verifyFalse(isfolder(fullfile(root, 'legacy')), ...
                'legacy/ should not be reintroduced.');
            testCase.verifyTrue(pathContains(fullfile(root, 'apps')), ...
                'startup_labkit should add apps/ to the path.');
            testCase.verifyTrue(pathContains(fullfile(root, 'apps', 'electrochem')), ...
                'startup_labkit should add nested app category folders to the path.');
            testCase.verifyTrue(pathContains(fullfile(root, 'apps', 'electrochem', 'cic')), ...
                'startup_labkit should add nested electrochem app folders.');
            testCase.verifyFalse(pathContains(fullfile(root, 'apps', 'electrochem', 'cic', '+cic')), ...
                'startup_labkit should not expose electrochem app-owned package folders directly.');
            testCase.verifyTrue(pathContains(fullfile(root, 'apps', 'image_measurement', 'curvature')), ...
                'startup_labkit should add nested image measurement app folders.');
            testCase.verifyFalse(pathContains(fullfile(root, 'apps', 'image_measurement', 'curvature', 'private')), ...
                'startup_labkit should not expose app-private helper folders.');
            testCase.verifyFalse(pathContains(fullfile(root, 'apps', 'image_measurement', 'curvature', '+curvature')), ...
                'startup_labkit should not expose app-owned package folders directly.');
        end
    end
end

function assertElectrochemPackageLayout(testCase, root, appFolder, packageName)
    appDir = fullfile(root, 'apps', 'electrochem', appFolder);
    packageDir = fullfile(appDir, ['+' packageName]);

    testCase.verifyTrue(isfolder(appDir), ...
        ['Missing electrochem app folder: apps/electrochem/' appFolder]);
    testCase.verifyTrue(isfile(fullfile(appDir, appEntrypointName(appFolder))), ...
        ['Missing electrochem app entrypoint under ' relativePath(root, appDir)]);
    testCase.verifyFalse(isfolder(fullfile(appDir, 'private')), ...
        ['Electrochem app should use an app-owned package, not private/: ' appFolder]);
    testCase.verifyFalse(isfolder(fullfile(appDir, '+app')), ...
        ['Electrochem app should not use a fixed +app namespace: ' appFolder]);
    workflowFiles = dir(fullfile(appDir, '*Workflow.m'));
    testCase.verifyTrue(isempty(workflowFiles), ...
        ['Electrochem app should not keep workflow dispatch adapters: ' appFolder]);
    assertAppOwnedPackageCapability(testCase, root, appDir, packageDir, ...
        'electrochem', packageName);
end

function name = appEntrypointName(appFolder)
    switch appFolder
        case 'chrono_overlay'
            name = 'labkit_ChronoOverlay_app.m';
        case 'cic'
            name = 'labkit_CIC_app.m';
        case 'csc'
            name = 'labkit_CSC_app.m';
        case 'eis'
            name = 'labkit_EIS_app.m';
        case 'vt_resistance'
            name = 'labkit_VTResistance_app.m';
        otherwise
            error('Unknown electrochem app folder: %s', appFolder);
    end
end

function assertImageMeasurementPackageLayout(testCase, root, appFolder, packageName, entrypointName)
    appDir = fullfile(root, 'apps', 'image_measurement', appFolder);
    packageDir = fullfile(appDir, ['+' packageName]);

    testCase.verifyTrue(isfolder(appDir), ...
        ['Missing image-measurement app folder: apps/image_measurement/' appFolder]);
    testCase.verifyTrue(isfile(fullfile(appDir, entrypointName)), ...
        ['Missing image-measurement app entrypoint under ' relativePath(root, appDir)]);
    testCase.verifyFalse(isfolder(fullfile(appDir, 'private')), ...
        ['Image-measurement app should use an app-owned package, not private/: ' appFolder]);
    testCase.verifyFalse(isfolder(fullfile(appDir, '+app')), ...
        ['Image-measurement app should not use a fixed +app namespace: ' appFolder]);
    workflowFiles = dir(fullfile(appDir, '*Workflow.m'));
    testCase.verifyTrue(isempty(workflowFiles), ...
        ['Image-measurement app should not keep workflow dispatch adapters: ' appFolder]);
    assertAppOwnedPackageCapability(testCase, root, appDir, packageDir, ...
        'image_measurement', packageName);
end

function assertAppOwnedPackageCapability(testCase, root, appDir, packageDir, family, packageName)
    testCase.verifyTrue(isfolder(packageDir), ...
        ['Missing app-owned package namespace: ' relativePath(root, packageDir)]);
    testCase.verifyFalse(isfolder(fullfile(packageDir, '+core')), ...
        ['App-owned package should not route through +core: ' relativePath(root, packageDir)]);
    testCase.verifyFalse(isfile(fullfile(packageDir, '+core', 'dispatch.m')), ...
        ['App-owned package should not keep +core/dispatch.m: ' relativePath(root, packageDir)]);

    packageFiles = dir(fullfile(packageDir, '**', '*.m'));
    testCase.verifyFalse(isempty(packageFiles), ...
        ['App-owned package should contain helper files: ' relativePath(root, packageDir)]);
    testCase.verifyTrue(hasNonUiPackageComponent(packageDir), ...
        ['App-owned package should expose directly testable non-UI behavior: ' ...
        relativePath(root, packageDir)]);
    testCase.verifyTrue(packageNamespaceHasDirectUnitTest(root, family, packageName), ...
        ['App-owned non-UI package functions should have direct unit tests: ' ...
        relativePath(root, packageDir)]);

    uiRunApp = fullfile(packageDir, '+ui', 'runApp.m');
    if isfile(uiRunApp)
        testCase.verifyTrue(numel(packageFiles) > 1, ...
            ['App-owned package should not be only a +ui/runApp.m wrapper: ' ...
            relativePath(root, appDir)]);
    end
end

function tf = hasNonUiPackageComponent(packageDir)
    componentNames = {'+ops', '+view', '+export', '+io', '+state'};
    tf = false;
    for k = 1:numel(componentNames)
        componentRoot = fullfile(packageDir, componentNames{k});
        files = dir(fullfile(componentRoot, '*.m'));
        if isfolder(componentRoot) && any(~[files.isdir])
            tf = true;
            return;
        end
    end
end

function tf = packageNamespaceHasDirectUnitTest(root, family, packageName)
    testRoot = fullfile(root, 'tests', 'unit', 'apps', family);
    if ~isfolder(testRoot)
        tf = false;
        return;
    end

    pattern = [packageName '\.(ops|view|export|io|state)\.'];
    testFiles = collectTextFiles(testRoot);
    tf = false;
    for k = 1:numel(testFiles)
        if ~isempty(regexp(fileread(testFiles{k}), pattern, 'once'))
            tf = true;
            return;
        end
    end
end

function assertAppFamilyBoundary(h, source, appName)
    if contains(appName, 'ChronoOverlay')
        h.assertDTAFacadeUsage(source, appName, 'chrono', true);
    elseif contains(appName, 'EIS')
        h.assertDTAFacadeUsage(source, appName, 'eis', true);
    elseif contains(appName, 'CSC')
        h.assertDTAFacadeUsage(source, appName, 'cvct', false);
    elseif contains(appName, 'VTResistance') || contains(appName, 'CIC')
        h.assertDTAFacadeUsage(source, appName, 'chrono', true);
    elseif contains(appName, 'DIC')
        h.assertDICAppBoundary(source, appName);
    elseif contains(appName, 'CurvatureMeasurement') || contains(appName, 'FocusStack') || ...
            contains(appName, 'BatchImageCrop')
        h.assertImageMeasurementAppBoundary(source, appName);
    elseif contains(appName, 'ECGPrint')
        h.assertWearableAppBoundary(source, appName);
    end
end

function legacy = legacyEntrypointInfo(appName)
    switch appName
        case 'labkit_ChronoOverlay_app'
            legacy = struct('launchName', 'launchChronoOverlayApp', ...
                'legacyCall', 'gamry_multiDTA_plot_export_gui(');
        case 'labkit_EIS_app'
            legacy = struct('launchName', 'launchEISApp', ...
                'legacyCall', 'gamry_EIS_multiDTA_plot_gui(');
        case 'labkit_CSC_app'
            legacy = struct('launchName', 'launchCSCApp', ...
                'legacyCall', 'gamry_CV_CSC_dta_gui(');
        case 'labkit_VTResistance_app'
            legacy = struct('launchName', 'launchVTResistanceApp', ...
                'legacyCall', 'gamry_VT_resistance_gui(');
        case 'labkit_CIC_app'
            legacy = struct('launchName', 'launchCICApp', ...
                'legacyCall', 'gamry_CIC_VT_gui_paperlabels(');
        case 'labkit_DICPreprocess_app'
            legacy = struct('launchName', 'launchDICPreprocessApp', ...
                'legacyCall', 'dic_preprocess_gui(');
        case 'labkit_DICPostprocess_app'
            legacy = struct('launchName', 'launchDICPostprocessApp', ...
                'legacyCall', 'dic_postprocess_gui(');
        case 'labkit_CurvatureMeasurement_app'
            legacy = struct('launchName', 'launchCurvatureMeasurementApp', ...
                'legacyCall', 'curvature_measurement_gui(');
        case 'labkit_FocusStack_app'
            legacy = struct('launchName', 'launchFocusStackApp', ...
                'legacyCall', 'focus_stack_gui(');
        case 'labkit_BatchImageCrop_app'
            legacy = struct('launchName', 'launchBatchImageCropApp', ...
                'legacyCall', 'batch_crop_gui(');
        case 'labkit_ECGPrint_app'
            legacy = struct('launchName', 'launchECGPrintApp', ...
                'legacyCall', 'wearable_ecg_print_gui(');
        otherwise
            error('Unknown app entrypoint in manifest: %s', appName);
    end
end

function files = collectTrackedTextScope(root)
    entries = {'README.md', 'AGENTS.md', 'docs', 'scripts', ...
        'tests', 'apps', '+labkit', '.github'};
    files = {};
    for k = 1:numel(entries)
        path = fullfile(root, entries{k});
        if isfolder(path)
            files = [files, collectTextFiles(path)]; %#ok<AGROW>
        elseif isfile(path) && isTextFile(path)
            files{end+1} = path; %#ok<AGROW>
        end
    end
end

function files = collectTextFiles(folder)
    files = {};
    entries = dir(folder);
    [~, order] = sort({entries.name});
    entries = entries(order);
    for k = 1:numel(entries)
        entry = entries(k);
        if entry.isdir
            if any(strcmp(entry.name, {'.', '..'}))
                continue;
            end
            files = [files, collectTextFiles(fullfile(folder, entry.name))]; %#ok<AGROW>
        else
            filepath = fullfile(folder, entry.name);
            if isTextFile(filepath)
                files{end+1} = filepath; %#ok<AGROW>
            end
        end
    end
end

function tf = isTextFile(filepath)
    [~, ~, ext] = fileparts(filepath);
    tf = any(strcmpi(ext, {'.m', '.md', '.ps1', '.sh', '.yml', '.yaml', ...
        '.json', '.txt', '.csv', '.tsv'}));
end

function assertNoDriveRootPath(content, rel)
    matchStarts = regexp(content, '[A-Za-z]:[\\/]', 'start');
    isDriveRoot = false(size(matchStarts));
    for k = 1:numel(matchStarts)
        isDriveRoot(k) = matchStarts(k) == 1 || ...
            ~isstrprop(content(matchStarts(k)-1), 'alpha');
    end
    assert(~any(isDriveRoot), ...
        ['Tracked text file %s contains a drive-root absolute path. ' ...
        'Use synthetic relative paths in source, tests, and docs.'], rel);
end

function assertNoCurrentHomePath(content, rel)
    homeValues = unique(string({getenv('USERPROFILE'), getenv('HOME')}));
    for k = 1:numel(homeValues)
        home = homeValues(k);
        if strlength(home) <= 3
            continue;
        end
        variants = unique([home, replace(home, "\", "/"), replace(home, "/", "\")]);
        for i = 1:numel(variants)
            assert(~contains(content, variants(i)), ...
                ['Tracked text file %s contains the current user home path. ' ...
                'Use synthetic relative paths in source, tests, and docs.'], rel);
        end
    end
end

function assertNoSampleTimestampToken(content, rel)
    assert(isempty(regexp(content, '\d{8}_\d{6}', 'once')), ...
        ['Tracked text file %s contains a timestamp-shaped sample token. ' ...
        'Use synthetic fixture names and metadata in source, tests, and docs.'], rel);
end

function tf = pathContains(folder)
    paths = strsplit(path, pathsep);
    tf = any(strcmp(paths, folder));
end

function rel = relativePath(root, filepath)
    rel = filepath;
    prefix = [root filesep];
    if startsWith(filepath, prefix)
        rel = filepath(numel(prefix)+1:end);
    end
    rel = strrep(rel, filesep, '/');
end
