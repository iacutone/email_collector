[
  # Ignore warnings about missing callbacks in plugs
  {"lib/email_collector_web/plugs/auth_plug.ex", :no_return},
  {"lib/email_collector_web/plugs/api_auth_plug.ex", :no_return},
  
  # Ignore warnings about Ecto query results
  {"lib/email_collector/accounts.ex", :no_return},
  {"lib/email_collector/campaigns.ex", :no_return},
  {"lib/email_collector/emails.ex", :no_return},
  
  # Ignore warnings about Phoenix controller actions
  {"lib/email_collector_web/controllers/*.ex", :no_return},
  
  # Ignore warnings about LiveView callbacks
  {"lib/email_collector_web/components/*.ex", :no_return}
] 