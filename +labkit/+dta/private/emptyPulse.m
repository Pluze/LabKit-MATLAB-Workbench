% Private DTA helper. Expected caller: labkit.dta facade and internal parser,
% session, pulse, or item pipeline. Inputs and outputs use internal structs,
% tables, file paths, or numeric vectors. Side effects: file discovery/parser reads
% only where named; assumes app-specific workflow decisions stay outside +labkit.
function pulse = emptyPulse()
%EMPTYPULSE Return the canonical empty chrono pulse struct.
%
% Output:
%   pulse - struct with ok=false and unit-explicit nested phase windows.
%
% Notes:
%   All private pulse detectors start from this shape so public DTA item and
%   pulse outputs remain stable when detection fails.

    pulse = struct('ok', false, 'method', '-', 'message', '');
    pulse.pre = struct('start_s', NaN, 'end_s', NaN);
    pulse.cath = struct('start_s', NaN, 'end_s', NaN, 'current_A', NaN);
    pulse.gap = struct('start_s', NaN, 'end_s', NaN, 'center_s', NaN);
    pulse.anod = struct('start_s', NaN, 'end_s', NaN, 'current_A', NaN);
    pulse.post = struct('start_s', NaN, 'end_s', NaN);
end
