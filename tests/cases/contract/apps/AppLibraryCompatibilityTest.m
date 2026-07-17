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
                @() batch_crop.sourceFiles.readItems(singlePath), ...
                @() image_enhance.sourceFiles.readImages(singlePath), ...
                @() image_match.sourceFiles.readImages(multiPaths), ...
                @() focus_stack.sourceFiles.readImages(multiPaths)};

            for k = 1:numel(readers)
                payload = readers{k}();
                testCase.verifyNotEmpty(payload, ...
                    sprintf('Reader %d should accept filePanel string-column paths.', k));
            end
        end

        function appReadersDoNotNormalizePathShapes(testCase)
            root = setupLabKitTestPath();
            readerFiles = [
                fullfile(root, "apps", "image_measurement", "batch_crop", ...
                    "+batch_crop", "+sourceFiles", "readItems.m")
                fullfile(root, "apps", "image_measurement", "image_enhance", ...
                    "+image_enhance", "+sourceFiles", "readImages.m")
                fullfile(root, "apps", "image_measurement", "image_match", ...
                    "+image_match", "+sourceFiles", "readImages.m")
                fullfile(root, "apps", "image_measurement", "focus_stack", ...
                    "+focus_stack", "+sourceFiles", "readImages.m")];
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

            emptyCropItems = batch_crop.sourceFiles.readItems(strings(0, 1));
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
                "event\.addedTasks"
                "event\.removedTasks"
                "event\.selectedTasks"
                "event\.paths"
                "event\.selection"
                "event\.addedPaths"
                "event\.removedPaths"
                "event\.selectedPaths"
                "labkit\.ui\.layout\.taskPanel"
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
                "Apps should consume canonical filePanel source records; " + ...
                "task/path-only events are retired: " + ...
                strjoin(findings, "; "));
        end

        function appDialogsUseRuntimeServices(testCase)
            root = setupLabKitTestPath();
            appFiles = collectAppMFiles(root);
            forbiddenPatterns = [
                "\bpwd\b"
                "\buigetfile\s*\("
                "\buigetdir\s*\("
                "\buiputfile\s*\("];
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
                "Apps should use filePanel and handler services.dialogs instead " + ...
                "of creating MATLAB dialogs directly: " + ...
                strjoin(findings, "; "));
        end

        function appAlertsUseRuntimeServices(testCase)
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
                "Apps should route alerts through handler services.dialogs.alert so " + ...
                "hidden GUI tests can record error paths without modal stalls: " + ...
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

        function appPackagesDoNotOwnCloseGuardState(testCase)
            root = setupLabKitTestPath();
            appFiles = collectAppMFiles(root);
            findings = strings(0, 1);

            for k = 1:numel(appFiles)
                content = string(fileread(appFiles(k)));
                if contains(content, "labkit.ui.runtime.setCloseGuard")
                    findings(end+1, 1) = string(localRelativePath(root, appFiles(k)));
                end
            end

            testCase.verifyEmpty(findings, ...
                "Close confirmation is framework-owned; app files must not " + ...
                "maintain close guard dirty state through removed runtime APIs: " + ...
                strjoin(findings, "; "));
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
    scope = labkitQualityScanScope(root);
    files = scope.appMFiles;
end

function files = collectAppRunFiles(root)
    scope = labkitQualityScanScope(root);
    files = scope.appRunFiles;
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
