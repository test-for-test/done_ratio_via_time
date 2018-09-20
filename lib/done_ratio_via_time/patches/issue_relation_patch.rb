module DoneRatioViaTime
  module Patches
    # Add new issue relation type
    module IssueRelationPatch
      def self.included(base)
        include_time_from = 'include_time_from'
        include_time_by = 'include_time_by'

        new_types = base::TYPES.merge(
          include_time_from => {
            name: :label_include_time_from,
            sym_name: :label_include_time_by,
            order: 10,
            sym: include_time_by
          },

          include_time_by => {
            name: :label_include_time_by,
            sym_name: :label_include_time_from,
            order: 11,
            sym: include_time_from,
            reverse: include_time_from
          }
        )

        base.send(:include, InstanceMethods)
        base.class_eval do
          const_set :TYPE_INCLUDE_TIME_FROM, include_time_from
          const_set :TYPE_INCLUDE_TIME_BY, include_time_by

          remove_const :TYPES
          const_set :TYPES, new_types.freeze

          inclusion_validator =
            _validators[:relation_type].find { |v| v.kind == :inclusion }
          inclusion_validator.instance_variable_set(:@delimiter, new_types.keys)
          after_save :update_issue_done_ratio
          after_destroy :update_issue_done_ratio
        end
      end

      module InstanceMethods
        def update_issue_done_ratio
          return if relation_type != IssueRelation::TYPE_INCLUDE_TIME_FROM ||
                    !issue_from.project.try(:module_enabled?, :issue_progress)

          issue_from.init_journal(User.current)
          issue_from.done_ratio = CalculateDoneRatio.call(issue_from)
          issue_from.save
          UpdateParentsDoneRatio.call(issue_from)
        end
      end
    end
  end
end

unless IssueRelation.included_modules
                    .include?(DoneRatioViaTime::Patches::IssueRelationPatch)
  IssueRelation.send(:include,
                     DoneRatioViaTime::Patches::IssueRelationPatch)
end
