module RedmineIssueProgress
  module Patches
    module TimeEntryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          validate :hours_overrun

          after_save :update_issue_done_ratio
          after_destroy :update_issue_done_ratio
        end
      end

      module InstanceMethods
        def update_issue_done_ratio
          return unless issue && issue.project.try(:module_enabled?,
                                                   :issue_progress)

          issue.init_journal(User.current)
          issue.done_ratio = CalculateDoneRatio.call(issue)
          issue.save
          UpdateParentsDoneRatio.call(issue)
        end

        def hours_overrun
          return unless issue &&
                        IssueProgressSetup.settings[:global][:enable_time_overrun] == 'true'

          if issue.estimated_hours.present?
            if ([self] + issue.time_entries).uniq.map(&:hours).sum > issue.estimated_hours
              errors.add :base, l(:error_max_spent_time)
            end
          else
            errors.add :base, l(:error_issue_not_estimated)
          end
        end
      end
    end
  end
end

unless TimeEntry.included_modules
                .include?(RedmineIssueProgress::Patches::TimeEntryPatch)
  TimeEntry.send(:include, RedmineIssueProgress::Patches::TimeEntryPatch)
end
