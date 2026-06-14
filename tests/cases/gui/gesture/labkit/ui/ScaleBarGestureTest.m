classdef ScaleBarGestureTest < matlab.uitest.TestCase
    %SCALEBARGESTURETEST Gesture-level scale-bar lifecycle coverage.

    methods (Test, TestTags = {'GUI', 'Gesture'})
        function referenceEditAndPlacementEmitStructuredTrace(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = uifigure('Visible', 'off', 'Name', 'labkit_scale_bar_gesture_probe');
            cleaner = onCleanup(@() delete(fig));
            grid = uigridlayout(fig, [2 1]);
            ax = uiaxes(grid);
            ax.Layout.Row = 1;
            bg = imagesc(ax, rand(80, 120));
            axis(ax, 'image');

            recorder = createLabKitTraceRecorder( ...
                "AppName", "labkit_ui", ...
                "TestName", "ScaleBarGestureTest", ...
                "RunId", "phase7-scale-bar-gesture");
            traceSink = createLabKitToolTraceSink(recorder);
            runtime = labkit.ui.tool.createRuntime(ax, struct( ...
                'figure', fig, ...
                'onTrace', traceSink));

            callbacks = struct('edit', 0, 'calibration', 0, 'bar', 0, 'placed', 0);
            tool = labkit.ui.tool.scaleBar(grid, 2, runtime, ...
                struct('onTrace', traceSink, ...
                'onReferenceEditChanged', @onReferenceEditChanged, ...
                'onCalibrationChanged', @onCalibrationChanged, ...
                'onScaleBarChanged', @onScaleBarChanged, ...
                'onScaleBarPlaced', @onScaleBarPlaced));
            tool.setImageSize([80 120 1]);
            tool.setBackground(bg);

            tool.setEnabled(struct('hasImage', false));
            assert(strcmp(tool.controls.measureReferenceButton.Enable, 'off'), ...
                'Scale-bar reference editing should be disabled without an image.');
            tool.setEnabled(struct('hasImage', true));
            tool.setEnabled(struct('hasImage', true));
            assert(strcmp(tool.controls.measureReferenceButton.Enable, 'on'), ...
                'Repeated enable should leave reference editing available.');

            tool.setReferencePixels(40);
            tool.setReferencePixels(40);
            tool.controls.referenceLengthSpinner.Value = 10;
            tool.controls.unitDropdown.Value = 'mm';
            h.invokeCallback(tool.controls.unitDropdown, 'ValueChangedFcn');
            cal = tool.calibration();
            assert(cal.isCalibrated && cal.pixelsPerUnit == 4, ...
                'Repeated same-value reference pixels should leave calibration stable.');

            h.invokeCallback(tool.controls.measureReferenceButton, 'ButtonPushedFcn');
            assert(tool.isReferenceEditActive() && strcmp(tool.controls.measureReferenceButton.Text, ...
                'Finish reference edit'), ...
                'Measure reference should start reference edit mode.');
            h.invokeCallback(tool.controls.measureReferenceButton, 'ButtonPushedFcn');
            assert(~tool.isReferenceEditActive() && strcmp(tool.controls.measureReferenceButton.Text, ...
                'Measure reference pixels'), ...
                'Second measure reference click should finish reference edit mode.');

            tool.controls.barLengthSpinner.Value = 5;
            h.invokeCallback(tool.controls.barLengthSpinner, 'ValueChangedFcn');
            h.invokeCallback(tool.controls.placeButton, 'ButtonPushedFcn');
            assert(tool.hasScaleBar() && callbacks.placed == 1 && callbacks.bar >= 1, ...
                'Place scale bar should store a bar and emit app-facing callbacks.');
            handles = tool.renderOverlay(ax);
            assert(isstruct(handles) && isvalid(handles.line) && isvalid(handles.label), ...
                'Placed scale bar should render overlay handles.');
            tool.delete();

            events = recorder.events();
            assertHasEvent(events, "scaleBar", "enabled.set");
            assertHasEvent(events, "scaleBar", "referencePixels.set");
            assertHasEvent(events, "scaleBar", "referenceEdit.start");
            assertHasEvent(events, "scaleBar", "referenceEdit.finish");
            assertHasEvent(events, "scaleBar", "scaleBar.place");
            assertHasEvent(events, "runtime", "session.activate");
            assertHasEvent(events, "runtime", "session.deactivate");
            assert(callbacks.edit >= 2 && callbacks.calibration >= 1, ...
                'Scale-bar lifecycle should emit reference edit and calibration callbacks.');
            writeGestureArtifacts(recorder, fig, "scale_bar_gesture");

            function onReferenceEditChanged(~, ~)
                callbacks.edit = callbacks.edit + 1;
            end

            function onCalibrationChanged(~, ~)
                callbacks.calibration = callbacks.calibration + 1;
            end

            function onScaleBarChanged(~, ~)
                callbacks.bar = callbacks.bar + 1;
            end

            function onScaleBarPlaced(~, ~)
                callbacks.placed = callbacks.placed + 1;
            end
        end
    end
end

function assertHasEvent(events, component, eventName)
    assert(any(string({events.component}) == component & string({events.event}) == eventName), ...
        'Missing structured event %s/%s.', component, eventName);
end

function writeGestureArtifacts(recorder, fig, name)
    paths = labkitArtifactPaths("Create", true);
    recorder.writeJsonl(fullfile(paths.guiTrace, name + ".jsonl"));
    recorder.writeText(fullfile(paths.guiTrace, name + ".txt"));
    writeLabKitJsonlArtifact(fullfile(paths.guiSnapshots, name + "_components.jsonl"), ...
        snapshotLabKitComponents(fig));
end
