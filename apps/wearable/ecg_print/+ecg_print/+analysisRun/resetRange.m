function applicationState = resetRange(applicationState)
%RESETRANGE Initialize selection at tenths of a second within the decoded source.
signal = applicationState.session.cache.signal;
last = 0;
if ~isempty(signal), last = signal.time(end); end
applicationState.project.parameters.roiStart = 0;
% Keep the exact file duration as the control limit; default to a valid tenth.
timeStep = 0.1;
endTime = round(last/timeStep)*timeStep;
if endTime > last, endTime = floor(last/timeStep)*timeStep; end
applicationState.project.parameters.roiEnd = endTime;
end
