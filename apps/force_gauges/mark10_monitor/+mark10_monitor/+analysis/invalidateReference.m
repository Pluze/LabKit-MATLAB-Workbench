function applicationState = invalidateReference(applicationState, context, ~)
%INVALIDATEREFERENCE Retire a contact estimate when its inputs change.
a = applicationState.session.analysis;
a.estimate = [];
a.lengthEstimateStatus = "Reference settings changed; estimate again or enter and confirm measured length.";
a.geometryConfirmed = false;
applicationState.session.analysis = a;
applicationState = mark10_monitor.analysis.invalidate(applicationState, context, []);
end
