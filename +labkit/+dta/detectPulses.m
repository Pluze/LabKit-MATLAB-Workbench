function [pulse, message] = detectPulses(t, Im, meta, mode)
%DETECTPULSES Locate cathodic and anodic pulse windows in chrono data.
%
% Usage:
%   [pulse, message] = labkit.dta.detectPulses(t, Im, meta)
%   [pulse, message] = labkit.dta.detectPulses(t, Im, meta, mode)
%
% Description:
%   Finds a negative pulse followed by a positive pulse. Metadata modes use
%   ISTEP/TSTEP values when available, or VSTEP/TSTEP values when current-step
%   metadata is absent. Current-based detection identifies dominant negative
%   and positive segments directly from Im.
%
% Inputs:
%   t - Numeric time vector in seconds. Values are used in their supplied
%       order and must correspond element-for-element with Im.
%   Im - Numeric current vector in amperes with the same number of elements as
%       t.
%   meta - Chrono metadata structure, usually item.meta from loadFile. A steps
%       field may contain I, V, and T values parsed from ISTEP, VSTEP, and
%       TSTEP metadata. Use struct() when metadata is unavailable.
%   mode - Character vector, string scalar, or structure with a mode field.
%       See Mode Values. Default: "Metadata first, then auto".
%
% Mode Values:
%   metadata_first - Accepts "metadata_first" or "Metadata first, then auto".
%       Uses metadata first and falls back to Im when metadata detection fails.
%       This is the default.
%   metadata_only - Accepts "metadata_only" or "Metadata only". Does not use
%       measured-current fallback.
%   current_only - Accepts "current_only" or "Auto from Im only". Ignores
%       metadata and detects segments from Im. The threshold is 25 percent of
%       max(abs(Im)), with a 1e-12 A numerical floor.
%
% Outputs:
%   pulse - Scalar structure describing the detected windows. pulse.ok is
%       false and numeric window fields are NaN when detection fails.
%   message - Character vector explaining which method succeeded or why
%       detection failed. The same text is stored in pulse.message.
%
% Output Fields:
%   ok - Logical success flag.
%   method - "metadata-current", "metadata-voltage", "auto-from-Im", or "-".
%   cath - Structure with start_s, end_s, and current_A.
%   anod - Structure with start_s, end_s, and current_A.
%   gap - Structure with start_s, end_s, and center_s.
%   cath_start - Cathodic-window start time in seconds.
%   cath_end - Cathodic-window end time in seconds.
%   anod_start - Anodic-window start time in seconds.
%   anod_end - Anodic-window end time in seconds.
%   Ic_nominal - Nominal or median cathodic current in amperes.
%   Ia_nominal - Nominal or median anodic current in amperes.
%   pre_start - Start time of the pre-pulse region in seconds.
%   pre_end - End time of the pre-pulse region in seconds.
%   gap_start - Start time between cathodic and anodic pulses in seconds.
%   gap_end - End time between cathodic and anodic pulses in seconds.
%   post_start - Start time of the post-pulse region in seconds.
%   post_end - End time of the post-pulse region in seconds.
%
% Example:
%   t = (0:0.001:0.020).';
%   Im = zeros(size(t));
%   Im(4:7) = -1e-3;
%   Im(13:16) = 1e-3;
%   [pulse, message] = labkit.dta.detectPulses( ...
%       t, Im, struct(), "Auto from Im only");

    if nargin < 3
        meta = struct();
    end
    if nargin < 4
        mode = "Metadata first, then auto";
    end

    [pulse, message] = detectPulseCore(t, Im, meta, mode);
end
