classdef AppLibraryCompatibilityTest < matlab.unittest.TestCase
    %APPLIBRARYCOMPATIBILITYTEST Verify app-facing boundary input shapes.

    methods (Test, TestTags = {'Integration'})
        function appReadersAcceptFilePanelStringColumns(testCase)
            setupLabKitTestPath();
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() removeTempFolder(folder));

            firstImage = fullfile(folder, 'input_a.png');
            secondImage = fullfile(folder, 'input_b.png');
            imwrite(uint8(40 * ones(8, 9, 3)), firstImage);
            imwrite(uint8(90 * ones(8, 9, 3)), secondImage);
            singlePath = reshape(string(firstImage), [], 1);
            multiPaths = reshape([string(firstImage); string(secondImage)], [], 1);

            readers = { ...
                @() batch_crop.appState.readItems(singlePath), ...
                @() image_enhance.io.readImages(singlePath), ...
                @() image_match.io.readImages(multiPaths), ...
                @() focus_stack.io.readImages(multiPaths)};

            for k = 1:numel(readers)
                payload = readers{k}();
                testCase.verifyNotEmpty(payload, ...
                    sprintf('Reader %d should accept filePanel string-column paths.', k));
            end
        end

        function filePanelIndicesNormalizeToStableItemIndices(testCase)
            setupLabKitTestPath();
            files = struct( ...
                'index', {2, [], 99, []}, ...
                'id', {'file1', 'file3', 'file4', 'file2'});

            idx = labkit.ui.view.fileIndices(files, 3);

            testCase.verifyEqual(idx, [2; 3], ...
                'filePanel index helpers should prefer valid index values, fall back from missing indices, and drop duplicates or out-of-range values.');
        end

        function appReadersDoNotNormalizePathShapes(testCase)
            root = setupLabKitTestPath();
            readerFiles = [
                fullfile(root, "apps", "image_measurement", "batch_crop", ...
                    "+batch_crop", "+appState", "readItems.m")
                fullfile(root, "apps", "image_measurement", "image_enhance", ...
                    "+image_enhance", "+io", "readImages.m")
                fullfile(root, "apps", "image_measurement", "image_match", ...
                    "+image_match", "+io", "readImages.m")
                fullfile(root, "apps", "image_measurement", "focus_stack", ...
                    "+focus_stack", "+io", "readImages.m")];
            forbiddenPatterns = [
                "string\(paths\)"
                "paths\s*=\s*paths\(:\)"
                "assertStringColumnPaths"
                "normalizePathList"];
            findings = strings(0, 1);
            for k = 1:numel(readerFiles)
                content = fileread(readerFiles(k));
                for p = 1:numel(forbiddenPatterns)
                    if ~isempty(regexp(content, forbiddenPatterns(p), 'once'))
                        findings(end+1, 1) = string(localRelativePath(root, readerFiles(k))) + ...
                            " matches " + forbiddenPatterns(p);
                    end
                end
            end
            testCase.verifyEmpty(findings, ...
                "App readers should rely on the filePanel string-column contract; " + ...
                "path normalization belongs inside labkit.image: " + ...
                strjoin(findings, "; "));

            emptyCropItems = batch_crop.appState.readItems(strings(0, 1));
            testCase.verifyEmpty(emptyCropItems, ...
                'Batch crop reader should preserve empty string-list shape as no items.');
        end

        function filePanelPathReachesImageFacade(testCase)
            setupLabKitTestPath();
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() removeTempFolder(folder));

            imagePath = fullfile(folder, 'source.png');
            imwrite(uint8(120 * ones(8, 9)), imagePath);
            eventPaths = reshape(string(imagePath), [], 1);

            records = labkit.image.readFiles(eventPaths);

            testCase.verifyEqual(numel(records), 1, ...
                'Image facade should accept filePanel string-column paths.');
            testCase.verifyEqual(records.name, "source.png");
            testCase.verifyEqual(size(records.image), [8 9 3], ...
                'Image facade should normalize grayscale source images to RGB.');
        end

        function filePanelFilesReachDtaFileFacade(testCase)
            setupLabKitTestPath();
            fixture = dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');

            [items, report] = labkit.dta.loadFiles({string(fixture)}, "chrono");

            testCase.verifyEqual(numel(items), 1, ...
                'DTA file facade should accept scalar-string cell-array file paths.');
            testCase.verifyEqual(report.nLoaded, 1, ...
                'DTA file facade should report the filePanel-shaped input as loaded.');
            testCase.verifyEqual(items{1}.type, "chrono", ...
                'DTA file facade should return parsed items without owning app file state.');
        end

        function filePanelPathReachesBiosignalRecordingFacade(testCase)
            setupLabKitTestPath();
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() removeTempFolder(folder));

            recordingPath = fullfile(folder, 'recording.csv');
            writeLines(recordingPath, [
                "time_s,ECG"
                "0,0.1"
                "0.01,0.3"
                "0.02,0.2"]);

            eventPaths = {recordingPath};
            filepath = char(string(eventPaths{1}));
            [recording, status] = labkit.biosignal.readRecording(filepath);

            testCase.verifyTrue(status.ok, status.message);
            testCase.verifyTrue(any(strcmp(labkit.biosignal.listChannels(recording), 'ECG')), ...
                'Biosignal facade should read the filePanel-selected recording.');

            signalByString = labkit.biosignal.getChannel(recording, "ECG");
            signalByIndex = labkit.biosignal.getChannel(recording, 1);
            testCase.verifyEqual(signalByString.displayName, signalByIndex.displayName, ...
                'Biosignal channel lookup should accept string and numeric UI values.');

            filtered = labkit.biosignal.filterSignal(signalByString, struct( ...
                'type', 'bandpass', ...
                'cutoffHz', [0.5 40], ...
                'edgeMode', 'none'));
            cropped = labkit.biosignal.cropSignal(filtered, [0 0.02]);
            testCase.verifyEqual(numel(cropped.time), numel(cropped.values), ...
                'Biosignal crop/filter option shapes should preserve signal alignment.');
        end

        function filePanelStringColumnsReachRhsFacade(testCase)
            setupLabKitTestPath();
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() removeTempFolder(folder));

            rhsFile = fullfile(folder, 'recording.rhs');
            writeSyntheticRhsFixture(rhsFile, struct("nBlocks", 2));

            filePaths = reshape(string(rhsFile), [], 1);
            testCase.verifyEqual(filePaths, string(rhsFile), ...
                'FilePanel file paths should arrive at app callbacks as string columns.');

            [index, indexStatus] = labkit.rhs.indexFile(filePaths(1));
            testCase.verifyTrue(indexStatus.ok, indexStatus.message);
            testCase.verifyTrue(index.hasData, ...
                'RHS facade should index the filePanel-selected file.');

            opts = struct( ...
                "family", 'amplifier', ...
                "channels", {{'C001'}}, ...
                "timeRangeSec", [0; 3/30000]);
            [window, windowStatus] = labkit.rhs.readWindow(filePaths(1), opts);
            testCase.verifyTrue(windowStatus.ok, windowStatus.message);
            testCase.verifyEqual(window.channels, "C-001", ...
                'RHS readWindow should accept app-style family, channel, and range shapes.');

            folderPaths = reshape(string(folder), [], 1);
            files = labkit.rhs.findFiles(folderPaths(1));
            testCase.verifyTrue(any(strcmp(files, rhsFile)), ...
                'RHS facade should discover files under the filePanel-selected folder.');
        end

        function appsUseFilePanelFileEventContract(testCase)
            root = setupLabKitTestPath();
            appFiles = collectAppMFiles(root);
            forbiddenPatterns = [
                "event\.tasks"
                "addedTasks"
                "removedTasks"
                "selectedTasks"
                "event\.paths"
                "event\.selection"
                "addedPaths"
                "removedPaths"
                "labkit\.ui\.spec\.taskPanel"
                "labkit\.ui\.view\.getTasks"
                "labkit\.ui\.view\.setTaskSelection"
                "labkit\.ui\.view\.taskLabels"
                "labkit\.ui\.view\.taskPaths"
                "labkit\.ui\.app\.normalizePathList"];
            findings = strings(0, 1);

            for k = 1:numel(appFiles)
                content = fileread(appFiles(k));
                for p = 1:numel(forbiddenPatterns)
                    if ~isempty(regexp(content, forbiddenPatterns(p), 'once'))
                        findings(end+1, 1) = string(localRelativePath(root, appFiles(k))) + ...
                            " matches " + forbiddenPatterns(p);
                    end
                end
            end

            testCase.verifyEmpty(findings, ...
                "Apps should consume filePanel file entries and extract paths with " + ...
                "labkit.ui.view.filePaths; task/path events are retired: " + ...
                strjoin(findings, "; "));
        end

        function appDialogsAvoidLabKitRuntimeDefaults(testCase)
            root = setupLabKitTestPath();
            appFiles = collectAppMFiles(root);
            forbiddenPatterns = [
                "\bpwd\b"
                "uigetdir\s*\(\s*pwd"
                "uiputfile\s*\("];
            findings = strings(0, 1);

            for k = 1:numel(appFiles)
                content = fileread(appFiles(k));
                for p = 1:numel(forbiddenPatterns)
                    if ~isempty(regexp(content, forbiddenPatterns(p), 'once'))
                        findings(end+1, 1) = string(localRelativePath(root, appFiles(k))) + ...
                            " matches " + forbiddenPatterns(p);
                    end
                end
            end
            findings = [findings; bareUigetfileFindings(root, appFiles)];

            testCase.verifyEmpty(findings, ...
                "Apps should not default file dialogs or exports into the LabKit " + ...
                "runtime folder; use filePanel, labkit.ui.app.defaultDialogFolder, " + ...
                "labkit.ui.app.promptOutputFile, or labkit.ui.app.promptOutputFolder: " + ...
                strjoin(findings, "; "));
        end

        function appAlertsUseFrameworkShowAlert(testCase)
            root = setupLabKitTestPath();
            appFiles = collectAppMFiles(root);
            findings = strings(0, 1);

            for k = 1:numel(appFiles)
                content = fileread(appFiles(k));
                if ~isempty(regexp(content, '\buialert\s*\(', 'once'))
                    findings(end+1, 1) = string(localRelativePath(root, appFiles(k)));
                end
            end

            testCase.verifyEmpty(findings, ...
                "Apps should route alerts through labkit.ui.app.showAlert " + ...
                "so hidden GUI workflow tests can record error paths without modal stalls: " + ...
                strjoin(findings, "; "));
        end

        function appRunnersReportCaughtCallbackExceptions(testCase)
            root = setupLabKitTestPath();
            runFiles = collectAppRunFiles(root);
            findings = strings(0, 1);

            for k = 1:numel(runFiles)
                content = string(fileread(runFiles(k)));
                catchBlocks = regexp(content, ...
                    'catch\s+ME([\s\S]*?)(?=\n\s*(?:catch|end)\b)', ...
                    'tokens');
                for c = 1:numel(catchBlocks)
                    block = string(catchBlocks{c}{1});
                    reportsException = contains(block, 'reportException') || ...
                        contains(block, 'showException');
                    if ~reportsException
                        findings(end+1, 1) = string(localRelativePath(root, runFiles(k))) + ...
                            " has catch ME without debug.reportException";
                    end
                end
            end

            testCase.verifyEmpty(unique(findings, "stable"), ...
                "App runners that catch MException and continue must report " + ...
                "through the debug context before alerts or recovery logs: " + ...
                strjoin(findings, "; "));
        end

        function dirtyImageWorkflowAppsUseCloseGuard(testCase)
            root = setupLabKitTestPath();
            guardedPackageDirs = [
                fullfile(root, "apps", "image_measurement", "focus_stack", ...
                    "+focus_stack")
                fullfile(root, "apps", "image_measurement", "image_enhance", ...
                    "+image_enhance")
                fullfile(root, "apps", "image_measurement", "image_match", ...
                    "+image_match")];
            findings = strings(0, 1);

            for k = 1:numel(guardedPackageDirs)
                content = readPackageSource(guardedPackageDirs(k));
                if ~contains(content, "labkit.ui.app.setCloseGuard")
                    findings(end+1, 1) = string(localRelativePath(root, guardedPackageDirs(k)));
                end
            end

            testCase.verifyEmpty(findings, ...
                "Image workflow apps with dirty/export fingerprints should " + ...
                "connect meaningful unfinished state to the framework close guard: " + ...
                strjoin(findings, "; "));
        end
    end
end

function findings = bareUigetfileFindings(root, files)
    findings = strings(0, 1);
    for k = 1:numel(files)
        content = fileread(files(k));
        calls = regexp(content, 'uigetfile\s*\(([\s\S]*?)\);', 'tokens');
        for c = 1:numel(calls)
            callText = string(calls{c}{1});
            hasSafeInputDefault = ~isempty(regexp(callText, ...
                'labkit\.ui\.app\.defaultDialogFolder\s*\(\s*["'']input["'']\s*\)', 'once'));
            if ~hasSafeInputDefault
                findings(end+1, 1) = string(localRelativePath(root, files(k))) + ...
                    " has uigetfile without labkit.ui.app.defaultDialogFolder(""input"")";
            end
        end
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

function files = collectAppMFiles(root)
    listing = dir(fullfile(root, "apps", "**", "*.m"));
    files = strings(0, 1);
    for k = 1:numel(listing)
        if ~listing(k).isdir
            files(end+1, 1) = string(fullfile(listing(k).folder, listing(k).name));
        end
    end
end

function files = collectAppRunFiles(root)
    listing = dir(fullfile(root, "apps", "**", "run.m"));
    files = strings(0, 1);
    packageMarker = filesep + "+";
    for k = 1:numel(listing)
        if listing(k).isdir
            continue;
        end
        pathValue = string(fullfile(listing(k).folder, listing(k).name));
        if contains(pathValue, packageMarker)
            files(end+1, 1) = pathValue;
        end
    end
end

function source = readPackageSource(packageDir)
    files = dir(fullfile(packageDir, "**", "*.m"));
    parts = cell(1, numel(files));
    for k = 1:numel(files)
        parts{k} = fileread(fullfile(files(k).folder, files(k).name));
    end
    source = string(strjoin(parts, newline));
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end

function writeLines(filepath, lines)
    fid = fopen(filepath, 'w');
    assert(fid > 0, 'Could not create temporary text fixture.');
    cleanup = onCleanup(@() fclose(fid));
    for k = 1:numel(lines)
        fprintf(fid, '%s\n', char(lines(k)));
    end
end
