function applicationState = setMinimumFrequency(applicationState, value, ~)
% Keep the two inclusive display bounds ordered after a committed adjustment.
window = applicationState.session.nyquist;
window.lower = min(max(value, window.limits(1)), window.limits(2));
window.upper = max(window.upper, window.lower);
applicationState.session.nyquist = window;
end
