function applicationState = resetFrequency(applicationState, ~)
% Restore the source-derived frequency domain without changing source data.
window = applicationState.session.nyquist;
window.lower = window.limits(1);
window.upper = window.limits(2);
applicationState.session.nyquist = window;
end
