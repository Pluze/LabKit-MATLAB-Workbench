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
%   pre - Structure with start_s and end_s.
%   cath - Structure with start_s, end_s, and current_A.
%   gap - Structure with start_s, end_s, and center_s.
%   anod - Structure with start_s, end_s, and current_A.
%   post - Structure with start_s and end_s.
%
% Failure Behavior:
%   Missing usable metadata, absent opposite-polarity current phases, or
%   unsupported mode text returns pulse.ok=false with NaN window fields and
%   an explanatory message. t and Im must be corresponding numeric vectors;
%   incompatible MATLAB values or lengths may raise the originating indexing
%   or conversion error.
%
% Example:
%   t = (0:0.001:0.020).';
%   Im = zeros(size(t));
%   Im(4:7) = -1e-3;
%   Im(13:16) = 1e-3;
%   [pulse, message] = labkit.dta.detectPulses( ...
%       t, Im, struct(), "Auto from Im only");
%
% See also labkit.dta.loadFile,
%   labkit.dta.getMainCurve

    if nargin < 3
        meta = struct();
    end
    if nargin < 4
        mode = "Metadata first, then auto";
    end

    [pulse, message] = detectPulseCore(t, Im, meta, mode);
end
