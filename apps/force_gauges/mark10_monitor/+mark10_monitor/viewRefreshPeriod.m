function period = viewRefreshPeriod()
%VIEWREFRESHPERIOD Return the bounded UI refresh period in seconds.
% Sampling and in-memory retention may run near 50 Hz. MATLAB serial and
% native-graphics callbacks share the client event thread, so the plot is a
% deliberately slower latest-snapshot consumer. Two visual updates per
% second leave most event-loop time to the device without changing which
% samples are retained for export.
period = 0.5;
end
