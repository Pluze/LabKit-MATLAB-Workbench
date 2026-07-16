classdef GuiLayoutVideoMarkerTest < matlab.unittest.TestCase
    %GUILAYOUTVIDEOMARKERTEST Verify Video Marker GUI launch and layout contract.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function video_marker_launches_with_expected_controls(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            [fig, debug] = labkit_VideoMarker_app("debug");
            drawnow;

            h.assertStandardWorkbenchLayout(fig);
            sessionChoices = video_marker.userInterface.sessionChoices();
            h.assertButtonContract(fig, {'Open video', 'Previous frame', ...
                'Next frame', 'Undo last point', 'Clear frame points', ...
                'Add keypoint', 'Remove keypoint', 'Move up', 'Move down', ...
                'Use preset', 'Add connection', 'Connect in order', ...
                'Remove connection', char(sessionChoices.openProject), ...
                char(sessionChoices.saveAutosave), ...
                char(sessionChoices.newSetup), ...
                'Measure reference pixels', ...
                'Place scale bar', 'Import marker CSV', 'Export marker CSV', ...
                'Export coordinate CSV'});
            h.assertDropdownGroups(fig, [ ...
                h.dropdownGroup({'Legacy leg (5 points)', 'Three-point chain', ...
                'Five-point chain'}, 1), ...
                h.dropdownGroup({'pixels', 'calibrated_physical'}, 1), ...
                h.dropdownGroup({'top_left_pixel_center', 'first_point'}, 1), ...
                h.dropdownGroup({'up', 'down'}, 1), ...
                h.dropdownGroup({'m', 'cm', 'mm', 'um', 'nm'}, 1), ...
                h.dropdownGroup({'Bottom center', 'Bottom left', 'Bottom right', ...
                'Top center', 'Top left', 'Top right'}, 1), ...
                h.dropdownGroup({'Black', 'White'}, 1)]);
            h.assertTabTitles(fig, {'Setup + Scale', 'Video', 'Import + Export', 'Log'});
            testCase.verifyEmpty(findall(fig, 'Type', 'uibutton', 'Text', 'Start point edit'));
            testCase.verifyEmpty(findall(fig, 'Type', 'uibutton', 'Text', 'Confirm frame'));
            testCase.verifyEmpty(findall(fig, 'Type', 'uibutton', 'Text', 'Interpolate frame'));
            testCase.verifyEmpty(findall(fig, 'Type', 'uibutton', 'Text', 'Track from previous'));
            testCase.verifyTrue(debug.enabled && debug.traceEnabled);
            assertAnyTextAreaContains(h, fig, 'Debug sample generation enabled', ...
                'Debug trace should be mirrored into the visible Log tab.');
        end


        function skeleton_setup_and_frame_change_use_continuous_marking(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());
            [fig, debug] = labkit_VideoMarker_app("debug");
            drawnow;
            h.assertStandardWorkbenchLayout(fig);

            ui = getappdata(fig, 'labkitUiRegistry');
            invoke(ui.controls.useSkeletonPreset.button);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(runtime.state.project.annotations.skeleton.pointNames, ...
                ["iliac"; "hip"; "knee"; "ankle"; "foot"]);
            setChoiceAnswer(fig, ...
                video_marker.userInterface.sessionChoices().discardAndStart);
            invoke(ui.controls.newSetup.button);
            ui = getappdata(fig, 'labkitUiRegistry');
            invoke(ui.controls.addKeypoint.button);
            invoke(ui.controls.addKeypoint.button);
            ui = getappdata(fig, 'labkitUiRegistry');
            editName(ui.controls.keypointTable.table, 1, 'hip');
            editName(ui.controls.keypointTable.table, 2, 'knee');
            ui = getappdata(fig, 'labkitUiRegistry');
            testui.control.setValue(ui, 'connectionFrom', 'hip');
            ui.controls.connectionFrom.valueHandle.ValueChangedFcn( ...
                ui.controls.connectionFrom.valueHandle, struct());
            ui = getappdata(fig, 'labkitUiRegistry');
            testCase.verifyFalse(any(string(ui.controls.connectionTo.valueHandle.Items) == "hip"));
            testui.control.setValue(ui, 'connectionTo', 'knee');
            invoke(ui.controls.connectInOrder.button);

            pack = video_marker.debug.writeSamplePack(debug);
            ui = getappdata(fig, 'labkitUiRegistry');
            ui.controls.videoFile.choosePaths = @(varargin) cellstr(pack.representativeFiles);
            setappdata(fig, 'labkitUiRegistry', ui);
            invoke(ui.controls.videoFile.chooseButton);
            drawnow;

            ui = getappdata(fig, 'labkitUiRegistry');
            registered = getappdata(ui.controls.videoAxes.primaryAxes, ...
                'labkit_ui_activeAnchorEditor');
            ax = ui.controls.videoAxes.primaryAxes;
            testCase.verifyTrue(contains(string(ax.Subtitle.String), ...
                'Click blank image space to add points'), ...
                'Video Marker should show its point-mode gestures on the preview.');
            xlim(ax, [10 70]);
            ylim(ax, [10 60]);
            scrollCallback = fig.WindowScrollWheelFcn;
            registered.editor.insertPoint([20 30]);
            testCase.verifyEqual(xlim(ax), [10 70], 'AbsTol', 1e-12);
            testCase.verifyEqual(ylim(ax), [10 60], 'AbsTol', 1e-12);
            testCase.verifyFalse(isempty(fig.WindowScrollWheelFcn));
            testCase.verifyEqual(fig.WindowScrollWheelFcn, scrollCallback);
            stillRegistered = getappdata(ax, 'labkit_ui_activeAnchorEditor');
            testCase.verifyEqual(stillRegistered.token, registered.token);
            registered.editor.insertPoint([40 50]);
            invoke(ui.controls.nextFrame.button);
            testCase.verifyEqual(xlim(ax), [10 70], 'AbsTol', 1e-12);
            testCase.verifyEqual(ylim(ax), [10 60], 'AbsTol', 1e-12);

            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(runtime.state.session.selection.currentFrame, 2);
            testCase.verifyEqual( ...
                runtime.state.project.annotations.skeleton.pointNames, ...
                ["hip"; "knee"]);
            testCase.verifyEqual( ...
                runtime.state.project.annotations.skeleton.edges, [1 2]);
            predicted = video_marker.frameAnnotations.framePoints( ...
                runtime.state.project.annotations.frames, 2);
            testCase.verifySize(predicted, [2 2]);
            testCase.verifyTrue(all(isfinite(predicted), 'all'));
            testCase.verifyEqual(video_marker.frameAnnotations.statusName( ...
                runtime.state.project.annotations.frames.frameStatus(1)), "confirmed");
            testCase.verifyEqual(video_marker.frameAnnotations.statusName( ...
                runtime.state.project.annotations.frames.frameStatus(2)), "draft");
            testCase.verifyEqual(video_marker.frameAnnotations.sourceName( ...
                runtime.state.project.annotations.frames.frameSource(1)), "manual");
            testCase.verifyEqual(video_marker.frameAnnotations.sourceName( ...
                runtime.state.project.annotations.frames.frameSource(2)), "predicted");

            predictedRevision = ...
                runtime.state.project.annotations.frames.anchorRevision(2);
            invoke(ui.controls.previousFrame.button);
            invoke(ui.controls.nextFrame.button);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints( ...
                runtime.state.project.annotations.frames, 2), ...
                predicted, 'AbsTol', 1e-12);
            testCase.verifyEqual( ...
                runtime.state.project.annotations.frames.anchorRevision(2), ...
                predictedRevision);
        end


        function session_actions_confirm_save_discard_and_open_mat(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());
            fig = labkit_VideoMarker_app();
            drawnow;
            ui = getappdata(fig, 'labkitUiRegistry');
            choices = video_marker.userInterface.sessionChoices();
            invoke(ui.controls.useSkeletonPreset.button);

            setChoiceAnswer(fig, choices.cancel);
            invoke(ui.controls.newSetup.button);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(numel( ...
                runtime.state.project.annotations.skeleton.pointIds), 5, ...
                'Cancel should preserve the current Video Marker project.');

            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            runtime.request.recoveryRoot = fullfile(folder, "recovery");
            setappdata(fig, 'labkitUiAppRuntime', runtime);
            invoke(ui.controls.saveAutosave.button);
            recoveryPath = string(getappdata(fig, 'labkitV2RecoveryFile'));
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyTrue(isfile(recoveryPath), ...
                'Save autosave should write a recovery copy immediately.');
            testCase.verifyEqual(string(runtime.document.path), "", ...
                'An autosave must not become the named project file.');
            projectPath = fullfile(folder, "saved-project.mat");
            labkit.ui.runtime.saveState(fig, projectPath);
            setChoiceAnswer(fig, choices.discardAndStart);
            invoke(ui.controls.newSetup.button);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEmpty( ...
                runtime.state.project.annotations.skeleton.pointIds, ...
                'Discard and start new should clear the project.');

            setappdata(fig, 'labkitUiUtilityStateFile', projectPath);
            ui = getappdata(fig, 'labkitUiRegistry');
            invoke(ui.controls.openProject.button);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(numel( ...
                runtime.state.project.annotations.skeleton.pointIds), 5, ...
                'Open MAT should invoke the same framework load-state path.');

            savedBeforeReset = fullfile(folder, "saved-before-reset.mat");
            setChoiceAnswer(fig, choices.saveAndStart);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            runtime.request.projectStateFile = savedBeforeReset;
            setappdata(fig, 'labkitUiAppRuntime', runtime);
            invoke(ui.controls.newSetup.button);
            testCase.verifyTrue(isfile(savedBeforeReset), ...
                'Save and start new should persist the current project first.');
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEmpty( ...
                runtime.state.project.annotations.skeleton.pointIds);
            clear folderCleanup;
        end


        function framework_recovery_restores_annotations_and_current_frame(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());
            [fig, debug] = labkit_VideoMarker_app("debug");
            drawnow;
            ui = getappdata(fig, 'labkitUiRegistry');
            invoke(ui.controls.useSkeletonPreset.button);

            pack = video_marker.debug.writeSamplePack(debug);
            videoPath = pack.representativeFiles(1);
            expected = [10 20; 20 25; 30 30; 40 35; 50 40];
            ui = getappdata(fig, 'labkitUiRegistry');
            ui.controls.videoFile.choosePaths = @(varargin) cellstr(videoPath);
            setappdata(fig, 'labkitUiRegistry', ui);
            invoke(ui.controls.videoFile.chooseButton);
            ui = getappdata(fig, 'labkitUiRegistry');
            registered = getappdata(ui.controls.videoAxes.primaryAxes, ...
                'labkit_ui_activeAnchorEditor');
            for k = 1:size(expected, 1)
                registered.editor.insertPoint(expected(k, :));
            end
            invoke(ui.controls.nextFrame.button);
            projectPath = fullfile(string(tempname), "recovery.mat");
            mkdir(fileparts(projectPath));
            folderCleanup = onCleanup(@() removeTempFolder(fileparts(projectPath)));
            labkit.ui.runtime.saveState(fig, projectPath);
            delete(fig);

            recovered = labkit.ui.runtime.launch(@video_marker.definition, ...
                @video_marker.requirements, @video_marker.version, ...
                "RequestAdapter", @(args) recoveryRequest( ...
                args, debug, projectPath));
            runtime = getappdata(recovered, 'labkitUiAppRuntime');
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints( ...
                runtime.state.project.annotations.frames, 1), expected);
            testCase.verifyEqual( ...
                runtime.state.session.selection.currentFrame, 2);
            testCase.verifyTrue(runtime.document.dirty, ...
                'Recovered documents should reopen as unsaved work.');
            clear folderCleanup
        end

        function legacy_project_loads_read_only_and_saves_current_format(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());
            [fig, debug] = labkit_VideoMarker_app("debug");
            pack = video_marker.debug.writeSamplePack(debug);
            videoPath = pack.representativeFiles(1);
            folder = string(tempname);
            mkdir(folder);
            folderCleanup = onCleanup(@() removeTempFolder(folder));
            legacyPath = fullfile(folder, "legacy_video_marker.mat");

            skeleton = video_marker.skeletonDefinition.fromParts( ...
                ["iliac"; "hip"; "knee"; "ankle"; "foot"], ...
                [1 2; 2 3; 3 4; 4 5]);
            annotations = video_marker.frameAnnotations.emptyAnnotations(6, 5);
            expected = [10 20; 20 25; 30 30; 40 35; 50 40];
            annotations = video_marker.frameAnnotations.setFramePoints( ...
                annotations, 1, expected, "confirmed");
            videoMarkerProject = struct( ...
                "schemaVersion", 1, ...
                "videoPath", videoPath, ...
                "videoReference", ...
                labkit.ui.runtime.createPortableFileReference( ...
                legacyPath, videoPath), ...
                "skeleton", skeleton, ...
                "annotations", annotations, ...
                "calibration", ...
                labkit.ui.interaction.scaleBarCalibration(20, 2, "mm"), ...
                "exportPreferences", struct( ...
                "unitMode", "calibrated_physical", ...
                "originMode", "first_point", ...
                "yAxisMode", "up", ...
                "startFrame", 1, "endFrame", 6), ...
                "currentFrame", 2);
            save(legacyPath, 'videoMarkerProject');

            labkit.ui.runtime.loadState(fig, legacyPath);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints( ...
                runtime.state.project.annotations.frames, 1), expected);
            testCase.verifyEqual( ...
                runtime.state.session.selection.currentFrame, 2);
            testCase.verifyEqual(video_marker.sourceFiles.pathForId( ...
                runtime.state.project.inputs.sources, "video"), videoPath);
            testCase.verifyEqual(string(who('-file', legacyPath)), ...
                "videoMarkerProject");

            currentPath = fullfile(folder, "current_video_marker.mat");
            labkit.ui.runtime.saveState(fig, currentPath);
            testCase.verifyEqual(string(who('-file', currentPath)), ...
                "labkitProject");
            clear folderCleanup
        end
    end
end

function [request, dispatchArgs] = recoveryRequest(~, debug, projectPath)
    request = struct("debug", debug, "recoveryFile", projectPath, ...
        "autosave", false);
    dispatchArgs = {};
end

function invoke(button)
    button.ButtonPushedFcn(button, struct());
end

function setChoiceAnswer(fig, answer)
    runtime = getappdata(fig, 'labkitUiAppRuntime');
    runtime.request.choiceDialog = @(varargin) answer;
    setappdata(fig, 'labkitUiAppRuntime', runtime);
end

function editName(tableHandle, row, value)
    previous = tableHandle.Data{row, 2};
    tableHandle.Data{row, 2} = value;
    tableHandle.CellEditCallback(tableHandle, struct( ...
        'Indices', [row 2], 'PreviousData', previous, ...
        'NewData', value, 'EditData', value));
end

function removeTempFolder(folder)
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
