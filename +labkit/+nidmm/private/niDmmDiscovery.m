function devices = niDmmDiscovery()
% Enumerate local NI-DMM aliases through user-installed NI software.
% Secondary-runtime facade boundary: user-installed NI .NET runtime.
template = struct("Resource", "", "Model", "", "Bus", "");
try
    NET.addAssembly("NationalInstruments.SystemConfiguration");
catch cause
    exception = MException("labkit:nidmm:DiscoveryUnavailable", ...
        "Install NI System Configuration support to discover NI-DMM devices.");
    throwAsCaller(addCause(exception, cause));
end
try
    system = NationalInstruments.SystemConfiguration.SystemConfiguration( ...
        "localhost");
    systemCleanup = onCleanup(@() disposeQuietly(system));
    experts = ["nidmmscx", "nidmm408x"];
    collections = cell(numel(experts), 1);
    collectionCleanups = cell(numel(experts), 1);
    total = 0;
    for expertIndex = 1:numel(experts)
        filter = NationalInstruments.SystemConfiguration.Filter(system);
        filterCleanup = onCleanup(@() disposeQuietly(filter));
        filter.ExpertProgrammaticName = char(experts(expertIndex));
        collection = system.FindHardware(filter);
        collections{expertIndex} = collection;
        collectionCleanups{expertIndex} = ...
            onCleanup(@() disposeQuietly(collection));
        total = total + double(collection.Count);
        clear filterCleanup
    end
    devices = repmat(template, total, 1);
    found = 0;
    for expertIndex = 1:numel(experts)
        collection = collections{expertIndex};
        for index = 0:double(collection.Count) - 1
            item = collection.Item(int32(index));
            itemCleanup = onCleanup(@() disposeQuietly(item));
            resource = strip(string(item.UserAlias));
            if strlength(resource) > 0
                model = propertyText(item, "ProductName");
                bus = string(item.ConnectsToBusType.ToString());
                found = found + 1;
                devices(found) = struct( ...
                    "Resource", resource, "Model", model, "Bus", bus);
            end
            clear itemCleanup
        end
    end
    devices = devices(1:found);
    clear collectionCleanups
    clear systemCleanup
catch cause
    if startsWith(string(cause.identifier), "labkit:nidmm:")
        rethrow(cause);
    end
    exception = MException("labkit:nidmm:DiscoveryFailed", ...
        "NI System Configuration could not enumerate local NI-DMM devices.");
    throwAsCaller(addCause(exception, cause));
end
if isempty(devices)
    return;
end
[~, first] = unique(lower(string({devices.Resource})), "stable");
devices = devices(sort(first));
end

function value = propertyText(item, property)
value = "";
try
    propertyInfo = item.GetType().GetProperty(char(property));
    value = strip(string(propertyInfo.GetValue(item, [])));
catch
end
end

function disposeQuietly(value)
try
    value.Dispose();
catch
end
end
