function [choices, passband] = bands()
% EMG review focuses on 5–500 Hz. Applying this band to the waveform is optional.
    passband = [5 500];
    choices = ["As recorded", "5–500 Hz"];
end
