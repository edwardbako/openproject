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

class Settings::WorkingDaysUpdateService < Settings::UpdateService
  def call(params)
    params = params.to_h.deep_symbolize_keys
    self.non_working_days_params = params.delete(:non_working_days) || []
    super
  end

  def validate_params(params)
    contract = Settings::WorkingDaysParamsContract.new(model, user, params:)
    ServiceResult.new success: contract.valid?,
                      errors: contract.errors,
                      result: model
  end

  def persist(call)
    ActiveRecord::Base.transaction do
      call.merge!(persist_non_working_days)
      call.merge!(super) if call.success?

      raise ActiveRecord::Rollback if call.failure?
    end

    call
  end

  private

  attr_accessor :non_working_days_params

  def persist_non_working_days
    # We don't support update for now
    to_create, to_delete = attributes_to_create_and_delete
    results = create_records(to_create)
    results.merge!(destroy_records(to_delete)) if results.success?
    results
  end

  def attributes_to_create_and_delete
    non_working_days_params.reduce([[], []]) do |results, nwd|
      results.first << nwd if !nwd[:id]
      results.last << nwd[:id] if nwd[:_destroy] && nwd[:id]
      results
    end
  end

  def create_records(attributes)
    wrap_results(attributes.map { |attrs| NonWorkingDay.create(attrs) })
  end

  def destroy_records(ids)
    wrap_results NonWorkingDay.where(id: ids).destroy_all
  end

  def wrap_results(records)
    result = NonWorkingDay.new
    errors = result.errors
    results = ServiceResult.success(errors:, result:)

    records.map do |r|
      results.add_dependent!(
        ServiceResult.new(success: r.errors.empty?, errors: r.errors, result: r)
      )
    end

    results
  end
end
