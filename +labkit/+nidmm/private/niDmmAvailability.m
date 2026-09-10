function status = niDmmAvailability()
% Inspect the fixed end-user-installed NI-DMM .NET runtime without hardware.
% Secondary-runtime facade boundary: user-installed NI-DMM .NET runtime.
status = struct("Available", false, ...
    "Status", "unsupported_platform", ...
    "Message", "NI-DMM USB devices require 64-bit Windows.", ...
    "DriverVersion", "", ...
    "RequiredComponent", ...
    "NationalInstruments.ModularInstruments.NIDmm.Fx45");
if ~ispc || computer("arch") ~= "win64"
    return;
end
try
    assembly = NET.addAssembly( ...
        "NationalInstruments.ModularInstruments.NIDmm.Fx45");
    requiredType = assembly.AssemblyHandle.GetType( ...
        "NationalInstruments.ModularInstruments.NIDmm.NIDmm");
    if isempty(requiredType)
        status.Status = "driver_incompatible";
        status.Message = "The installed NI-DMM .NET API is incompatible.";
        return;
    end
    status.Available = true;
    status.Status = "available";
    status.Message = "NI-DMM runtime is available.";
    status.DriverVersion = string( ...
        assembly.AssemblyHandle.GetName().Version.ToString());
catch
    status.Status = "driver_missing";
    status.Message = "Install the 64-bit NI-DMM driver with .NET support.";
end
end
