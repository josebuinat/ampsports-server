# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

admin1 = Admin.create email: "admin@ampersports.fi", password: "ampersports", first_name: "John", last_name: "Smith",
                      admin_birth_day: 23, admin_birth_month: 1, admin_birth_year: 1971, admin_ssn: "131052-308T", level: 3

admin2 = Admin.create email: "employee@ampersports.fi", password: "ampersports", first_name: "Jane", last_name: "Smith",
                      admin_birth_day: 23, admin_birth_month: 1, admin_birth_year: 1971, admin_ssn: "131052-308T", level: 1
