classdef GuiLayoutNerveResponseAnalysisTest < matlab.unittest.TestCase
    %GUILAYOUTNERVERESPONSEANALYSISTEST Verify nerve-response GUI workflow.

    methods (Test, TestTags = {'GUI', 'Workflow'})
        function nerve_response_analysis_workflow_analyzes_filter_record(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = tempname;
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            filterPath = fullfile(folder, 'filter_record.json');
            writeFilterRecordJson(filterPath);

            fig = h.launchFigure('labkit_NerveResponseAnalysis_app', ...
                'Nerve Response Analysis');
            driver = labkitWorkflowDriver(fig);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(runtime.definition.contractVersion, 2, ...
                'Nerve Response Analysis must execute through Runtime V2.');
            driver.chooseFiles('sessionFile', filterPath);

            driver.click('Choose filter');
            testCase.verifyTrue(driver.enabled('runAnalysis'), ...
                'Nerve-response analysis should enable after a filter record loads.');
            ui = driver.registry();
            testCase.verifyTrue(contains(string(ui.controls.sessionFile.status.Value), ...
                'filter_record.json'), ...
                'Nerve-response workflow should show the selected filter record.');

            driver.click('Analyze Filtered Files');

            ui = driver.registry();
            testCase.verifyTrue(contains(string(ui.controls.statusField.valueHandle.Value), ...
                'Analyzed 1 recording'), ...
                'Nerve-response workflow should report analyzed recordings.');
            data = driver.tableData('summaryTable');
            testCase.verifyTrue(rowHasValue(data, 'Recordings', '2'), ...
                'Nerve-response summary should include all filter-record rows.');
            testCase.verifyTrue(rowHasValue(data, 'Analyzed', '1'), ...
                'Nerve-response summary should include accepted recording count.');
            testCase.verifyTrue(rowHasValue(data, 'Issues', '1'), ...
                'Nerve-response summary should include the missing-RHS issue.');
            testCase.verifyTrue(any(contains(string(driver.textAreaValue('details')), ...
                'First issue')), ...
                'Nerve-response details should show the first analysis issue.');
            testCase.verifyGreaterThan(driver.previewChildCount('preview'), 0, ...
                'Nerve-response workflow should redraw the analysis preview.');
            testCase.verifyTrue(driver.enabled('exportAnalysis'), ...
                'Nerve-response export should enable after analysis with a default output folder.');

            driver.click('Export Analysis');
            outputPath = fullfile(folder, 'nerve_response_analysis', ...
                'nerve_response_analysis.json');
            testCase.verifyTrue(exist(outputPath, 'file') == 2, ...
                'Nerve-response workflow should export the analysis JSON.');
            manifestPath = fullfile(folder, 'nerve_response_analysis', ...
                'nerve_response_analysis.labkit.json');
            testCase.verifyTrue(exist(manifestPath, 'file') == 2, ...
                'Nerve-response export should include a standard result manifest.');

            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyFalse(isfield( ...
                runtime.state.project.results.lastExport, 'analysis'), ...
                'Durable export records must not embed analysis cache data.');
            testCase.verifyNotEmpty(runtime.state.session.cache.analysis, ...
                'Analysis tables should remain in the rebuildable session cache.');
            projectPath = fullfile(folder, 'nerve-response-project.mat');
            labkit.ui.runtime.saveState(fig, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 2);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'cache'));
            driver.click('Reset');
            labkit.ui.runtime.loadState(fig, projectPath);
            h.waitForUiIdle(fig);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyNotEmpty(runtime.state.session.cache.filterRecord, ...
                'Project reopen should rebuild parsed filter-record cache.');
            testCase.verifyEmpty(runtime.state.session.cache.analysis, ...
                'Project reopen should not restore transient analysis tables.');
            driver.click('Analyze Filtered Files');
            ui = driver.registry();
            testCase.verifyTrue(contains(string( ...
                ui.controls.statusField.valueHandle.Value), ...
                'Analyzed 1 recording'));
        end
    end
end

function writeFilterRecordJson(filepath)
    payload = struct();
    payload.recordings = [ ...
        struct('recordingId', 'R001', 'filePath', 'missing_bad.rhs', ...
        'label', 'bad', 'comment', 'manual reject'), ...
        struct('recordingId', 'R002', 'filePath', 'missing_good.rhs', ...
        'label', 'good', 'comment', 'manual keep')];
    fid = fopen(filepath, 'w');
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', jsonencode(payload));
end

function tf = rowHasValue(data, metric, value)
    tf = any(strcmp(string(data(:, 1)), metric) & strcmp(string(data(:, 2)), value));
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
