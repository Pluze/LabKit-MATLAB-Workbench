function modeled = reconstructTravel(time, profile)
%RECONSTRUCTTRAVEL Evaluate signed linear travel only inside supported strokes.
modeled = nan(size(time));
for stroke = profile.strokes
    inMotion = time>=stroke.interval_s(1) & time<=stroke.interval_s(2);
    modeled(inMotion) = stroke.anchorGap_mm + ...
        (stroke.speed_mm_min/60)*(time(inMotion)-stroke.anchor_s);
end
end
