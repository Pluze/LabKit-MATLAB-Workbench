function period = viewRefreshPeriod()
%VIEWREFRESHPERIOD Return the bounded UI refresh period in seconds.
% Sampling and recording may run at 50 Hz, while presentation is capped at
% 30 Hz. MATLAB timer periods use millisecond precision, so 34 ms stays below
% that ceiling instead of rounding one-thirtieth of a second down to 33 ms.
period = 0.034;
end
