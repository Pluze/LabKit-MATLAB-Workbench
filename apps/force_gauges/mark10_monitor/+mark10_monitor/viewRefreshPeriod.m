function period = viewRefreshPeriod()
%VIEWREFRESHPERIOD Return the bounded UI refresh period in seconds.
% Sampling and in-memory retention may run at 50 Hz, while a 10 Hz plot is
% responsive to the eye and leaves the MATLAB event queue available for
% controls and serial work.
period = 0.1;
end
