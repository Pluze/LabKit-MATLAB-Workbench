function [status, output] = runIsolatedAppProbe(app)
%RUNISOLATEDAPPPROBE Run one public App contract in a reset child process.
%   [STATUS, OUTPUT] = labkittest.runIsolatedAppProbe(APP) is the single-App
%   convenience form of labkittest.runIsolatedAppProbes. New catalog specs
%   normally use the batch form so public Apps share one child startup while
%   every probe still resets its executable path boundary.

    [status, output] = labkittest.runIsolatedAppProbes(app);
end
