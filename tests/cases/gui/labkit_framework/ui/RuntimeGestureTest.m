classdef RuntimeGestureTest < matlab.unittest.TestCase
    %RUNTIMEGESTURETEST Gesture-level checks for image axes runtime ownership.

    methods (Test, TestTags = {'GUI', 'Gesture'})
        function sessionsRestoreCallbacksAndEmitTrace(testCase)
            setupLabKitTestPath();
            h = guiTestHelpers();
            h.assertUifigureAvailable();
            cleanup = onCleanup(@() h.closeAllFigures());

            fig = uifigure('Visible', 'off', 'Name', 'labkit_runtime_gesture_probe');
            cleaner = onCleanup(@() delete(fig));
            ax = uiaxes(fig);
            bg = image(ax, zeros(30, 40, 3, 'uint8'));
            axis(ax, 'image');

            recorder = createLabKitTraceRecorder( ...
                "AppName", "labkit_ui", ...
                "TestName", "RuntimeGestureTest", ...
                "RunId", "phase7-runtime-gesture");
            traceSink = createLabKitToolTraceSink(recorder);

            interactionStates = strings(0, 1);
            defaultScrollCalls = 0;
            runtime = labkit.ui.interaction.runtime(ax, struct( ...
                'figure', fig, ...
                'defaultScrollFcn', @onDefaultScroll, ...
                'scrollScope', 'figure', ...
                'onTrace', traceSink, ...
                'onInteractionChanged', @onInteractionChanged));
            assert(~isempty(fig.WindowScrollWheelFcn), ...
                'Runtime should install a managed app default scroll callback.');
            fig.WindowScrollWheelFcn(fig, struct());
            assert(defaultScrollCalls == 1, ...
                'Runtime default scroll wrapper should call the app callback.');

            sessionA = runtime.createSession(struct( ...
                'name', 'firstGesture', ...
                'onPointerDown', @(~,~) setappdata(fig, 'firstPointer', true), ...
                'onScroll', @(~,~) setappdata(fig, 'firstScroll', true), ...
                'scrollScope', 'figure'));
            sessionA.setBackground(bg);
            sessionA.activate();
            assert(sessionA.isActive() && runtime.isInteractionActive(), ...
                'First session should become active.');
            assert(~isempty(ax.ButtonDownFcn) && strcmp(bg.HitTest, 'on'), ...
                'Active session should own axes/background pointer callbacks.');

            sessionB = runtime.createSession(struct( ...
                'name', 'secondGesture', ...
                'onPointerDown', @(~,~) setappdata(fig, 'secondPointer', true), ...
                'onScroll', @(~,~) setappdata(fig, 'secondScroll', true), ...
                'scrollScope', 'figure'));
            sessionB.activate();
            assert(~sessionA.isActive() && sessionB.isActive(), ...
                'Activating a second session should deactivate the first session.');
            assert(strcmp(bg.HitTest, 'off') && strcmp(bg.PickableParts, 'none'), ...
                'Peer deactivation should release the first session background hit testing.');

            dragMotionCalls = 0;
            dragReleaseCalls = 0;
            releaseSawCallbacksCleared = false;
            sessionB.captureDrag(@onDragMotion, @onDragRelease);
            assert(~isempty(fig.WindowButtonMotionFcn) && ~isempty(fig.WindowButtonUpFcn), ...
                'Drag capture should install temporary figure callbacks.');
            staleMotionFcn = fig.WindowButtonMotionFcn;
            releaseFcn = fig.WindowButtonUpFcn;
            staleMotionFcn(fig, struct());
            releaseFcn(fig, struct());
            staleMotionFcn(fig, struct());
            assert(dragMotionCalls == 1 && dragReleaseCalls == 1, ...
                'Stale queued drag motion should not run after release.');
            assert(releaseSawCallbacksCleared, ...
                'Drag release should clear temporary figure callbacks before release work runs.');
            assert(isempty(fig.WindowButtonMotionFcn) && isempty(fig.WindowButtonUpFcn), ...
                'Normal drag release should clear temporary figure callbacks.');

            sessionB.captureDrag(@onDragError, []);
            didThrow = false;
            try
                fig.WindowButtonMotionFcn(fig, struct());
            catch ME
                didThrow = strcmp(ME.identifier, 'labkit:Test:DragFailure');
            end
            assert(didThrow, 'Runtime should rethrow drag callback errors.');
            assert(isempty(fig.WindowButtonMotionFcn) && isempty(fig.WindowButtonUpFcn), ...
                'Drag callback errors should still clear temporary figure callbacks.');

            sessionB.deactivate();
            assert(~runtime.isInteractionActive(), ...
                'Runtime should report no active interaction after deactivation.');
            assert(~isempty(fig.WindowScrollWheelFcn), ...
                'Session deactivation should restore the managed runtime default scroll callback.');
            runtime.delete();
            assert(isempty(ax.ButtonDownFcn) && isempty(fig.WindowScrollWheelFcn), ...
                'Runtime deletion should restore pre-runtime axes and figure callbacks.');

            events = recorder.events();
            assertHasEvent(events, "runtime", "session.activate");
            assertHasEvent(events, "runtime", "session.peerDeactivate");
            assertHasEvent(events, "runtime", "drag.capture");
            assertHasEvent(events, "runtime", "drag.release");
            assertHasEvent(events, "runtime", "drag.motionError");
            assert(any(contains(interactionStates, "true:secondGesture")), ...
                'Runtime should report active interaction state for the second session.');
            writeGestureArtifacts(recorder, fig, "runtime_gesture");

            function onInteractionChanged(active, name)
                interactionStates(end+1, 1) = string(logical(active)) + ":" + string(name);
            end

            function onDefaultScroll(~, ~)
                defaultScrollCalls = defaultScrollCalls + 1;
            end

            function onDragMotion(~, ~)
                dragMotionCalls = dragMotionCalls + 1;
            end

            function onDragRelease(~, ~)
                releaseSawCallbacksCleared = isempty(fig.WindowButtonMotionFcn) && ...
                    isempty(fig.WindowButtonUpFcn);
                dragReleaseCalls = dragReleaseCalls + 1;
            end

            function onDragError(~, ~)
                error('labkit:Test:DragFailure', 'Synthetic drag failure.');
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
