function extensions = supportedExtensions()
%SUPPORTEDEXTENSIONS Return thermal source-image extensions.
%
% App-facing contract:
%   extensions = labkit.thermal.supportedExtensions()
%
% Inputs:
%   None.
%
% Outputs:
%   extensions - string row of lowercase extensions accepted by
%       labkit.thermal.readFile/readFiles.

    extensions = [".jpg", ".jpeg", ".rjpg"];
end
