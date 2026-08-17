function state = invalidate(state, ~, ~)
%INVALIDATE Clear results after data interpretation parameters change.
state.session.analysis.resultRows = cell(0, 11);
state.session.analysis.plotStrain_percent = zeros(0, 1);
state.session.analysis.plotStress_MPa = zeros(0, 1);
state.session.analysis.fitLines = struct( ...
    "strain_percent", {}, "stress_MPa", {}, "accepted", {});
state.session.analysis.summary = "No current modulus analysis.";
state.session.analysis.status = ...
    "Analysis settings changed; calculate modulus again.";
state.session.analysis.resultRevision = nextRevision(state.session.analysis);
end

function value = nextRevision(analysis)
value = 1;
if isfield(analysis, "resultRevision")
    value = analysis.resultRevision + 1;
end
end
