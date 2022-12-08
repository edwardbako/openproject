#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe Admin::Settings::WorkingDaysSettingsController do
  before do
    allow(@controller).to receive(:set_localization)
    @params = {}

    @user = create(:admin)
    allow(User).to receive(:current).and_return @user
  end

  describe 'show.html' do
    def fetch
      get 'show'
    end

    it_behaves_like 'a controller action with require_admin'
  end

  describe 'show' do
    render_views

    it 'contains check boxes for the working days' do
      get 'show'

      expect(response).to be_successful
      expect(response).to render_template 'admin/settings/working_days_settings/show'
    end
  end

  describe 'update' do
    it 'stores the working days settings if checked' do
      patch 'update', params: { settings: { working_days: ['1', '2'] } }

      expect(response).to redirect_to action: 'show'
    end
  end
end
