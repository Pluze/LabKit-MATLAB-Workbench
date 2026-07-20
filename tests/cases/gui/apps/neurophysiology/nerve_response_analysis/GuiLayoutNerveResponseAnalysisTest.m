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
            protocolPath = fullfile(folder, "protocol.json");
            writeProtocolJson(protocolPath);
            alternateFolder = fullfile(folder, "alternate");
            mkdir(alternateFolder);

            runtime = labkit.app.internal.RuntimeFactory.createMatlab( ...
                nerve_response_analysis.definition(), [], struct( ...
                    "alert", @(~, ~) [], ...
                    "chooseOutputFolder", @(~) ...
                        labkit.app.dialog.Choice(alternateFolder)));
            runtimeCleanup = onCleanup(@() runtime.close());
            fig = runtime.figureHandle();
            ids = ["sessionFile", "protocolFile", "maxRecordings", ...
                "maxDurationSec", "statusField", "runAnalysis", ...
                "resetWorkflow", "summaryTable", "details", ...
                "outputFolder", "chooseOutputFolder", ...
                "clearOutputFolder", "exportAnalysis", "logPanel", ...
                "preview"];
            for id = ids
                testCase.verifyEqual(numel(findall(fig, "Tag", id)), 1);
            end
            runtime.applyFileSelection('sessionFile', filterPath, 1);
            testCase.verifyNotEmpty( ...
                runtime.State.session.cache.filterRecord);
            defaultOutputFolder = fullfile( ...
                folder, "nerve_response_analysis");
            testCase.verifyEqual( ...
                runtime.State.session.workflow.outputFolder, ...
                string(defaultOutputFolder));
            runtime.applyFileSelection("protocolFile", protocolPath, 1);
            testCase.verifyEqual( ...
                runtime.State.session.cache.protocolPath, ...
                string(protocolPath));

            runtime.invokeAction('runAnalysis');
            analysis = runtime.State.session.cache.analysis;
            testCase.verifyEqual(analysis.recordingCount, 2);
            testCase.verifyEqual(analysis.analyzedCount, 1);
            testCase.verifyEqual(height(analysis.issues), 1);
            previewAxes = findall(fig, 'Tag', 'preview');
            testCase.verifyNotEmpty(previewAxes.Children);
            runtime.applyControlValue("preview", "Issues");
            testCase.verifyEqual( ...
                runtime.State.session.view.previewMode, "Issues");
            testCase.verifyNotEmpty(previewAxes.Children);

            runtime.invokeAction('exportAnalysis');
            outputPath = fullfile( ...
                defaultOutputFolder, 'nerve_response_analysis.json');
            testCase.verifyTrue(exist(outputPath, 'file') == 2, ...
                'Nerve-response workflow should export the analysis JSON.');
            manifestPath = ...
                runtime.State.project.results.lastExport.manifestPath;
            testCase.verifyEqual(string(manifestPath), string(fullfile( ...
                defaultOutputFolder, ...
                "nerve_response_analysis.labkit.json")));
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
            runtime.invokeAction("clearOutputFolder");
            testCase.verifyEqual( ...
                runtime.State.session.workflow.outputFolder, "");
            runtime.invokeAction("chooseOutputFolder");
            testCase.verifyEqual( ...
                runtime.State.session.workflow.outputFolder, ...
                string(alternateFolder));
            runtime.invokeAction("resetWorkflow");
            testCase.verifyEmpty(runtime.State.project.inputs.sources);
            testCase.verifyEmpty(runtime.State.session.cache.filterRecord);
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

function writeProtocolJson(filepath)
    fid = fopen(filepath, 'w');
    cleaner = onCleanup(@() fclose(fid));
    fprintf(fid, '%s', jsonencode(struct()));
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
