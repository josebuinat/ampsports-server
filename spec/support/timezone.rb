::Timezone::Lookup.config(:test)

# default geocode stub
::Timezone::Lookup.lookup.stub(60.175405, 24.914562, 'Europe/Helsinki')

# San Jose
::Timezone::Lookup.lookup.stub(37.2155652, -121.8664214, 'America/Los_Angeles')

# Helsinki, Finland
::Timezone::Lookup.lookup.stub(60.1699, 24.9384, 'Europe/Helsinki')

# five, twelve, twenty
::Timezone::Lookup.lookup.stub(60.2103587, 24.8790765, 'Europe/Helsinki')
::Timezone::Lookup.lookup.stub(60.281247, 24.995652, 'Europe/Helsinki')
::Timezone::Lookup.lookup.stub(60.35461945, 24.9621778, 'Europe/Helsinki')


def in_venue_tz
  Time.use_zone(venue.timezone) { yield }
end
