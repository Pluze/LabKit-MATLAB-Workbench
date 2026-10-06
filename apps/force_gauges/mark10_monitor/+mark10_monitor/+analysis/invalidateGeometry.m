function applicationState = invalidateGeometry(applicationState, context, ~)
%INVALIDATEGEOMETRY Require review after changing dimensions.
applicationState.session.analysis.geometryConfirmed = false;
applicationState = mark10_monitor.analysis.invalidate(applicationState, context, []);
end
