json.partial! 'base', admin: @admin
json.permissions @admin.permissions
json.in_company_listed_as_public @admin.company.can_be_listed_as_public?
