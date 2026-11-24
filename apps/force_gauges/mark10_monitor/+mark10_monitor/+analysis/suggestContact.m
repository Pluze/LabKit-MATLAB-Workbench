function applicationState = suggestContact(applicationState, context)
%SUGGESTCONTACT Offer a draft only when the user requests offline review.
if applicationState.session.acquisition.monitoring, return; end
[t, f, ~] = mark10_monitor.analysis.sourceData(applicationState,context);
a = applicationState.session.analysis;
contact = mark10_monitor.analysis.contactCandidate(t,f);
if isfinite(contact)
    a.travelDraft.contact_s = contact;
    a.contactSuggestion = compose("Candidate %.4g s. Review against the force trace before applying.",contact);
else
    a.contactSuggestion = "No sustained force rise resolved. Enter a contact time from the recording.";
end
applicationState.session.analysis = a;
end
