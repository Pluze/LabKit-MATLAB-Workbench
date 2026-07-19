classdef GuiLayoutNerveResponseAnalysisTest < matlab.unittest.TestCase
    %GUILAYOUTNERVERESPONSEANALYSISTEST Verify nerve-response GUI workflow.

    methods (Test, TestTags = {'GUI', 'Workflow'})
        function nerve_response_analysis_workflow_analyzes_filter_record(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            filterPath = fullfile(folder, 'filter_record.json');
            writeFilterRecordJson(filterPath);

            runtime = nerve_response_analysis.definition().createMatlabRuntime( ...
                [], struct("alert", @(~, ~) []));
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            runtime.applyFileSelection('sessionFile', filterPath, 1);
            testCase.verifyNotEmpty( ...
                runtime.State.session.cache.filterRecord);

            runtime.invokeAction('runAnalysis');
            analysis = runtime.State.session.cache.analysis;
            testCase.verifyEqual(analysis.recordingCount, 2);
            testCase.verifyEqual(analysis.analyzedCount, 1);
            testCase.verifyEqual(height(analysis.issues), 1);
            previewAxes = findall(fig, 'Tag', 'preview');
            testCase.verifyNotEmpty(previewAxes.Children);

            runtime.invokeAction('exportAnalysis');
            outputPath = fullfile(folder, 'nerve_response_analysis.json');
            testCase.verifyTrue(exist(outputPath, 'file') == 2, ...
                'Nerve-response workflow should export the analysis JSON.');
            manifestPath = ...
                runtime.State.project.results.lastExport.manifestPath;
            testCase.verifyTrue(exist(manifestPath, 'file') == 2, ...
                'Nerve-response export should include a standard result manifest.');

            testCase.verifyFalse(isfield( ...
                runtime.State.project.results.lastExport, 'analysis'), ...
                'Durable export records must not embed analysis cache data.');
            projectPath = fullfile(folder, 'nerve-response-project.mat');
            runtime.saveProject(runtime.State, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 2);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'cache'));
            runtime.applyFileSelection( ...
                'sessionFile', strings(1, 0), zeros(1, 0));
            runtime.restoreProject(projectPath);
            testCase.verifyNotEmpty(runtime.State.session.cache.filterRecord, ...
                'Project reopen should rebuild parsed filter-record cache.');
            testCase.verifyEmpty(runtime.State.session.cache.analysis, ...
                'Project reopen should not restore transient analysis tables.');
            runtime.invokeAction('runAnalysis');
            testCase.verifyEqual( ...
                runtime.State.session.cache.analysis.analyzedCount, 1);
            clear runtimeCleanup
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

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
