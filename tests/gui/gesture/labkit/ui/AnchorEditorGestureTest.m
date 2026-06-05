classdef AnchorEditorGestureTest < matlab.uitest.TestCase
    %ANCHOREDITORGESTURETEST Gesture-level anchor editor operation coverage.

    methods (Test, TestTags = {'GUI', 'Gesture'})
        function anchorOperationsEmitStructuredTrace(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures()); %#ok<NASGU>

            fig = uifigure('Visible', 'off', 'Name', 'labkit_anchor_gesture_probe');
            cleaner = onCleanup(@() delete(fig)); %#ok<NASGU>
            ax = uiaxes(fig);
            image(ax, zeros(50, 70, 3, 'uint8'));
            axis(ax, 'image');

            recorder = createLabKitTraceRecorder( ...
                "AppName", "labkit_ui", ...
                "TestName", "AnchorEditorGestureTest", ...
                "RunId", "phase7-anchor-gesture");
            traceSink = createLabKitToolTraceSink(recorder);
            runtime = labkit.ui.tool.createRuntime(ax, struct( ...
                'figure', fig, ...
                'onTrace', traceSink));

            changedReasons = strings(0, 1);
            editor = labkit.ui.tool.anchorEditor(runtime, [50 70 3], ...
                struct('closed', false, ...
                'style', 'Straight lines', ...
                'onTrace', traceSink, ...
                'onChanged', @onChanged));
            editor.start([8 8; 24 18]);
            startedPoints = editor.getPoints();
            assert(startedPoints(1, 1) == 8 && startedPoints(2, 1) == 24, ...
                'Anchor editor should start with the provided points.');

            editor.insertPoint([36 18]);
            points = editor.getPoints();
            assert(isequal(size(points), [3 2]), ...
                'Anchor insert operation should add a point.');

            editor.undoLast();
            assert(isequal(size(editor.getPoints()), [2 2]), ...
                'Anchor undo operation should remove the last point.');

            editor.setStyle('Curve');
            editor.setStyle('Curve');
            editor.clearPoints();
            assert(isempty(editor.getPoints()), ...
                'Anchor clear operation should remove all points.');
            editor.delete();

            events = recorder.events();
            assertHasEvent(events, "anchorEditor", "edit.start");
            assertHasEvent(events, "anchorEditor", "anchor.insert");
            assertHasEvent(events, "anchorEditor", "anchor.undo");
            assertHasEvent(events, "anchorEditor", "anchor.clear");
            assertHasEvent(events, "anchorEditor", "style.noop");
            assertHasEvent(events, "runtime", "session.activate");
            assertHasEvent(events, "runtime", "session.deactivate");
            assert(any(changedReasons == "add point") && any(changedReasons == "undo point") && ...
                any(changedReasons == "clear points"), ...
                'Anchor editor should emit semantic change reasons for add, undo, and clear operations.');
            writeGestureArtifacts(recorder, fig, "anchor_editor_gesture");

            function onChanged(~, reason)
                changedReasons(end+1, 1) = string(reason); %#ok<AGROW>
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
