local Translations = {
    error = {
        busy = "You're already on a courier job.",
        cooldown = "Take a breather — come back in a minute.",
        no_vehicle_spawn = "No clear space to spawn a vehicle.",
        too_far = "You're too far away.",
        invalid_job = "That courier job is no longer valid.",
        no_package = "You don't have the delivery package.",
    },
    success = {
        started = "Courier job started. Pick up the package.",
        picked_up = "Package picked up. Deliver to the next address.",
        delivered = "Delivered. Next stop sent.",
        finished = "Route complete. Get paid.",
        tier_up = "Courier rep tier unlocked: %{tier}",
    },
    info = {
        interact_pickup = "Pick up package",
        interact_deliver = "Deliver package",
        interact_start = "Start courier route",
        waypoint_set = "Waypoint set.",
        rep_gain = "Courier rep: %{rep} (%{tier})",
        police_alerted = "That drop was noisy — police might be alerted.",
    }
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
