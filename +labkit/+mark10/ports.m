function values = ports()
%PORTS List serial ports currently available to the Mark-10 driver.
%
% Usage:
%   values = labkit.mark10.ports()
%
% Description:
%   Returns MATLAB serial ports that are currently available. It does not
%   open or identify any port; use discover for protocol probing.
%
% Inputs:
%   None.
%
% Outputs:
%   values - Column string array of serial port names.
%
% Errors:
%   MATLAB serialportlist errors are propagated.
%
% Typical Call:
%   values = labkit.mark10.ports();
%   assert(iscolumn(values))
%
% See also labkit.mark10.discover, labkit.mark10.connect
    values = string(serialportlist("available"));
    values = values(:);
end
