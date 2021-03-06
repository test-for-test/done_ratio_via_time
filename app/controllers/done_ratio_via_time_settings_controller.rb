# Copyright (C) 2018 Tecforce - All rights reserved.

# This file is part of “Done ration via time plugin”.

# “Done ration via time plugin” or its sources can not be copied and/or
# distributed without the express permission of Tecforce. Unauthorized copying
# of this file, via any media, is strictly prohibited.

# Proprietary and confidential.
# For more details please contact sales@tecforce.ru.

class DoneRatioViaTimeSettingsController < ApplicationController
  before_action :require_admin

  def edit
    @settings = DoneRatioSetup.settings[:global]
  end

  def update
    new_done_ratio_calculation_type =
      settings_params[:done_ratio_calculation_type]
    if new_done_ratio_calculation_type.present? &&
       DoneRatioSetup.settings[:global][:done_ratio_calculation_type] !=
       new_done_ratio_calculation_type
      is_recalculation_required = true
    end
    DoneRatioSetup.setting[:global] = settings_params
    flash[:notice] = l(:notice_successful_update)
    if is_recalculation_required
      DoneRatioSetup.setting[:job_id] =
        IssueDoneRatioRecalculationWorker.perform_async
    end
    redirect_to action: :edit
  end

  private

  def settings_params
    params.require(:settings).permit(:done_ratio_calculation_type,
                                     :enable_time_overrun,
                                     trackers_with_disabled_manual_mode: [])
  end
end
