function applicationState = applyTravelSettings(applicationState, context)
%APPLYTRAVELSETTINGS Validate and commit the settings used by monitoring and analysis.
settings = applicationState.session.analysis.travelDraft;
if ~any(settings.mode==mark10_monitor.analysis.travelModes()) || ...
        ~isfinite(settings.speed_mm_min) || settings.speed_mm_min<0 || ...
        (settings.mode=="Entered speed" && settings.speed_mm_min==0) || ...
        ~isfinite(settings.contact_s) || (settings.contact_s<0 && settings.contact_s~=-1)
    context.alert("Enter a positive speed for Entered speed and a contact time of -1 or a nonnegative time.", ...
        "Travel Reconstruction");
    return;
end
applicationState.session.analysis.travel = settings;
applicationState.session.analysis.contactSuggestion = "";
applicationState = mark10_monitor.analysis.invalidate(applicationState,context,[]);
applicationState = mark10_monitor.analysis.reprojectPlots(applicationState,context);
end
