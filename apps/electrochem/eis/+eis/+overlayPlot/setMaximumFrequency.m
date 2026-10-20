function applicationState = setMaximumFrequency(applicationState, value, ~)
% Keep the two inclusive display bounds ordered after a committed adjustment.
window = applicationState.session.nyquist;
window.upper = min(max(value, window.limits(1)), window.limits(2));
window.lower = min(window.lower, window.upper);
applicationState.session.nyquist = window;
end
