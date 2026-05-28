function Q = computeInjectedCharge(t, Im, pulse, useMeasuredCurrent)
%COMPUTEINJECTEDCHARGE Compute injected charge over cathodic/anodic pulses.

    if nargin < 4
        useMeasuredCurrent = true;
    end

    Q = struct();
    cathMask = (t >= pulse.cath_start) & (t <= pulse.cath_end);
    anodMask = (t >= pulse.anod_start) & (t <= pulse.anod_end);
    Q.cathMask = cathMask;
    Q.anodMask = anodMask;

    if sum(cathMask) < 2 || sum(anodMask) < 2
        Q.ok = false;
        Q.message = 'Pulse windows too short after detection.';
        return;
    end

    Q.Ic_est_A = median(Im(cathMask), 'omitnan');
    Q.Ia_est_A = median(Im(anodMask), 'omitnan');
    if ~isfinite(Q.Ic_est_A)
        Q.Ic_est_A = pulse.Ic_nominal;
    end
    if ~isfinite(Q.Ia_est_A)
        Q.Ia_est_A = pulse.Ia_nominal;
    end

    if useMeasuredCurrent
        Qc = abs(trapz(t(cathMask), Im(cathMask)));
        Qa = abs(trapz(t(anodMask), Im(anodMask)));
    else
        Qc = abs(pulse.Ic_nominal * (pulse.cath_end - pulse.cath_start));
        Qa = abs(pulse.Ia_nominal * (pulse.anod_end - pulse.anod_start));
    end

    Q.Qc_C = Qc;
    Q.Qa_C = Qa;
    Q.Qt_C = Qc + Qa;
    Q.ok = true;
    Q.message = 'OK';
end
