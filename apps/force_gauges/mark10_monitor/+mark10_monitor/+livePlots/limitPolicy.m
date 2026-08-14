function policy = limitPolicy(rate_Hz)
%LIMITPOLICY Define unit-safe headroom and a sample-count time horizon.
arguments
    rate_Hz (1, 1) double {mustBePositive, mustBeFinite}
end
% Physical margins are user-facing monitor defaults. The time margin covers
% a fixed sample horizon, so faster streams do not force more limit changes.
samplesPerExpansion = 250;
policy = struct("initialForceMargin_N", 1, ...
    "initialTravelMargin_mm", 10, ...
    "timeMargin_s", samplesPerExpansion / rate_Hz);
end
