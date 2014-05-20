require 'rubygems'
gem "highline"

require "highline/import"
require "heroku-api"
require "json"
require "cf_heroku_migrator/version"

class CfMigrator
  def self.migrate
    heroku_username = ask("What is your heroku username:  ")
    heroku_password = ask("What is your heroku password:  ") { |q| q.echo = "*" }

    heroku = Heroku::API.new(:username => heroku_username, :password => heroku_password)

    apps = heroku.get_apps.body.collect { |app| app["name"] }

    heroku_app_name = ask("Which app do you want to import? (#{apps.join(", ")}):  ")

    config_vars = heroku.get_config_vars(heroku_app_name).body
    database_url = config_vars["DATABASE_URL"]
    config_vars_to_exclude = %w(PGBACKUPS_URL BUNDLE_WITHOUT LOGGING_EXPANDED_UPGRADE DATABASE_URL APP_NAME COMMIT_HASH URL HEROKU_POSTGRESQL_SILVER_URL LAST_GIT_BY RACK_ENV LANG CONSOLE_AUTH STACK)
    config_vars.delete_if { |key, value| config_vars_to_exclude.include? key }

    config_vars_keys_to_import = ask("Which config vars do you want to import? Space separate them, or press Enter to select all. (#{config_vars.keys.join(", ")}):  ")
    if config_vars_keys_to_import.length > 0
      keys_to_keep = config_vars_keys_to_import.downcase.split(" ")
      config_vars.select! { |key, value| keys_to_keep.include? key.downcase }

      raise "KEY NOT FOUND" unless keys_to_keep.length == config_vars.length
    end
    say "Pushing app to CF"
    `cf push #{heroku_app_name} --no-start --random-route`

    say "Creating a DB"
    `cf create-service elephantsql turtle #{heroku_app_name}-db`

    say "Binding to app #{heroku_app_name}"
    `cf bind-service #{heroku_app_name} #{heroku_app_name}-db`

    app_json = JSON.parse(`cf curl /v2/apps`)["resources"].find { |resource| resource["entity"]["name"] == heroku_app_name }
    service_binding_url = app_json["entity"]["service_bindings_url"]
    elephantsql_url = JSON.parse(`cf curl #{service_binding_url}`)["resources"].first["entity"]["credentials"]["uri"]


    say "Migrating DB from Heroku to CF"
    `pg_dump #{database_url} | psql -q #{elephantsql_url}`

    config_vars.each do |k, v|
      say "Setting ENV: #{k}"
      `cf set-env #{heroku_app_name} #{k} #{v}`
    end

    exec "cf start #{heroku_app_name} "
  end
end