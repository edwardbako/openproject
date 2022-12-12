#  OpenProject is an open source project management software.
#  Copyright (C) 2010-2022 the OpenProject GmbH
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License version 3.
#
#  OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
#  Copyright (C) 2006-2013 Jean-Philippe Lang
#  Copyright (C) 2010-2013 the ChiliProject Team
#
#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
#  See COPYRIGHT and LICENSE files for more details.

require 'spec_helper'
require_relative 'shared/shared_call_examples'

describe Settings::WorkingDaysUpdateService do
  let(:instance) do
    described_class.new(user:)
  end
  let(:user) { build_stubbed(:user) }
  let(:contract) do
    instance_double(Settings::UpdateContract,
                    validate: contract_success,
                    errors: instance_double(ActiveModel::Error))
  end
  let(:contract_success) { true }
  let(:params_contract) do
    instance_double(Settings::WorkingDaysParamsContract,
                    valid?: params_contract_success,
                    errors: instance_double(ActiveModel::Error))
  end
  let(:params_contract_success) { true }
  let(:setting_name) { :a_setting_name }
  let(:new_setting_value) { 'a_new_setting_value' }
  let(:previous_setting_value) { 'the_previous_setting_value' }
  let(:setting_params) { { setting_name => new_setting_value } }
  let(:params) { setting_params }

  before do
    # stub a setting definition
    allow(Setting)
      .to receive(:[])
          .and_call_original
    allow(Setting)
      .to receive(:[]).with(setting_name)
          .and_return(previous_setting_value)
    allow(Setting)
      .to receive(:[]=)

    # stub contract
    allow(Settings::UpdateContract)
      .to receive(:new)
          .and_return(contract)
    allow(Settings::WorkingDaysParamsContract)
      .to receive(:new)
          .and_return(params_contract)
  end

  describe '#call' do
    subject { instance.call(params) }

    include_examples 'successful call'

    context 'when non working days are present' do
      let!(:existing_nwd) { create(:non_working_day) }
      let!(:nwd_to_delete) { create(:non_working_day) }
      let(:params) do
        {
          non_working_days: {
            '0' => { 'name' => 'Christmas Eve', 'date' => '2022-12-24' },
            '1' => { 'name' => 'NYE', 'date' => '2022-12-31' },
            '2' => { 'id' => existing_nwd.id },
            '3' => { 'id' => nwd_to_delete.id, '_destroy' => true }
          }
        }
      end

      include_examples 'successful call'

      it 'persists the non working days' do
        expect { subject }.to change(NonWorkingDay, :count).by(1)

        expect(NonWorkingDay.all).to contain_exactly(
          have_attributes(name: 'Christmas Eve', date: Date.parse('2022-12-24')),
          have_attributes(name: 'NYE', date: Date.parse('2022-12-31')),
          have_attributes(existing_nwd.attributes)
        )
      end
    end

    context 'when the params contract is not successfully validated' do
      let(:params_contract_success) { false }

      include_examples 'unsuccessful call'

      context 'when non working days are present' do
        include_examples 'unsuccessful call'

        it 'does not persists the non working days' do
          expect { subject }.not_to change(NonWorkingDay, :count)
        end
      end
    end

    context 'when the contract is not successfully validated' do
      let(:contract_success) { false }

      include_examples 'unsuccessful call'

      context 'when non working days are present' do
        include_examples 'unsuccessful call'
      end
    end
  end
end
