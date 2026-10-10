function values = ecgNextBandpass(values)
%ECGNEXTBANDPASS Prepare a 1000 Hz ECG for ECGNExT without optional Toolboxes.
%   values = ecg_print.analysisRun.ecgNextBandpass(values) returns a column
%   vector, using a fifth-order Butterworth bandpass prototype (0.5-40 Hz)
%   applied forward and backward. This App preparation choice doubles the
%   magnitude-response order and removes phase delay; ECGNExT itself accepts
%   caller-prepared bandpassed data and does not prescribe filtering phase.
%   Input must be a finite real numeric vector with more than 30 samples;
%   otherwise ecg_print:InvalidECGNextFilterInput is raised. Units are unchanged.
%   No files, graphics, or optional Toolboxes are used.
%   See also ecg_print.analysisRun.ecgNextExtract.
if ~isnumeric(values) || ~isreal(values) || ~isvector(values) || ...
        numel(values) <= 30 || any(~isfinite(values))
    error('ecg_print:InvalidECGNextFilterInput', ...
        'Supply more than 30 finite samples at 1000 Hz.');
end
% Frozen MATLAB butter(5,[0.5 40]/500), zp2sos reference coefficients.
% Stable second-order sections avoid the ill-conditioned order-10 polynomial.
sections = [ ...
1 2 1 1 -1.7774929094729197 .77819849336114644;
1 2 1 1 -1.6209907298835668 .67186136810409625;
1 0 -1 1 -1.8023385728586963 .86052931372513675;
1 -2 1 1 -1.9948828608336933 .99489303040689925;
1 -2 1 1 -1.9980894557783366 .99809936096251872];
gain = 2.018200062062877e-5;
sections(1,1:3) = sections(1,1:3) * gain;
% Three times the realized filter order, matching the reference padding.
padding = 30;
values = double(values(:));
for k = 1:size(sections, 1)
    padded = [2*values(1)-values(padding+1:-1:2); values; ...
        2*values(end)-values(end-1:-1:end-padding)];
    b = sections(k,1:3);
    a = sections(k,4:6);
    % Solve the two-state constant-input equilibrium directly.
    initial = [1+a(2), -1; a(3), 1] \ ...
        [b(2)-a(2)*b(1); b(3)-a(3)*b(1)];
    forward = filter(b, a, padded, initial*padded(1));
    reverse = flipud(forward);
    reverse = filter(b, a, reverse, initial*reverse(1));
    padded = flipud(reverse);
    values = padded(padding+1:end-padding);
end
end
