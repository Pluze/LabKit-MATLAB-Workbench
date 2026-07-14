classdef GuiLayoutVideoMarkerTest < matlab.unittest.TestCase
    %GUILAYOUTVIDEOMARKERTEST Verify Video Marker GUI launch and layout contract.

    methods (Test, TestTags = {'GUI', 'Structural'})
        function video_marker_launches_with_expected_controls(testCase)
            setupLabKitTestPath();
            autosaveCleanup = isolateAutosave();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            [fig, debug] = labkit_VideoMarker_app("debug");
            drawnow;

            h.assertStandardWorkbenchLayout(fig);
            h.assertButtonContract(fig, {'Open video', 'Previous frame', ...
                'Next frame', 'Undo last point', 'Clear frame points', ...
                'Interpolate frame', 'Track from previous', ...
                'Add keypoint', 'Remove keypoint', 'Move up', 'Move down', ...
                'Use preset', 'Add connection', 'Connect in order', ...
                'Remove connection', 'Open project', ...
                'Save project', 'New setup (clear current)', 'Measure reference pixels', ...
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
            testCase.verifyTrue(debug.enabled && debug.traceEnabled);
            assertAnyTextAreaContains(h, fig, 'Video marker debug trace enabled', ...
                'Debug trace should be mirrored into the visible Log tab.');
        end


        function skeleton_setup_and_frame_change_use_continuous_marking(testCase)
            setupLabKitTestPath();
            autosaveCleanup = isolateAutosave();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());
            [fig, debug] = labkit_VideoMarker_app("debug");
            drawnow;
            h.assertStandardWorkbenchLayout(fig);

            ui = getappdata(fig, 'labkitUiRegistry');
            invoke(ui.controls.useSkeletonPreset.button);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(runtime.state.skeleton.pointNames, ...
                ["iliac"; "hip"; "knee"; "ankle"; "foot"]);
            invoke(ui.controls.newSetup.button);
            ui = getappdata(fig, 'labkitUiRegistry');
            invoke(ui.controls.addKeypoint.button);
            invoke(ui.controls.addKeypoint.button);
            ui = getappdata(fig, 'labkitUiRegistry');
            editName(ui.controls.keypointTable.table, 1, 'hip');
            editName(ui.controls.keypointTable.table, 2, 'knee');
            ui = getappdata(fig, 'labkitUiRegistry');
            labkit.ui.control.setValue(ui, 'connectionFrom', 'hip');
            ui.controls.connectionFrom.valueHandle.ValueChangedFcn( ...
                ui.controls.connectionFrom.valueHandle, struct());
            ui = getappdata(fig, 'labkitUiRegistry');
            testCase.verifyFalse(any(string(ui.controls.connectionTo.valueHandle.Items) == "hip"));
            labkit.ui.control.setValue(ui, 'connectionTo', 'knee');
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
            testCase.verifyEqual(runtime.state.currentFrame, 2);
            testCase.verifyEqual(string(ui.controls.trackFromPrevious.button.Enable), "on");
            testCase.verifyEqual(runtime.state.skeleton.pointNames, ["hip"; "knee"]);
            testCase.verifyEqual(runtime.state.skeleton.edges, [1 2]);
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints( ...
                runtime.state.annotations, 2), [20 30; 40 50]);
            testCase.verifyEqual(video_marker.frameAnnotations.statusName( ...
                runtime.state.annotations.frameStatus(1)), "confirmed");
            testCase.verifyEqual(video_marker.frameAnnotations.statusName( ...
                runtime.state.annotations.frameStatus(2)), "draft");
        end


        function matching_autosave_can_restore_when_video_opens(testCase)
            setupLabKitTestPath();
            autosaveCleanup = isolateAutosave();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());
            [fig, debug] = labkit_VideoMarker_app("debug");
            drawnow;
            ui = getappdata(fig, 'labkitUiRegistry');
            invoke(ui.controls.useSkeletonPreset.button);

            pack = video_marker.debug.writeSamplePack(debug);
            videoPath = pack.representativeFiles(1);
            [~, info] = video_marker.videoSource.openVideo(videoPath);
            saved = video_marker.appLifecycle.createInitialState();
            saved.videoPath = videoPath;
            saved.videoInfo = info;
            presets = video_marker.userInterface.skeletonPresets();
            saved.skeleton = video_marker.skeletonDefinition.fromParts( ...
                presets(1).pointNames, presets(1).edges);
            saved.annotations = video_marker.frameAnnotations.emptyAnnotations( ...
                info.frameCount, 5);
            expected = [10 20; 20 25; 30 30; 40 35; 50 40];
            saved.annotations = video_marker.frameAnnotations.setFramePoints( ...
                saved.annotations, 1, expected, "confirmed");
            video_marker.autosave.write(videoPath, saved);
            setappdata(fig, 'labkitUiConfirmFcn', ...
                @(~, ~, ~, confirmText, ~) confirmText);

            ui = getappdata(fig, 'labkitUiRegistry');
            ui.controls.videoFile.choosePaths = @(varargin) cellstr(videoPath);
            setappdata(fig, 'labkitUiRegistry', ui);
            invoke(ui.controls.videoFile.chooseButton);
            runtime = getappdata(fig, 'labkitUiAppRuntime');
            testCase.verifyEqual(video_marker.frameAnnotations.framePoints( ...
                runtime.state.annotations, 1), expected);
            testCase.verifyTrue(isappdata(fig, 'labkitUiConfirmations'));
        end
    end
end

function invoke(button)
    button.ButtonPushedFcn(button, struct());
end

function editName(tableHandle, row, value)
    previous = tableHandle.Data{row, 2};
    tableHandle.Data{row, 2} = value;
    tableHandle.CellEditCallback(tableHandle, struct( ...
        'Indices', [row 2], 'PreviousData', previous, ...
        'NewData', value, 'EditData', value));
end

function cleanup = isolateAutosave()
    previous = string(getenv('LABKIT_VIDEO_MARKER_AUTOSAVE_ROOT'));
    folder = string(tempname);
    mkdir(folder);
    setenv('LABKIT_VIDEO_MARKER_AUTOSAVE_ROOT', folder);
    cleanup = onCleanup(@() restoreAutosaveRoot(previous, folder));
end

function restoreAutosaveRoot(previous, folder)
    setenv('LABKIT_VIDEO_MARKER_AUTOSAVE_ROOT', previous);
    if exist(folder, 'dir') == 7
        rmdir(folder, 's');
    end
end
