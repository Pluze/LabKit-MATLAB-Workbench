function [choices, passband, lineBand] = bands()
% The comparison protocol uses a 20–450 Hz passband and a 58–62 Hz line band.
    passband = [20 450];
    lineBand = [58 62];
    choices = ["As recorded", "20–450 Hz"];
end
