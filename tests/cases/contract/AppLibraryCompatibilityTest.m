classdef AppLibraryCompatibilityTest < matlab.unittest.TestCase
    %APPLIBRARYCOMPATIBILITYTEST Verify app-facing boundary input shapes.

    methods (Test, TestTags = {'Integration'})
        function appReadersAcceptPathPanelStringColumns(testCase)
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
                @() batch_crop.state.readItems(singlePath), ...
                @() image_enhance.io.readImages(singlePath), ...
                @() image_match.io.readImages(multiPaths), ...
                @() focus_stack.io.readImages(multiPaths)};

            for k = 1:numel(readers)
                payload = readers{k}();
                testCase.verifyNotEmpty(payload, ...
                    sprintf('Reader %d should accept pathPanel string-column paths.', k));
            end
        end

        function appReadersDoNotNormalizePathShapes(testCase)
            root = setupLabKitTestPath();
            readerFiles = [
                fullfile(root, "apps", "image_measurement", "batch_crop", ...
                    "+batch_crop", "+state", "readItems.m")
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
                "App readers should rely on the pathPanel string-column contract; " + ...
                "normalization belongs inside the UI event producer: " + ...
                strjoin(findings, "; "));

            emptyCropItems = batch_crop.state.readItems(strings(0, 1));
            testCase.verifyEmpty(emptyCropItems, ...
                'Batch crop reader should preserve empty string-list shape as no items.');
        end

        function pathPanelCellPathsReachDtaSessionFacade(testCase)
            setupLabKitTestPath();
            fixture = dtaFixturePath('chrono_chronopot_current_pulse_0p2ms.DTA');
            session = labkit.dta.makeSession('compatibility');

            [session, report] = labkit.dta.addFilesToSession( ...
                session, {string(fixture)}, "chrono");

            testCase.verifyEqual(numel(session.items), 1, ...
                'DTA session facade should accept scalar-string cell-array paths.');
            testCase.verifyEqual(report.nAdded, 1, ...
                'DTA session facade should report the pathPanel-shaped input as added.');

            itemName = session.items(1).name;
            [selectedByString, idxByString] = labkit.dta.selectSessionItems( ...
                session, string(itemName));
            [selectedByCell, idxByCell] = labkit.dta.selectSessionItems( ...
                session, {string(itemName)});
            testCase.verifyEqual(idxByString, 1, ...
                'DTA selection should accept scalar string listbox values.');
            testCase.verifyEqual(idxByCell, 1, ...
                'DTA selection should accept scalar-string cell listbox values.');
            testCase.verifyEqual(selectedByString.name, selectedByCell.name, ...
                'DTA selection shapes should resolve to the same item.');

            [removedSession, removeReport] = labkit.dta.removeSelectedItemsFromSession( ...
                session, {string(itemName)}, struct());
            testCase.verifyEmpty(removedSession.items, ...
                'DTA removal should accept scalar-string cell listbox values.');
            testCase.verifyEqual(numel(removeReport.removed), 1, ...
                'DTA removal should report one removed item.');
        end

        function pathPanelCellPathReachesBiosignalRecordingFacade(testCase)
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
                'Biosignal facade should read the pathPanel-selected recording.');

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

        function pathPanelStringColumnsReachRhsFacade(testCase)
            setupLabKitTestPath();
            folder = tempname;
            mkdir(folder);
            cleanup = onCleanup(@() removeTempFolder(folder));

            rhsFile = fullfile(folder, 'recording.rhs');
            writeSyntheticRhsFixture(rhsFile, struct("nBlocks", 2));

            filePaths = reshape(string(rhsFile), [], 1);
            testCase.verifyEqual(filePaths, string(rhsFile), ...
                'PathPanel file paths should arrive at app callbacks as string columns.');

            [index, indexStatus] = labkit.rhs.indexFile(filePaths(1));
            testCase.verifyTrue(indexStatus.ok, indexStatus.message);
            testCase.verifyTrue(index.hasData, ...
                'RHS facade should index the pathPanel-selected file.');

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
                'RHS facade should discover files under the pathPanel-selected folder.');
        end

        function appsUseNormalizedPathEventContract(testCase)
            root = setupLabKitTestPath();
            appFiles = collectAppMFiles(root);
            forbiddenPatterns = [
                "event\.paths\{"
                "event\.paths\(:\)"
                "string\(event\.paths"
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
                "Apps should consume pathPanel event.paths directly as a string column; " + ...
                "path normalization belongs inside pathPanel, not app code: " + ...
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
                "runtime folder; use pathPanel, labkit.ui.app.defaultDialogFolder, " + ...
                "or labkit.ui.app.promptOutputFile: " + ...
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
