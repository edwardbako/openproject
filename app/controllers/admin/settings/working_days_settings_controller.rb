module Admin::Settings
  class WorkingDaysSettingsController < ::Admin::SettingsController
    current_menu_item [:show] do
      :working_days
    end

    def default_breadcrumb
      t(:label_working_days)
    end

    def show_local_breadcrumb
      true
    end

    def settings_params
      settings = super
      settings[:working_days] = parse_working_days_params(settings)
      settings
    end

    def update_service
      ::Settings::WorkingDaysUpdateService
    end

    private

    def parse_working_days_params(settings)
      settings[:working_days] ? settings[:working_days].compact_blank.map(&:to_i).uniq : []
    end
  end
end
