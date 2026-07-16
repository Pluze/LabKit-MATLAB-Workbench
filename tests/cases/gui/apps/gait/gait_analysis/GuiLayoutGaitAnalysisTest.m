classdef GuiLayoutGaitAnalysisTest < matlab.unittest.TestCase
    %GUILAYOUTGAITANALYSISTEST Verify Gait Analysis GUI launch and layout contract.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function gait_analysis_launches_with_expected_controls(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            [fig, debug] = labkit_GaitAnalysis_app("debug");
            drawnow;

            h.assertStandardWorkbenchLayout(fig);
            h.assertButtonContract(fig, {'Open pose file', 'Run analysis', ...
                'Choose output folder', 'Export CSV set'});
            h.assertTabTitles(fig, {'Source', 'Roles + Detection', ...
                'Results + Export', 'Log'});
            h.assertDropdownGroups(fig, h.dropdownGroup({'Trajectory', 'Angles', 'Steps'}, 1));
            testCase.verifyTrue(debug.enabled && debug.traceEnabled);
            assertAnyTextAreaContains(h, fig, 'Debug sample generation enabled', ...
                'Runtime debug-sample lifecycle should be mirrored into the Log tab.');

            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(runtime.definition.contractVersion, 2, ...
                'Gait Analysis must execute through Runtime V2.');
            driver = labkitWorkflowDriver(fig);
            pack = gait_analysis.debug.writeSamplePack(debug);
            driver.chooseFiles('poseFile', pack.representativeFiles);
            driver.click('Open pose file');
            testCase.verifyTrue(driver.enabled('runAnalysis'));
            testCase.verifyGreaterThan(driver.previewChildCount('gaitAxes'), 0);
            driver.click('Run analysis');
            testCase.verifyTrue(driver.enabled('exportResults'));
            testCase.verifyGreaterThan(height( ...
                getappdata(fig, 'labkitUiAppRuntime').state.project.results.analysis.frameTable), 0);
            driver.dropdown('Angles');
            testCase.verifyGreaterThan(driver.previewChildCount('gaitAxes'), 0);

            outputFolder = string(tempname);
            mkdir(outputFolder);
            outputCleanup = onCleanup(@() removeTempFolder(outputFolder));
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            runtime.request.outputFolderChooser = @(~, ~) char(outputFolder);
            setappdata(fig, 'labkitUiAppRuntime', runtime);
            driver.click('Choose output folder');
            driver.click('Export CSV set');
            expected = ["synthetic_gait_pose_frames.csv", ...
                "synthetic_gait_pose_coordinates.csv", ...
                "synthetic_gait_pose_steps.csv", ...
                "synthetic_gait_pose_summary.csv", ...
                "synthetic_gait_pose_gait.labkit.json"];
            for filepath = fullfile(outputFolder, expected)
                testCase.verifyTrue(isfile(filepath), ...
                    "Missing gait output: " + filepath);
            end

            projectPath = fullfile(outputFolder, 'gait-project.mat');
            labkit.ui.runtime.saveState(fig, projectPath);
            saved = load(projectPath, 'labkitProject');
            testCase.verifyEqual(saved.labkitProject.app.payloadVersion, 1);
            testCase.verifyFalse(isfield(saved.labkitProject.payload, 'pose'));
            labkit.ui.runtime.loadState(fig, projectPath);
            h.waitForUiIdle(fig);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyTrue(runtime.state.session.cache.pose.ok, ...
                'Project reopen should rebuild decoded pose cache.');
            testCase.verifyTrue(runtime.state.project.results.analysis.ok, ...
                'Project reopen should retain durable gait results.');
            clear outputCleanup;
        end
    end
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
