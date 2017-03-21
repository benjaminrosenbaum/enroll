module Api
  module V1
    module Mobile::Util
      class EmployeeUtil < Api::V1::Mobile::Base

        def employees_sorted_by
          @employee_name ? _census_employees_by_status.employee_name(@employee_name) : _census_employees_by_status
        end

        def roster_employees
          @employees.compact.map { |ee|
            _cache_result.empty? ? _roster_employee(ee, ee.benefit_group_assignments) :
                _roster_employee(ee, _cached_benefit_group_assignments(ee), _cache_result[:grouped_bga_enrollments])
          }
        end

        #
        # A faster way of counting employees who are enrolled vs waived vs terminated
        # where enrolled + waived = counting towards SHOP minimum healthcare participation
        # We first do the query to find families with appropriate enrollments,
        # then check again inside the map/reduce to get only those enrollments.
        # This avoids undercounting, e.g. two family members working for the same employer.
        #
        def count_by_enrollment_status
          return [0, 0, 0] if _benefit_group_assignments.blank?

          enrolled_or_renewal = HbxEnrollment::ENROLLED_STATUSES + HbxEnrollment::RENEWAL_STATUSES
          waived = HbxEnrollment::WAIVED_STATUSES
          terminated = HbxEnrollment::TERMINATED_STATUSES

          bga_ids = @benefit_group_assignments.map(&:id)
          all_enrollments = FamilyUtil.new(benefit_group_assignment_ids: bga_ids, aasm_states: enrolled_or_renewal + waived + terminated).family_hbx_enrollments
          benefit_group = BenefitGroupUtil.new all_enrollments: all_enrollments

          # Return count of enrolled, count of waived, count of terminated - only including those originally asked for
          benefit_group.benefit_group_assignment_ids enrolled_or_renewal, waived, terminated do |enrolled_ids, waived_ids, terminated_ids|
            [enrolled_ids, waived_ids, terminated_ids].map { |found_ids| (found_ids & bga_ids).count }
          end
        end

        #
        # Private
        #
        private

        def _cached_benefit_group_assignments employee
          _cache_result[:employees_benefits].detect { |b| b.keys.include? employee.id.to_s }.try(:[], :benefit_group_assignments) || []
        end

        def _cache_result
          @cache_result ||= Api::V1::Mobile::Cache::PlanCache.new(employees: @employees, employer_profile: @employer_profile).plan_and_benefit_group
        end

        def _benefit_group_assignments
          @benefit_group_assignments ||= @benefit_group.census_members.map do |ee|
            ee.benefit_group_assignments.select do |bga|
              @benefit_group.ids.include?(bga.benefit_group_id) &&
                  (::PlanYear::RENEWING_PUBLISHED_STATE.include?(@benefit_group.plan_year.aasm_state) || bga.is_active)
            end.tap { |bgas_for_ee| BenefitGroupAssignmentsUtil.new(assignments: bgas_for_ee).unique_by_year }
          end.flatten
        end

        def _census_employees_by_status
          @census_employees ||= case @status
                                  when :terminated.to_s
                                    @employer_profile.census_employees.terminated
                                  when :all.to_s
                                    @employer_profile.census_employees
                                  else
                                    @employer_profile.census_employees.active
                                end.sorted
        end

        def _roster_employee employee, benefit_group_assignments, grouped_bga_enrollments=nil
          result = _employee_hash employee
          result[:enrollments] = _enrollment_instance(benefit_group_assignments, grouped_bga_enrollments).populate_enrollments
          result[:dependents] = DependentUtil.new(employee: employee).include_dependents
          result
        end

        def _employee_hash employee
          result = JSON.parse Api::V1::Mobile::Insured::InsuredPerson.new(person: employee).basic_person
          result[:id] = employee.id
          result[:hired_on] = employee.hired_on
          result[:is_business_owner] = employee.is_business_owner
          result
        end

        def _enrollment_instance benefit_group_assignments, grouped_bga_enrollments
          enrollment = Api::V1::Mobile::Enrollment::EmployeeEnrollment.new benefit_group_assignments: benefit_group_assignments
          enrollment.grouped_bga_enrollments = grouped_bga_enrollments if grouped_bga_enrollments
          enrollment
        end

      end
    end
  end
end