function applicationState = useRecommendedFrequency(applicationState, ~)
% Restore the source-derived recommended display window.
window = applicationState.session.nyquist;
window.lower = window.recommended;
window.upper = window.limits(2);
applicationState.session.nyquist = window;
end
