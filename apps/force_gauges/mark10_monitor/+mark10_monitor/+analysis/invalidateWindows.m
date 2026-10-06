function applicationState = invalidateWindows(applicationState, ~, ~)
%INVALIDATEWINDOWS Keep the current curve while retiring window fits.
a = applicationState.session.analysis;
a.resultRows = cell(0, 12);
a.fitLines = struct("strain_percent", {}, "stress_MPa", {}, "pointsX", {}, "pointsY", {}, "row", {}, "windowIndex", {});
a.selectedResult = 0;
a.status = "Strain windows changed; calculate window moduli.";
a.resultRevision = a.resultRevision + 1;
applicationState.session.analysis = a;
end
