function result = compute(time, force, travel, parameters, experimentType)
%COMPUTE Prepare selected engineering data and fit all enabled strain windows.
curve = mark10_monitor.analysis.prepareCurve(time,force,travel,parameters,experimentType);
result = mark10_monitor.analysis.fitWindows(curve,parameters.windows,experimentType);
result.curve = curve;
end
