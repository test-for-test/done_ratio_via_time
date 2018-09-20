require 'singleton'

module IssueProgressSetup
  class SettingsProxy
    include Singleton

    def []=(key, value)
      key = key.intern if key.is_a?(String)
      settings = safe_load
      settings[key] = value
      Setting.plugin_redmine_issue_progress = settings
    end

    def to_h
      h = safe_load
      h.freeze
      h
    end

    private

    def safe_load
      # At the first migration, the settings table will not exist
      return {} unless Setting.table_exists?

      settings = Setting.plugin_redmine_issue_progress.dup
      if settings.is_a?(String)
        Rails.logger.error 'Unable to load settings'
        return {}
      end
      settings
    end
  end

  def setting
    SettingsProxy.instance
  end
  module_function :setting

  def settings
    SettingsProxy.instance.to_h
  end
  module_function :settings
end
