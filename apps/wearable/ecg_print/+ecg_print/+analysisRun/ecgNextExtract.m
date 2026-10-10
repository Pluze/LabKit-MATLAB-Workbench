function result = ecgNextExtract(raw, bandpassed, rPeaks, fs)
%ECGNEXTEXTRACT Extract noise using the pinned FDA ECGNExT algorithm.
%   result = ecg_print.analysisRun.ecgNextExtract(raw, bandpassed, rPeaks, fs)
%   accepts equal-length finite real vectors in the same amplitude units,
%   accurate strictly increasing integer R indices, and fs exactly 1000 Hz.
%   Supply at least 30 seconds of stable-morphology ECG and at least four
%   peaks spaced more than 200 ms apart. Filtering and peak identification
%   are caller responsibilities. A simultaneous clean reference is preferred.
%
%   result.noise and result.time are row vectors matching the FDA outputs.
%   Time is a crossfaded plotting reference, not a uniform sampling clock.
%   result.template and result.synthetic expose intermediate median ECGs;
%   synthetic retains the reference's boundary NaNs. beatIndex assigns each
%   extracted sample to its nearest R interval; beatComplete marks intervals
%   with all planned samples and excludes first/last boundary beats. These
%   provenance fields are App additions. No SNR is defined here.
%   Raw minus bandpassed residual is restored after QRS removal. Default
%   QRS blank and blend widths are respectively 40 and 60 ms per side.
%
%   Invalid inputs raise ecg_print:InvalidECGNextInput. Unsupported reference
%   indexing raises ecg_print:ECGNextPeakGeometry; inadequate median coverage
%   raises ecg_print:ECGNextTemplateUnavailable or ECGNextTemplateTooShort.
%   This function has no graphics, files, or optional Toolbox dependencies.
%
%   Derived and modified from dbp-osel/ECGNExT NoiseExtractClass.m at
%   972c66cb274319acf705776d723b8e52372e22f0. Modifications: value-struct
%   interface, input guards, intermediate outputs, and diagnostic error.
%   The default reference calculation and its sample indexing are retained.
%   See Galeotti and Scully, Journal of Electrocardiology 51 (2018), S56-S60.
%   See also ecg_print.analysisRun.analyzeSignal.

%{
This classdef construct includes the functions and sub modules necessary
to implement the ECG_NExT algorithm that obtains representative samples
of noise and motion artifacts from ECG devices under test.

Authors:
Ahmad Suliman
Christopher Scully
Loriano Galeotti

The ECG_NExT algorithm is described and published in:
Galeotti, L. and C.G. Scully, "A method to extract realistic artifacts from
electrocardiogram recordings from robust algorithm testing," Journal of
Electrocardiology, 2018. 51(6, Supplement): p. S56-S60.

If you have found this software useful, please consider citing our publication.

Disclaimer:
This software and documentation (the "Software") were developed at the Food
and Drug Administration (FDA) by employees of the Federal Government in the
course of their official duties. Pursuant to Title 17, Section 105 of the
United States Code, this work is not subject to copyright protection and is
in the public domain. Permission is hereby granted, free of charge, to any
person obtaining a copy of the Software, to deal in the Software without
restriction, including without limitation the rights to use, copy, modify,
merge, publish, distribute, sublicense, or sell copies of the Software or
derivatives, and to permit persons to whom the Software is furnished to do
so. FDA assumes no responsibility whatsoever for use by other parties of
the Software, its source code, documentation or compiled executables, and
makes no guarantees, expressed or implied, about its quality, reliability,
or any other characteristic. Further, use of this code in no way implies
endorsement by the FDA or confers any advantage in regulatory decisions.
Although this software can be redistributed and/or modified freely, we ask
that any derivative works bear some notice that they are derived from it,
and any modified versions bear some notice that they have been modified.
%}

if ~isnumeric(raw) || ~isvector(raw) || ~isreal(raw) || ...
        ~isnumeric(bandpassed) || ~isvector(bandpassed) || ...
        ~isreal(bandpassed) || numel(raw) ~= numel(bandpassed) || ...
        any(~isfinite(raw)) || any(~isfinite(bandpassed)) || ...
        ~isequal(fs, 1000) || numel(raw) < 30000 || ...
        ~isnumeric(rPeaks) || ~isvector(rPeaks) || ~isreal(rPeaks) || ...
        numel(rPeaks) < 4 || any(~isfinite(rPeaks)) || ...
        any(rPeaks ~= fix(rPeaks)) || any(diff(rPeaks) <= 200) || ...
        any(rPeaks < 1 | rPeaks > numel(raw))
    error('ecg_print:InvalidECGNextInput', ...
        'Use finite ECG vectors at 1000 Hz, at least 30 s, and reliable R indices.');
end
raw = double(raw(:)');
bandpassed = double(bandpassed(:)');
rPeaks = double(rPeaks(:)');
% Preserve reference indexing while rejecting its undefined edge geometry.
shortLeft = floor(min(diff(rPeaks)) * .29);
shortPeaks = rPeaks;
if shortPeaks(1) < shortLeft
    shortPeaks(1) = [];
end
if numel(raw) < shortPeaks(end) + 2 * shortLeft
    shortPeaks(end) = [];
end
if isempty(shortPeaks) || shortPeaks(1) - shortLeft < 1 || ...
        shortPeaks(end) + 2 * shortLeft > numel(raw)
    error('ecg_print:ECGNextPeakGeometry', ...
        'R indices are incompatible with the reference median window.');
end
[medianBeat, alignment] = ComputeMedianBeat_long(bandpassed, rPeaks, fs);
if any(~isfinite(medianBeat))
    error('ecg_print:ECGNextTemplateUnavailable', ...
        'No complete median beat; review the R indices and recording interval.');
end
synthetic = GenSynECG_blend(medianBeat, rPeaks, numel(raw), fs);
noise = RemRpkEffect(bandpassed - synthetic, rPeaks, fs);
residual = RemRpkEffect(raw - bandpassed, rPeaks, fs);
time = RemRpkEffect((0:numel(raw)-1) / fs, rPeaks, fs);
bandResidualNoise = noise;
noise = noise + residual;
% Carry beat identity through exactly the same removal and crossfade. Every
% crossfade lies within +/-100 ms of R; spacing >200 ms guarantees that
% both contributors have the same nearest-R identity.
sourceBeat = discretize(1:numel(raw), [-Inf (rPeaks(1:end-1)+rPeaks(2:end))/2 Inf]);
plannedBeat = round(RemRpkEffect(sourceBeat, rPeaks, fs));
compressedRaw = RemRpkEffect(raw,rPeaks,fs);
compressedSignal = RemRpkEffect(synthetic,rPeaks,fs);
keep = ~isnan(noise);
beatIndex = plannedBeat(keep);
expected = accumarray(plannedBeat(isfinite(plannedBeat))', 1, [numel(rPeaks) 1]);
observed = accumarray(beatIndex', 1, [numel(rPeaks) 1]);
complete = expected > 0 & expected == observed;
complete([1 end]) = false;
result = struct('noise', noise(keep), 'time', time(keep), ...
    'template', medianBeat, 'synthetic', synthetic, ...
    'beatIndex', beatIndex, 'beatComplete', complete, ...
    'bandResidualNoise',bandResidualNoise(keep), ...
    'restoredResidualNoise',residual(keep), ...
    'compressedRaw',compressedRaw(keep),'compressedSignal',compressedSignal(keep), ...
    'alignment',alignment);
end

function [sigOut, stitch] = RemRpkEffect(sigIn, Rpeaks, fs, varargin)
    % This function removes an area around R peaks and merges the segments
    % surrounding the removed area with crossfade of neighboring signal
    % segments around the removed area.
    %
    % Inputs:
    % sigIn: This input can represent an ECG, the estimated noise or the time
    % vector in this context as a row of samples.
    % Rpeaks: R peak indices
    % fs: sampling frequency
    %
    % Outputs:
    % sigOut: blended sigIn
    % stitch: midpoint of crossfade region (samples of sigOut).

    % Definition of blanklen and blendlen parameters:
    % The blanklen parameter is the length of signal (in milliseconds) being
    % removed from around of each R peak in final ECG noise; this is the part
    % really canceled before and after each Rpeak.
    % The blendlen parameter is the length of the neighboring signal segment
    % (in milliseconds) around the canceled part to be crossfaded when
    % stitching.

    % An "if" construct is included to make blanklen and blendlen parameters
    % optional and assign them default values.
    if isempty(varargin)
        blanklen = 40e-3;
        blendlen = 60e-3;
    else
        blanklen = varargin{1}(1);
        blendlen = varargin{1}(2);
    end
    % Convert to samples:
    blanklen = blanklen * fs;
    blendlen = blendlen * fs;

    % Create linear crossfade function
    W = linspace(1, 0, blendlen + 1);

    out_locs = [Rpeaks(:)-blanklen Rpeaks(:)+blanklen];
    blend_locs = [out_locs(:,1)-blendlen out_locs(:,2)+blendlen];

    % Adjust for Rpeaks too close to end of signal
    if blend_locs(end,2) >= length(sigIn)
        blend_locs(end,:) = [];
        out_locs(end,:) = [];
        Rpeaks(end) = [];
    end

    % Initialize the stitch vector
    rpkLen = length(Rpeaks);
    stitch = zeros(1, rpkLen);

    % Start after 1st beat to remove errors related to location of 1st beat
    sigOut(1:blend_locs(1,2)) = NaN;
    for n = 2:rpkLen
        % Copy from end of last blend region to start of new blend region
        segadd = sigIn(blend_locs(n-1,2)+1:blend_locs(n,1)-1);
        sigOut(length(sigOut)+1:length(sigOut)+length(segadd)) = segadd;

        % Blend cross fade region
        segadd = sigIn(blend_locs(n,1):out_locs(n,1)).*W + ...
            sigIn(out_locs(n,2):blend_locs(n,2)).*(1-W);

        % Keep track of stitch points:
        stitch(n) = length(sigOut) + floor(length(segadd)/2);
        sigOut(length(sigOut)+1:length(sigOut)+length(segadd)) = segadd;
    end
    stitch(1) = [];

    % Add data after last Rpeak
    segadd = sigIn(blend_locs(n,2)+1:end);
    sigOut(length(sigOut)+1:length(sigOut)+length(segadd)) = segadd;
% End of function
end

function [MedBeat, alignment] = ComputeMedianBeat_long(ECG, Rpeaks, fs)
    % Compute median beat
	%
    % Inputs: ECG, R-peak locations
    % Output: Median beat, correction

    % Get short median, it is used to adjust X and Y offset
    MedShort = ComputeMedianBeat_short(ECG, Rpeaks);

    shortl = floor(length(MedShort)/3);

    % Arbitrary area for the QRS complex to do time sync. For normal
	% patients should be <120ms, in this case let's do 50 ms each side.

    arbLen = 50e-3;
    arbLenSamp = arbLen*fs;
    qrsa = min(arbLenSamp, shortl-1) ;

    % Arbitray max lag for crosscorr search in seconds.
    maxcorrlag = 20e-3;
    maxcorrlagSamp = maxcorrlag*fs;

    % Number of extra samples in each median beat (on the left double on
    % the right) should be at least as much as the cross-fade half duration
    extrabeat = 60;

    % Since sampling frequency at development time was 1000 samples/s:
    extrabeat = ceil(extrabeat*fs/1000);

    % Determine max RR interval to set segment lengths
    RRint = diff(Rpeaks);
    maxRR = max(RRint);

    % Get left and right segments, chop out a bit from 1/3>
    segl = floor(maxRR*0.35) + extrabeat + 1;
    segr = 2*segl;

    % Initialize
    ECGmatxy = NaN(length(Rpeaks),segl + segr + 1);
    yoffset = NaN(length(Rpeaks),1);
    xoffset = yoffset ;

    m = 1;

    % Catch cases where first Rpeak is too close to start of record
    while (m < length(Rpeaks)) && (Rpeaks(m) - segl - maxcorrlagSamp < 1)
        m = m + 1;
    end
    % Main loop on each qrs peak to fill ECG beat array
    while (m < length(Rpeaks)) && ...
            (Rpeaks(m) + segr + maxcorrlagSamp < length(ECG))
        % Calculate difference from short beat on Y
        shortdiff = MedShort - ECG(Rpeaks(m)-shortl:Rpeaks(m)+2*shortl);
        yoffset(m) = mean(shortdiff);
        [crosscorr,xcorrlag] = xcorr(ECG(Rpeaks(m)-qrsa:Rpeaks(m)+qrsa), ...
            MedShort(shortl-qrsa:shortl+qrsa), maxcorrlagSamp);
        [~, maxxcorri] = max(crosscorr);
        xoffset(m) = xcorrlag(maxxcorri);
        xoff = -xoffset(m);

        % Correct on X and Y.
        ECGmatxy(m,:) = (ECG(Rpeaks(m)-segl+xoff:Rpeaks(m)+2*segl+xoff))' + yoffset(m);

		% Increase loop counter
        m = m + 1;
    % End while
    end

    % Compute median from ECG beat array
    MedBeat = median(ECGmatxy, 1, 'omitnan');
    alignment = struct('shortTemplate',MedShort,'alignedBeats',ECGmatxy, ...
        'time',(-segl:segr)/fs,'timeShiftSamples',xoffset, ...
        'verticalShift',yoffset,'rPeaks',Rpeaks);
% End of function
end

function [MedBeat, ECGmat] = ComputeMedianBeat_short(ECG, Rpeaks)
    % Compute median beat
	%
    % Inputs: ECG, R-peak locations
    % Output: Median beat

    % Get RR intervals
    RRint = diff(Rpeaks);
    minRR = min(RRint);

    % Get left and right segments, chop out a bit from 1/3
    segl = floor(minRR*.29);
    segr = 2*segl;

    % Remove peaks too close to the edge
    if Rpeaks(1) < segl
        Rpeaks = Rpeaks(2:end);
    end
    if length(ECG) < Rpeaks(end) + segr
        Rpeaks = Rpeaks(1:end-1);
    end

    % Initialize and fill ECG beat array
    ECGmat = zeros(length(Rpeaks), segl + segr + 1);
    for m = 1:length(Rpeaks)
        ECGmat(m,:) = (ECG(Rpeaks(m)-segl:Rpeaks(m)+segr))';
    end

    % Compute median from ECG beat array
    MedBeat = median(ECGmat,1, "omitnan");

    % Ensure it is a row
    MedBeat = MedBeat(:)';
end

function [SynECG] = GenSynECG_blend(MedBeat, Rpeaks, ecgRefLen, fs)
    % Compute synthetic ECG by blending median beats.
	%
    % Inputs: MedBeat, Rpeak location, ecgRefLen (Length of reference ECG),
    % Output: synthetic ECG

    % Cross-fade over last xx elements
    % Half of the crossfade
    crosshalfn = 50;

    % Since sampling rate at development time was 1000 sample/s:
    crosshalfn = floor(crosshalfn*fs/1000);
    medl = floor(length(MedBeat)/3);

    % Add a dummy beat at the end to fill the full space
    Rpeaks(end+1) = Rpeaks(end)+floor(mean(diff(Rpeaks)));

    % Set total out recording duration to avoid overflow
    ECGlen = max(ecgRefLen, Rpeaks(end)+2*medl+2);

    % Create linear crossfade function
    W = linspace(1, 0, 2*crosshalfn + 1);

    % Create empty output.
    SynECG = NaN(1,ECGlen);
    m = 2 ;

    % If initial Rpeak is <= medl, delete and start with second Rpeak
    if Rpeaks(1) < medl
        Rpeaks(1) = [];
    end

    while m < length(Rpeaks)
        % Get segment duration for current beat (a beat is 1 segment to the
        % left and 2 segments to the right of QRS)
        segl = floor((Rpeaks(m) - Rpeaks(m-1))*1/3);

        % Merge point is 1/3 beat back.
        mergepoint = Rpeaks(m) - segl;

        % Getting pointers for extremes of crossfade region of output
        sl = mergepoint - crosshalfn;
        sr = mergepoint + crosshalfn;

        % Pointers for xfade region of median beat
        ml = medl + 1 - segl - crosshalfn;
        mr = ml + 2*crosshalfn;
        mx = length(MedBeat) - mr;

        % Check for errors:
        if ml < 1
            error('ecg_print:ECGNextTemplateTooShort', ...
                'Median beat is too short for the reference crossfade.');
        end

        % Crossfade on the left
        SynECG(sl:sr) = SynECG(sl:sr).*W + MedBeat(ml:mr).*(1 - W);

        % Stamp median beat outside the crossfade region
        SynECG(sr+1: sr+mx) = MedBeat(mr+1:end);

        % Increment counter
        m = m + 1;
    % End while
    end
    SynECG = SynECG(1:ecgRefLen);
% End function
end
