# frozen_string_literal: true

ActiveAdmin.register Enrollment do # rubocop:disable Metrics/BlockLength
  # See permitted parameters documentation:
  # https://github.com/activeadmin/activeadmin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  permit_params :member_id, :start_time, :end_time
  belongs_to :mission

  index do
    column :member
    column :mission
    column(:start_time) { |enrollment| enrollment.start_time.strftime('%H:%M') }
    column(:end_time) { |enrollment| enrollment.end_time.strftime('%H:%M') }
    actions
  end

  form do |f|
    unless f.object.persisted?
      f.object.start_time = resource.mission.start_date
      f.object.end_time = resource.mission.due_date
    end
    f.inputs do
      f.input :member, include_blank: false
      f.input :start_time, include_blank: false
      f.input :end_time, include_blank: false
      actions
    end
  end

  controller do # rubocop:disable Metrics/BlockLength
    def create # rubocop:disable Metrics/AbcSize
      build_resource
      transaction_result = Admin::Enrollments::CreateTransaction.new.call(resource)
      if transaction_result.success?
        flash[:notice] = translate 'enrollments.create.confirm_enroll'
        redirect_to admin_mission_path(params[:mission_id])
      else
        flash[:error] = transaction_result.failure
        render :new
      end
    end

    def update # rubocop:disable Metrics/AbcSize
      build_resource
      transaction_result = update_transaction
      if transaction_result.success?
        flash[:notice] = translate 'enrollments.update.confirm_update'
        redirect_to admin_mission_path(params[:mission_id])
      else
        flash[:error] = transaction_result.failure
        render :edit
      end
    end

    private

    def update_transaction
      enrollment = Enrollment.find(params[:id])
      Admin::Enrollments::UpdateTransaction.new.call({ params: permitted_params[:enrollment], enrollment: enrollment })
    end
  end
end
