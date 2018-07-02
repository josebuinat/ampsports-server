Geocoder.configure(lookup: :test)

Geocoder::Lookup::Test.add_stub(
  'Helsinki, Finland', [
    {
      'latitude'     => 60.1699,
      'longitude'    => 24.9384,
      'address'      => 'Helsinki, Finland',
      'country'      => 'Finland',
      'country_code' => 'fi'
    }
  ]
)

Geocoder::Lookup::Test.add_stub(
  '6604 Northridge Dr, San Jose 95120', [
    {
      'latitude'     => 37.2155652,
      'longitude'    => -121.8664214,
      'address'      => '6604 Northridge Dr, San Jose 95120',
      'country'      => 'USA',
      'country_code' => 'us'
    }
  ]
)

{ five: [60.2103587, 24.8790765], # 5.55 km (3.45 mi) from Helsinki
  twelve: [60.281247, 24.995652], # 12.70 km (7.89 mi) from Helsinki
  twenty: [60.35461945, 24.9621778] # 20.10 km (12.49 mi)
}.each do |name, coordinates|
  Geocoder::Lookup::Test.add_stub(
    # Geocode fires with "street, city zip"
    "#{name}, Helsinki 00100", [
    {
      'latitude'     => coordinates[0],
      'longitude'    => coordinates[1],
      'address'      => 'Helsinki, Finland',
      'country'      => 'Finland',
      'country_code' => 'fi'
    }
  ]
)
end

Geocoder::Lookup::Test.set_default_stub (
  [
    {
      'latitude'     => 60.175405,
      'longitude'    => 24.914562,
      'address'      => 'Mannerheimintie 5, Helsinki, 00100',
      'state'        => 'Helsinki',
      'state_code'   => 'HL',
      'country'      => 'Finland',
      'country_code' => 'FI'
    }
  ]
)
