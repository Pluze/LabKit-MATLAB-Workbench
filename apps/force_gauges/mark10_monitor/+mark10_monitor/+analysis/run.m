function state = run(state, context)
%RUN Calculate per-branch stiffness and Young's modulus estimates.
try
    [time_s, force_N, travel_mm, source] = ...
        mark10_monitor.analysis.sourceData(state, context);
    result = mark10_monitor.analysis.compute(time_s, force_N, travel_mm, ...
        state.session.analysis, state.session.experiment.type);
catch cause
    state.session.analysis.status = string(cause.message);
    context.alert(cause.message, "Modulus Analysis");
    return;
end
state.session.analysis.resultRows = result.rows;
state.session.analysis.plotStrain_percent = result.plotStrain_percent;
state.session.analysis.plotStress_MPa = result.plotStress_MPa;
state.session.analysis.fitLines = result.fitLines;
state.session.analysis.summary = result.summary;
state.session.analysis.status = compose( ...
    "Analyzed %s: %d branch(es), %d accepted fit(s).", ...
    source, result.segmentCount, result.acceptedCount);
state.session.analysis.resultRevision = nextRevision(state.session.analysis);
end

function value = nextRevision(analysis)
value = 1;
if isfield(analysis, "resultRevision")
    value = analysis.resultRevision + 1;
end
end
