function period = framePeriod()
%FRAMEPERIOD Return the responsive fixed-speed replay frame period.
% Replay advances data in chunks at 10 visual frames per second. This stays
% comfortably below the 30 Hz App presentation ceiling and leaves MATLAB's
% event loop available for plot navigation and playback controls.
period = 0.1;
end
