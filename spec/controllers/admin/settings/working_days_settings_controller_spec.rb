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
  shared_let(:user) { create(:admin) }

  current_user { user }

  describe 'show' do
    describe 'permissions' do
      let(:fetch) { get 'show' }

      it_behaves_like 'a controller action with require_admin'
    end

    it 'contains check boxes for the working days' do
      get 'show'

      expect(response).to be_successful
      expect(response).to render_template 'admin/settings/working_days_settings/show'
    end
  end

  describe 'update' do
    let(:working_days) { [*'1'..'7'] }
    let(:non_working_days) { {} }
    let(:params) do
      { settings: { working_days:, non_working_days: } }
    end

    subject { patch 'update', params: }

    it 'succeeds' do
      subject

      expect(response).to redirect_to action: 'show'
      expect(flash[:notice]).to eq I18n.t(:notice_successful_update)
    end

    context 'with non_working_days' do
      let(:non_working_days) do
        { '0' => { 'name' => 'Christmas Eve', 'date' => '2022-12-24' } }
      end

      it 'succeeds' do
        subject

        expect(response).to redirect_to action: 'show'
        expect(flash[:notice]).to eq I18n.t(:notice_successful_update)
      end

      it 'creates the non_working_days' do
        expect { subject }.to change(NonWorkingDay, :count).by(1)
        expect(NonWorkingDay.first).to have_attributes(name: 'Christmas Eve', date: '2022-12-24')
      end

      it 'updates existing non_working_days' do
        nwd = NonWorkingDay.create!(name: 'Christmas', date: '2022-12-24')
        non_working_days["0"]["id"] = nwd.id.to_s

        expect { subject }.not_to change(NonWorkingDay, :count)
        expect(NonWorkingDay.first).to have_attributes(name: 'Christmas Eve', date: '2022-12-24')
      end
    end
  end
end
