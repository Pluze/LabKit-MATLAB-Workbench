function sink = createLabKitToolTraceSink(recorder)
%CREATELABKITTOOLTRACESINK Adapt UI interaction trace messages to structured events.
%
% Expected caller: GUI structural and gesture tests that pass an onTrace
% callback into labkit.ui.interaction components. Input is a trace recorder from
% createLabKitTraceRecorder. Output is a callback(message) function handle.
% Side effects: appends sanitized structured events to the recorder.

    sink = @capture;

    function capture(message)
        [component, detailMessage] = splitToolMessage(message);
        [eventName, details] = classifyToolEvent(component, detailMessage);
        recorder.record(component, eventName, "test", details);
    end
end

function [component, detailMessage] = splitToolMessage(message)
    message = string(message);
    parts = split(message, ":");
    if numel(parts) < 2
        component = "tool";
        detailMessage = strtrim(message);
        return;
    end

    rawComponent = strtrim(parts(1));
    detailMessage = strtrim(strjoin(parts(2:end), ":"));
    switch rawComponent
        case "imageAxesRuntime"
            component = "runtime";
        case "anchorCurveEditor"
            component = "anchorEditor";
        case "scaleBarTool"
            component = "scaleBar";
        otherwise
            component = rawComponent;
    end
end

function [eventName, details] = classifyToolEvent(component, message)
    eventName = "trace";
    details = struct("message", message);

    if component == "runtime"
        eventName = classifyRuntimeEvent(message);
    elseif component == "anchorEditor"
        eventName = classifyAnchorEvent(message);
    elseif component == "scaleBar"
        eventName = classifyScaleBarEvent(message);
    end
end

function eventName = classifyRuntimeEvent(message)
    if startsWith(message, "activate session")
        eventName = "session.activate";
    elseif startsWith(message, "deactivate session")
        eventName = "session.deactivate";
    elseif startsWith(message, "deactivate peer")
        eventName = "session.peerDeactivate";
    elseif startsWith(message, "capture drag")
        eventName = "drag.capture";
    elseif startsWith(message, "release drag")
        eventName = "drag.release";
    elseif startsWith(message, "drag motion error")
        eventName = "drag.motionError";
    elseif startsWith(message, "drag release error")
        eventName = "drag.releaseError";
    elseif startsWith(message, "installed session scroll")
        eventName = "scroll.install";
    elseif contains(message, "default scroll")
        eventName = "scroll.default";
    elseif startsWith(message, "delete runtime")
        eventName = "runtime.delete";
    else
        eventName = "trace";
    end
end

function eventName = classifyAnchorEvent(message)
    if startsWith(message, "start")
        eventName = "edit.start";
    elseif startsWith(message, "setActive")
        eventName = "active.set";
    elseif startsWith(message, "insertPoint")
        eventName = "anchor.insert";
    elseif startsWith(message, "undoLast")
        eventName = "anchor.undo";
    elseif startsWith(message, "clearPoints")
        eventName = "anchor.clear";
    elseif startsWith(message, "notifyChanged")
        eventName = "changed";
    elseif startsWith(message, "onAnchorDragged")
        eventName = "drag.update";
    elseif startsWith(message, "onAnchorReleased")
        eventName = "drag.release";
    elseif startsWith(message, "setStyle skipped unchanged")
        eventName = "style.noop";
    else
        eventName = "trace";
    end
end

function eventName = classifyScaleBarEvent(message)
    if startsWith(message, "Measure reference button starting edit")
        eventName = "referenceEdit.start";
    elseif startsWith(message, "Measure reference button finishing active edit")
        eventName = "referenceEdit.finish";
    elseif startsWith(message, "setEnabled")
        eventName = "enabled.set";
    elseif startsWith(message, "setReferencePixels")
        eventName = "referencePixels.set";
    elseif startsWith(message, "panel scale-bar settings changed")
        eventName = "settings.change";
    elseif startsWith(message, "Place scale bar complete")
        eventName = "scaleBar.place";
    else
        eventName = "trace";
    end
end
