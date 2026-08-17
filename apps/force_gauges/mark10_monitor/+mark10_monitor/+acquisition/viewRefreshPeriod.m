function period = viewRefreshPeriod()
%VIEWREFRESHPERIOD Return the bounded UI refresh period in seconds.
% Sampling and in-memory retention may run near 50 Hz on the background
% worker. The client receives bounded batches at most every 0.1 seconds, so
% a 10 Hz latest-snapshot view is smooth without creating redundant renders
% or changing which samples are retained for export.
period = 0.1;
end
