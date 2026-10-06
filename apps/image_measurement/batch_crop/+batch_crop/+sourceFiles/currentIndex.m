function index = currentIndex(applicationState)
index = max(0, round(double( ...
    applicationState.session.selection.currentIndex)));
end
