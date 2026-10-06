function session = applyPreviewContext(session, context)
%APPLYPREVIEWCONTEXT Commit preview calculation outputs to transient session.
session.view.windowStartSec = context.windowStartSec;
session.view.windowDurationSec = context.windowDurationSec;
session.view.roiSec = context.roiSec;
session.cache.preview = context.preview;
session.workflow.statusMessage = context.statusMessage;
session.workflow.lastAction = context.lastAction;
end
